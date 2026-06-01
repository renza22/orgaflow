begin;

-- =========================================================
-- Sprint 5: Auto Rebalance Wizard
-- OrgaFlow
-- =========================================================

-- 1. Samakan definisi admin dengan Flutter.
-- Owner, admin, dan beberapa position operasional boleh rebalance.
create or replace function public.is_org_admin(org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.members m
    where m.organization_id = org_id
      and m.profile_id = auth.uid()
      and m.status = 'active'::public.member_status_enum
      and (
        m.role in ('owner'::public.member_role_enum, 'admin'::public.member_role_enum)
        or lower(coalesce(m.position_code, '')) in (
          'ketua_divisi',
          'kadep',
          'kepala_departemen',
          'koordinator_divisi'
        )
      )
  );
$$;


-- 2. Tambahkan kolom status eksekusi ke rebalance_items.
alter table public.rebalance_items
  add column if not exists status text not null default 'proposed';

alter table public.rebalance_items
  add column if not exists applied_at timestamptz;

alter table public.rebalance_items
  add column if not exists applied_by uuid references auth.users(id) on delete set null;

alter table public.rebalance_items
  add column if not exists skipped_reason text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'rebalance_items_status_chk'
      and conrelid = 'public.rebalance_items'::regclass
  ) then
    alter table public.rebalance_items
      add constraint rebalance_items_status_chk
      check (status in ('proposed', 'approved', 'rejected', 'applied', 'skipped'));
  end if;
end $$;

create index if not exists rebalance_items_plan_status_idx
  on public.rebalance_items (plan_id, status);


-- 3. Biar query bisa di-run ulang tanpa konflik signature.
drop function if exists public.generate_auto_rebalance_plan(uuid, integer, uuid);
drop function if exists public.execute_rebalance_plan(uuid, uuid[]);


-- =========================================================
-- RPC 1: generate_auto_rebalance_plan
-- Membuat rekomendasi rebalance otomatis.
-- =========================================================

