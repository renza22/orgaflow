begin;

-- =========================================================
-- OR-71: Real-time Overload Detection & Alerting
-- =========================================================
-- Tujuan:
-- - Saat admin assign task aktif atau menaikkan estimated_hours task aktif,
--   database menghitung projected workload member secara instan.
-- - Jika projected load mencapai/melewati overload_threshold organisasi,
--   proses disimpan DITOLAK dengan error yang bisa ditampilkan UI sebagai alert.
--
-- Catatan:
-- - Overload threshold disimpan sebagai rasio desimal:
--   1.00 = 100%, 0.75 = 75%.
-- - Konsisten dengan Task 61/69, beban aktif hanya task status todo/in_progress.
-- - Jika ingin aturan strict "> threshold" bukan ">= threshold", ubah operator
--   pada would_overload dari >= menjadi >.
-- =========================================================


-- =========================================================
-- 1. Preview helper: hitung proyeksi beban untuk 1 task + 1 member.
-- =========================================================

create or replace function public.get_task_assignment_overload_preview(
  p_task_id uuid,
  p_member_id uuid,
  p_estimated_hours_override integer default null
)
returns table (
  task_id uuid,
  member_id uuid,
  profile_id uuid,
  full_name text,
  organization_id uuid,
  task_title text,
  task_status text,
  old_estimated_hours integer,
  effective_estimated_hours integer,
  current_assigned_hours integer,
  weekly_capacity_hours integer,
  projected_assigned_hours integer,
  current_load_ratio numeric,
  projected_load_ratio numeric,
  current_load_percentage numeric,
  projected_load_percentage numeric,
  overload_threshold numeric,
  overload_threshold_percentage numeric,
  is_task_active_for_workload boolean,
  is_already_assigned boolean,
  would_overload boolean,
  alert_message text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
  v_project_id uuid;
  v_task_title text;
  v_task_status public.task_status_enum;
  v_old_estimated_hours integer;
  v_effective_estimated_hours integer;
  v_is_task_active boolean;
  v_is_already_assigned boolean;
  v_member_org_id uuid;
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
    t.status,
    coalesce(t.estimated_hours, 0)::integer
  into
    v_project_id,
    v_org_id,
    v_task_title,
    v_task_status,
    v_old_estimated_hours
  from public.tasks t
  join public.projects p on p.id = t.project_id
  where t.id = p_task_id;

  if v_org_id is null then
    raise exception using
      message = 'Task tidak ditemukan.',
      errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_org_id) then
    raise exception using
      message = 'Hanya admin organisasi yang dapat mengecek overload assignment.',
      errcode = '42501';
  end if;

  select m.organization_id
  into v_member_org_id
  from public.members m
  where m.id = p_member_id
    and m.status = 'active'::public.member_status_enum;

  if v_member_org_id is null then
    raise exception using
      message = 'Member aktif tidak ditemukan.',
      errcode = 'P0002';
  end if;

  if v_member_org_id <> v_org_id then
    raise exception using
      message = 'Member tidak berada di organisasi task ini.',
      errcode = '23514';
  end if;

  v_effective_estimated_hours := coalesce(
    p_estimated_hours_override,
    v_old_estimated_hours,
    0
  );

  if v_effective_estimated_hours <= 0 then
    raise exception using
      message = 'Estimated hours wajib lebih dari 0.',
      errcode = '23514';
  end if;

  v_is_task_active := v_task_status in (
    'todo'::public.task_status_enum,
    'in_progress'::public.task_status_enum
  );

  select exists (
    select 1
    from public.task_assignments ta
    where ta.task_id = p_task_id
      and ta.member_id = p_member_id
  )
  into v_is_already_assigned;

  return query
  with base as (
    select
      m.id as member_id,
      m.profile_id,
      coalesce(pf.full_name, 'Tanpa Nama')::text as full_name,
      m.organization_id,
      coalesce(w.assigned_hours, 0)::integer as current_assigned_hours,
      coalesce(w.weekly_capacity_hours, m.weekly_capacity_hours, 0)::integer
        as weekly_capacity_hours,
      coalesce(w.load_ratio, 0)::numeric as current_load_ratio,
      coalesce(w.load_percentage, 0)::numeric as current_load_percentage,
      coalesce(ows.overload_threshold, 1.0000)::numeric as overload_threshold
    from public.members m
    join public.profiles pf on pf.id = m.profile_id
    left join public.v_member_workload w on w.member_id = m.id
    left join public.organization_workload_settings ows
      on ows.organization_id = m.organization_id
    where m.id = p_member_id
  ),
  projected as (
    select
      b.*,
      case
        when not v_is_task_active then b.current_assigned_hours
        when v_is_already_assigned then
          greatest(
            b.current_assigned_hours - v_old_estimated_hours + v_effective_estimated_hours,
            0
          )::integer
        else
          (b.current_assigned_hours + v_effective_estimated_hours)::integer
      end as projected_assigned_hours
    from base b
  ),
  calculated as (
    select
      p.*,
      case
        when p.weekly_capacity_hours <= 0 then null::numeric
        else round(
          p.projected_assigned_hours::numeric / p.weekly_capacity_hours::numeric,
          4
        )
      end as projected_load_ratio,
      case
        when p.weekly_capacity_hours <= 0 then null::numeric
        else round(
          (
            p.projected_assigned_hours::numeric / p.weekly_capacity_hours::numeric
          ) * 100,
          2
        )
      end as projected_load_percentage
    from projected p
  )
  select
    p_task_id as task_id,
    c.member_id,
    c.profile_id,
    c.full_name,
    c.organization_id,
    coalesce(v_task_title, 'Tanpa Judul')::text as task_title,
    v_task_status::text as task_status,
    v_old_estimated_hours as old_estimated_hours,
    v_effective_estimated_hours as effective_estimated_hours,
    c.current_assigned_hours,
    c.weekly_capacity_hours,
    c.projected_assigned_hours,
    c.current_load_ratio,
    c.projected_load_ratio,
    c.current_load_percentage,
    coalesce(c.projected_load_percentage, 0)::numeric as projected_load_percentage,
    c.overload_threshold,
    round(c.overload_threshold * 100, 2)::numeric as overload_threshold_percentage,
    v_is_task_active as is_task_active_for_workload,
    v_is_already_assigned as is_already_assigned,
    case
      when not v_is_task_active then false
      when c.weekly_capacity_hours <= 0 then true
      when c.projected_load_ratio >= c.overload_threshold then true
      else false
    end as would_overload,
    case
      when not v_is_task_active then
        format(
          'Task "%s" belum dihitung sebagai beban aktif karena statusnya %s.',
          coalesce(v_task_title, 'Tanpa Judul'),
          v_task_status::text
        )
      when c.weekly_capacity_hours <= 0 then
        format(
          '%s belum mengatur kapasitas mingguan. Assignment/edit durasi ditahan.',
          c.full_name
        )
      when c.projected_load_ratio >= c.overload_threshold then
        format(
          'Overload terdeteksi: %s akan mencapai %s%% (%s/%s jam), melewati threshold %s%%.',
          c.full_name,
          round(c.projected_load_percentage, 0),
          c.projected_assigned_hours,
          c.weekly_capacity_hours,
          round(c.overload_threshold * 100, 0)
        )
      else
        format(
          'Aman: %s akan berada di %s%% (%s/%s jam).',
          c.full_name,
          round(c.projected_load_percentage, 0),
          c.projected_assigned_hours,
          c.weekly_capacity_hours
        )
    end::text as alert_message
  from calculated c;
