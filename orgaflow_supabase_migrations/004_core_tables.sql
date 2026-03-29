create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text generated always as (public.slugify(name)) stored,
  type_code text not null references public.organization_types(code) on delete restrict,
  invite_code text not null unique,
  description text,
  created_by uuid not null references auth.users(id) on delete restrict,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organizations_invite_code_format_chk
    check (invite_code ~ '^[A-Z0-9]+-[0-9]{4}-[A-Z0-9]+$')
);

create unique index if not exists organizations_slug_key
  on public.organizations (slug);

create trigger trg_organizations_updated_at
before update on public.organizations
for each row execute function public.set_updated_at();

create table if not exists public.portfolio_links (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  platform_code text not null references public.portfolio_platforms(code) on delete restrict,
  url text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists portfolio_links_profile_id_idx
  on public.portfolio_links (profile_id);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  role public.member_role_enum not null default 'member',
  position_code text references public.position_templates(code) on delete set null,
  division_code text references public.division_templates(code) on delete set null,
  weekly_capacity_hours integer not null default 0 check (weekly_capacity_hours >= 0),
  capacity_used_hours integer not null default 0 check (capacity_used_hours >= 0),
  availability_status public.availability_status_enum not null default 'available',
  status public.member_status_enum not null default 'active',
  joined_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint members_unique_profile_per_org unique (profile_id, organization_id)
);

create index if not exists members_profile_id_idx
  on public.members (profile_id);

create index if not exists members_organization_id_idx
  on public.members (organization_id);

create trigger trg_members_updated_at
before update on public.members
for each row execute function public.set_updated_at();

create table if not exists public.member_skills (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  proficiency_level smallint not null default 3 check (proficiency_level between 1 and 5),
  source text not null default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_skills_unique unique (member_id, skill_id)
);

create index if not exists member_skills_member_id_idx
  on public.member_skills (member_id);

create index if not exists member_skills_skill_id_idx
  on public.member_skills (skill_id);

create trigger trg_member_skills_updated_at
before update on public.member_skills
for each row execute function public.set_updated_at();

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  description text,
  status public.project_status_enum not null default 'draft',
  start_date date,
  end_date date,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists projects_organization_id_idx
  on public.projects (organization_id);

create trigger trg_projects_updated_at
before update on public.projects
for each row execute function public.set_updated_at();

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  parent_task_id uuid references public.tasks(id) on delete set null,
  title text not null,
  description text,
  estimated_hours integer not null default 0 check (estimated_hours >= 0),
  priority public.task_priority_enum not null default 'medium',
  status public.task_status_enum not null default 'backlog',
  due_date date,
  sort_order integer not null default 0,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists tasks_project_id_idx
  on public.tasks (project_id);

create index if not exists tasks_parent_task_id_idx
  on public.tasks (parent_task_id);

create index if not exists tasks_status_idx
  on public.tasks (status);

create trigger trg_tasks_updated_at
before update on public.tasks
for each row execute function public.set_updated_at();

create table if not exists public.task_skill_requirements (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  minimum_level smallint not null default 3 check (minimum_level between 1 and 5),
  priority_weight numeric(5,2) not null default 1.00 check (priority_weight > 0),
  created_at timestamptz not null default now(),
  constraint task_skill_requirements_unique unique (task_id, skill_id)
);

create index if not exists task_skill_requirements_task_id_idx
  on public.task_skill_requirements (task_id);

create index if not exists task_skill_requirements_skill_id_idx
  on public.task_skill_requirements (skill_id);

create table if not exists public.task_dependencies (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  depends_on_task_id uuid not null references public.tasks(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint task_dependencies_unique unique (task_id, depends_on_task_id),
  constraint task_dependencies_not_self_chk check (task_id <> depends_on_task_id)
);

create index if not exists task_dependencies_task_id_idx
  on public.task_dependencies (task_id);

create index if not exists task_dependencies_depends_on_task_id_idx
  on public.task_dependencies (depends_on_task_id);

create or replace function public.validate_task_dependency_same_project()
returns trigger
language plpgsql
as $$
declare
  v_task_project uuid;
  v_dep_project uuid;
begin
  select project_id into v_task_project from public.tasks where id = new.task_id;
  select project_id into v_dep_project from public.tasks where id = new.depends_on_task_id;

  if v_task_project is null or v_dep_project is null then
    raise exception 'Task dependency references missing task';
  end if;

  if v_task_project <> v_dep_project then
    raise exception 'Dependency must belong to the same project';
  end if;

  return new;
end;
$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_validate_task_dependency_same_project') THEN
    EXECUTE 'DROP TRIGGER trg_validate_task_dependency_same_project ON public.task_dependencies';
  END IF;
END $$;

create trigger trg_validate_task_dependency_same_project
before insert or update on public.task_dependencies
for each row execute function public.validate_task_dependency_same_project();

create table if not exists public.task_assignments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  assigned_by uuid references auth.users(id) on delete set null,
  assigned_at timestamptz not null default now(),
  allocation_hours integer check (allocation_hours is null or allocation_hours >= 0),
  is_primary boolean not null default true,
  created_at timestamptz not null default now(),
  constraint task_assignments_unique unique (task_id, member_id)
);

create index if not exists task_assignments_task_id_idx
  on public.task_assignments (task_id);

create index if not exists task_assignments_member_id_idx
  on public.task_assignments (member_id);