create function public.generate_auto_rebalance_plan(
  p_organization_id uuid,
  p_max_items integer default 5,
  p_project_id uuid default null
)
returns table (
  plan_id uuid,
  item_id uuid,
  item_status text,
  task_id uuid,
  task_title text,
  task_status text,
  estimated_hours integer,
  from_member_id uuid,
  from_member_name text,
  from_load_percentage numeric,
  from_assigned_hours integer,
  from_capacity_hours integer,
  to_member_id uuid,
  to_member_name text,
  to_current_load_percentage numeric,
  to_projected_load_percentage numeric,
  to_assigned_hours integer,
  to_capacity_hours integer,
  matching_skill_count integer,
  matched_skills text[],
  score_before numeric,
  score_after numeric,
  recommendation_reason text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_plan_id uuid;
  v_limit integer;
  v_inserted_count integer;
begin
  if auth.uid() is null then
    raise exception using
      message = 'User belum login.',
      errcode = '28000';
  end if;

  if p_organization_id is null then
    raise exception using
      message = 'Organisasi wajib dipilih.',
      errcode = '23502';
  end if;

  if not public.is_org_admin(p_organization_id) then
    raise exception using
      message = 'Hanya admin organisasi yang dapat menjalankan Auto Rebalance.',
      errcode = '42501';
  end if;

  v_limit := greatest(coalesce(p_max_items, 5), 1);

  insert into public.rebalance_plans (
    organization_id,
    project_id,
    created_by,
    status,
    reason,
    summary
  )
  values (
    p_organization_id,
    p_project_id,
    auth.uid(),
    'proposed'::public.rebalance_plan_status_enum,
    'Auto Rebalance Wizard',
    jsonb_build_object(
      'mode', 'auto_rebalance',
      'generated_at', now(),
      'max_items', v_limit
    )
  )
  returning id into v_plan_id;

  insert into public.rebalance_items (
    plan_id,
    task_id,
    from_member_id,
    to_member_id,
    recommendation_reason,
    score_before,
    score_after,
    status
  )
  with source_tasks as (
    select
      t.id as task_id,
      t.title as task_title,
      t.status as task_status,
      p.id as project_id,
      p.organization_id,
      ta.member_id as from_member_id,
      coalesce(ta.allocation_hours, t.estimated_hours, 0)::integer as moving_hours,
      coalesce(t.estimated_hours, 0)::integer as estimated_hours,
      sw.full_name as from_member_name,
      coalesce(sw.assigned_hours, 0)::integer as source_assigned_hours,
      coalesce(sw.weekly_capacity_hours, 0)::integer as source_capacity_hours,
      coalesce(sw.load_ratio, 0)::numeric as source_load_ratio,
      coalesce(sw.load_percentage, 0)::numeric as source_load_percentage,
      coalesce(sw.warning_threshold, 0.7000)::numeric as warning_threshold,
      coalesce(sw.overload_threshold, 1.0000)::numeric as overload_threshold
    from public.task_assignments ta
    join public.tasks t
      on t.id = ta.task_id
    join public.projects p
      on p.id = t.project_id
    join public.v_member_workload sw
      on sw.member_id = ta.member_id
    where p.organization_id = p_organization_id
      and (p_project_id is null or p.id = p_project_id)
      and t.status in (
        'todo'::public.task_status_enum,
        'in_progress'::public.task_status_enum
      )
      and coalesce(sw.weekly_capacity_hours, 0) > 0
      and coalesce(sw.load_ratio, 0) >= coalesce(sw.warning_threshold, 0.7000)
      and coalesce(ta.allocation_hours, t.estimated_hours, 0) > 0
  ),
  required_summary as (
    select
      tsr.task_id,
      count(*)::integer as required_skill_count
    from public.task_skill_requirements tsr
    group by tsr.task_id
  ),
  candidate_pairs as (
    select
      st.*,
      tm.id as to_member_id,
      tp.full_name as to_member_name,
      coalesce(tw.assigned_hours, 0)::integer as target_assigned_hours,
      coalesce(tw.weekly_capacity_hours, tm.weekly_capacity_hours, 0)::integer as target_capacity_hours,
      coalesce(tw.load_ratio, 0)::numeric as target_current_load_ratio,
      coalesce(tw.load_percentage, 0)::numeric as target_current_load_percentage,

      case
        when coalesce(tw.weekly_capacity_hours, tm.weekly_capacity_hours, 0) <= 0 then 999::numeric
        else round(
          (
            (coalesce(tw.assigned_hours, 0) + st.moving_hours)::numeric
            / coalesce(tw.weekly_capacity_hours, tm.weekly_capacity_hours, 0)::numeric
          ),
          4
        )
      end as target_projected_load_ratio,

      case
        when coalesce(tw.weekly_capacity_hours, tm.weekly_capacity_hours, 0) <= 0 then 999::numeric
        else round(
          (
            (coalesce(tw.assigned_hours, 0) + st.moving_hours)::numeric
            / coalesce(tw.weekly_capacity_hours, tm.weekly_capacity_hours, 0)::numeric
          ) * 100,
          2
        )
      end as target_projected_load_percentage,

      case
        when st.source_capacity_hours <= 0 then 0::numeric
        else round(
          greatest(st.source_assigned_hours - st.moving_hours, 0)::numeric
          / st.source_capacity_hours::numeric,
          4
        )
      end as source_after_load_ratio,

      case
        when st.source_capacity_hours <= 0 then 0::numeric
        else round(
          (
            greatest(st.source_assigned_hours - st.moving_hours, 0)::numeric
            / st.source_capacity_hours::numeric
          ) * 100,
          2
        )
      end as source_after_load_percentage,

      coalesce(rs.required_skill_count, 0)::integer as required_skill_count,
      coalesce(sm.matching_skill_count, 0)::integer as matching_skill_count,
      coalesce(sm.matched_skills, '{}'::text[]) as matched_skills
    from source_tasks st
    join public.members tm
      on tm.organization_id = st.organization_id
     and tm.status = 'active'::public.member_status_enum
     and tm.availability_status = 'available'::public.availability_status_enum
     and tm.id <> st.from_member_id
    join public.profiles tp
      on tp.id = tm.profile_id
    left join public.v_member_workload tw
      on tw.member_id = tm.id
    left join required_summary rs
      on rs.task_id = st.task_id
    left join lateral (
      select
        count(distinct req.skill_id)::integer as matching_skill_count,
        coalesce(
          array_agg(distinct s.name order by s.name)
            filter (where s.name is not null),
          '{}'::text[]
        ) as matched_skills
      from public.task_skill_requirements req
      join public.member_skills ms
        on ms.skill_id = req.skill_id
       and ms.member_id = tm.id
       and ms.proficiency_level >= req.minimum_level
      left join public.skills s
        on s.id = req.skill_id
      where req.task_id = st.task_id
    ) sm on true
    where not exists (
        select 1
        from public.task_assignments existing_ta
        where existing_ta.task_id = st.task_id
          and existing_ta.member_id = tm.id
      )
      and coalesce(tw.load_ratio, 0) < st.warning_threshold
      and (
        coalesce(rs.required_skill_count, 0) = 0
        or coalesce(sm.matching_skill_count, 0) > 0
      )
      and (
        case
          when coalesce(tw.weekly_capacity_hours, tm.weekly_capacity_hours, 0) <= 0 then false
          else
            (
              (coalesce(tw.assigned_hours, 0) + st.moving_hours)::numeric
              / coalesce(tw.weekly_capacity_hours, tm.weekly_capacity_hours, 0)::numeric
            ) < st.warning_threshold
        end
      )
  ),
  scored as (
    select
      cp.*,
      (
        case
          when cp.required_skill_count = 0 then 20
          else round(
            least(
              cp.matching_skill_count::numeric
              / nullif(cp.required_skill_count, 0)::numeric,
              1
            ) * 60
          )::integer
        end
        +
        round(
          greatest(cp.warning_threshold - cp.target_projected_load_ratio, 0)
          / nullif(cp.warning_threshold, 0)
          * 30
        )::integer
        +
        case
          when cp.source_after_load_ratio < cp.source_load_ratio then 10
          else 0
        end
      )::integer as total_score,

      format(
        '%s turun dari %s%% ke %s%%. %s naik dari %s%% ke %s%%. Skill cocok: %s.',
        coalesce(cp.from_member_name, 'Anggota sumber'),
        round(cp.source_load_percentage, 0),
        round(cp.source_after_load_percentage, 0),
        coalesce(cp.to_member_name, 'Anggota target'),
        round(cp.target_current_load_percentage, 0),
        round(cp.target_projected_load_percentage, 0),
        case
          when array_length(cp.matched_skills, 1) is null then 'tidak ada requirement khusus'
          else array_to_string(cp.matched_skills, ', ')
        end
      )::text as recommendation_reason
    from candidate_pairs cp
  ),
  ranked_task as (
    select
      s.*,
      row_number() over (
        partition by s.task_id
        order by
          s.total_score desc,
          s.matching_skill_count desc,
          s.target_projected_load_ratio asc,
          s.to_member_name asc
      ) as rn_task
    from scored s
  ),
  task_winners as (
    select *
    from ranked_task
    where rn_task = 1
  ),
  ranked_target as (
    select
      tw.*,
      row_number() over (
        partition by tw.to_member_id
        order by
          tw.source_load_ratio desc,
          tw.total_score desc,
          tw.moving_hours desc,
          tw.task_title asc
      ) as rn_target
    from task_winners tw
  ),
  final_suggestions as (
    select *
    from ranked_target
    where rn_target = 1
    order by
      source_load_ratio desc,
      total_score desc,
      moving_hours desc,
      task_title asc
    limit v_limit
  )
  select
    v_plan_id,
    fs.task_id,
    fs.from_member_id,
    fs.to_member_id,
    fs.recommendation_reason,
    least(999.99, greatest(0, fs.source_load_percentage))::numeric(5,2),
    least(999.99, greatest(0, fs.source_after_load_percentage))::numeric(5,2),
    'proposed'
  from final_suggestions fs;

  get diagnostics v_inserted_count = row_count;

  update public.rebalance_plans
  set summary = summary || jsonb_build_object(
      'suggested_items', v_inserted_count,
      'generated_at', now()
    )
  where id = v_plan_id;

  return query
  select
    ri.plan_id,
    ri.id as item_id,
    ri.status as item_status,
    t.id as task_id,
    t.title as task_title,
    t.status::text as task_status,
    coalesce(t.estimated_hours, 0)::integer as estimated_hours,

    ri.from_member_id,
    coalesce(pf.full_name, 'Tanpa Nama')::text as from_member_name,
    coalesce(wf.load_percentage, 0)::numeric as from_load_percentage,
    coalesce(wf.assigned_hours, 0)::integer as from_assigned_hours,
    coalesce(wf.weekly_capacity_hours, 0)::integer as from_capacity_hours,

    ri.to_member_id,
    coalesce(pt.full_name, 'Tanpa Nama')::text as to_member_name,
    coalesce(wt.load_percentage, 0)::numeric as to_current_load_percentage,

    case
      when coalesce(wt.weekly_capacity_hours, 0) <= 0 then 0::numeric
      else round(
        (
          (coalesce(wt.assigned_hours, 0) + coalesce(t.estimated_hours, 0))::numeric
          / wt.weekly_capacity_hours::numeric
        ) * 100,
        2
      )
    end as to_projected_load_percentage,

    coalesce(wt.assigned_hours, 0)::integer as to_assigned_hours,
    coalesce(wt.weekly_capacity_hours, 0)::integer as to_capacity_hours,

    coalesce(sm.matching_skill_count, 0)::integer as matching_skill_count,
    coalesce(sm.matched_skills, '{}'::text[]) as matched_skills,

    ri.score_before,
    ri.score_after,
    ri.recommendation_reason
  from public.rebalance_items ri
  join public.tasks t
    on t.id = ri.task_id
  left join public.members mf
    on mf.id = ri.from_member_id
  left join public.profiles pf
    on pf.id = mf.profile_id
  left join public.members mt
    on mt.id = ri.to_member_id
  left join public.profiles pt
    on pt.id = mt.profile_id
  left join public.v_member_workload wf
    on wf.member_id = ri.from_member_id
  left join public.v_member_workload wt
    on wt.member_id = ri.to_member_id
  left join lateral (
    select
      count(distinct req.skill_id)::integer as matching_skill_count,
      coalesce(
        array_agg(distinct s.name order by s.name)
          filter (where s.name is not null),
        '{}'::text[]
      ) as matched_skills
    from public.task_skill_requirements req
    join public.member_skills ms
      on ms.skill_id = req.skill_id
     and ms.member_id = ri.to_member_id
     and ms.proficiency_level >= req.minimum_level
    left join public.skills s
      on s.id = req.skill_id
    where req.task_id = t.id
  ) sm on true
  where ri.plan_id = v_plan_id
  order by ri.created_at asc;
end;
$$;

grant execute on function public.generate_auto_rebalance_plan(uuid, integer, uuid)
to authenticated;


-- =========================================================
-- RPC 2: execute_rebalance_plan
-- Mengeksekusi item rebalance yang di-approve admin.
-- =========================================================

create function public.execute_rebalance_plan(
  p_plan_id uuid,
  p_item_ids uuid[] default null
)
returns table (
  plan_id uuid,
  requested_count integer,
  applied_count integer,
  skipped_count integer,
  message text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
  v_plan_status public.rebalance_plan_status_enum;
  v_requested_count integer := 0;
  v_applied_count integer := 0;
  v_skipped_count integer := 0;

  v_allocation_hours integer;
  v_is_primary boolean;
  v_moving_hours integer;

  v_target_assigned_hours integer;
  v_target_capacity_hours integer;
  v_warning_threshold numeric;
  v_projected_ratio numeric;

  v_required_skill_count integer;
  v_matching_skill_count integer;

  r record;
begin
  if auth.uid() is null then
    raise exception using
      message = 'User belum login.',
      errcode = '28000';
  end if;

  if p_plan_id is null then
    raise exception using
      message = 'Plan rebalance wajib dipilih.',
      errcode = '23502';
  end if;

  select rp.organization_id, rp.status
  into v_org_id, v_plan_status
  from public.rebalance_plans rp
  where rp.id = p_plan_id;

  if v_org_id is null then
    raise exception using
      message = 'Plan rebalance tidak ditemukan.',
      errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_org_id) then
    raise exception using
      message = 'Hanya admin organisasi yang dapat mengeksekusi rebalance.',
      errcode = '42501';
  end if;

  if v_plan_status in (
    'applied'::public.rebalance_plan_status_enum,
    'cancelled'::public.rebalance_plan_status_enum
  ) then
    raise exception using
      message = 'Plan rebalance sudah selesai atau dibatalkan.',
      errcode = '23514';
  end if;

  for r in
    select
      ri.id as item_id,
      ri.task_id,
      ri.from_member_id,
      ri.to_member_id,
      t.title as task_title,
      t.status as task_status,
      coalesce(t.estimated_hours, 0)::integer as estimated_hours,
      p.id as project_id,
      p.organization_id,
      coalesce(pf.full_name, 'Anggota sumber') as from_member_name,
      coalesce(pt.full_name, 'Anggota target') as to_member_name
    from public.rebalance_items ri
    join public.tasks t
      on t.id = ri.task_id
    join public.projects p
      on p.id = t.project_id
    left join public.members mf
      on mf.id = ri.from_member_id
    left join public.profiles pf
      on pf.id = mf.profile_id
    left join public.members mt
      on mt.id = ri.to_member_id
    left join public.profiles pt
      on pt.id = mt.profile_id
    where ri.plan_id = p_plan_id
      and (
        p_item_ids is null
        or array_length(p_item_ids, 1) is null
        or ri.id = any(p_item_ids)
      )
      and ri.status in ('proposed', 'approved')
    order by ri.created_at asc
    for update of ri
  loop
    v_requested_count := v_requested_count + 1;

    if r.organization_id <> v_org_id then
      update public.rebalance_items
      set status = 'skipped',
          skipped_reason = 'Task tidak berada di organisasi plan.'
      where id = r.item_id;

      v_skipped_count := v_skipped_count + 1;
      continue;
    end if;

    if r.task_status not in (
      'todo'::public.task_status_enum,
      'in_progress'::public.task_status_enum
    ) then
      update public.rebalance_items
      set status = 'skipped',
          skipped_reason = 'Task tidak lagi aktif.'
      where id = r.item_id;

      v_skipped_count := v_skipped_count + 1;
      continue;
    end if;

    select ta.allocation_hours, ta.is_primary
    into v_allocation_hours, v_is_primary
    from public.task_assignments ta
    where ta.task_id = r.task_id
      and ta.member_id = r.from_member_id
    limit 1;

    if not found then
      update public.rebalance_items
      set status = 'skipped',
          skipped_reason = 'Assignment sumber sudah tidak ditemukan.'
      where id = r.item_id;

      v_skipped_count := v_skipped_count + 1;
      continue;
    end if;

    if exists (
      select 1
      from public.task_assignments ta
      where ta.task_id = r.task_id
        and ta.member_id = r.to_member_id
    ) then
      update public.rebalance_items
      set status = 'skipped',
          skipped_reason = 'Member target sudah memiliki task ini.'
      where id = r.item_id;

      v_skipped_count := v_skipped_count + 1;
      continue;
    end if;

    v_moving_hours := coalesce(v_allocation_hours, r.estimated_hours, 0);

    select
      coalesce(w.assigned_hours, 0)::integer,
      coalesce(w.weekly_capacity_hours, m.weekly_capacity_hours, 0)::integer,
      coalesce(w.warning_threshold, 0.7000)::numeric
    into
      v_target_assigned_hours,
      v_target_capacity_hours,
      v_warning_threshold
    from public.members m
    left join public.v_member_workload w
      on w.member_id = m.id
    where m.id = r.to_member_id
      and m.organization_id = v_org_id
      and m.status = 'active'::public.member_status_enum
      and m.availability_status = 'available'::public.availability_status_enum;

    if not found then
      update public.rebalance_items
      set status = 'skipped',
          skipped_reason = 'Member target tidak aktif atau tidak available.'
      where id = r.item_id;

      v_skipped_count := v_skipped_count + 1;
      continue;
    end if;

    if v_target_capacity_hours <= 0 then
      update public.rebalance_items
      set status = 'skipped',
          skipped_reason = 'Member target belum mengatur kapasitas mingguan.'
      where id = r.item_id;

      v_skipped_count := v_skipped_count + 1;
      continue;
    end if;

    v_projected_ratio := round(
      (v_target_assigned_hours + v_moving_hours)::numeric
      / v_target_capacity_hours::numeric,
      4
    );

    if v_projected_ratio >= v_warning_threshold then
      update public.rebalance_items
      set status = 'skipped',
          skipped_reason = 'Member target tidak lagi berada dalam status green.'
      where id = r.item_id;

      v_skipped_count := v_skipped_count + 1;
      continue;
    end if;

    select count(*)::integer
    into v_required_skill_count
    from public.task_skill_requirements req
    where req.task_id = r.task_id;

    if v_required_skill_count > 0 then
      select count(distinct req.skill_id)::integer
      into v_matching_skill_count
      from public.task_skill_requirements req
      join public.member_skills ms
        on ms.skill_id = req.skill_id
       and ms.member_id = r.to_member_id
       and ms.proficiency_level >= req.minimum_level
      where req.task_id = r.task_id;

      if coalesce(v_matching_skill_count, 0) = 0 then
        update public.rebalance_items
        set status = 'skipped',
            skipped_reason = 'Member target tidak lagi memiliki skill yang cocok.'
        where id = r.item_id;

        v_skipped_count := v_skipped_count + 1;
        continue;
      end if;
    end if;

    delete from public.task_assignments
    where task_id = r.task_id
      and member_id = r.from_member_id;

    insert into public.task_assignments (
      task_id,
      member_id,
      assigned_by,
      allocation_hours,
      is_primary
    )
    values (
      r.task_id,
      r.to_member_id,
      auth.uid(),
      v_allocation_hours,
      coalesce(v_is_primary, true)
    );

    insert into public.project_members (
      project_id,
      member_id,
      added_by
    )
    values (
      r.project_id,
      r.to_member_id,
      auth.uid()
    )
    on conflict on constraint project_members_unique
    do nothing;

    insert into public.notifications (
      recipient_member_id,
      actor_user_id,
      type,
      title,
      body,
      entity_type,
      entity_id
    )
    values
    (
      r.to_member_id,
      auth.uid(),
      'rebalance'::public.notification_type_enum,
      'Task hasil rebalance',
      format('Task "%s" dipindahkan ke Anda melalui Auto Rebalance.', r.task_title),
      'task',
      r.task_id
    ),
    (
      r.from_member_id,
      auth.uid(),
      'rebalance'::public.notification_type_enum,
      'Task dialihkan',
      format('Task "%s" dialihkan dari Anda melalui Auto Rebalance.', r.task_title),
      'task',
      r.task_id
    );

    update public.rebalance_items
    set status = 'applied',
        applied_at = now(),
        applied_by = auth.uid(),
        skipped_reason = null
    where id = r.item_id;

    v_applied_count := v_applied_count + 1;
  end loop;

  if v_requested_count = 0 then
    raise exception using
      message = 'Tidak ada item rebalance yang dipilih.',
      errcode = 'P0002';
  end if;

  if v_applied_count > 0 then
    update public.rebalance_plans
    set status = 'applied'::public.rebalance_plan_status_enum,
        summary = summary || jsonb_build_object(
          'requested_count', v_requested_count,
          'applied_count', v_applied_count,
          'skipped_count', v_skipped_count,
          'applied_at', now()
        )
    where id = p_plan_id;

    insert into public.activity_logs (
      actor_user_id,
      organization_id,
      entity_type,
      entity_id,
      action,
      metadata
    )
    values (
      auth.uid(),
      v_org_id,
      'rebalance_plan',
      p_plan_id,
      'auto_rebalance_applied',
      jsonb_build_object(
        'requested_count', v_requested_count,
        'applied_count', v_applied_count,
        'skipped_count', v_skipped_count
      )
    );

    perform public.refresh_organization_fairness_scores(v_org_id, current_date);
  else
    update public.rebalance_plans
    set summary = summary || jsonb_build_object(
      'requested_count', v_requested_count,
      'applied_count', v_applied_count,
      'skipped_count', v_skipped_count,
      'last_attempt_at', now()
    )
    where id = p_plan_id;
  end if;

  return query
  select
    p_plan_id,
    v_requested_count,
    v_applied_count,
    v_skipped_count,
    case
      when v_applied_count > 0 then
        format(
          'Auto Rebalance selesai. %s task dipindahkan, %s item dilewati.',
          v_applied_count,
          v_skipped_count
        )
      else
        format(
          'Tidak ada task yang dipindahkan. %s item dilewati karena sudah tidak valid.',
          v_skipped_count
        )
    end::text;
end;
$$;

grant execute on function public.execute_rebalance_plan(uuid, uuid[])
to authenticated;

commit;