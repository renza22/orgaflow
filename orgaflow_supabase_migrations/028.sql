begin;

-- =========================================================
-- OR-66: Enable realtime notifications
-- =========================================================
-- Tabel public.notifications sudah ada.
-- RLS select/update own sudah ada dari migration lama.
-- Query ini hanya memastikan notifications masuk ke publication realtime.
-- =========================================================

alter table public.notifications replica identity full;

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  )
  and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    execute 'alter publication supabase_realtime add table public.notifications';
  end if;
end $$;

notify pgrst, 'reload schema';

commit;