begin;

create or replace function public.validate_task_due_within_project_deadline()
returns trigger
language plpgsql
as $$
declare
  project_deadline date;
begin
  if new.project_id is null or new.due_date is null then
    return new;
  end if;

  select p.end_date
    into project_deadline
  from public.projects p
  where p.id = new.project_id;

  if project_deadline is not null and new.due_date > project_deadline then
    raise exception
      using
        message = 'Task due_date tidak boleh melewati deadline project.',
        detail = format(
          'Task due_date %s melebihi project end_date %s.',
          new.due_date,
          project_deadline
        ),
        errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_tasks_validate_due_within_project_deadline
on public.tasks;

create trigger trg_tasks_validate_due_within_project_deadline
before insert or update of project_id, due_date
on public.tasks
for each row
execute function public.validate_task_due_within_project_deadline();

create or replace function public.validate_project_deadline_not_before_existing_tasks()
returns trigger
language plpgsql
as $$
begin
  if new.end_date is null then
    return new;
  end if;

  if exists (
    select 1
    from public.tasks t
    where t.project_id = new.id
      and t.due_date is not null
      and t.due_date > new.end_date
  ) then
    raise exception
      using
        message = 'Deadline project tidak boleh lebih awal dari task yang sudah ada.',
        detail = 'Masih ada task dengan due_date melebihi end_date project baru.',
        errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_projects_validate_deadline_against_tasks
on public.projects;

create trigger trg_projects_validate_deadline_against_tasks
before update of end_date
on public.projects
for each row
execute function public.validate_project_deadline_not_before_existing_tasks();

commit;