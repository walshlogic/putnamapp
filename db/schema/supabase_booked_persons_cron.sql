-- pg_cron schedule for refresh_booked_persons().
--
-- The function itself (CREATE OR REPLACE FUNCTION public.refresh_booked_persons)
-- lives in ~/pcso-scraper/sql/setup_auto_refresh_pg_cron.sql — it was created
-- there before this repo's db/schema/ existed and was never copied in. This
-- file is ONLY the schedule portion.
--
-- Recomputes birth-month/year windows in public.booked_persons by intersecting
-- age + booking_date across each person's bookings. Up to that point the
-- function was only being called at the end of each backfill run via
-- scripts/import_pcso_bookings.py — meaning the table went stale between
-- backfills (the hourly TS scraper at ~/pcso-scraper/ does not call it).
--
-- Runs at 4:45 AM after the existing two cron jobs:
--   4:00 AM   refresh-top-100-lists
--   4:30 AM   refresh-agency-stats
--   4:45 AM   refresh-booked-persons  <-- this one
--
-- Idempotent — drop any prior schedule, then re-add.

SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname = 'refresh-booked-persons';
SELECT cron.schedule(
  'refresh-booked-persons',
  '45 4 * * *',
  $$SELECT public.refresh_booked_persons();$$
);
