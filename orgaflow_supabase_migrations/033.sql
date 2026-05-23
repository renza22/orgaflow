begin;

-- =========================================================
-- Sprint 5 Task 78
-- Member Autonomy: Sub-task & Checklist Engine
-- =========================================================

create table if not exists public.subtasks (
  id uuid primary key default gen_random_uuid(),

  parent_task_id uuid not null
    references public.tasks(id)
    on delete cascade,

  assigned_member_id uuid not null
    references public.members(id)
    on delete cascade,

  created_by_member_id uuid not null
    references public.members(id)
    on delete cascade,

  title text not null,
  description text not null default '',

  status text not null default 'todo'
    check (status in ('todo', 'in_progress', 'done')),

  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists subtasks_parent_task_idx
  on public.subtasks(parent_task_id);

create index if not exists subtasks_assigned_member_idx
  on public.subtasks(assigned_member_id);

create index if not exists subtasks_created_by_member_idx
  on public.subtasks(created_by_member_id);


-- updated_at otomatis
create or replace function public.touch_subtasks_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();

  if new.status = 'done' and old.status is distinct from 'done' then
    new.completed_at = now();
  elsif new.status <> 'done' then
    new.completed_at = null;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_touch_subtasks_updated_at on public.subtasks;

create trigger trg_touch_subtasks_updated_at
before update on public.subtasks
for each row
execute function public.touch_subtasks_updated_at();


-- =========================================================
-- Helper: cek apakah user adalah assignee task utama
-- =========================================================

create or replace function public.is_current_user_assigned_to_task(p_task_id uuid)
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
      and m.status = 'active'::public.member_status_enum
  );
$$;


-- =========================================================
-- RLS
-- Member assigned bisa lihat subtask task-nya.
-- Admin organisasi bisa lihat semua subtask.
-- Write lewat RPC, bukan direct insert/update/delete.
-- =========================================================

alter table public.subtasks enable row level security;

drop policy if exists subtasks_select_assignee_or_admin on public.subtasks;
drop policy if exists subtasks_no_direct_insert on public.subtasks;
drop policy if exists subtasks_no_direct_update on public.subtasks;
drop policy if exists subtasks_no_direct_delete on public.subtasks;

create policy subtasks_select_assignee_or_admin
on public.subtasks
for select
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p
      on p.id = t.project_id
    where t.id = subtasks.parent_task_id
      and (
        public.is_org_admin(p.organization_id)
        or exists (
          select 1
          from public.task_assignments ta
          join public.members m
            on m.id = ta.member_id
          where ta.task_id = t.id
            and m.profile_id = auth.uid()
            and m.status = 'active'::public.member_status_enum
        )
      )
  )
);

create policy subtasks_no_direct_insert
on public.subtasks
for insert
to authenticated
with check (false);

create policy subtasks_no_direct_update
on public.subtasks
for update
to authenticated
using (false)
with check (false);

create policy subtasks_no_direct_delete
on public.subtasks
for delete
to authenticated
using (false);


-- =========================================================
-- RPC: get_task_subtasks
-- Admin bisa lihat.
-- Assigned member bisa lihat.
-- =========================================================

drop function if exists public.get_task_subtasks(uuid);

