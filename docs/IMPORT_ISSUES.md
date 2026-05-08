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
- **How to retry once fixed:** the 3 dates are already marked `ok=false` in `public.scrape_runs`. Re-run `python3 scripts/backfill_pcso_bookings.py --start-date 2025-02-08 --end-date 2025-02-14` — resume skips the 4 successful days, re-attempts the 3 failed ones.

## Resolved issues

### [RESOLVED 2026-04-22] `assets/.env` pointed to a deleted Supabase project

- **Symptom:** `httpx.ConnectError: nodename nor servname provided, or not known` when any Python ingest tried to write to Supabase.
- **Root cause:** `assets/.env` in repo had `SUPABASE_URL=https://zvmsixumxifgznqirwwh.supabase.co` — this project had been canceled/deleted when the user spun up a fresh Supabase project (`uuhftgvyinrgzlhvudxf`). DNS returned NXDOMAIN on the dead hostname.
- **Fix:** during backfill runs, shell-export overrides read from `/Users/walshwill/pcso-scraper/.env` (which has current credentials):
  ```bash
  export SUPABASE_URL=$(grep '^SUPABASE_URL=' /Users/walshwill/pcso-scraper/.env | cut -d= -f2-)
  export SUPABASE_SERVICE_ROLE_KEY=$(grep '^SUPABASE_SERVICE_ROLE_KEY=' /Users/walshwill/pcso-scraper/.env | cut -d= -f2-)
  ```
- **Permanent fix applied 2026-04-23:** updated `assets/.env` in place with current project credentials (`SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` pulled from `/Users/walshwill/pcso-scraper/.env`; preserved `PCSO_BOOKINGS_TABLE`, `PCSO_CHARGES_TABLE`, `PCSO_PHOTOS_BUCKET`). Old stale file backed up as `assets/.env.stale-<timestamp>` in case anything broke. Verified via clean-subprocess connection test. `scripts/setup_hourly_pcso_cron.sh` was never installed in crontab in this repo (the live PCSO scraper runs from `~/pcso-scraper/` via launchd) — but running this repo's importer manually now works.
- **`flutter_env.json` refreshed 2026-04-23:** pulled fresh `SUPABASE_URL` + anon key (legacy JWT, `role=anon`) via `mcp__supabase__get_project_url` + `mcp__supabase__get_publishable_keys`. Preserved `REVENUECAT_IOS_API_KEY`, `REVENUECAT_ANDROID_API_KEY`, `WEATHER_LAT`, `WEATHER_LON`. Old stale file backed up as `flutter_env.json.stale-<timestamp>`. `flutter run` in dev mode now works without needing `--dart-define`; TestFlight builds are unaffected (they override via `--dart-define` at build time regardless).
- **`assets/.env.save` deleted 2026-04-23** — was a stale duplicate of the old `.env`. The timestamped backup `assets/.env.stale-<timestamp>` is kept as the historical record.

### [RESOLVED 2026-04-23] `public.charges` missing `agency` column

- **Symptom:** `PGRST204 Could not find the 'agency' column of 'charges' in the schema cache` when the Python importer tried to write normalized agency names.
- **Root cause:** when the Supabase project was recreated, the migration that adds `agency text` to `public.charges` and rebuilds the `recent_bookings_with_charges` view was never re-applied to the new project. (The original SQL lived in the now-deleted `zAgencyStatsUpdate/` folder; logic is preserved in the parser instead.)
- **Fix applied:** executed `ALTER TABLE public.charges ADD COLUMN agency text` + recreated the view (preserving its current shape, just adding `'agency', c.agency` to the JSONB build). Also backfilled ~19K existing charges' agency values by regex on their `case_number` with PCS/PCSO/PPD/IPD/WPD/FHP/FWC normalization. Parser in `scripts/import_pcso_bookings.py` updated to extract+normalize agency at scrape time going forward.

### [RESOLVED 2026-04-23] ALL filter in Jail Log errors with `PGRST205 public.booking_stats not found`

