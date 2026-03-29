create table if not exists public.organization_types (
  code text primary key,
  label text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.study_programs (
  code text primary key,
  label text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_study_program_code_fkey'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_study_program_code_fkey
      FOREIGN KEY (study_program_code) REFERENCES public.study_programs(code) ON DELETE SET NULL;
  END IF;
END $$;

create index if not exists profiles_study_program_code_idx
  on public.profiles (study_program_code);

create table if not exists public.position_templates (
  code text primary key,
  label text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.division_templates (
  code text primary key,
  label text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.portfolio_platforms (
  code text primary key,
  label text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.skill_categories (
  code text primary key,
  label text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.skills (
  id uuid primary key default gen_random_uuid(),
  category_code text not null references public.skill_categories(code) on delete restrict,
  name text not null unique,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists skills_category_code_idx
  on public.skills (category_code, sort_order, name);
