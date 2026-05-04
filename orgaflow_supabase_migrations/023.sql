begin;

-- =========================================================
-- TASK 61: Backend Workload Calculation
-- =========================================================
-- Rumus:
-- load_ratio = total_jam_task_aktif / kapasitas_jam_mingguan
--
-- Mapping field dari requirement ke schema aktual:
-- estimated_effort  -> public.tasks.estimated_hours
-- weekly_capacity   -> public.members.weekly_capacity_hours
-- task_status       -> public.tasks.status
--
-- Rule Sprint 3:
-- - Hanya task status TODO dan IN_PROGRESS yang dihitung.
-- - DONE tidak dihitung.
-- - BACKLOG, BLOCKED, IN_REVIEW, CANCELLED juga tidak dihitung
--   karena requirement task 61 secara eksplisit menyebut hanya
--   TODO dan IN_PROGRESS.
--
-- Threshold default:
-- safe      : load_ratio < 0.70
-- warning   : 0.70 <= load_ratio <= 0.90
-- critical  : load_ratio > 0.90
-- overload  : load_ratio > 1.00
--
-- load_ratio disimpan sebagai rasio desimal:
-- 0.70 = 70%, 1.10 = 110%.
-- =========================================================


-- =========================================================
-- 1. Tabel setting threshold per organisasi.
--    Ini disiapkan supaya nanti fitur Kelola Organisasi
--    bisa mengubah threshold tanpa perlu ubah view/function.
-- =========================================================

create table if not exists public.organization_workload_settings (
  organization_id uuid primary key
    references public.organizations(id)
    on delete cascade,

  warning_threshold numeric(6,4) not null default 0.7000,
  critical_threshold numeric(6,4) not null default 0.9000,
  overload_threshold numeric(6,4) not null default 1.0000,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint organization_workload_settings_threshold_chk
    check (
      warning_threshold >= 0
      and critical_threshold > warning_threshold
      and overload_threshold > critical_threshold
      and overload_threshold <= 10
    )
);

comment on table public.organization_workload_settings is
  'Konfigurasi threshold workload per organisasi. Nilai 1.0 berarti 100%.';

comment on column public.organization_workload_settings.warning_threshold is
  'Ambang warning. Default 0.70 = 70%.';

comment on column public.organization_workload_settings.critical_threshold is
  'Ambang critical. Default 0.90 = 90%.';

comment on column public.organization_workload_settings.overload_threshold is
  'Ambang overload. Default 1.00 = 100%.';


drop trigger if exists trg_organization_workload_settings_updated_at
on public.organization_workload_settings;

create trigger trg_organization_workload_settings_updated_at
before update on public.organization_workload_settings
for each row
execute function public.set_updated_at();


-- Isi default untuk organisasi yang sudah ada.
insert into public.organization_workload_settings (
  organization_id,
  warning_threshold,
  critical_threshold,
  overload_threshold
)
select
  o.id,
  0.7000,
  0.9000,
  1.0000
from public.organizations o
on conflict (organization_id) do nothing;


-- =========================================================
-- 2. RLS untuk organization_workload_settings.
--    Semua member organisasi boleh baca.
--    Hanya admin/owner/role operasional admin yang boleh ubah.
-- =========================================================

alter table public.organization_workload_settings
enable row level security;

drop policy if exists "organization_workload_settings_select_same_org"
on public.organization_workload_settings;

drop policy if exists "organization_workload_settings_insert_admin_only"
on public.organization_workload_settings;

drop policy if exists "organization_workload_settings_update_admin_only"
on public.organization_workload_settings;

drop policy if exists "organization_workload_settings_delete_admin_only"
on public.organization_workload_settings;


create policy "organization_workload_settings_select_same_org"
on public.organization_workload_settings
for select
to authenticated
using (
  public.is_org_member(organization_id)
);


create policy "organization_workload_settings_insert_admin_only"
on public.organization_workload_settings
for insert
to authenticated
with check (
  public.is_org_admin(organization_id)
);


create policy "organization_workload_settings_update_admin_only"
on public.organization_workload_settings
for update
to authenticated
using (
  public.is_org_admin(organization_id)
)
with check (
  public.is_org_admin(organization_id)
);