- **Symptom:** tapping the ALL time filter in the app shows `Failed to load bookings: DatabaseException ... Could not find the table 'public.booking_stats' in the schema cache`. 24HRS / 1YR / 5YRS tabs worked fine.
- **Root cause:** the Dart `BookingRepository` queries `public.booking_stats` for pre-calculated counts when ALL is selected. The table existed in the old (deleted) Supabase project but was never created in the new one. Dart code has a fallback for empty result rows, but NOT for "table doesn't exist" — PostgREST raises before the fallback can trigger.
- **Fix applied:** created empty `public.booking_stats (stat_key text primary key, count integer default 0, updated_at timestamptz default now())` with RLS + public-read policy. App's existing fallback now kicks in cleanly — counts on-the-fly in ~2 sec instead of erroring.
- **Future optimization:** populate `booking_stats` rows for `total_all`, `in_jail_all`, `released_all` to make ALL filter instant instead of 2 sec on-the-fly count.

### [RESOLVED 2026-04-24] `flutter pub get` returns 403 on pub.dev advisories endpoint

- **Symptom:** `flutter pub get` (and any flutter command that calls it implicitly, like `flutter build ipa`) fails partway through with a "Failed to update packages" error and a noisy stack trace pointing into `HostedSource._fetchAdvisories`. Looking at `~/.pub-cache/log/pub_log.txt` shows `HTTP response 403 Forbidden for GET https://pub.dev/api/packages/<name>/advisories` for every package.
- **Root cause:** the office network blocks pub.dev's `/advisories` endpoint specifically. Other pub.dev endpoints (package metadata, tarballs) seem to be allowed; only the security-advisories API is being denied. Pub treats any 403 from advisories as fatal.
- **Workaround:** use `--offline` + `--no-pub` when on a network that blocks the endpoint. Local cache is at `~/.pub-cache/` and contains everything needed if pub get has succeeded once before:
  ```bash
  flutter pub get --offline
  flutter build ipa --release --no-pub --dart-define=...
  ```
- **Fix in build_testflight.sh:** the script now tries online pub get first, falls back to `--offline` if it fails, and passes `--no-pub` to `flutter build ipa` so the inner pub get doesn't re-trigger the failure.
- **Permanent fix (when on a non-blocking network):** `flutter pub get` once to refresh the lock file. No code change needed.

### [RESOLVED 2026-04-23] `flutter run --release` crashes with "Missing SUPABASE_URL or SUPABASE_ANON_KEY in --dart-define"

- **Symptom:** after merging Cowork's rebrand commit, running `flutter run --release -d <iphone>` without explicit `--dart-define` args loads the app to a red error screen: `App Initialization Error — Exception: Missing SUPABASE_URL or SUPABASE_ANON_KEY in --dart-define`.
- **Root cause:** Cowork's rebrand (commit `19ff2b3`) rewrote `lib/config/app_config.dart` to use `String.fromEnvironment('SUPABASE_URL')` etc. — **compile-time** env vars from `--dart-define`. Dropped the previous `flutter_env.json` runtime-load fallback. This matches how TestFlight builds work (the build command passes `--dart-define`), but `flutter run` does not auto-forward env from any source.
- **Fix / how to run release-debug on device:** pass all 6 vars on the command line, sourced from `flutter_env.json`:
  ```bash
  cd /Users/walshwill/Putnam+Life/App/putnamlife
  DEFINES=$(python3 -c "
  import json
  d = json.load(open('flutter_env.json'))
  for k in ('SUPABASE_URL','SUPABASE_ANON_KEY','REVENUECAT_IOS_API_KEY','REVENUECAT_ANDROID_API_KEY','WEATHER_LAT','WEATHER_LON'):
      if k in d: print(f'--dart-define={k}={d[k]}')
  ")
  flutter run --release -d <device-id> $DEFINES
  ```
  Same pattern for `flutter build ipa` when cutting TestFlight builds.

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
