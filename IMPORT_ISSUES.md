# Import Issues Log

Running log of known issues encountered during data imports (PCSO jail log, PPA TRIM, Clerk of Court, etc.). Add new entries at the top. Mark as `RESOLVED` when closed.

## Open issues

### [OPEN] PCSO jail log — 3 dates in Feb 2025 return HTTP 500

- **First seen:** 2026-04-22 during 2025 backfill run
- **Affected dates:** 2025-02-08, 2025-02-12, 2025-02-14
- **Symptom:** when searching with **Both Current And Released** or **Released Only** (`TypeJailSearch=1` or `2`) for any of those specific `booking_date` values, PCSO's `jail.aspx` returns HTTP 500 Internal Server Error.
- **Root cause:** server-side bug at PCSO (confirmed via in-browser manual test on 2026-04-23 — identical `Sys.WebForms.PageRequestManagerServerErrorException`). The "released-inmates" code path crashes on those dates. Likely a corrupted row or join-breaking NULL in their DB.
- **What works:** `TypeJailSearch=0` (Current Only) returns 200 with 0 results, as expected (no one from Feb 2025 still in jail).
- **Scope of data loss:** ~30 bookings total (~3 days × avg 8–12 bookings/day) = 0.2% of historical data. Verified adjacent days (02-07, 02-09, 02-10, 02-11, 02-13, 02-15) all scrape cleanly.
- **Workaround:** none from our side.
- **Action:** accepted the loss per user decision 2026-04-23. Retry quarterly (PCSO may clean up their DB). If user emails PCSO records/IT with a screenshot, they may fix it faster.
- **How to retry once fixed:** the 3 dates are already marked `ok=false` in `public.scrape_runs`. Re-run `python3 backfill_pcso_bookings.py --start-date 2025-02-08 --end-date 2025-02-14` — resume skips the 4 successful days, re-attempts the 3 failed ones.

## Resolved issues

### [RESOLVED 2026-04-22] `assets/.env` pointed to a deleted Supabase project

- **Symptom:** `httpx.ConnectError: nodename nor servname provided, or not known` when any Python ingest tried to write to Supabase.
- **Root cause:** `assets/.env` in repo had `SUPABASE_URL=https://zvmsixumxifgznqirwwh.supabase.co` — this project had been canceled/deleted when the user spun up a fresh Supabase project (`uuhftgvyinrgzlhvudxf`). DNS returned NXDOMAIN on the dead hostname.
- **Fix:** during backfill runs, shell-export overrides read from `/Users/walshwill/pcso-scraper/.env` (which has current credentials):
  ```bash
  export SUPABASE_URL=$(grep '^SUPABASE_URL=' /Users/walshwill/pcso-scraper/.env | cut -d= -f2-)
  export SUPABASE_SERVICE_ROLE_KEY=$(grep '^SUPABASE_SERVICE_ROLE_KEY=' /Users/walshwill/pcso-scraper/.env | cut -d= -f2-)
  ```
- **Permanent fix applied 2026-04-23:** updated `assets/.env` in place with current project credentials (`SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` pulled from `/Users/walshwill/pcso-scraper/.env`; preserved `PCSO_BOOKINGS_TABLE`, `PCSO_CHARGES_TABLE`, `PCSO_PHOTOS_BUCKET`). Old stale file backed up as `assets/.env.stale-<timestamp>` in case anything broke. Verified via clean-subprocess connection test. `setup_hourly_pcso_cron.sh` was never installed in crontab, so the main-repo importer had no live cron to break in the first place — but running it manually now works.
- **`flutter_env.json` refreshed 2026-04-23:** pulled fresh `SUPABASE_URL` + anon key (legacy JWT, `role=anon`) via `mcp__supabase__get_project_url` + `mcp__supabase__get_publishable_keys`. Preserved `REVENUECAT_IOS_API_KEY`, `REVENUECAT_ANDROID_API_KEY`, `WEATHER_LAT`, `WEATHER_LON`. Old stale file backed up as `flutter_env.json.stale-<timestamp>`. `flutter run` in dev mode now works without needing `--dart-define`; TestFlight builds are unaffected (they override via `--dart-define` at build time regardless).
- **`assets/.env.save` deleted 2026-04-23** — was a stale duplicate of the old `.env`. The timestamped backup `assets/.env.stale-<timestamp>` is kept as the historical record.

### [RESOLVED 2026-04-23] `public.charges` missing `agency` column

- **Symptom:** `PGRST204 Could not find the 'agency' column of 'charges' in the schema cache` when the Python importer tried to write normalized agency names.
- **Root cause:** when the Supabase project was recreated, the migration at `zAgencyStatsUpdate/agency_stats_fix_charges_agency.sql` was never re-applied to the new project. That migration adds `agency text` to `public.charges` and recreates `recent_bookings_with_charges` view to expose it.
- **Fix applied:** executed `ALTER TABLE public.charges ADD COLUMN agency text` + recreated the view (preserving its current shape, just adding `'agency', c.agency` to the JSONB build). Also backfilled ~19K existing charges' agency values by regex on their `case_number` with PCS/PCSO/PPD/IPD/WPD/FHP/FWC normalization. Parser in `import_pcso_bookings.py` updated to extract+normalize agency at scrape time going forward.

### [RESOLVED 2026-04-23] ALL filter in Jail Log errors with `PGRST205 public.booking_stats not found`

- **Symptom:** tapping the ALL time filter in the app shows `Failed to load bookings: DatabaseException ... Could not find the table 'public.booking_stats' in the schema cache`. 24HRS / 1YR / 5YRS tabs worked fine.
- **Root cause:** the Dart `BookingRepository` queries `public.booking_stats` for pre-calculated counts when ALL is selected. The table existed in the old (deleted) Supabase project but was never created in the new one. Dart code has a fallback for empty result rows, but NOT for "table doesn't exist" — PostgREST raises before the fallback can trigger.
- **Fix applied:** created empty `public.booking_stats (stat_key text primary key, count integer default 0, updated_at timestamptz default now())` with RLS + public-read policy. App's existing fallback now kicks in cleanly — counts on-the-fly in ~2 sec instead of erroring.
- **Future optimization:** populate `booking_stats` rows for `total_all`, `in_jail_all`, `released_all` to make ALL filter instant instead of 2 sec on-the-fly count.

### [RESOLVED 2026-04-22] psql direct connection IPv6-only from user's home network

- **Symptom:** `psql: could not translate host name "db.<ref>.supabase.co"` during PPA TRIM ingest.
- **Root cause:** Supabase direct connection hostname (`db.<ref>.supabase.co`) is IPv6-only unless you have the $10/mo IPv4 add-on. User's home network couldn't reach it.
- **Fix applied:** pivoted to Supabase Management API via curl + Personal Access Token (same token MCP uses). Works around the need for psql altogether for one-shot schema + bulk-load operations. Helper script at `ingest/ppa_trim/scripts/mgmt_api_load.sh`.
- **Related failed path:** the session pooler on `aws-0-us-east-1.pooler.supabase.com:5432` also didn't work (`FATAL: Tenant or user not found`) — never figured out the exact right URL format. Management API path is proven; use it for future bulk operations until there's reason to fight pooler again.

---

## Template for new issues

```
### [OPEN|RESOLVED YYYY-MM-DD] Short issue title

- **First seen:** when, which job
- **Affected:** dates/records/scope
- **Symptom:** exact error or observed behavior
- **Root cause:** what's actually wrong, where
- **Scope of impact:** data volume, user-visible? critical?
- **Workaround:** if any
- **Action / Fix:** what was done or what's the plan
```
