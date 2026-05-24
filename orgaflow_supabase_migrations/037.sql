begin;

-- =========================================================
-- Task 81: Activity Logs & Audit Trail
-- Transparansi aktivitas penting organisasi
-- =========================================================


-- =========================================================
-- 1. Trigger log saat auto rebalance berhasil memindahkan task
-- =========================================================

create or replace function public.log_rebalance_item_applied()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
  v_project_id uuid;
  v_project_name text;
  v_task_title text;
  v_from_name text;
  v_to_name text;
  v_actor_user_id uuid;
  v_message text;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if new.status <> 'applied'
     or old.status is not distinct from 'applied' then
    return new;
  end if;

  v_actor_user_id := new.applied_by;

  if v_actor_user_id is null then
    return new;
  end if;

  select
    p.organization_id,
    p.id,
    p.name,
    t.title,
    coalesce(from_profile.full_name, 'Anggota sumber'),
    coalesce(to_profile.full_name, 'Anggota target')
  into
    v_org_id,
    v_project_id,
    v_project_name,
    v_task_title,
    v_from_name,
    v_to_name
  from public.tasks t
  join public.projects p
    on p.id = t.project_id
  left join public.members from_member
    on from_member.id = new.from_member_id
  left join public.profiles from_profile
    on from_profile.id = from_member.profile_id
  left join public.members to_member
    on to_member.id = new.to_member_id
  left join public.profiles to_profile
    on to_profile.id = to_member.profile_id
  where t.id = new.task_id;

  if v_org_id is null then
    return new;
  end if;

  v_message := format(
    'Sistem otomatis merebalance ''%s'' dari %s ke %s.',
    coalesce(v_task_title, 'Task tanpa judul'),
    v_from_name,
    v_to_name
  );

  insert into public.activity_logs (
    actor_user_id,
    organization_id,
    entity_type,
    entity_id,
    action,
    metadata
  )
  values (
    v_actor_user_id,
    v_org_id,
    'task',
    new.task_id,
    'auto_rebalance_task_moved',
    jsonb_build_object(
      'message', v_message,
      'task_id', new.task_id,
      'task_title', v_task_title,
      'project_id', v_project_id,
      'project_name', v_project_name,
      'from_member_id', new.from_member_id,
      'from_member_name', v_from_name,
      'to_member_id', new.to_member_id,
      'to_member_name', v_to_name,
      'rebalance_item_id', new.id,
      'rebalance_plan_id', new.plan_id
    )
  );

  return new;
end;
$$;

drop trigger if exists trg_log_rebalance_item_applied
on public.rebalance_items;

create trigger trg_log_rebalance_item_applied
after update of status
on public.rebalance_items
for each row
execute function public.log_rebalance_item_applied();


-- =========================================================
-- 2. Trigger log saat member menambahkan sub-task
-- =========================================================

create or replace function public.log_subtask_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
  v_project_id uuid;
  v_project_name text;
  v_parent_task_title text;
  v_actor_user_id uuid;
  v_actor_name text;
  v_message text;
begin
  select
    m.profile_id,
    coalesce(pf.full_name, 'Anggota')
  into
    v_actor_user_id,
    v_actor_name
  from public.members m
  left join public.profiles pf
    on pf.id = m.profile_id
  where m.id = new.created_by_member_id;

  if v_actor_user_id is null then
    return new;
  end if;

  select
    pr.organization_id,
    pr.id,
    pr.name,
    t.title
  into
    v_org_id,
    v_project_id,
    v_project_name,
    v_parent_task_title
  from public.tasks t
  join public.projects pr
    on pr.id = t.project_id
  where t.id = new.parent_task_id;

  if v_org_id is null then
    return new;
  end if;

  v_message := format(
    '%s menambahkan sub-task ''%s'' pada task ''%s''.',
    v_actor_name,
    new.title,
    coalesce(v_parent_task_title, 'Task utama')
  );

  insert into public.activity_logs (
    actor_user_id,
    organization_id,
    entity_type,
    entity_id,
    action,
    metadata
  )
  values (
    v_actor_user_id,
    v_org_id,
    'subtask',
    new.id,
    'subtask_created',
    jsonb_build_object(
      'message', v_message,
      'subtask_id', new.id,
      'subtask_title', new.title,
      'parent_task_id', new.parent_task_id,
      'parent_task_title', v_parent_task_title,
      'project_id', v_project_id,
      'project_name', v_project_name,
      'actor_member_id', new.created_by_member_id,
      'actor_name', v_actor_name
    )
  );

  return new;
