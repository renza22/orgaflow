begin;

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
  normalized_priority public.task_priority_enum;
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

  normalized_priority :=
    case lower(btrim(coalesce(p_priority, 'medium')))
      when 'low' then 'low'::public.task_priority_enum
      when 'medium' then 'medium'::public.task_priority_enum
      when 'high' then 'high'::public.task_priority_enum
      when 'critical' then 'critical'::public.task_priority_enum
      else 'medium'::public.task_priority_enum
    end;

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
    normalized_priority,
    p_due_date,
    'backlog'::public.task_status_enum
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
      coalesce(nullif(req->>'minimum_level', '')::smallint, 1),
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