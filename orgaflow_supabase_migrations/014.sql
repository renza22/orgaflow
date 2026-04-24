begin;

create or replace function public.is_org_admin(org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.members m
    where m.organization_id = org_id
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.role in ('owner', 'admin')
  );
$$;

drop policy if exists "projects_insert_same_org" on public.projects;
drop policy if exists "projects_update_delete_same_org" on public.projects;
drop policy if exists "projects_update_delete_same_org_delete" on public.projects;

drop policy if exists "projects_insert_admin_only" on public.projects;
drop policy if exists "projects_update_admin_only" on public.projects;
drop policy if exists "projects_delete_admin_only" on public.projects;

create policy "projects_insert_admin_only"
on public.projects for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.is_org_admin(organization_id)
);

create policy "projects_update_admin_only"
on public.projects for update
to authenticated
using (public.is_org_admin(organization_id))
with check (public.is_org_admin(organization_id));

create policy "projects_delete_admin_only"
on public.projects for delete
to authenticated
using (public.is_org_admin(organization_id));

commit;