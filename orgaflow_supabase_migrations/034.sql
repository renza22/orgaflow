begin;

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

  if p_subtask_id is null then
    raise exception 'Sub-task wajib dipilih.';
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

  update public.subtasks as st
  set
    title = case
      when p_title is null then st.title
      when length(trim(p_title)) = 0 then st.title
      else trim(p_title)
    end,
    description = case
      when p_description is null then st.description
      else trim(p_description)
    end,
    status = case
      when p_status is null then st.status
      else p_status
    end
  where st.id = p_subtask_id;

  return query
  select
    gs.id,
    gs.parent_task_id,
    gs.title,
    gs.description,
    gs.status,
    gs.assigned_member_id,
    gs.assigned_to_name,
    gs.assigned_to_email,
    gs.created_by_member_id,
    gs.created_by_name,
    gs.created_by_email,
    gs.created_at,
    gs.updated_at,
    gs.completed_at
  from public.get_task_subtasks(v_parent_task_id) as gs
  where gs.id = p_subtask_id;
end;
$$;

grant execute on function public.update_my_subtask(uuid, text, text, text)
to authenticated;

commit;