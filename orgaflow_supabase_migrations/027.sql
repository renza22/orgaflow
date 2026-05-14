begin;

-- =========================================================
-- OR-66: Smart Assign Wizard
-- =========================================================
-- Adds two RPCs:
-- 1. get_smart_assign_recommendations(task_id): Top 3 candidates
--    based on skill match, capacity availability, and fairness.
-- 2. assign_task_with_notification(task_id, member_id): atomic assignment,
--    project membership sync, and assignment notification.
-- =========================================================

-- Recreate safely if this migration is re-run during development.
drop function if exists public.get_smart_assign_recommendations(uuid, integer, numeric);
drop function if exists public.assign_task_with_notification(uuid, uuid);

-- =========================================================
-- 1. Smart Assign recommendations
-- =========================================================

create or replace function public.get_smart_assign_recommendations(
  p_task_id uuid,
  p_limit integer default 3,
  p_hard_overload_threshold numeric default 1.2000
)
returns table (
  task_id uuid,
  member_id uuid,
  profile_id uuid,
  full_name text,
  position_code text,
  position_label text,
  division_code text,
  division_label text,
  weekly_capacity_hours integer,
  current_assigned_hours integer,
  task_estimated_hours integer,
  projected_assigned_hours integer,
  current_load_ratio numeric,
  projected_load_ratio numeric,
  current_load_percentage numeric,
  projected_load_percentage numeric,
  workload_status text,
  active_task_count integer,
  assignment_count integer,
  required_skill_count integer,
  matching_skill_count integer,
  matched_skills text[],
  missing_skills text[],
  skill_score integer,
  capacity_score integer,
  fairness_score integer,
  total_score integer,
  recommendation_rank integer,
  recommendation_reason text,
  preemptive_alert_level text,
  preemptive_alert_message text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
begin
  if auth.uid() is null then
    raise exception using
      message = 'User belum login.',
      errcode = '28000';
  end if;

  select p.organization_id
  into v_organization_id
  from public.tasks t
  join public.projects p on p.id = t.project_id
  where t.id = p_task_id;

  if v_organization_id is null then
    raise exception using
      message = 'Task tidak ditemukan.',
      errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_organization_id) then
    raise exception using
      message = 'Hanya admin organisasi yang dapat melihat rekomendasi Smart Assign.',
      errcode = '42501';
  end if;

  return query
  with task_context as (
    select
      t.id as task_id,
      t.project_id,
      p.organization_id,
      t.title as task_title,
      coalesce(t.estimated_hours, 0)::integer as estimated_hours
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = p_task_id
  ),
  required_skill_rows as (
    select
      tsr.skill_id,
      coalesce(s.name, 'Skill tidak diketahui')::text as skill_name,
      tsr.minimum_level
    from public.task_skill_requirements tsr
    left join public.skills s on s.id = tsr.skill_id
    where tsr.task_id = p_task_id
  ),
  required_skill_summary as (
    select count(*)::integer as required_skill_count
    from required_skill_rows
  ),
  member_base as (
    select
      m.id as member_id,
      m.profile_id,
      coalesce(pf.full_name, 'Tanpa Nama')::text as full_name,
      m.position_code,
      pt.label::text as position_label,
      m.division_code,
      dt.label::text as division_label,
      coalesce(w.weekly_capacity_hours, m.weekly_capacity_hours, 0)::integer as weekly_capacity_hours,
      coalesce(w.assigned_hours, 0)::integer as current_assigned_hours,
      coalesce(w.active_task_count, 0)::integer as active_task_count,
      coalesce(w.load_ratio, 0)::numeric as current_load_ratio,
      coalesce(w.load_percentage, 0)::numeric as current_load_percentage,
      coalesce(w.workload_status, 'safe')::text as workload_status,
      coalesce(w.warning_threshold, 0.7000)::numeric as warning_threshold,
      coalesce(w.critical_threshold, 0.9000)::numeric as critical_threshold,
      coalesce(w.overload_threshold, 1.0000)::numeric as overload_threshold
    from public.members m
    join public.profiles pf on pf.id = m.profile_id
    left join public.position_templates pt on pt.code = m.position_code
    left join public.division_templates dt on dt.code = m.division_code
    left join public.v_member_workload w on w.member_id = m.id
    where m.organization_id = v_organization_id
      and m.status = 'active'::public.member_status_enum
      and not exists (
        select 1
        from public.task_assignments existing_ta
        where existing_ta.task_id = p_task_id
          and existing_ta.member_id = m.id
      )
      and (
        p_hard_overload_threshold is null
        or coalesce(w.load_ratio, 0)::numeric < p_hard_overload_threshold
      )
  ),
  skill_match as (
    select
      mb.member_id,
      count(distinct rs.skill_id) filter (where rs.skill_id is not null)::integer as matching_skill_count,
      coalesce(
        array_agg(distinct rs.skill_name order by rs.skill_name) filter (where rs.skill_id is not null),
        '{}'::text[]
      ) as matched_skills
    from member_base mb
    left join public.member_skills ms on ms.member_id = mb.member_id
    left join required_skill_rows rs on rs.skill_id = ms.skill_id
    group by mb.member_id
  ),
  assignment_counts as (
    select
      ta.member_id,
      count(*)::integer as assignment_count
    from public.task_assignments ta
    join public.tasks t
      on t.id = ta.task_id
     and t.status in ('todo'::public.task_status_enum, 'in_progress'::public.task_status_enum)
    join public.projects p
      on p.id = t.project_id
     and p.organization_id = v_organization_id
    group by ta.member_id
  ),
  candidate_raw as (
    select
      tc.task_id,
      mb.member_id,
      mb.profile_id,
      mb.full_name,
      mb.position_code,
      mb.position_label,
      mb.division_code,
      mb.division_label,
      mb.weekly_capacity_hours,
      mb.current_assigned_hours,
      tc.estimated_hours as task_estimated_hours,
      (mb.current_assigned_hours + tc.estimated_hours)::integer as projected_assigned_hours,
      mb.current_load_ratio,
      case
        when mb.weekly_capacity_hours <= 0 then 0::numeric
        else round(
          (mb.current_assigned_hours + tc.estimated_hours)::numeric
          / mb.weekly_capacity_hours::numeric,
          4
        )
      end as projected_load_ratio,
      mb.current_load_percentage,
      case
        when mb.weekly_capacity_hours <= 0 then 0::numeric
        else round(
          ((mb.current_assigned_hours + tc.estimated_hours)::numeric
          / mb.weekly_capacity_hours::numeric) * 100,
          2
        )
      end as projected_load_percentage,
      mb.workload_status,
      mb.warning_threshold,
      mb.critical_threshold,
      mb.overload_threshold,
      mb.active_task_count,
      coalesce(ac.assignment_count, 0)::integer as assignment_count,
      rss.required_skill_count,
      coalesce(sm.matching_skill_count, 0)::integer as matching_skill_count,
      coalesce(sm.matched_skills, '{}'::text[]) as matched_skills,
      coalesce(
        (
          select array_agg(rs.skill_name order by rs.skill_name)
          from required_skill_rows rs
          where not exists (
            select 1
            from public.member_skills ms2
            where ms2.member_id = mb.member_id
              and ms2.skill_id = rs.skill_id
          )
        ),
        '{}'::text[]
      ) as missing_skills,
      min(coalesce(ac.assignment_count, 0)) over ()::integer as min_assignment_count
    from task_context tc
    cross join required_skill_summary rss
    join member_base mb on true
    left join skill_match sm on sm.member_id = mb.member_id
    left join assignment_counts ac on ac.member_id = mb.member_id
  ),
  scored as (
    select
      cr.*,
      case
        when cr.required_skill_count = 0 then 0
        when cr.matching_skill_count > 0 then 50
        else 0
      end::integer as skill_score,
      case
        when cr.weekly_capacity_hours <= 0 then -20
        when cr.current_load_ratio < cr.warning_threshold then 30
        when cr.current_load_ratio <= cr.critical_threshold then 10
        else -20
      end::integer as capacity_score,
      case
        when cr.assignment_count = cr.min_assignment_count then 10
        else 0
      end::integer as fairness_score
    from candidate_raw cr
  ),
  scored_with_total as (
    select
      s.*,
      (s.skill_score + s.capacity_score + s.fairness_score)::integer as total_score,
      case
        when s.weekly_capacity_hours <= 0 then 'no_capacity'
        when s.projected_load_ratio > s.overload_threshold then 'overload'
        when s.projected_load_ratio > s.critical_threshold then 'critical'
        when s.projected_load_ratio >= s.warning_threshold then 'warning'
        else 'safe'
      end::text as preemptive_alert_level,
      case
        when s.weekly_capacity_hours <= 0 then
          'Anggota belum mengatur kapasitas mingguan.'
        when s.projected_load_ratio > s.overload_threshold then
          format('Jika task ini diassign, load menjadi %s%% dan melewati kapasitas.', round(s.projected_load_percentage, 0))
        when s.projected_load_ratio > s.critical_threshold then
          format('Jika task ini diassign, load menjadi %s%% dan masuk status critical.', round(s.projected_load_percentage, 0))
        when s.projected_load_ratio >= s.warning_threshold then
          format('Jika task ini diassign, load menjadi %s%% dan masuk status warning.', round(s.projected_load_percentage, 0))
        else
          'Kapasitas masih aman setelah assignment.'
      end::text as preemptive_alert_message
    from scored s
  ),
  ranked as (
    select
      swt.*,
      row_number() over (
        order by
          swt.total_score desc,
          swt.skill_score desc,
          swt.capacity_score desc,
          swt.fairness_score desc,
          swt.projected_load_ratio asc,
          swt.full_name asc
      )::integer as recommendation_rank
    from scored_with_total swt
  )
  select
    r.task_id,
    r.member_id,
    r.profile_id,
    r.full_name,
    r.position_code,
    r.position_label,
    r.division_code,
    r.division_label,
    r.weekly_capacity_hours,
    r.current_assigned_hours,
    r.task_estimated_hours,
    r.projected_assigned_hours,
    r.current_load_ratio,
    r.projected_load_ratio,
    r.current_load_percentage,
    r.projected_load_percentage,
    r.workload_status,
    r.active_task_count,
    r.assignment_count,
    r.required_skill_count,
    r.matching_skill_count,
    r.matched_skills,
    r.missing_skills,
    r.skill_score,
    r.capacity_score,
    r.fairness_score,
    r.total_score,
    r.recommendation_rank,
    concat_ws(
      ' • ',
      case
        when r.required_skill_count = 0 then 'Task belum punya skill requirement'
        when r.matching_skill_count > 0 then format('Skill cocok: %s (+50)', array_to_string(r.matched_skills, ', '))
        else 'Skill belum cocok (+0)'
      end,
      case
        when r.weekly_capacity_hours <= 0 then 'Kapasitas belum diatur (-20)'
        when r.current_load_ratio < r.warning_threshold then format('Load saat ini %s%%, masih aman (+30)', round(r.current_load_percentage, 0))
        when r.current_load_ratio <= r.critical_threshold then format('Load saat ini %s%%, cukup sibuk (+10)', round(r.current_load_percentage, 0))
        else format('Load saat ini %s%%, sudah sibuk (-20)', round(r.current_load_percentage, 0))
      end,
      case
        when r.fairness_score > 0 then 'Jumlah task aktif paling sedikit di kandidat aktif (+10)'
        else format('Memiliki %s task aktif saat ini (+0 fairness)', r.assignment_count)
      end
    )::text as recommendation_reason,
    r.preemptive_alert_level,
    r.preemptive_alert_message
  from ranked r
  order by r.recommendation_rank
  limit greatest(coalesce(p_limit, 3), 1);
