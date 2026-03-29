create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.slugify(input_text text)
returns text
language sql
immutable
as $$
  select trim(both '-' from regexp_replace(lower(coalesce(input_text, '')), '[^a-z0-9]+', '-', 'g'));
$$;

create or replace function public.generate_invite_code(org_name text)
returns text
language plpgsql
as $$
declare
  v_prefix text;
  v_suffix text;
begin
  v_prefix := upper(left(regexp_replace(public.slugify(org_name), '[^a-z0-9]', '', 'g') || 'ORGA', 4));
  v_suffix := upper(substr(md5(gen_random_uuid()::text), 1, 4));
  return v_prefix || '-' || to_char(current_date, 'YYYY') || '-' || v_suffix;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    full_name
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  full_name text,
  nim text unique,
  study_program_code text,
  avatar_path text,
  bio text,
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') THEN
    EXECUTE 'DROP TRIGGER on_auth_user_created ON auth.users';
  END IF;
END $$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
