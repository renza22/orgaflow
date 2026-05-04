begin;

-- =========================================================
-- TASK 63: Organization Settings / Edit Organization Info
-- =========================================================
-- Tujuan:
-- - Menyimpan data edit organisasi dari halaman Kelola Organisasi.
-- - Menambahkan field periode/semester/tanggal kepengurusan.
-- - Menambahkan burnout_alert_days ke workload settings.
-- - Menambahkan table bobot Smart Assignment agar slider tidak lokal/dummy.
--
-- Catatan:
-- - organizations.name/type_code/description/logo_path/invite_code sudah ada.
-- - organization_workload_settings sudah dibuat pada migration 023.
-- =========================================================


-- =========================================================
-- 1. Tambah field informasi organisasi.
-- =========================================================

alter table public.organizations
  add column if not exists period_label text,
  add column if not exists semester_label text,
  add column if not exists period_start_date date,
  add column if not exists period_end_date date;

comment on column public.organizations.period_label is
  'Label periode kepengurusan organisasi, contoh: 2025/2026.';

comment on column public.organizations.semester_label is
  'Label semester aktif organisasi, contoh: Ganjil 2025/2026.';

comment on column public.organizations.period_start_date is
  'Tanggal mulai periode kepengurusan organisasi.';

comment on column public.organizations.period_end_date is
  'Tanggal akhir periode kepengurusan organisasi.';


do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'organizations_period_date_order_chk'
  ) then
    alter table public.organizations
      add constraint organizations_period_date_order_chk
      check (
        period_start_date is null
        or period_end_date is null
        or period_end_date >= period_start_date
      );
  end if;
end $$;


-- =========================================================
-- 2. Tambah burnout_alert_days ke workload settings.
-- =========================================================

alter table public.organization_workload_settings
  add column if not exists burnout_alert_days integer not null default 14;

comment on column public.organization_workload_settings.burnout_alert_days is
  'Jumlah hari berada pada status overload sebelum burnout alert dikirim.';


do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'organization_workload_settings_burnout_days_chk'
  ) then
    alter table public.organization_workload_settings
      add constraint organization_workload_settings_burnout_days_chk
      check (burnout_alert_days between 1 and 365);
  end if;
end $$;


-- =========================================================
-- 3. Table setting bobot Smart Assignment per organisasi.
-- =========================================================

create table if not exists public.organization_assignment_settings (
  organization_id uuid primary key
    references public.organizations(id)
    on delete cascade,

  skill_weight numeric(6,4) not null default 0.4000,
  capacity_weight numeric(6,4) not null default 0.3500,
  fairness_weight numeric(6,4) not null default 0.2500,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint organization_assignment_settings_weight_range_chk
    check (
      skill_weight >= 0
      and capacity_weight >= 0
      and fairness_weight >= 0
      and skill_weight <= 1
      and capacity_weight <= 1
      and fairness_weight <= 1
    ),

  constraint organization_assignment_settings_weight_sum_chk
    check (
      abs((skill_weight + capacity_weight + fairness_weight) - 1.0000) <= 0.0001
    )
);

comment on table public.organization_assignment_settings is
  'Konfigurasi bobot algoritma Smart Assignment per organisasi. Nilai 1.0 berarti 100%.';

comment on column public.organization_assignment_settings.skill_weight is
  'Bobot skill match. Default 0.40 = 40%.';

comment on column public.organization_assignment_settings.capacity_weight is
  'Bobot capacity score. Default 0.35 = 35%.';

comment on column public.organization_assignment_settings.fairness_weight is
  'Bobot fairness bonus. Default 0.25 = 25%.';


drop trigger if exists trg_organization_assignment_settings_updated_at
on public.organization_assignment_settings;

create trigger trg_organization_assignment_settings_updated_at
before update on public.organization_assignment_settings
for each row
execute function public.set_updated_at();


insert into public.organization_assignment_settings (
  organization_id,
  skill_weight,
  capacity_weight,
  fairness_weight
)
select
  o.id,
  0.4000,
  0.3500,
  0.2500
from public.organizations o
on conflict (organization_id) do nothing;


-- =========================================================
-- 4. RLS organization_assignment_settings.
-- =========================================================

alter table public.organization_assignment_settings
enable row level security;