end;
$$;

drop trigger if exists trg_log_subtask_created
on public.subtasks;

create trigger trg_log_subtask_created
after insert
on public.subtasks
for each row
execute function public.log_subtask_created();


-- =========================================================
-- 3. RPC untuk Flutter membaca activity logs
-- =========================================================

drop function if exists public.get_activity_logs(uuid, integer, text, uuid);

create function public.get_activity_logs(
  p_organization_id uuid,
  p_limit integer default 20,
  p_entity_type text default null,
  p_entity_id uuid default null
)
returns table (
  id text,
  activity_type text,
  message text,
  actor_name text,
  target_name text,
  project_name text,
  task_name text,
  entity_type text,
  entity_id uuid,
  action text,
  is_system_action boolean,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_limit integer;
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

  if not public.is_org_member(p_organization_id) then
    raise exception using
      message = 'Anda tidak punya akses ke activity logs organisasi ini.',
      errcode = '42501';
  end if;

  v_limit := least(greatest(coalesce(p_limit, 20), 1), 100);

  return query
  select
    al.id::text as id,

    case
      when al.action = 'auto_rebalance_task_moved' then 'autoBalance'
      when al.action = 'auto_rebalance_applied' then 'autoBalance'
      when al.action = 'subtask_created' then 'subTaskAdded'
      when al.action = 'task_created' then 'taskCreated'
      when al.action = 'task_completed' then 'taskCompleted'
      when al.action = 'task_assigned' then 'taskAssigned'
      when al.action = 'task_reassigned' then 'taskReassigned'
      else 'system'
    end::text as activity_type,

    coalesce(
      al.metadata ->> 'message',
      case
        when al.action = 'auto_rebalance_applied' then
          format(
            'Sistem menjalankan Auto Rebalance. %s task dipindahkan, %s item dilewati.',
            coalesce(al.metadata ->> 'applied_count', '0'),
            coalesce(al.metadata ->> 'skipped_count', '0')
          )
        else
          al.action
      end
    )::text as message,

    case
      when al.action in ('auto_rebalance_task_moved', 'auto_rebalance_applied') then 'Sistem'
      else coalesce(actor_profile.full_name, al.metadata ->> 'actor_name', 'Sistem')
    end::text as actor_name,

    coalesce(
      al.metadata ->> 'to_member_name',
      al.metadata ->> 'target_name'
    )::text as target_name,

    coalesce(
      al.metadata ->> 'project_name',
      project_from_task.name
    )::text as project_name,

    coalesce(
      al.metadata ->> 'task_title',
      al.metadata ->> 'parent_task_title',
      task_from_entity.title
    )::text as task_name,

    al.entity_type,
    al.entity_id,
    al.action,

    (
      al.action in ('auto_rebalance_task_moved', 'auto_rebalance_applied')
      or al.metadata ->> 'actor_name' = 'Sistem'
    ) as is_system_action,

    al.created_at
  from public.activity_logs al
  left join public.profiles actor_profile
    on actor_profile.id = al.actor_user_id
  left join public.tasks task_from_entity
    on al.entity_type = 'task'
   and task_from_entity.id = al.entity_id
  left join public.projects project_from_task
    on project_from_task.id = task_from_entity.project_id
  where al.organization_id = p_organization_id
    and (p_entity_type is null or al.entity_type = p_entity_type)
    and (p_entity_id is null or al.entity_id = p_entity_id)
  order by al.created_at desc
  limit v_limit;
end;
$$;

grant execute on function public.get_activity_logs(uuid, integer, text, uuid)
to authenticated;

commit;