end;
$$;

grant execute on function public.get_smart_assign_recommendations(uuid, integer, numeric)
to authenticated;

-- =========================================================
-- 2. Atomic assignment + project member sync + notification
-- =========================================================

create or replace function public.assign_task_with_notification(
  p_task_id uuid,
  p_member_id uuid
)
returns table (
  assignment_id uuid,
  task_id uuid,
  member_id uuid,
  notification_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_project_id uuid;
  v_task_title text;
  v_task_status public.task_status_enum;
  v_member_organization_id uuid;
  v_assignment_id uuid;
  v_notification_id uuid;
begin
  if auth.uid() is null then
    raise exception using
      message = 'User belum login.',
      errcode = '28000';
  end if;

  select
    t.project_id,
    p.organization_id,
    t.title,
    t.status
  into
    v_project_id,
    v_organization_id,
    v_task_title,
    v_task_status
  from public.tasks t
  join public.projects p on p.id = t.project_id
  where t.id = p_task_id;

  if v_organization_id is null then
    raise exception using
      message = 'Task tidak ditemukan.',
      errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_organization_id) then
    raise exception using
      message = 'Hanya admin organisasi yang dapat melakukan assignment.',
      errcode = '42501';
  end if;

  if v_task_status in ('done'::public.task_status_enum, 'cancelled'::public.task_status_enum) then
    raise exception using
      message = 'Task yang sudah selesai atau dibatalkan tidak dapat diassign.',
      errcode = '23514';
  end if;

  select m.organization_id
  into v_member_organization_id
  from public.members m
  where m.id = p_member_id
    and m.status = 'active'::public.member_status_enum;

  if v_member_organization_id is null then
    raise exception using
      message = 'Member aktif tidak ditemukan.',
      errcode = 'P0002';
  end if;

  if v_member_organization_id <> v_organization_id then
    raise exception using
      message = 'Member tidak berada di organisasi task ini.',
      errcode = '23514';
  end if;

  insert into public.task_assignments (
    task_id,
    member_id,
    assigned_by
  )
  values (
    p_task_id,
    p_member_id,
    auth.uid()
  )
  on conflict on constraint task_assignments_task_member_unique
  do nothing
  returning id into v_assignment_id;

  if v_assignment_id is null then
    raise exception using
      message = 'Member ini sudah ditugaskan pada task tersebut.',
      errcode = '23505';
  end if;

  insert into public.project_members (
    project_id,
    member_id,
    added_by
  )
  values (
    v_project_id,
    p_member_id,
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
  values (
    p_member_id,
    auth.uid(),
    'assignment'::public.notification_type_enum,
    'Task baru ditugaskan',
    format('Anda ditugaskan ke task "%s".', coalesce(v_task_title, 'Tanpa Judul')),
    'task',
    p_task_id
  )
  returning id into v_notification_id;

  return query
  select
    v_assignment_id,
    p_task_id,
    p_member_id,
    v_notification_id;
end;
$$;

grant execute on function public.assign_task_with_notification(uuid, uuid)
to authenticated;

notify pgrst, 'reload schema';

commit;