drop policy if exists "organization_assignment_settings_select_same_org"
on public.organization_assignment_settings;

drop policy if exists "organization_assignment_settings_insert_admin_only"
on public.organization_assignment_settings;

drop policy if exists "organization_assignment_settings_update_admin_only"
on public.organization_assignment_settings;

drop policy if exists "organization_assignment_settings_delete_admin_only"
on public.organization_assignment_settings;


create policy "organization_assignment_settings_select_same_org"
on public.organization_assignment_settings
for select
to authenticated
using (
  public.is_org_member(organization_id)
);


create policy "organization_assignment_settings_insert_admin_only"
on public.organization_assignment_settings
for insert
to authenticated
with check (
  public.is_org_admin(organization_id)
);


create policy "organization_assignment_settings_update_admin_only"
on public.organization_assignment_settings
for update
to authenticated
using (
  public.is_org_admin(organization_id)
)
with check (
  public.is_org_admin(organization_id)
);


create policy "organization_assignment_settings_delete_admin_only"
on public.organization_assignment_settings
for delete
to authenticated
using (
  public.is_org_admin(organization_id)
);


grant select, insert, update, delete
on public.organization_assignment_settings
to authenticated;


-- =========================================================
-- 5. RPC read settings.
-- =========================================================
-- Dipakai halaman Kelola Organisasi untuk load 1 paket data:
-- organization info + workload threshold + smart assignment weight.
-- =========================================================

