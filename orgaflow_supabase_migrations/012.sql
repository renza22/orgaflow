alter table public.organizations
  add column if not exists logo_path text;

comment on column public.organizations.logo_path is
  'Relative path logo organisasi di Supabase Storage bucket organization-logos';