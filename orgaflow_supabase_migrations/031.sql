begin;

-- =========================================================
-- OR-74: Fairness Score
-- =========================================================
-- Fairness dihitung dari sebaran load_ratio anggota aktif.
-- Dasar:
--   Load Ratio member = assigned_hours / weekly_capacity_hours
--   Rata-rata organisasi = avg(load_ratio)
--   Standar deviasi = stddev_pop(load_ratio)
--   Organization fairness score = max(0, 100 - stddev * 100)
--
-- Catatan:
-- - Jika stddev = 0, score = 100.
-- - Member dengan weekly_capacity_hours <= 0 tidak dimasukkan ke statistik
--   fairness karena load ratio-nya tidak valid sebagai pembanding.
-- - v_member_workload tetap menjadi sumber workload terkini.
-- =========================================================

-- =========================================================
-- 1. Tabel histori fairness organisasi.
--    fairness_scores existing tetap dipakai untuk histori per member.
-- =========================================================

create table if not exists public.organization_fairness_scores (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  score_date date not null default current_date,
  member_count integer not null default 0 check (member_count >= 0),
  no_capacity_count integer not null default 0 check (no_capacity_count >= 0),
  average_load_ratio numeric(8,4) not null default 0,
  stddev_load_ratio numeric(8,4) not null default 0,
  fairness_score numeric(5,2) not null default 0 check (fairness_score >= 0 and fairness_score <= 100),
  safe_count integer not null default 0 check (safe_count >= 0),
  warning_count integer not null default 0 check (warning_count >= 0),
  overload_count integer not null default 0 check (overload_count >= 0),
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organization_fairness_scores_unique unique (organization_id, score_date)
);

create index if not exists organization_fairness_scores_org_date_idx
  on public.organization_fairness_scores (organization_id, score_date desc);

drop trigger if exists trg_organization_fairness_scores_updated_at
on public.organization_fairness_scores;

create trigger trg_organization_fairness_scores_updated_at
before update on public.organization_fairness_scores
for each row
execute function public.set_updated_at();

alter table public.organization_fairness_scores enable row level security;

drop policy if exists "organization_fairness_scores_select_same_org"
on public.organization_fairness_scores;

drop policy if exists "organization_fairness_scores_insert_admin_only"
on public.organization_fairness_scores;

drop policy if exists "organization_fairness_scores_update_admin_only"
on public.organization_fairness_scores;

drop policy if exists "organization_fairness_scores_delete_admin_only"
on public.organization_fairness_scores;

create policy "organization_fairness_scores_select_same_org"
on public.organization_fairness_scores
for select
to authenticated
using (public.is_org_member(organization_id));

create policy "organization_fairness_scores_insert_admin_only"
on public.organization_fairness_scores
for insert
to authenticated
with check (public.is_org_admin(organization_id));

create policy "organization_fairness_scores_update_admin_only"
on public.organization_fairness_scores
for update
to authenticated
using (public.is_org_admin(organization_id))
with check (public.is_org_admin(organization_id));

create policy "organization_fairness_scores_delete_admin_only"
on public.organization_fairness_scores
for delete
to authenticated
using (public.is_org_admin(organization_id));

grant select, insert, update, delete
on public.organization_fairness_scores
to authenticated;

-- =========================================================
-- 2. RPC: ringkasan fairness organisasi secara live.
-- =========================================================

