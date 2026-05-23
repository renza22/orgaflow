-- Aktifkan extension pg_cron jika belum aktif.
create extension if not exists pg_cron;

-- Hapus job lama jika pernah dibuat.
select cron.unschedule(jobid)
from cron.job
where jobname = 'orgaflow-burnout-alert-daily';

-- Jalan setiap jam 00:00 WIB.
-- Cron Supabase biasanya memakai UTC, jadi 17:00 UTC = 00:00 WIB.
select cron.schedule(
  'orgaflow-burnout-alert-daily',
  '0 17 * * *',
  $$select public.run_burnout_alert_check();$$
);