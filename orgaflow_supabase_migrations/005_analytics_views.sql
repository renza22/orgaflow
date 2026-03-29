create table if not exists public.fairness_scores (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  score_date date not null default current_date,
  workload_hours integer not null default 0 check (workload_hours >= 0),
  capacity_hours integer not null default 0 check (capacity_hours >= 0),
  fairness_score numeric(5,2) not null default 0,
  note text,
  created_at timestamptz not null default now(),
  constraint fairness_scores_unique unique (member_id, score_date)
);

create index if not exists fairness_scores_member_id_idx
  on public.fairness_scores (member_id);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_member_id uuid not null references public.members(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  type public.notification_type_enum not null default 'system',
  title text not null,
  body text,
  entity_type text,
  entity_id uuid,
  is_read boolean not null default false,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists notifications_recipient_member_id_idx
  on public.notifications (recipient_member_id, is_read, created_at desc);

create table if not exists public.rebalance_plans (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  status public.rebalance_plan_status_enum not null default 'draft',
  reason text,
  summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists rebalance_plans_organization_id_idx
  on public.rebalance_plans (organization_id);

create trigger trg_rebalance_plans_updated_at
before update on public.rebalance_plans
for each row execute function public.set_updated_at();

create table if not exists public.rebalance_items (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.rebalance_plans(id) on delete cascade,
  task_id uuid not null references public.tasks(id) on delete cascade,
  from_member_id uuid references public.members(id) on delete set null,
  to_member_id uuid references public.members(id) on delete set null,
  recommendation_reason text,
  score_before numeric(5,2),
  score_after numeric(5,2),
  created_at timestamptz not null default now()
);

create index if not exists rebalance_items_plan_id_idx
  on public.rebalance_items (plan_id);

create index if not exists rebalance_items_task_id_idx
  on public.rebalance_items (task_id);

create table if not exists public.activity_logs (
  id bigint generated always as identity primary key,
  actor_user_id uuid not null references auth.users(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete set null,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists activity_logs_actor_user_id_idx
  on public.activity_logs (actor_user_id, created_at desc);

create index if not exists activity_logs_org_id_idx
  on public.activity_logs (organization_id, created_at desc);

create or replace view public.v_member_workload
with (security_invoker = true) as
select
  m.id as member_id,
  m.organization_id,
  m.profile_id,
  p.full_name,
  m.position_code,
  m.division_code,
  m.weekly_capacity_hours,
  coalesce(sum(coalesce(ta.allocation_hours, t.estimated_hours)), 0) as assigned_hours,
  case
    when m.weekly_capacity_hours = 0 then 0
    else round(coalesce(sum(coalesce(ta.allocation_hours, t.estimated_hours)), 0)::numeric / m.weekly_capacity_hours::numeric, 2)
  end as load_ratio,
  case
    when m.weekly_capacity_hours = 0 then 'no_capacity'
    when coalesce(sum(coalesce(ta.allocation_hours, t.estimated_hours)), 0)::numeric / nullif(m.weekly_capacity_hours, 0)::numeric > 1 then 'overload'
    when coalesce(sum(coalesce(ta.allocation_hours, t.estimated_hours)), 0)::numeric / nullif(m.weekly_capacity_hours, 0)::numeric >= 0.8 then 'warning'
    else 'safe'
  end as workload_status
from public.members m
join public.profiles p on p.id = m.profile_id
left join public.task_assignments ta on ta.member_id = m.id
left join public.tasks t on t.id = ta.task_id
group by
  m.id,
  m.organization_id,
  m.profile_id,
  p.full_name,
  m.position_code,
  m.division_code,
  m.weekly_capacity_hours;