create function public.get_task_subtasks(p_parent_task_id uuid)
returns table (
  id uuid,
  parent_task_id uuid,
  title text,
  description text,
  status text,
  assigned_member_id uuid,
  assigned_to_name text,
  assigned_to_email text,
  created_by_member_id uuid,
  created_by_name text,
  created_by_email text,
  created_at timestamptz,
  updated_at timestamptz,
  completed_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
begin
  if auth.uid() is null then
    raise exception 'User belum login.';
  end if;

  select p.organization_id
  into v_org_id
  from public.tasks t
  join public.projects p
    on p.id = t.project_id
  where t.id = p_parent_task_id;

  if v_org_id is null then
    raise exception 'Task utama tidak ditemukan.';
  end if;

  if not public.is_org_admin(v_org_id)
     and not public.is_current_user_assigned_to_task(p_parent_task_id) then
    raise exception 'Anda tidak punya akses melihat sub-task ini.';
  end if;

  return query
  select
    s.id,
    s.parent_task_id,
    s.title,
    s.description,
    s.status,
    s.assigned_member_id,
    coalesce(ap.full_name, 'Tanpa Nama') as assigned_to_name,
    coalesce(ap.email, '') as assigned_to_email,
    s.created_by_member_id,
    coalesce(cp.full_name, 'Tanpa Nama') as created_by_name,
    coalesce(cp.email, '') as created_by_email,
    s.created_at,
    s.updated_at,
    s.completed_at
  from public.subtasks s
  join public.members am
    on am.id = s.assigned_member_id
  join public.profiles ap
    on ap.id = am.profile_id
  join public.members cm
    on cm.id = s.created_by_member_id
  join public.profiles cp
    on cp.id = cm.profile_id
  where s.parent_task_id = p_parent_task_id
  order by s.created_at asc;
end;
$$;

grant execute on function public.get_task_subtasks(uuid)
to authenticated;


-- =========================================================
-- RPC: create_my_subtask
-- Assignee dikunci ke diri sendiri.
-- Tidak menambah workload organisasi.
-- =========================================================

drop function if exists public.create_my_subtask(uuid, text, text);

create function public.create_my_subtask(
  p_parent_task_id uuid,
  p_title text,
  p_description text default ''
)
returns table (
  id uuid,
  parent_task_id uuid,
  title text,
  description text,
  status text,
  assigned_member_id uuid,
  assigned_to_name text,
  assigned_to_email text,
  created_by_member_id uuid,
  created_by_name text,
  created_by_email text,
  created_at timestamptz,
  updated_at timestamptz,
  completed_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_member_id uuid;
  v_subtask_id uuid;
begin
  if auth.uid() is null then
    raise exception 'User belum login.';
  end if;

  if p_parent_task_id is null then
    raise exception 'Task utama wajib dipilih.';
  end if;

  if length(trim(coalesce(p_title, ''))) = 0 then
    raise exception 'Judul sub-task wajib diisi.';
  end if;

  select m.id
  into v_member_id
  from public.task_assignments ta
  join public.members m
    on m.id = ta.member_id
  where ta.task_id = p_parent_task_id
    and m.profile_id = auth.uid()
    and m.status = 'active'::public.member_status_enum
  limit 1;

  if v_member_id is null then
    raise exception 'Hanya member yang ditugaskan pada task utama yang boleh membuat sub-task.';
  end if;

  insert into public.subtasks (
    parent_task_id,
    assigned_member_id,
    created_by_member_id,
    title,
    description,
    status
  )
  values (
    p_parent_task_id,
    v_member_id,
    v_member_id,
    trim(p_title),
    coalesce(p_description, ''),
    'todo'
  )
  returning subtasks.id into v_subtask_id;

  return query
  select *
  from public.get_task_subtasks(p_parent_task_id)
  where get_task_subtasks.id = v_subtask_id;
end;
$$;

grant execute on function public.create_my_subtask(uuid, text, text)
to authenticated;


-- =========================================================
-- RPC: update_my_subtask
-- Hanya pemilik sub-task yang bisa edit atau checklist.
-- Admin hanya melihat, bukan mengubah.
-- =========================================================

drop function if exists public.update_my_subtask(uuid, text, text, text);

create function public.update_my_subtask(
  p_subtask_id uuid,
  p_title text default null,
  p_description text default null,
  p_status text default null
)
returns table (
  id uuid,
  parent_task_id uuid,
  title text,
  description text,
  status text,
  assigned_member_id uuid,
  assigned_to_name text,
  assigned_to_email text,
  created_by_member_id uuid,
  created_by_name text,
  created_by_email text,
  created_at timestamptz,
  updated_at timestamptz,
  completed_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_parent_task_id uuid;
begin
  if auth.uid() is null then
    raise exception 'User belum login.';
  end if;

  if p_status is not null and p_status not in ('todo', 'in_progress', 'done') then
    raise exception 'Status sub-task tidak valid.';
  end if;

  select s.parent_task_id
  into v_parent_task_id
  from public.subtasks s
  join public.members m
    on m.id = s.assigned_member_id
  where s.id = p_subtask_id
    and m.profile_id = auth.uid()
    and m.status = 'active'::public.member_status_enum;

  if v_parent_task_id is null then
    raise exception 'Sub-task tidak ditemukan atau bukan milik Anda.';
  end if;

  update public.subtasks
  set
    title = case
      when p_title is null then title
      when length(trim(p_title)) = 0 then title
      else trim(p_title)
    end,
    description = coalesce(p_description, description),
    status = coalesce(p_status, status)
  where subtasks.id = p_subtask_id;

  return query
  select *
  from public.get_task_subtasks(v_parent_task_id)
  where get_task_subtasks.id = p_subtask_id;
end;
$$;

grant execute on function public.update_my_subtask(uuid, text, text, text)
to authenticated;


-- =========================================================
-- RPC: delete_my_subtask
-- Hanya pemilik sub-task yang bisa hapus.
-- =========================================================

drop function if exists public.delete_my_subtask(uuid);

create function public.delete_my_subtask(p_subtask_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'User belum login.';
  end if;

  delete from public.subtasks s
  using public.members m
  where s.id = p_subtask_id
    and m.id = s.assigned_member_id
    and m.profile_id = auth.uid()
    and m.status = 'active'::public.member_status_enum;

  if not found then
    raise exception 'Sub-task tidak ditemukan atau bukan milik Anda.';
  end if;
end;
$$;

grant execute on function public.delete_my_subtask(uuid)
to authenticated;

commit;