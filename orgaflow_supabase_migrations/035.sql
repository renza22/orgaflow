begin;

-- =========================================================
-- Task 80: Advanced Burnout Notification
-- Chronological Alert
-- =========================================================

-- Snapshot workload harian.
-- Data ini dipakai untuk menghitung overload berturut-turut.
create table if not exists public.member_workload_daily_snapshots (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete cascade,

  member_id uuid not null
    references public.members(id)
    on delete cascade,

  profile_id uuid
    references public.profiles(id)
    on delete set null,

  snapshot_date date not null,

  weekly_capacity_hours integer not null default 0,
  assigned_hours integer not null default 0,
  active_task_count integer not null default 0,

  load_ratio numeric(8,4) not null default 0,
  load_percentage numeric(8,2) not null default 0,

  workload_status text not null default 'safe',
  overload_threshold numeric(6,4) not null default 1.0000,
  burnout_alert_days integer not null default 14,

  is_red_zone boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint member_workload_daily_snapshots_unique
    unique (member_id, snapshot_date),

  constraint member_workload_daily_snapshots_burnout_days_chk
    check (burnout_alert_days between 1 and 365)
);

create index if not exists member_workload_daily_snapshots_org_date_idx
  on public.member_workload_daily_snapshots (organization_id, snapshot_date desc);

create index if not exists member_workload_daily_snapshots_member_date_idx
  on public.member_workload_daily_snapshots (member_id, snapshot_date desc);

create index if not exists member_workload_daily_snapshots_red_idx
  on public.member_workload_daily_snapshots (organization_id, member_id, snapshot_date desc)
  where is_red_zone = true;


drop trigger if exists trg_member_workload_daily_snapshots_updated_at
on public.member_workload_daily_snapshots;

create trigger trg_member_workload_daily_snapshots_updated_at
before update on public.member_workload_daily_snapshots
for each row
execute function public.set_updated_at();