end;
$$;

grant execute on function public.get_task_assignment_overload_preview(uuid, uuid, integer)
to authenticated;


-- =========================================================
-- 2. Replace assign_task_with_notification agar assignment aktif diblokir
--    jika projected load mencapai/melewati overload threshold.
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
  v_preview record;
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

  if v_task_status = 'done'::public.task_status_enum then
    raise exception using
      message = 'Task yang sudah selesai tidak dapat diassign.',
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

  if exists (
    select 1
    from public.task_assignments ta
    where ta.task_id = p_task_id
      and ta.member_id = p_member_id
  ) then
    raise exception using
      message = 'Member ini sudah ditugaskan pada task tersebut.',
      errcode = '23505';
  end if;

  select *
  into v_preview
  from public.get_task_assignment_overload_preview(p_task_id, p_member_id, null)
  limit 1;

  if coalesce(v_preview.would_overload, false) then
    raise exception using
      message = coalesce(
        v_preview.alert_message,
        'Overload terdeteksi. Assignment ditahan.'
      ),
      errcode = 'P0001';
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
  returning id into v_assignment_id;

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


-- =========================================================
-- 3. Replace update_task_with_requirements agar kenaikan durasi task aktif
--    diblokir jika membuat salah satu assignee mencapai/melewati overload.
-- =========================================================

