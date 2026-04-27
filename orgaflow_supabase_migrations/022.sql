begin;

-- 1. Pastikan tidak ada assignment duplicate.
delete from public.task_assignments a
using public.task_assignments b
where a.ctid < b.ctid
  and a.task_id = b.task_id
  and a.member_id = b.member_id;

alter table public.task_assignments
drop constraint if exists task_assignments_task_member_unique;

alter table public.task_assignments
add constraint task_assignments_task_member_unique
unique (task_id, member_id);


-- 2. Helper: cek apakah user login adalah assignee task.
create or replace function public.is_task_assignee(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.task_assignments ta
    join public.members m
      on m.id = ta.member_id
    where ta.task_id = p_task_id
      and m.profile_id = auth.uid()
      and m.status = 'active'
  );
$$;


-- 3. RPC khusus member assignee untuk update progress task.
--    Admin tetap memakai update_task_status_admin yang sudah ada.
create or replace function public.update_assigned_task_progress(
  p_task_id uuid,
  p_status text
)
returns public.tasks
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_task public.tasks;
  v_project_id uuid;
  normalized_status_text text;
  normalized_status public.task_status_enum;
  v_has_unfinished_dependency boolean;
begin
  if auth.uid() is null then
    raise exception
      using
        message = 'User belum login.',
        errcode = '28000';
  end if;

  if p_task_id is null then
    raise exception
      using
        message = 'Task wajib dipilih.',
        errcode = '23502';
  end if;

  if not public.is_task_assignee(p_task_id) then
    raise exception
      using
        message = 'Hanya assignee task yang dapat mengubah progres task ini.',
        errcode = '42501';
  end if;

  normalized_status_text :=
    lower(
      replace(
        replace(
          btrim(coalesce(p_status, '')),
          '-',
          '_'
        ),
        ' ',
        '_'
      )
    );

  normalized_status :=
    case normalized_status_text
      when 'backlog' then 'backlog'::public.task_status_enum
      when 'todo' then 'todo'::public.task_status_enum
      when 'in_progress' then 'in_progress'::public.task_status_enum
      when 'inprogress' then 'in_progress'::public.task_status_enum
      when 'done' then 'done'::public.task_status_enum
      else null
    end;

  if normalized_status is null then
    raise exception
      using
        message = 'Status progres task tidak valid.',
        detail = format('Status yang diterima: %s', p_status),
        errcode = '23514';
  end if;

  select project_id
    into v_project_id
  from public.tasks
  where id = p_task_id;

  if v_project_id is null then
    raise exception
      using
        message = 'Task tidak ditemukan.',
        errcode = 'P0002';
  end if;

  select exists (
    select 1
    from public.task_dependencies td
    join public.tasks dep
      on dep.id = td.depends_on_task_id
    where td.task_id = p_task_id
      and dep.status <> 'done'::public.task_status_enum
  )
  into v_has_unfinished_dependency;

  if v_has_unfinished_dependency
     and normalized_status <> 'blocked'::public.task_status_enum then
    raise exception
      using
        message = 'Task masih terkunci karena dependency belum selesai.',
        detail = 'Selesaikan semua dependency task terlebih dahulu.',
        errcode = '23514';
  end if;

  update public.tasks
  set status = normalized_status
  where id = p_task_id
  returning *
  into updated_task;

  perform public.recompute_project_task_blocking(v_project_id);

  select *
    into updated_task
  from public.tasks
  where id = p_task_id;

  return updated_task;
end;
$$;

revoke all on function public.update_assigned_task_progress(uuid, text) from public;
grant execute on function public.update_assigned_task_progress(uuid, text) to authenticated;


-- 4. Perkuat RLS task_assignments agar member org bisa baca assignment,
--    tapi mutation assignment tetap admin.
drop policy if exists "task_assignments_select_same_org" on public.task_assignments;
drop policy if exists "task_assignments_insert_admin_only" on public.task_assignments;
drop policy if exists "task_assignments_update_admin_only" on public.task_assignments;
drop policy if exists "task_assignments_delete_admin_only" on public.task_assignments;

create policy "task_assignments_select_same_org"
on public.task_assignments for select
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_assignments.task_id
      and public.is_org_member(p.organization_id)
  )
);

create policy "task_assignments_insert_admin_only"
on public.task_assignments for insert
to authenticated
with check (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_assignments.task_id
      and public.is_org_admin(p.organization_id)
  )
);

create policy "task_assignments_update_admin_only"
on public.task_assignments for update
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_assignments.task_id
      and public.is_org_admin(p.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_assignments.task_id
      and public.is_org_admin(p.organization_id)
  )
);

create policy "task_assignments_delete_admin_only"
on public.task_assignments for delete
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_assignments.task_id
      and public.is_org_admin(p.organization_id)
  )
);


-- 5. Recreate workload view agar task DONE tidak dihitung sebagai active assigned hours.
--    Ini yang memenuhi rule: kalau status pindah ke DONE, kapasitas jam kerja member bebas lagi.
drop view if exists public.v_member_workload;

create view public.v_member_workload as
select
  m.id as member_id,
  m.organization_id,
  m.profile_id,
  coalesce(pf.full_name, 'Tanpa Nama') as full_name,
  m.position_code,
  m.division_code,
  coalesce(m.weekly_capacity_hours, 0) as weekly_capacity_hours,
  coalesce(
    sum(
      coalesce(ta.allocation_hours, t.estimated_hours, 0)
    ) filter (
      where t.id is not null
        and t.status <> 'done'::public.task_status_enum
    ),
    0
  )::integer as assigned_hours,
  case
    when coalesce(m.weekly_capacity_hours, 0) <= 0 then 0::numeric
    else (
      coalesce(
        sum(
          coalesce(ta.allocation_hours, t.estimated_hours, 0)
        ) filter (
          where t.id is not null
            and t.status <> 'done'::public.task_status_enum
        ),
        0
      )::numeric / nullif(m.weekly_capacity_hours, 0)
    )
  end as load_ratio,
  case
    when coalesce(m.weekly_capacity_hours, 0) <= 0 then 'no_capacity'
    when (
      coalesce(
        sum(
          coalesce(ta.allocation_hours, t.estimated_hours, 0)
        ) filter (
          where t.id is not null
            and t.status <> 'done'::public.task_status_enum
        ),
        0
      )::numeric / nullif(m.weekly_capacity_hours, 0)
    ) > 1 then 'overload'
    when (
      coalesce(
        sum(
          coalesce(ta.allocation_hours, t.estimated_hours, 0)
        ) filter (
          where t.id is not null
            and t.status <> 'done'::public.task_status_enum
        ),
        0
      )::numeric / nullif(m.weekly_capacity_hours, 0)
    ) >= 0.8 then 'warning'
    else 'safe'
  end as workload_status
from public.members m
left join public.profiles pf
  on pf.id = m.profile_id
left join public.task_assignments ta
  on ta.member_id = m.id
left join public.tasks t
  on t.id = ta.task_id
where m.status = 'active'
group by
  m.id,
  m.organization_id,
  m.profile_id,
  pf.full_name,
  m.position_code,
  m.division_code,
  m.weekly_capacity_hours;

grant select on public.v_member_workload to authenticated;

commit;