-- Status burnout alert.
create table if not exists public.member_burnout_alerts (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete cascade,

  member_id uuid not null
    references public.members(id)
    on delete cascade,

  status text not null default 'active'
    check (status in ('active', 'critical', 'resolved')),

  first_red_date date not null,
  last_red_date date not null,

  streak_days integer not null default 1
    check (streak_days >= 0),

  threshold_days integer not null default 14
    check (threshold_days between 1 and 365),

  triggered_at timestamptz,
  resolved_at timestamptz,
  last_notification_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists member_burnout_alerts_org_status_idx
  on public.member_burnout_alerts (organization_id, status);

create index if not exists member_burnout_alerts_member_status_idx
  on public.member_burnout_alerts (member_id, status);

create unique index if not exists member_burnout_alerts_one_open_idx
  on public.member_burnout_alerts (member_id)
  where status in ('active', 'critical');


drop trigger if exists trg_member_burnout_alerts_updated_at
on public.member_burnout_alerts;

create trigger trg_member_burnout_alerts_updated_at
before update on public.member_burnout_alerts
for each row
execute function public.set_updated_at();


-- =========================================================
-- RLS
-- Admin bisa lihat semua alert organisasi.
-- Member bisa lihat alert miliknya sendiri.
-- Write hanya lewat function.
-- =========================================================

alter table public.member_workload_daily_snapshots enable row level security;
alter table public.member_burnout_alerts enable row level security;

drop policy if exists member_workload_daily_snapshots_select_policy
on public.member_workload_daily_snapshots;

drop policy if exists member_workload_daily_snapshots_no_direct_insert
on public.member_workload_daily_snapshots;

drop policy if exists member_workload_daily_snapshots_no_direct_update
on public.member_workload_daily_snapshots;

drop policy if exists member_workload_daily_snapshots_no_direct_delete
on public.member_workload_daily_snapshots;

create policy member_workload_daily_snapshots_select_policy
on public.member_workload_daily_snapshots
for select
to authenticated
using (
  public.is_org_admin(organization_id)
  or exists (
    select 1
    from public.members m
    where m.id = member_workload_daily_snapshots.member_id
      and m.profile_id = auth.uid()
      and m.status = 'active'::public.member_status_enum
  )
);

create policy member_workload_daily_snapshots_no_direct_insert
on public.member_workload_daily_snapshots
for insert
to authenticated
with check (false);

create policy member_workload_daily_snapshots_no_direct_update
on public.member_workload_daily_snapshots
for update
to authenticated
using (false)
with check (false);

create policy member_workload_daily_snapshots_no_direct_delete
on public.member_workload_daily_snapshots
for delete
to authenticated
using (false);


drop policy if exists member_burnout_alerts_select_policy
on public.member_burnout_alerts;

drop policy if exists member_burnout_alerts_no_direct_insert
on public.member_burnout_alerts;

drop policy if exists member_burnout_alerts_no_direct_update
on public.member_burnout_alerts;

drop policy if exists member_burnout_alerts_no_direct_delete
on public.member_burnout_alerts;

create policy member_burnout_alerts_select_policy
on public.member_burnout_alerts
for select
to authenticated
using (
  public.is_org_admin(organization_id)
  or exists (
    select 1
    from public.members m
    where m.id = member_burnout_alerts.member_id
      and m.profile_id = auth.uid()
      and m.status = 'active'::public.member_status_enum
  )
);

create policy member_burnout_alerts_no_direct_insert
on public.member_burnout_alerts
for insert
to authenticated
with check (false);

create policy member_burnout_alerts_no_direct_update
on public.member_burnout_alerts
for update
to authenticated
using (false)
with check (false);

create policy member_burnout_alerts_no_direct_delete
on public.member_burnout_alerts
for delete
to authenticated
using (false);

grant select on public.member_workload_daily_snapshots to authenticated;
grant select on public.member_burnout_alerts to authenticated;


-- =========================================================
-- RPC: run_burnout_alert_check
-- Dipanggil cron harian.
-- Bisa juga dites manual dari SQL Editor.
-- =========================================================

drop function if exists public.run_burnout_alert_check(date, uuid);

create function public.run_burnout_alert_check(
  p_run_date date default null,
  p_organization_id uuid default null
)
returns table (
  organization_id uuid,
  member_id uuid,
  full_name text,
  alert_id uuid,
  streak_days integer,
  threshold_days integer,
  alert_status text,
  notification_created boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_run_date date;
  v_streak_days integer;
  v_first_red_date date;
  v_alert_id uuid;
  v_should_notify boolean;
  v_notification_created boolean;
  r record;
begin
  v_run_date := coalesce(
    p_run_date,
    (now() at time zone 'Asia/Jakarta')::date
  );

  if auth.uid() is not null and p_organization_id is not null then
    if not public.is_org_admin(p_organization_id) then
      raise exception using
        message = 'Hanya admin organisasi yang dapat menjalankan pengecekan burnout.',
        errcode = '42501';
    end if;
  end if;

  -- 1. Simpan snapshot workload hari ini.
  insert into public.member_workload_daily_snapshots (
    organization_id,
    member_id,
    profile_id,
    snapshot_date,
    weekly_capacity_hours,
    assigned_hours,
    active_task_count,
    load_ratio,
    load_percentage,
    workload_status,
    overload_threshold,
    burnout_alert_days,
    is_red_zone
  )
  select
    w.organization_id,
    w.member_id,
    w.profile_id,
    v_run_date,
    coalesce(w.weekly_capacity_hours, 0)::integer,
    coalesce(w.assigned_hours, 0)::integer,
    coalesce(w.active_task_count, 0)::integer,
    coalesce(w.load_ratio, 0)::numeric,
    coalesce(w.load_percentage, 0)::numeric,
    coalesce(w.workload_status, 'safe')::text,
    coalesce(ows.overload_threshold, 1.0000)::numeric,
    coalesce(ows.burnout_alert_days, 14)::integer,
    (
      coalesce(w.weekly_capacity_hours, 0) > 0
      and coalesce(w.load_ratio, 0) >= coalesce(ows.overload_threshold, 1.0000)
    ) as is_red_zone
  from public.v_member_workload w
  left join public.organization_workload_settings ows
    on ows.organization_id = w.organization_id
  where p_organization_id is null
     or w.organization_id = p_organization_id
  on conflict on constraint member_workload_daily_snapshots_unique
  do update
  set
    organization_id = excluded.organization_id,
    profile_id = excluded.profile_id,
    weekly_capacity_hours = excluded.weekly_capacity_hours,
    assigned_hours = excluded.assigned_hours,
    active_task_count = excluded.active_task_count,
    load_ratio = excluded.load_ratio,
    load_percentage = excluded.load_percentage,
    workload_status = excluded.workload_status,
    overload_threshold = excluded.overload_threshold,
    burnout_alert_days = excluded.burnout_alert_days,
    is_red_zone = excluded.is_red_zone,
    updated_at = now();

  -- 2. Hitung streak dan update alert.
  for r in
    select
      s.organization_id,
      s.member_id,
      s.profile_id,
      s.snapshot_date,
      s.weekly_capacity_hours,
      s.assigned_hours,
      s.load_ratio,
      s.load_percentage,
      s.workload_status,
      s.burnout_alert_days,
      s.is_red_zone,
      coalesce(p.full_name, 'Tanpa Nama') as full_name
    from public.member_workload_daily_snapshots s
    join public.members m
      on m.id = s.member_id
    left join public.profiles p
      on p.id = s.profile_id
    where s.snapshot_date = v_run_date
      and m.status = 'active'::public.member_status_enum
      and (
        p_organization_id is null
        or s.organization_id = p_organization_id
      )
  loop
    v_alert_id := null;
    v_streak_days := 0;
    v_first_red_date := null;
    v_should_notify := false;
    v_notification_created := false;

    if r.is_red_zone = false then
      update public.member_burnout_alerts ba
      set
        status = 'resolved',
        resolved_at = now(),
        last_red_date = v_run_date,
        streak_days = 0
      where ba.organization_id = r.organization_id
        and ba.member_id = r.member_id
        and ba.status in ('active', 'critical')
      returning ba.id into v_alert_id;

      if v_alert_id is not null then
        return query
        select
          r.organization_id,
          r.member_id,
          r.full_name::text,
          v_alert_id,
          0::integer,
          r.burnout_alert_days::integer,
          'resolved'::text,
          false;
      end if;

      continue;
    end if;

    select count(*)::integer
    into v_streak_days
    from (
      select
        s.snapshot_date,
        row_number() over (order by s.snapshot_date desc)::integer as rn
      from public.member_workload_daily_snapshots s
      where s.member_id = r.member_id
        and s.snapshot_date <= v_run_date
        and s.is_red_zone = true
      order by s.snapshot_date desc
    ) red_days
    where red_days.snapshot_date = v_run_date - (red_days.rn - 1);

    v_first_red_date := v_run_date - greatest(v_streak_days - 1, 0);

    if v_streak_days >= r.burnout_alert_days then
      update public.member_burnout_alerts ba
      set
        status = 'critical',
        first_red_date = v_first_red_date,
        last_red_date = v_run_date,
        streak_days = v_streak_days,
        threshold_days = r.burnout_alert_days,
        triggered_at = coalesce(ba.triggered_at, now())
      where ba.organization_id = r.organization_id
        and ba.member_id = r.member_id
        and ba.status in ('active', 'critical')
      returning ba.id,
        ba.last_notification_at is null
      into v_alert_id, v_should_notify;

      if v_alert_id is null then
        insert into public.member_burnout_alerts (
          organization_id,
          member_id,
          status,
          first_red_date,
          last_red_date,
          streak_days,
          threshold_days,
          triggered_at
        )
        values (
          r.organization_id,
          r.member_id,
          'critical',
          v_first_red_date,
          v_run_date,
          v_streak_days,
          r.burnout_alert_days,
          now()
        )
        returning id into v_alert_id;

        v_should_notify := true;
      end if;

      if v_should_notify then
        insert into public.notifications (
          recipient_member_id,
          actor_user_id,
          type,
          title,
          body,
          entity_type,
          entity_id
        )
        select distinct
          recipient.id,
          null::uuid,
          'system'::public.notification_type_enum,
          'Critical Burnout Alert',
          format(
            '%s berada di zona merah selama %s hari berturut-turut. Batas organisasi: %s hari.',
            r.full_name,
            v_streak_days,
            r.burnout_alert_days
          ),
          'burnout_alert',
          v_alert_id
        from public.members recipient
        where recipient.organization_id = r.organization_id
          and recipient.status = 'active'::public.member_status_enum
          and (
            recipient.id = r.member_id
            or recipient.role in (
              'owner'::public.member_role_enum,
              'admin'::public.member_role_enum
            )
            or lower(coalesce(recipient.position_code, '')) in (
              'ketua_divisi',
              'kadep',
              'kepala_departemen',
              'koordinator_divisi'
            )
          );

        update public.member_burnout_alerts ba
        set last_notification_at = now()
        where ba.id = v_alert_id;

        v_notification_created := true;
      end if;

      return query
      select
        r.organization_id,
        r.member_id,
        r.full_name::text,
        v_alert_id,
        v_streak_days,
        r.burnout_alert_days::integer,
        'critical'::text,
        v_notification_created;

    else
      update public.member_burnout_alerts ba
      set
        status = 'active',
        first_red_date = v_first_red_date,
        last_red_date = v_run_date,
        streak_days = v_streak_days,
        threshold_days = r.burnout_alert_days
      where ba.organization_id = r.organization_id
        and ba.member_id = r.member_id
        and ba.status in ('active', 'critical')
      returning ba.id into v_alert_id;

      if v_alert_id is null then
        insert into public.member_burnout_alerts (
          organization_id,
          member_id,
          status,
          first_red_date,
          last_red_date,
          streak_days,
          threshold_days
        )
        values (
          r.organization_id,
          r.member_id,
          'active',
          v_first_red_date,
          v_run_date,
          v_streak_days,
          r.burnout_alert_days
        )
        returning id into v_alert_id;
      end if;

      return query
      select
        r.organization_id,
        r.member_id,
        r.full_name::text,
        v_alert_id,
        v_streak_days,
        r.burnout_alert_days::integer,
        'active'::text,
        false;
    end if;
  end loop;
end;
$$;


-- =========================================================
-- RPC: get_critical_burnout_alerts
-- Untuk Flutter jika ingin menampilkan alert aktif di halaman Fairness.
-- =========================================================

drop function if exists public.get_critical_burnout_alerts(uuid);

create function public.get_critical_burnout_alerts(
  p_organization_id uuid
)
returns table (
  alert_id uuid,
  organization_id uuid,
  member_id uuid,
  full_name text,
  position_code text,
  division_code text,
  assigned_hours integer,
  weekly_capacity_hours integer,
  load_ratio numeric,
  load_percentage numeric,
  streak_days integer,
  threshold_days integer,
  first_red_date date,
  last_red_date date,
  triggered_at timestamptz,
  last_notification_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception using
      message = 'User belum login.',
      errcode = '28000';
  end if;

  if not public.is_org_admin(p_organization_id) then
    raise exception using
      message = 'Hanya admin organisasi yang dapat melihat Critical Burnout Alert.',
      errcode = '42501';
  end if;

  return query
  select
    ba.id as alert_id,
    ba.organization_id,
    ba.member_id,
    coalesce(p.full_name, 'Tanpa Nama')::text as full_name,
    m.position_code,
    m.division_code,
    coalesce(w.assigned_hours, 0)::integer as assigned_hours,
    coalesce(w.weekly_capacity_hours, 0)::integer as weekly_capacity_hours,
    coalesce(w.load_ratio, 0)::numeric as load_ratio,
    coalesce(w.load_percentage, 0)::numeric as load_percentage,
    ba.streak_days,
    ba.threshold_days,
    ba.first_red_date,
    ba.last_red_date,
    ba.triggered_at,
    ba.last_notification_at
  from public.member_burnout_alerts ba
  join public.members m
    on m.id = ba.member_id
  left join public.profiles p
    on p.id = m.profile_id
  left join public.v_member_workload w
    on w.member_id = ba.member_id
  where ba.organization_id = p_organization_id
    and ba.status = 'critical'
  order by
    ba.streak_days desc,
    ba.triggered_at desc;
end;
$$;

grant execute on function public.get_critical_burnout_alerts(uuid)
to authenticated;

commit;