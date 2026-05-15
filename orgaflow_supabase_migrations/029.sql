begin;

-- =========================================================
-- TASK 69: Threshold Admin Settings
-- =========================================================
-- Goal:
-- - Admin mengatur 2 threshold utama: warning dan overload.
-- - warning_threshold: load >= warning dan < overload => warning/kuning.
-- - overload_threshold: load >= overload => overload/merah.
-- - critical_threshold tetap disimpan untuk backward compatibility, tetapi
--   tidak dipakai lagi oleh v_member_workload.
-- =========================================================

-- 1. Longgarkan constraint lama yang mewajibkan warning < critical < overload.
alter table public.organization_workload_settings
  drop constraint if exists organization_workload_settings_threshold_chk;

alter table public.organization_workload_settings
  drop constraint if exists organization_workload_settings_threshold_two_step_chk;

-- Simpan critical_threshold sama dengan overload_threshold agar kompatibel
-- dengan model/RPC lama, tetapi status critical tidak lagi diproduksi view.
update public.organization_workload_settings
set
  critical_threshold = overload_threshold,
  updated_at = now()
where critical_threshold is distinct from overload_threshold;

alter table public.organization_workload_settings
  add constraint organization_workload_settings_threshold_two_step_chk
  check (
    warning_threshold >= 0
    and overload_threshold > warning_threshold
    and overload_threshold <= 10
    and critical_threshold >= warning_threshold
    and critical_threshold <= overload_threshold
  );

comment on constraint organization_workload_settings_threshold_two_step_chk
on public.organization_workload_settings is
  'Task 69: warning_threshold dan overload_threshold adalah threshold utama. critical_threshold hanya untuk backward compatibility.';

comment on column public.organization_workload_settings.warning_threshold is
  'Ambang warning. Contoh 0.75 = 75%. Load >= warning dan < overload menjadi warning.';

comment on column public.organization_workload_settings.overload_threshold is
  'Ambang overload. Contoh 1.00 = 100%. Load >= overload menjadi overload.';

comment on column public.organization_workload_settings.critical_threshold is
  'Backward compatibility. Tidak dipakai lagi oleh v_member_workload Task 69.';


-- 2. Rebuild v_member_workload agar memakai 2 threshold utama.
drop view if exists public.v_member_workload;

create view public.v_member_workload
with (security_invoker = true)
as
with active_assignment_load as (
  select
    ta.member_id,
    coalesce(
      sum(coalesce(ta.allocation_hours, t.estimated_hours, 0)) filter (
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
  group by ta.member_id
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
    coalesce(ows.critical_threshold, ows.overload_threshold, 1.0000)::numeric as critical_threshold,
    coalesce(ows.overload_threshold, 1.0000)::numeric as overload_threshold
  from public.members m
  left join public.profiles pf
    on pf.id = m.profile_id
  left join active_assignment_load aal
    on aal.member_id = m.id
  left join public.organization_workload_settings ows
    on ows.organization_id = m.organization_id
  where m.status = 'active'::public.member_status_enum
),
calculated as (
  select
    mwb.*,
    case
      when mwb.weekly_capacity_hours <= 0 then 0::numeric
      else round(mwb.assigned_hours::numeric / mwb.weekly_capacity_hours::numeric, 4)
    end as computed_load_ratio,
    case
      when mwb.weekly_capacity_hours <= 0 then 0::numeric
      else round((mwb.assigned_hours::numeric / mwb.weekly_capacity_hours::numeric) * 100, 2)
    end as computed_load_percentage
  from member_workload_base mwb
)
select
  c.member_id,
  c.organization_id,
  c.profile_id,
  c.full_name,
  c.position_code,
  c.division_code,
  c.weekly_capacity_hours,
  c.assigned_hours,
  c.active_task_count,
  c.computed_load_ratio as load_ratio,
  c.computed_load_percentage as load_percentage,
  c.warning_threshold,
  c.critical_threshold,
  c.overload_threshold,
  case
    when c.weekly_capacity_hours <= 0 then 'no_capacity'
    when c.computed_load_ratio >= c.overload_threshold then 'overload'
    when c.computed_load_ratio >= c.warning_threshold then 'warning'
    else 'safe'
  end as workload_status
from calculated c;

comment on view public.v_member_workload is
  'Task 69 workload view. Status memakai 2 threshold utama: safe, warning, overload, no_capacity.';

grant select on public.v_member_workload to authenticated;


-- 3. Rebuild get_organization_settings dengan output tetap kompatibel.
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
    org.id as organization_id,
    org.name,
    org.slug,
    org.type_code,
    org.invite_code,
    org.description,
    org.logo_path,
    org.period_label,
    org.semester_label,
    org.period_start_date,
    org.period_end_date,
    org.is_active,
    coalesce(ows.warning_threshold, 0.7000)::numeric as warning_threshold,
    coalesce(ows.critical_threshold, ows.overload_threshold, 1.0000)::numeric as critical_threshold,
    coalesce(ows.overload_threshold, 1.0000)::numeric as overload_threshold,
    coalesce(ows.burnout_alert_days, 14)::integer as burnout_alert_days,
    coalesce(oas.skill_weight, 0.4000)::numeric as skill_weight,
    coalesce(oas.capacity_weight, 0.3500)::numeric as capacity_weight,
    coalesce(oas.fairness_weight, 0.2500)::numeric as fairness_weight,
    org.updated_at
  from public.organizations org
  left join public.organization_workload_settings ows
    on ows.organization_id = org.id
  left join public.organization_assignment_settings oas
    on oas.organization_id = org.id
  where org.id = p_organization_id;
end;
$$;

grant execute on function public.get_organization_settings(uuid)
to authenticated;


-- 4. Rebuild update_organization_settings.
--    Signature tetap sama supaya Flutter lama/baru tetap kompatibel.
--    p_critical_threshold diterima tetapi tidak menjadi threshold status utama.
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
  p_critical_threshold numeric default 1.0000,
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
  v_effective_critical_threshold numeric;
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
     or p_overload_threshold <= p_warning_threshold
     or p_overload_threshold > 10 then
    raise exception 'Threshold workload tidak valid. Pastikan warning lebih kecil dari overload.';
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
    raise exception 'Bobot Smart Assignment harus berada di antara 0 sampai 100.';
  end if;

  v_weight_sum := p_skill_weight + p_capacity_weight + p_fairness_weight;

  if abs(v_weight_sum - 1.0000) > 0.0001 then
    raise exception 'Total bobot Smart Assignment harus 100.';
  end if;

  -- Task 69: critical_threshold hanya kompatibilitas. Samakan dengan overload.
  v_effective_critical_threshold := p_overload_threshold;

  update public.organizations org
  set
    name = v_name,
    type_code = p_type_code,
    description = v_description,
    period_label = v_period_label,
    semester_label = v_semester_label,
    period_start_date = p_period_start_date,
    period_end_date = p_period_end_date,
    updated_at = now()
  where org.id = p_organization_id;

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
    v_effective_critical_threshold,
    p_overload_threshold,
    p_burnout_alert_days
  )
  on conflict on constraint organization_workload_settings_pkey
  do update
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
  on conflict on constraint organization_assignment_settings_pkey
  do update
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

notify pgrst, 'reload schema';

commit;
