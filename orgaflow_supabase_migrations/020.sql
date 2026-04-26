begin;

create or replace function public.update_task_status_admin(
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
  v_org_id uuid;
  normalized_status_text text;
  normalized_status public.task_status_enum;
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
      when 'in_review' then 'in_review'::public.task_status_enum
      when 'blocked' then 'blocked'::public.task_status_enum
      else null
    end;

  if normalized_status is null then
    raise exception
      using
        message = 'Status task tidak valid.',
        detail = format('Status yang diterima: %s', p_status),
        errcode = '23514';
  end if;

  select p.organization_id
    into v_org_id
  from public.tasks t
  join public.projects p on p.id = t.project_id
  where t.id = p_task_id;

  if v_org_id is null then
    raise exception
      using
        message = 'Task tidak ditemukan.',
        errcode = 'P0002';
  end if;

  if not public.is_org_admin(v_org_id) then
    raise exception
      using
        message = 'Hanya admin organisasi yang dapat mengubah status task.',
        errcode = '42501';
  end if;

  update public.tasks
  set status = normalized_status
  where id = p_task_id
  returning *
  into updated_task;

  return updated_task;
end;
$$;

revoke all on function public.update_task_status_admin(uuid, text) from public;

grant execute on function public.update_task_status_admin(uuid, text) to authenticated;

commit;