-- Fix RLS policies for project_members table
-- This migration can be run multiple times safely

-- Drop existing policies if they exist
drop policy if exists "Users can view project members in their organization" on public.project_members;
drop policy if exists "Admins and owners can add project members" on public.project_members;
drop policy if exists "Admins and owners can remove project members" on public.project_members;

-- Recreate policies
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
