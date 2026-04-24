alter table public.projects
drop constraint if exists projects_date_order_chk;

alter table public.projects
add constraint projects_date_order_chk
check (
  start_date is null
  or end_date is null
  or start_date <= end_date
);