create or replace function public.get_organization_fairness_summary(
  p_organization_id uuid
)
returns table (
  organization_id uuid,
  member_count integer,
  eligible_member_count integer,
  no_capacity_count integer,
  average_load_ratio numeric,
  average_load_percentage numeric,
  stddev_load_ratio numeric,
  stddev_load_percentage numeric,
  fairness_score numeric,
  min_load_ratio numeric,
  max_load_ratio numeric,
  safe_count integer,
  warning_count integer,
  overload_count integer,
  generated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_org_member(p_organization_id) then
    raise exception
      using message = 'Anda tidak memiliki akses ke organisasi ini.',
            errcode = '42501';
  end if;

  return query
  with workload as (
    select
      w.member_id,
      w.load_ratio::numeric as load_ratio,
      w.workload_status,
      w.weekly_capacity_hours
    from public.v_member_workload w
    where w.organization_id = p_organization_id
  ),
  eligible as (
    select wl.*
    from workload wl
    where wl.weekly_capacity_hours > 0
  ),
  stats as (
    select
      count(*)::integer as eligible_count,
      coalesce(avg(e.load_ratio), 0)::numeric as avg_load,
      coalesce(stddev_pop(e.load_ratio), 0)::numeric as stddev_load,
      coalesce(min(e.load_ratio), 0)::numeric as min_load,
      coalesce(max(e.load_ratio), 0)::numeric as max_load
    from eligible e
  ),
  counts as (
    select
      count(*)::integer as member_count,
      count(*) filter (where wl.weekly_capacity_hours <= 0)::integer as no_capacity_count,
      count(*) filter (where wl.workload_status = 'safe')::integer as safe_count,
      count(*) filter (where wl.workload_status = 'warning')::integer as warning_count,
      count(*) filter (where wl.workload_status = 'overload')::integer as overload_count
    from workload wl
  )
  select
    p_organization_id as organization_id,
    coalesce(c.member_count, 0)::integer as member_count,
    coalesce(s.eligible_count, 0)::integer as eligible_member_count,
    coalesce(c.no_capacity_count, 0)::integer as no_capacity_count,
    round(coalesce(s.avg_load, 0), 4) as average_load_ratio,
    round(coalesce(s.avg_load, 0) * 100, 2) as average_load_percentage,
    round(coalesce(s.stddev_load, 0), 4) as stddev_load_ratio,
    round(coalesce(s.stddev_load, 0) * 100, 2) as stddev_load_percentage,
    case
      when coalesce(s.eligible_count, 0) = 0 then 0::numeric
      when coalesce(s.stddev_load, 0) = 0 then 100::numeric
      else round(greatest(0::numeric, 100::numeric - (coalesce(s.stddev_load, 0) * 100)), 2)
    end as fairness_score,
    round(coalesce(s.min_load, 0), 4) as min_load_ratio,
    round(coalesce(s.max_load, 0), 4) as max_load_ratio,
    coalesce(c.safe_count, 0)::integer as safe_count,
    coalesce(c.warning_count, 0)::integer as warning_count,
    coalesce(c.overload_count, 0)::integer as overload_count,
    now() as generated_at
  from stats s
  cross join counts c;
end;
$$;

grant execute on function public.get_organization_fairness_summary(uuid)
to authenticated;

-- =========================================================
-- 3. RPC: breakdown fairness per member secara live.
-- =========================================================

create or replace function public.get_member_fairness_breakdown(
  p_organization_id uuid
)
returns table (
  organization_id uuid,
  member_id uuid,
  profile_id uuid,
  full_name text,
  position_code text,
  division_code text,
  weekly_capacity_hours integer,
  assigned_hours integer,
  active_task_count integer,
  load_ratio numeric,
  load_percentage numeric,
  workload_status text,
  average_load_ratio numeric,
  deviation_ratio numeric,
  deviation_percentage numeric,
  individual_fairness_score numeric,
  organization_fairness_score numeric
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_org_member(p_organization_id) then
    raise exception
      using message = 'Anda tidak memiliki akses ke organisasi ini.',
            errcode = '42501';
  end if;

  return query
  with workload as (
    select
      w.member_id,
      w.organization_id,
      w.profile_id,
      w.full_name,
      w.position_code,
      w.division_code,
      w.weekly_capacity_hours,
      w.assigned_hours,
      w.active_task_count,
      w.load_ratio::numeric as load_ratio,
      w.load_percentage::numeric as load_percentage,
      w.workload_status
    from public.v_member_workload w
    where w.organization_id = p_organization_id
  ),
  eligible as (
    select wl.*
    from workload wl
    where wl.weekly_capacity_hours > 0
  ),
  stats as (
    select
      count(*)::integer as eligible_count,
      coalesce(avg(e.load_ratio), 0)::numeric as avg_load,
      coalesce(stddev_pop(e.load_ratio), 0)::numeric as stddev_load
    from eligible e
  ),
  org_score as (
    select
      s.avg_load,
      case
        when s.eligible_count = 0 then 0::numeric
        when s.stddev_load = 0 then 100::numeric
        else round(greatest(0::numeric, 100::numeric - (s.stddev_load * 100)), 2)
      end as org_fairness_score
    from stats s
  )
  select
    wl.organization_id,
    wl.member_id,
    wl.profile_id,
    wl.full_name,
    wl.position_code,
    wl.division_code,
    wl.weekly_capacity_hours,
    wl.assigned_hours,
    wl.active_task_count,
    round(wl.load_ratio, 4) as load_ratio,
    round(wl.load_percentage, 2) as load_percentage,
    wl.workload_status,
    round(os.avg_load, 4) as average_load_ratio,
    case
      when wl.weekly_capacity_hours <= 0 then 0::numeric
      else round(abs(wl.load_ratio - os.avg_load), 4)
    end as deviation_ratio,
    case
      when wl.weekly_capacity_hours <= 0 then 0::numeric
      else round(abs(wl.load_ratio - os.avg_load) * 100, 2)
    end as deviation_percentage,
    case
      when wl.weekly_capacity_hours <= 0 then 0::numeric
      else round(greatest(0::numeric, 100::numeric - (abs(wl.load_ratio - os.avg_load) * 100)), 2)
    end as individual_fairness_score,
    os.org_fairness_score as organization_fairness_score
  from workload wl
  cross join org_score os
  order by
    case when wl.weekly_capacity_hours <= 0 then 1 else 0 end,
    abs(wl.load_ratio - os.avg_load) desc,
    wl.full_name asc;
end;
$$;

grant execute on function public.get_member_fairness_breakdown(uuid)
to authenticated;

-- =========================================================
-- 4. RPC: simpan snapshot fairness ke histori.
--    Admin/owner bisa menjalankan ini setelah assignment/update task,
--    atau dari dashboard sebagai refresh snapshot.
-- =========================================================

create or replace function public.refresh_organization_fairness_scores(
  p_organization_id uuid,
  p_score_date date default current_date
)
returns table (
  organization_id uuid,
  score_date date,
  member_count integer,
  eligible_member_count integer,
  no_capacity_count integer,
  average_load_ratio numeric,
  stddev_load_ratio numeric,
  fairness_score numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_summary record;
begin
  if not public.is_org_admin(p_organization_id) then
    raise exception
      using message = 'Hanya admin organisasi yang dapat menyimpan snapshot fairness.',
            errcode = '42501';
  end if;

  select *
    into v_summary
  from public.get_organization_fairness_summary(p_organization_id)
  limit 1;

  insert into public.organization_fairness_scores (
    organization_id,
    score_date,
    member_count,
    no_capacity_count,
    average_load_ratio,
    stddev_load_ratio,
    fairness_score,
    safe_count,
    warning_count,
    overload_count,
    note
  )
  values (
    p_organization_id,
    coalesce(p_score_date, current_date),
    coalesce(v_summary.member_count, 0),
    coalesce(v_summary.no_capacity_count, 0),
    coalesce(v_summary.average_load_ratio, 0),
    coalesce(v_summary.stddev_load_ratio, 0),
    coalesce(v_summary.fairness_score, 0),
    coalesce(v_summary.safe_count, 0),
    coalesce(v_summary.warning_count, 0),
    coalesce(v_summary.overload_count, 0),
    format(
      'Average load %s%%, stddev %s%%',
      coalesce(v_summary.average_load_percentage, 0),
      coalesce(v_summary.stddev_load_percentage, 0)
    )
  )
  on conflict on constraint organization_fairness_scores_unique do update
  set
    member_count = excluded.member_count,
    no_capacity_count = excluded.no_capacity_count,
    average_load_ratio = excluded.average_load_ratio,
    stddev_load_ratio = excluded.stddev_load_ratio,
    fairness_score = excluded.fairness_score,
    safe_count = excluded.safe_count,
    warning_count = excluded.warning_count,
    overload_count = excluded.overload_count,
    note = excluded.note,
    updated_at = now();

  insert into public.fairness_scores (
    member_id,
    score_date,
    workload_hours,
    capacity_hours,
    fairness_score,
    note
  )
  select
    b.member_id,
    coalesce(p_score_date, current_date) as score_date,
    b.assigned_hours,
    b.weekly_capacity_hours,
    b.individual_fairness_score,
    format(
      'Load %s%%, avg org %s%%, deviation %s%%, org fairness %s%%',
      b.load_percentage,
      round(b.average_load_ratio * 100, 2),
      b.deviation_percentage,
      b.organization_fairness_score
    ) as note
  from public.get_member_fairness_breakdown(p_organization_id) b
  on conflict on constraint fairness_scores_unique do update
  set
    workload_hours = excluded.workload_hours,
    capacity_hours = excluded.capacity_hours,
    fairness_score = excluded.fairness_score,
    note = excluded.note;

  return query
  select
    p_organization_id as organization_id,
    coalesce(p_score_date, current_date) as score_date,
    coalesce(v_summary.member_count, 0)::integer as member_count,
    coalesce(v_summary.eligible_member_count, 0)::integer as eligible_member_count,
    coalesce(v_summary.no_capacity_count, 0)::integer as no_capacity_count,
    coalesce(v_summary.average_load_ratio, 0)::numeric as average_load_ratio,
    coalesce(v_summary.stddev_load_ratio, 0)::numeric as stddev_load_ratio,
    coalesce(v_summary.fairness_score, 0)::numeric as fairness_score;
end;
$$;

grant execute on function public.refresh_organization_fairness_scores(uuid, date)
to authenticated;

-- =========================================================
-- 5. View histori fairness organisasi untuk dashboard trend.
-- =========================================================

create or replace view public.v_organization_fairness_trend
with (security_invoker = true)
as
select
  ofs.organization_id,
  ofs.score_date,
  ofs.member_count,
  ofs.no_capacity_count,
  ofs.average_load_ratio,
  round(ofs.average_load_ratio * 100, 2) as average_load_percentage,
  ofs.stddev_load_ratio,
  round(ofs.stddev_load_ratio * 100, 2) as stddev_load_percentage,
  ofs.fairness_score,
  ofs.safe_count,
  ofs.warning_count,
  ofs.overload_count,
  ofs.note,
  ofs.created_at,
  ofs.updated_at
from public.organization_fairness_scores ofs;

grant select on public.v_organization_fairness_trend
to authenticated;

notify pgrst, 'reload schema';

commit;
select *
from public.refresh_organization_fairness_scores(
  'ORG_ID'::uuid,
  current_date
);