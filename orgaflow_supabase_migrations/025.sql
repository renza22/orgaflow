begin;

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

  update public.organizations o
  set
    name = v_name,
    type_code = p_type_code,
    description = v_description,
    period_label = v_period_label,
    semester_label = v_semester_label,
    period_start_date = p_period_start_date,
    period_end_date = p_period_end_date,
    updated_at = now()
  where o.id = p_organization_id;

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