create or replace function public.update_task_with_requirements(
  p_task_id uuid,
  p_title text,
  p_description text default null,
  p_estimated_hours integer default 1,
  p_priority text default 'medium',
  p_due_date date default null,
  p_requirements jsonb default '[]'::jsonb
)
returns public.tasks
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_task public.tasks;
  req jsonb;
  v_org_id uuid;
  v_old_estimated_hours integer;
  v_task_status public.task_status_enum;
  normalized_priority public.task_priority_enum;
  v_overload_details text;
begin
  if auth.uid() is null then
    raise exception using
      message = 'User belum login.',
      errcode = '28000';
  end if;

  if p_task_id is null then
    raise exception using
      message = 'Task wajib dipilih.',
      errcode = '23502';
  end if;

  select
    p.organization_id,
    coalesce(t.estimated_hours, 0)::integer,
    t.status
  into
    v_org_id,
    v_old_estimated_hours,
    v_task_status
  from public.tasks t
  join public.projects p on p.id = t.project_id
  where t.id = p_task_id;

  if v_org_id is null then
    raise exception using
      message = 'Task tidak ditemukan.',
      errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_org_id) then
    raise exception using
      message = 'Hanya admin organisasi yang dapat mengubah task.',
      errcode = '42501';
  end if;

  if p_title is null or btrim(p_title) = '' then
    raise exception using
      message = 'Judul task wajib diisi.',
      errcode = '23514';
  end if;

  if p_estimated_hours is null or p_estimated_hours <= 0 then
    raise exception using
      message = 'Estimated hours wajib lebih dari 0.',
      errcode = '23514';
  end if;

  if p_requirements is null
     or jsonb_typeof(p_requirements) <> 'array'
     or jsonb_array_length(p_requirements) = 0 then
    raise exception using
      message = 'Skill requirements wajib diisi minimal satu skill.',
      errcode = '23514';
  end if;

  normalized_priority :=
    case lower(btrim(coalesce(p_priority, 'medium')))
      when 'low' then 'low'::public.task_priority_enum
      when 'medium' then 'medium'::public.task_priority_enum
      when 'high' then 'high'::public.task_priority_enum
      when 'critical' then 'critical'::public.task_priority_enum
      else 'medium'::public.task_priority_enum
    end;

  -- OR-71: hanya blokir ketika durasi task aktif dinaikkan.
  -- Edit title/description/priority/due_date atau menurunkan durasi tetap boleh.
  if v_task_status in (
       'todo'::public.task_status_enum,
       'in_progress'::public.task_status_enum
     )
     and p_estimated_hours > v_old_estimated_hours then
    select string_agg(preview.alert_message, E'\n')
    into v_overload_details
    from public.task_assignments ta
    cross join lateral public.get_task_assignment_overload_preview(
      p_task_id,
      ta.member_id,
      p_estimated_hours
    ) preview
    where ta.task_id = p_task_id
      and preview.would_overload = true;

    if v_overload_details is not null then
      raise exception using
        message = 'Overload terdeteksi. Perubahan durasi task ditahan.'
                  || E'\n' || v_overload_details,
        errcode = 'P0001';
    end if;
  end if;

  update public.tasks
  set
    title = btrim(p_title),
    description = nullif(btrim(coalesce(p_description, '')), ''),
    estimated_hours = p_estimated_hours,
    priority = normalized_priority,
    due_date = p_due_date
  where id = p_task_id
  returning *
  into updated_task;

  delete from public.task_skill_requirements
  where task_id = p_task_id;

  for req in
    select value
    from jsonb_array_elements(p_requirements)
  loop
    if nullif(req->>'skill_id', '') is null then
      raise exception using
        message = 'Setiap skill requirement wajib memiliki skill_id.',
        errcode = '23514';
    end if;

    insert into public.task_skill_requirements (
      task_id,
      skill_id,
      minimum_level,
      priority_weight
    )
    values (
      p_task_id,
      (req->>'skill_id')::uuid,
      coalesce(nullif(req->>'minimum_level', '')::smallint, 1),
      coalesce(nullif(req->>'priority_weight', '')::numeric, 1)
    );
  end loop;

  return updated_task;
end;
$$;

grant execute on function public.update_task_with_requirements(
  uuid, text, text, integer, text, date, jsonb
)
to authenticated;

notify pgrst, 'reload schema';

commit;
