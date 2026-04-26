begin;

-- 1. Pastikan estimated_hours valid untuk data existing.
update public.tasks
set estimated_hours = 1
where estimated_hours is null
   or estimated_hours <= 0;

alter table public.tasks
alter column estimated_hours set default 1;

alter table public.tasks
alter column estimated_hours set not null;

alter table public.tasks
drop constraint if exists tasks_estimated_hours_positive_chk;

alter table public.tasks
add constraint tasks_estimated_hours_positive_chk
check (estimated_hours > 0);


-- 2. Cegah duplicate skill requirement pada task yang sama.
delete from public.task_skill_requirements a
using public.task_skill_requirements b
where a.ctid < b.ctid
  and a.task_id = b.task_id
  and a.skill_id = b.skill_id;

alter table public.task_skill_requirements
drop constraint if exists task_skill_requirements_task_skill_unique;

alter table public.task_skill_requirements
add constraint task_skill_requirements_task_skill_unique
unique (task_id, skill_id);


-- 3. RPC atomic untuk membuat task + skill requirements dalam satu transaksi.
create or replace function public.create_task_with_requirements(
  p_project_id uuid,
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
  new_task public.tasks;
  req jsonb;
begin
  if auth.uid() is null then
    raise exception
      using
        message = 'User belum login.',
        errcode = '28000';
  end if;

  if p_project_id is null then
    raise exception
      using
        message = 'Project wajib dipilih.',
        errcode = '23502';
  end if;

  if p_title is null or btrim(p_title) = '' then
    raise exception
      using
        message = 'Judul task wajib diisi.',
        errcode = '23514';
  end if;

  if p_estimated_hours is null or p_estimated_hours <= 0 then
    raise exception
      using
        message = 'Estimated hours wajib lebih dari 0.',
        errcode = '23514';
  end if;

  if p_requirements is null
     or jsonb_typeof(p_requirements) <> 'array'
     or jsonb_array_length(p_requirements) = 0 then
    raise exception
      using
        message = 'Skill requirements wajib diisi minimal satu skill.',
        errcode = '23514';
  end if;

  if not exists (
    select 1
    from public.projects p
    where p.id = p_project_id
      and public.is_org_admin(p.organization_id)
  ) then
    raise exception
      using
        message = 'Hanya admin organisasi yang dapat membuat task.',
        errcode = '42501';
  end if;

  insert into public.tasks (
    project_id,
    created_by,
    title,
    description,
    estimated_hours,
    priority,
    due_date,
    status
  )
  values (
    p_project_id,
    auth.uid(),
    btrim(p_title),
    nullif(btrim(coalesce(p_description, '')), ''),
    p_estimated_hours,
    coalesce(nullif(p_priority, ''), 'medium')::public.task_priority,
    p_due_date,
    'backlog'::public.task_status
  )
  returning *
  into new_task;

  for req in
    select value
    from jsonb_array_elements(p_requirements)
  loop
    if nullif(req->>'skill_id', '') is null then
      raise exception
        using
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
      new_task.id,
      (req->>'skill_id')::uuid,
      coalesce(nullif(req->>'minimum_level', '')::integer, 1),
      coalesce(nullif(req->>'priority_weight', '')::numeric, 1)
    );
  end loop;

  return new_task;
end;
$$;

grant execute on function public.create_task_with_requirements(
  uuid,
  text,
  text,
  integer,
  text,
  date,
  jsonb
) to authenticated;

commit;