create or replace function public.get_organization_settings(
  p_organization_id uuid
)
returns table (
  organization_id uuid,
  name text,
  slug text,
  type_code text,
  invite_code text,
  description text,
  logo_path text,
  period_label text,
  semester_label text,
  period_start_date date,
  period_end_date date,
  is_active boolean,
  warning_threshold numeric,
  critical_threshold numeric,
  overload_threshold numeric,
  burnout_alert_days integer,
  skill_weight numeric,
  capacity_weight numeric,
  fairness_weight numeric,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_org_member(p_organization_id) then
    raise exception 'Anda tidak memiliki akses ke organisasi ini.';
  end if;

  return query
  select
    o.id as organization_id,
    o.name,
    o.slug,
    o.type_code,
    o.invite_code,
    o.description,
    o.logo_path,
    o.period_label,
    o.semester_label,
    o.period_start_date,
    o.period_end_date,
    o.is_active,
    coalesce(ows.warning_threshold, 0.7000)::numeric as warning_threshold,
    coalesce(ows.critical_threshold, 0.9000)::numeric as critical_threshold,
    coalesce(ows.overload_threshold, 1.0000)::numeric as overload_threshold,
    coalesce(ows.burnout_alert_days, 14)::integer as burnout_alert_days,
    coalesce(oas.skill_weight, 0.4000)::numeric as skill_weight,
    coalesce(oas.capacity_weight, 0.3500)::numeric as capacity_weight,
    coalesce(oas.fairness_weight, 0.2500)::numeric as fairness_weight,
    o.updated_at
  from public.organizations o
  left join public.organization_workload_settings ows
    on ows.organization_id = o.id
  left join public.organization_assignment_settings oas
    on oas.organization_id = o.id
  where o.id = p_organization_id;
end;
$$;

grant execute on function public.get_organization_settings(uuid)
to authenticated;


-- =========================================================
-- 6. RPC update settings.
-- =========================================================
-- p_warning_threshold / p_critical_threshold / p_overload_threshold
-- memakai rasio desimal:
-- 0.70 = 70%
-- 0.90 = 90%
-- 1.00 = 100%
--
-- p_skill_weight / p_capacity_weight / p_fairness_weight
-- juga memakai rasio desimal:
-- 0.40 = 40%
-- =========================================================

create or replace function public.update_organization_settings(
  p_organization_id uuid,
  p_name text,
  p_type_code text,
  p_description text default null,
  p_period_label text default null,
  p_semester_label text default null,
  p_period_start_date date default null,
  p_period_end_date date default null,
  p_warning_threshold numeric default 0.7000,
  p_critical_threshold numeric default 0.9000,
  p_overload_threshold numeric default 1.0000,
  p_burnout_alert_days integer default 14,
  p_skill_weight numeric default 0.4000,
  p_capacity_weight numeric default 0.3500,
  p_fairness_weight numeric default 0.2500
)
returns table (
  organization_id uuid,
  name text,
  slug text,
  type_code text,
  invite_code text,
  description text,
  logo_path text,
  period_label text,
  semester_label text,
  period_start_date date,
  period_end_date date,
  is_active boolean,
  warning_threshold numeric,
  critical_threshold numeric,
  overload_threshold numeric,
  burnout_alert_days integer,
  skill_weight numeric,
  capacity_weight numeric,
  fairness_weight numeric,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
  v_description text;
  v_period_label text;
  v_semester_label text;
  v_weight_sum numeric;
begin
  if not public.is_org_admin(p_organization_id) then
    raise exception 'Hanya admin organisasi yang dapat mengubah pengaturan organisasi.';
  end if;

  v_name := nullif(btrim(coalesce(p_name, '')), '');
  v_description := nullif(btrim(coalesce(p_description, '')), '');
  v_period_label := nullif(btrim(coalesce(p_period_label, '')), '');
  v_semester_label := nullif(btrim(coalesce(p_semester_label, '')), '');

  if v_name is null then
    raise exception 'Nama organisasi wajib diisi.';
  end if;

  if not exists (
    select 1
    from public.organization_types ot
    where ot.code = p_type_code
      and ot.is_active = true
  ) then
    raise exception 'Tipe organisasi tidak valid.';
  end if;

  if p_period_start_date is not null
     and p_period_end_date is not null
     and p_period_end_date < p_period_start_date then
    raise exception 'Tanggal selesai periode tidak boleh lebih awal dari tanggal mulai.';
  end if;

  if p_warning_threshold < 0
     or p_critical_threshold <= p_warning_threshold
     or p_overload_threshold <= p_critical_threshold
     or p_overload_threshold > 10 then
    raise exception 'Threshold workload tidak valid. Pastikan warning < critical < overload.';
  end if;

  if p_burnout_alert_days < 1 or p_burnout_alert_days > 365 then
    raise exception 'Burnout alert days harus berada di antara 1 sampai 365.';
  end if;

  if p_skill_weight < 0
     or p_capacity_weight < 0
     or p_fairness_weight < 0
     or p_skill_weight > 1
     or p_capacity_weight > 1
     or p_fairness_weight > 1 then
    raise exception 'Bobot Smart Assignment harus berada di antara 0%% sampai 100%%.';
  end if;

  v_weight_sum := p_skill_weight + p_capacity_weight + p_fairness_weight;

  if abs(v_weight_sum - 1.0000) > 0.0001 then
    raise exception 'Total bobot Smart Assignment harus 100%%.';
  end if;

  update public.organizations
  set
    name = v_name,
    type_code = p_type_code,
    description = v_description,
    period_label = v_period_label,
    semester_label = v_semester_label,
    period_start_date = p_period_start_date,
    period_end_date = p_period_end_date,
    updated_at = now()
  where id = p_organization_id;

  insert into public.organization_workload_settings (
    organization_id,
    warning_threshold,
    critical_threshold,
    overload_threshold,
    burnout_alert_days
  )
  values (
    p_organization_id,
    p_warning_threshold,
    p_critical_threshold,
    p_overload_threshold,
    p_burnout_alert_days
  )
  on conflict (organization_id) do update
  set
    warning_threshold = excluded.warning_threshold,
    critical_threshold = excluded.critical_threshold,
    overload_threshold = excluded.overload_threshold,
    burnout_alert_days = excluded.burnout_alert_days,
    updated_at = now();

  insert into public.organization_assignment_settings (
    organization_id,
    skill_weight,
    capacity_weight,
    fairness_weight
  )
  values (
    p_organization_id,
    p_skill_weight,
    p_capacity_weight,
    p_fairness_weight
  )
  on conflict (organization_id) do update
  set
    skill_weight = excluded.skill_weight,
    capacity_weight = excluded.capacity_weight,
    fairness_weight = excluded.fairness_weight,
    updated_at = now();

  return query
  select *
  from public.get_organization_settings(p_organization_id);
end;
$$;

grant execute on function public.update_organization_settings(
  uuid,
  text,
  text,
  text,
  text,
  text,
  date,
  date,
  numeric,
  numeric,
  numeric,
  integer,
  numeric,
  numeric,
  numeric
)
to authenticated;

commit;