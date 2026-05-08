begin;

-- =========================================================
-- TASK 64: Profile User Avatar Storage Policies
-- =========================================================
-- Bucket khusus foto profile user:
-- - bucket: profile-avatars
-- - kolom database: public.profiles.avatar_path
-- - path file: {profile_id}/avatar_{timestamp}.{ext}
--
-- Bucket ini berbeda dari logo organisasi:
-- - bucket organisasi: organization-logos
-- - kolom organisasi: public.organizations.logo_path
-- =========================================================


-- Pastikan bucket profile-avatars ada dan private.
-- User sudah membuat bucket manual, tetapi query ini tetap aman
-- jika dijalankan ulang.
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'profile-avatars',
  'profile-avatars',
  false,
  5242880,
  array[
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp'
  ]
)
on conflict (id) do update
set
  public = false,
  file_size_limit = 5242880,
  allowed_mime_types = array[
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp'
  ];


-- Bersihkan policy lama jika pernah ada.
drop policy if exists "profile_avatars_select_self_or_same_org"
on storage.objects;

drop policy if exists "profile_avatars_insert_own"
on storage.objects;

drop policy if exists "profile_avatars_update_own"
on storage.objects;

drop policy if exists "profile_avatars_delete_own"
on storage.objects;


-- =========================================================
-- SELECT:
-- Avatar bisa dilihat oleh:
-- 1. Pemilik avatar sendiri.
-- 2. Member aktif yang berada dalam organisasi yang sama
--    dengan pemilik profile tersebut.
-- =========================================================

create policy "profile_avatars_select_self_or_same_org"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'profile-avatars'
  and array_length(storage.foldername(name), 1) = 1
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (
      select 1
      from public.members self_m
      join public.members target_m
        on target_m.organization_id = self_m.organization_id
      where self_m.profile_id = auth.uid()
        and self_m.status = 'active'
        and target_m.profile_id::text = (storage.foldername(name))[1]
        and target_m.status = 'active'
    )
  )
);


-- =========================================================
-- INSERT:
-- User hanya boleh upload avatar ke folder profile miliknya sendiri.
-- Format path:
-- {auth.uid()}/avatar_{timestamp}.{jpg|jpeg|png|webp}
-- =========================================================

create policy "profile_avatars_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile-avatars'
  and array_length(storage.foldername(name), 1) = 1
  and (storage.foldername(name))[1] = auth.uid()::text
  and storage.filename(name) like 'avatar_%'
  and lower(storage.extension(name)) = any (
    array['jpg', 'jpeg', 'png', 'webp']
  )
);


-- =========================================================
-- UPDATE:
-- User hanya boleh overwrite/update avatar miliknya sendiri.
-- =========================================================

create policy "profile_avatars_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile-avatars'
  and array_length(storage.foldername(name), 1) = 1
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'profile-avatars'
  and array_length(storage.foldername(name), 1) = 1
  and (storage.foldername(name))[1] = auth.uid()::text
  and storage.filename(name) like 'avatar_%'
  and lower(storage.extension(name)) = any (
    array['jpg', 'jpeg', 'png', 'webp']
  )
);


-- =========================================================
-- DELETE:
-- User hanya boleh hapus avatar miliknya sendiri.
-- =========================================================

create policy "profile_avatars_delete_own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'profile-avatars'
  and array_length(storage.foldername(name), 1) = 1
  and (storage.foldername(name))[1] = auth.uid()::text
);


notify pgrst, 'reload schema';

commit;