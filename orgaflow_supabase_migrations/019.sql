begin;

-- 1. Selaraskan definisi admin org dengan aplikasi.
-- Owner/admin selalu boleh. Kadep/ketua divisi juga dianggap admin operasional
-- jika direpresentasikan melalui position_code = 'ketua_divisi'.
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
      and m.status = 'active'
      and (
        m.role in ('owner', 'admin')
        or lower(coalesce(m.position_code, '')) = 'ketua_divisi'
      )
  );
$$;


-- 2. RPC atomic untuk update task + rewrite skill requirements.
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
  normalized_priority public.task_priority_enum;
begin
  if auth.uid() is null then
    raise exception
      using message = 'User belum login.', errcode = '28000';
  end if;

  if p_task_id is null then
    raise exception
      using message = 'Task wajib dipilih.', errcode = '23502';
  end if;

  select p.organization_id
    into v_org_id
  from public.tasks t
  join public.projects p on p.id = t.project_id
  where t.id = p_task_id;

  if v_org_id is null then
    raise exception
      using message = 'Task tidak ditemukan.', errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_org_id) then
    raise exception
      using message = 'Hanya admin organisasi yang dapat mengubah task.', errcode = '42501';
  end if;

  if p_title is null or btrim(p_title) = '' then
    raise exception
      using message = 'Judul task wajib diisi.', errcode = '23514';
  end if;

  if p_estimated_hours is null or p_estimated_hours <= 0 then
    raise exception
      using message = 'Estimated hours wajib lebih dari 0.', errcode = '23514';
  end if;

  if p_requirements is null
     or jsonb_typeof(p_requirements) <> 'array'
     or jsonb_array_length(p_requirements) = 0 then
    raise exception
      using message = 'Skill requirements wajib diisi minimal satu skill.', errcode = '23514';
  end if;

  normalized_priority :=
    case lower(btrim(coalesce(p_priority, 'medium')))
      when 'low' then 'low'::public.task_priority_enum
      when 'medium' then 'medium'::public.task_priority_enum
      when 'high' then 'high'::public.task_priority_enum
      when 'critical' then 'critical'::public.task_priority_enum
      else 'medium'::public.task_priority_enum
    end;

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
      raise exception
        using message = 'Setiap skill requirement wajib memiliki skill_id.', errcode = '23514';
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


-- 3. RPC aman untuk delete task.
-- FK database akan cascade ke task_skill_requirements, task_dependencies,
-- task_assignments, dan relasi lain yang memang on delete cascade.
create or replace function public.delete_task_cascade(
  p_task_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
begin
  if auth.uid() is null then
    raise exception
      using message = 'User belum login.', errcode = '28000';
  end if;

  if p_task_id is null then
    raise exception
      using message = 'Task wajib dipilih.', errcode = '23502';
  end if;

  select p.organization_id
    into v_org_id
  from public.tasks t
  join public.projects p on p.id = t.project_id
  where t.id = p_task_id;

  if v_org_id is null then
    raise exception
      using message = 'Task tidak ditemukan.', errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_org_id) then
    raise exception
      using message = 'Hanya admin organisasi yang dapat menghapus task.', errcode = '42501';
  end if;

  delete from public.tasks
  where id = p_task_id;
end;
$$;

revoke all on function public.update_task_with_requirements(
  uuid, text, text, integer, text, date, jsonb
) from public;

grant execute on function public.update_task_with_requirements(
  uuid, text, text, integer, text, date, jsonb
) to authenticated;

revoke all on function public.delete_task_cascade(uuid) from public;
grant execute on function public.delete_task_cascade(uuid) to authenticated;


-- 4. Kunci RLS tasks: select tetap untuk member org, mutation hanya admin.
drop policy if exists "tasks_insert_same_org" on public.tasks;
drop policy if exists "tasks_update_delete_same_org" on public.tasks;
drop policy if exists "tasks_update_delete_same_org_delete" on public.tasks;

drop policy if exists "tasks_insert_admin_only" on public.tasks;
drop policy if exists "tasks_update_admin_only" on public.tasks;
drop policy if exists "tasks_delete_admin_only" on public.tasks;

create policy "tasks_insert_admin_only"
on public.tasks for insert
to authenticated
with check (
  created_by = auth.uid()
  and exists (
    select 1
    from public.projects p
    where p.id = tasks.project_id
      and public.is_org_admin(p.organization_id)
  )
);

create policy "tasks_update_admin_only"
on public.tasks for update
to authenticated
using (
  exists (
    select 1
    from public.projects p
    where p.id = tasks.project_id
      and public.is_org_admin(p.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.projects p
    where p.id = tasks.project_id
      and public.is_org_admin(p.organization_id)
  )
);

create policy "tasks_delete_admin_only"
on public.tasks for delete
to authenticated
using (
  exists (
    select 1
    from public.projects p
    where p.id = tasks.project_id
      and public.is_org_admin(p.organization_id)
  )
);


-- 5. Kunci RLS task_skill_requirements.
drop policy if exists "task_skill_requirements_same_org" on public.task_skill_requirements;

drop policy if exists "task_skill_requirements_select_same_org" on public.task_skill_requirements;
drop policy if exists "task_skill_requirements_insert_admin_only" on public.task_skill_requirements;
drop policy if exists "task_skill_requirements_update_admin_only" on public.task_skill_requirements;
drop policy if exists "task_skill_requirements_delete_admin_only" on public.task_skill_requirements;

create policy "task_skill_requirements_select_same_org"
on public.task_skill_requirements for select
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_skill_requirements.task_id
      and public.is_org_member(p.organization_id)
  )
);

create policy "task_skill_requirements_insert_admin_only"
on public.task_skill_requirements for insert
to authenticated
with check (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_skill_requirements.task_id
      and public.is_org_admin(p.organization_id)
  )
);

create policy "task_skill_requirements_update_admin_only"
on public.task_skill_requirements for update
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_skill_requirements.task_id
      and public.is_org_admin(p.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_skill_requirements.task_id
      and public.is_org_admin(p.organization_id)
  )
);

create policy "task_skill_requirements_delete_admin_only"
on public.task_skill_requirements for delete
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_skill_requirements.task_id
      and public.is_org_admin(p.organization_id)
  )
);


-- 6. Kunci RLS dependency task juga, karena dependency adalah bagian dari pengelolaan task.
drop policy if exists "task_dependencies_same_org" on public.task_dependencies;

drop policy if exists "task_dependencies_select_same_org" on public.task_dependencies;
drop policy if exists "task_dependencies_insert_admin_only" on public.task_dependencies;
drop policy if exists "task_dependencies_update_admin_only" on public.task_dependencies;
drop policy if exists "task_dependencies_delete_admin_only" on public.task_dependencies;

create policy "task_dependencies_select_same_org"
on public.task_dependencies for select
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_dependencies.task_id
      and public.is_org_member(p.organization_id)
  )
);

create policy "task_dependencies_insert_admin_only"
on public.task_dependencies for insert
to authenticated
with check (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_dependencies.task_id
      and public.is_org_admin(p.organization_id)
  )
);

create policy "task_dependencies_update_admin_only"
on public.task_dependencies for update
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_dependencies.task_id
      and public.is_org_admin(p.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_dependencies.task_id
      and public.is_org_admin(p.organization_id)
  )
);

create policy "task_dependencies_delete_admin_only"
on public.task_dependencies for delete
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    join public.projects p on p.id = t.project_id
    where t.id = task_dependencies.task_id
      and public.is_org_admin(p.organization_id)
  )
);

commit;