create policy "organization_workload_settings_delete_admin_only"
on public.organization_workload_settings
for delete
to authenticated
using (
  public.is_org_admin(organization_id)
);


grant select, insert, update, delete
on public.organization_workload_settings
to authenticated;


-- =========================================================
-- 3. Rebuild workload view.
-- =========================================================
-- View ini menjadi sumber utama backend untuk kalkulasi beban.
--
-- Output penting:
-- - assigned_hours      : total jam task aktif
-- - weekly_capacity_hours
-- - load_ratio          : rasio desimal, contoh 1.10
-- - load_percentage     : persen, contoh 110.00
-- - workload_status     : safe / warning / critical / overload / no_capacity
--
-- Catatan:
-- allocation_hours dipakai dulu bila ada.
-- Kalau allocation_hours null, fallback ke tasks.estimated_hours.
-- =========================================================

drop view if exists public.v_member_workload;

create view public.v_member_workload
with (security_invoker = true)
as
with active_assignment_load as (
  select
    ta.member_id,
    coalesce(
      sum(
        coalesce(ta.allocation_hours, t.estimated_hours, 0)
      ) filter (
        where t.status in (
          'todo'::public.task_status_enum,
          'in_progress'::public.task_status_enum
        )
      ),
      0
    )::integer as assigned_hours,
    count(t.id) filter (
      where t.status in (
        'todo'::public.task_status_enum,
        'in_progress'::public.task_status_enum
      )
    )::integer as active_task_count
  from public.task_assignments ta
  join public.tasks t
    on t.id = ta.task_id
  group by
    ta.member_id
),
member_workload_base as (
  select
    m.id as member_id,
    m.organization_id,
    m.profile_id,
    coalesce(pf.full_name, 'Tanpa Nama') as full_name,
    m.position_code,
    m.division_code,
    coalesce(m.weekly_capacity_hours, 0)::integer as weekly_capacity_hours,
    coalesce(aal.assigned_hours, 0)::integer as assigned_hours,
    coalesce(aal.active_task_count, 0)::integer as active_task_count,
    coalesce(ows.warning_threshold, 0.7000)::numeric as warning_threshold,
    coalesce(ows.critical_threshold, 0.9000)::numeric as critical_threshold,
    coalesce(ows.overload_threshold, 1.0000)::numeric as overload_threshold
  from public.members m
  left join public.profiles pf
    on pf.id = m.profile_id
  left join active_assignment_load aal
    on aal.member_id = m.id
  left join public.organization_workload_settings ows
    on ows.organization_id = m.organization_id
  where m.status = 'active'::public.member_status_enum
)
select
  mwb.member_id,
  mwb.organization_id,
  mwb.profile_id,
  mwb.full_name,
  mwb.position_code,
  mwb.division_code,
  mwb.weekly_capacity_hours,
  mwb.assigned_hours,
  mwb.active_task_count,

  case
    when mwb.weekly_capacity_hours <= 0 then 0::numeric
    else round(
      mwb.assigned_hours::numeric / mwb.weekly_capacity_hours::numeric,
      4
    )
  end as load_ratio,

  case
    when mwb.weekly_capacity_hours <= 0 then 0::numeric
    else round(
      (
        mwb.assigned_hours::numeric / mwb.weekly_capacity_hours::numeric
      ) * 100,
      2
    )
  end as load_percentage,

  mwb.warning_threshold,
  mwb.critical_threshold,
  mwb.overload_threshold,

  case
    when mwb.weekly_capacity_hours <= 0 then 'no_capacity'

    when (
      mwb.assigned_hours::numeric
      / nullif(mwb.weekly_capacity_hours, 0)::numeric
    ) > mwb.overload_threshold then 'overload'

    when (
      mwb.assigned_hours::numeric
      / nullif(mwb.weekly_capacity_hours, 0)::numeric
    ) > mwb.critical_threshold then 'critical'

    when (
      mwb.assigned_hours::numeric
      / nullif(mwb.weekly_capacity_hours, 0)::numeric
    ) >= mwb.warning_threshold then 'warning'

    else 'safe'
  end as workload_status
from member_workload_base mwb;

comment on view public.v_member_workload is
  'View kalkulasi workload Sprint 3. Hanya task todo dan in_progress yang dihitung sebagai beban aktif.';

grant select on public.v_member_workload to authenticated;

commit;