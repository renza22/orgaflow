drop policy if exists "organization_logos_insert_owner_admin" on storage.objects;
drop policy if exists "organization_logos_select_owner_admin" on storage.objects;
drop policy if exists "organization_logos_update_owner_admin" on storage.objects;
drop policy if exists "organization_logos_delete_owner_admin" on storage.objects;

create policy "organization_logos_insert_owner_admin"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'organization-logos'
  and array_length(storage.foldername(name), 1) = 1
  and storage.filename(name) like 'logo_%'
  and lower(storage.extension(name)) = any (array['jpg', 'jpeg', 'png', 'webp'])
  and exists (
    select 1
    from public.members m
    where m.organization_id::text = (storage.foldername(name))[1]
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.role in ('owner', 'admin')
  )
);

create policy "organization_logos_select_owner_admin"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'organization-logos'
  and array_length(storage.foldername(name), 1) = 1
  and exists (
    select 1
    from public.members m
    where m.organization_id::text = (storage.foldername(name))[1]
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.role in ('owner', 'admin')
  )
);

create policy "organization_logos_update_owner_admin"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'organization-logos'
  and array_length(storage.foldername(name), 1) = 1
  and exists (
    select 1
    from public.members m
    where m.organization_id::text = (storage.foldername(name))[1]
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.role in ('owner', 'admin')
  )
)
with check (
  bucket_id = 'organization-logos'
  and array_length(storage.foldername(name), 1) = 1
  and storage.filename(name) like 'logo_%'
  and lower(storage.extension(name)) = any (array['jpg', 'jpeg', 'png', 'webp'])
  and exists (
    select 1
    from public.members m
    where m.organization_id::text = (storage.foldername(name))[1]
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.role in ('owner', 'admin')
  )
);

create policy "organization_logos_delete_owner_admin"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'organization-logos'
  and array_length(storage.foldername(name), 1) = 1
  and exists (
    select 1
    from public.members m
    where m.organization_id::text = (storage.foldername(name))[1]
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.role in ('owner', 'admin')
  )
);