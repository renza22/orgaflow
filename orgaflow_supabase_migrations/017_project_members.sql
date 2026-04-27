-- Create project_members table
create table if not exists public.project_members (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  added_by uuid references auth.users(id) on delete set null,
  added_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint project_members_unique unique (project_id, member_id)
);

create index if not exists project_members_project_id_idx
  on public.project_members (project_id);

create index if not exists project_members_member_id_idx
  on public.project_members (member_id);

-- Enable RLS
alter table public.project_members enable row level security;

-- Drop existing policies if they exist
drop policy if exists "Users can view project members in their organization" on public.project_members;
drop policy if exists "Admins and owners can add project members" on public.project_members;
drop policy if exists "Admins and owners can remove project members" on public.project_members;

-- RLS Policies
create policy "Users can view project members in their organization"
  on public.project_members for select
  using (
    exists (
      select 1 from public.projects p
      inner join public.members m on m.organization_id = p.organization_id
      where p.id = project_members.project_id
        and m.profile_id = auth.uid()
    )
  );

create policy "Admins and owners can add project members"
  on public.project_members for insert
  with check (
    exists (
      select 1 from public.projects p
      inner join public.members m on m.organization_id = p.organization_id
      where p.id = project_members.project_id
        and m.profile_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
  );

create policy "Admins and owners can remove project members"
  on public.project_members for delete
  using (
    exists (
      select 1 from public.projects p
      inner join public.members m on m.organization_id = p.organization_id
      where p.id = project_members.project_id
        and m.profile_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
  );

-- Update RLS policy for projects table to restrict member access
-- Drop existing policy if exists
drop policy if exists "Users can view projects in their organization" on public.projects;

-- Create new policy: owners/admins see all, members only see their assigned projects
create policy "Users can view projects based on role"
  on public.projects for select
  using (
    exists (
      select 1 from public.members m
      where m.organization_id = projects.organization_id
        and m.profile_id = auth.uid()
        and (
          m.role in ('owner', 'admin')
          or exists (
            select 1 from public.project_members pm
            where pm.project_id = projects.id
              and pm.member_id = m.id
          )
        )
    )
  );
