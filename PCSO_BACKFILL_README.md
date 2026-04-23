# PCSO Jail Log Backfill

Companion to the hourly live-page importer ([PCSO_JAIL_LOG_README.md](PCSO_JAIL_LOG_README.md)). This script fills historical bookings the hourly importer cannot see because the live `jail.aspx` page only surfaces the most recent records.

## Purpose

- Fill historical gaps in `public.bookings` and `public.charges` going back as far as PCSO serves data (target: 1980s–present).
- Capture each booking's photo into `pcso-booking-photos` storage during the same pass.
- Populate `charges.agency` (e.g., PUTNAM COUNTY SHERIFF, PALATKA POLICE DEPARTMENT) with a normalized canonical name so `agency_stats` aggregations are accurate.
- Be resumable across interruptions and safe to re-run (idempotent).

## Design

### Why a new script (not the hourly importer)

The hourly `import_pcso_bookings.py` fetches `jail.aspx` with no query parameters — PCSO's site returns only the most recent ~20 bookings. There is no way to widen that window without submitting the search form. The backfill script submits the form with `TypeJailSearch=2` ("Both Current And Released") and a specific date range, then paginates the result set.

### Chunking strategy: one day at a time

Early observation: a single query for a full year returned ~460 records when the actual count should be ~2,500. The PCSO site imposes an effective cap on how many records a single filtered result set can return. **Day-by-day chunking avoids the cap entirely** — a single day rarely exceeds a dozen bookings, so no pagination risk.

### The "Both Current And Released" rule

The "Search For" dropdown has three values:
- `0` Current Inmates Only
- `1` Released Inmates Only
- `2` Both Current And Released ← **always use this**

Using `0` (default) silently drops anyone already released — which, for historical dates, is nearly everyone. We always send `TypeJailSearch: 2`.

### Why the ASP.NET form dance (not just AddMoreResults)

The `jail.aspx/AddMoreResults` endpoint is a JSON page-method used for pagination within an **already-filtered** result set. It does **not** accept a date filter as the primary query — that filter is applied by the initial form POST which sets up the session's filtered result set. So the flow is:

1. `GET /smartwebclient/jail.aspx` → capture `__VIEWSTATE`, `__VIEWSTATEGENERATOR`, `__EVENTVALIDATION`, session cookies.
2. `POST /smartwebclient/jail.aspx` with all those fields + `tbBeginDate`, `tbEndDate`, `TypeSearch=2`, `btnSumit=Submit` → server runs the search and renders the first page of matches.
3. `POST /smartwebclient/Jail.aspx/AddMoreResults` with incrementing `RecordsLoaded` offset → paginate within the filtered set until the server returns `resultsAttempted > resultsReturned` (end of matches) or returns zero.

### Agency: extraction and normalization

The PCSO jail log stores agency inline with case number: e.g., `"250646CF (PUTNAM COUNTY SHERIFF)"` or `"00 (PPD)"`. One charge = exactly one agency; one booking can have multiple agencies across its charges.

The parser:
1. Keeps `case_number` **exactly as PCSO returns it** (the app's booking-detail UI displays this string verbatim — changing the format would break the UI).
2. Extracts the parenthetical as raw agency text.
3. Normalizes to a canonical name:
   - `PCS`, `PCSO` → `PUTNAM COUNTY SHERIFF`
   - `PPD` → `PALATKA POLICE DEPARTMENT`
   - `IPD` → `INTERLACHEN POLICE DEPARTMENT`
   - `WPD` → `WELAKA POLICE DEPARTMENT`
   - `FHP` → `FLORIDA HIGHWAY PATROL`
   - `FWC` → `FISH AND WILDLIFE`
   - Substring matches for already-spelled-out forms (e.g., "PUTNAM COUNTY SHERIFF OFFICE" → `PUTNAM COUNTY SHERIFF`)
   - Unrecognized values are kept as-is (trimmed, original casing) so nothing is lost.
4. Writes the normalized value to `public.charges.agency` (added column — additive schema change, preserves all existing columns).

The app's "first charge's agency" convention is preserved by the view `recent_bookings_with_charges` which aggregates charges as a JSONB array ordered by `charge_order`, so `charges[0].agency` is always the booking's primary agency.

### Resume capability

Every successful day-chunk writes a row to `public.scrape_runs` with `ok=true`, `begin_date`, `end_date`. On every run, the script queries `scrape_runs` for successful rows in the requested date window and skips those days. A crash mid-run leaves no `scrape_runs` row for that day, so rerunning the same command picks up exactly where it left off.

### Hourly cron management

The script auto-disables the launchd job `com.pcso.scrape.hourly` at startup (`launchctl unload`) and re-enables it on exit via a `try/finally` block. A SIGINT/SIGTERM signal handler also triggers the re-enable. If the process dies unrecoverably (SIGKILL, power loss), launchd's `RunAtLoad: true` re-enables the job at next login automatically, and the script writes `/tmp/pcso_restore_cron.sh` as a manual-restore helper. Override with `--no-cron-toggle` to leave cron running during the backfill.

### Photos inline

Photos are synced to the `pcso-booking-photos` Supabase storage bucket **during the same pass** as the data (reusing `import_pcso_bookings._sync_photos`). This makes each booking atomically complete: if the script is interrupted, every booking successfully written has its photo too. Disable with `--no-photos` if photos are being fetched separately.

## Usage

### Environment

Requires the same env vars as the hourly importer:

```bash
export SUPABASE_URL=https://<new-project-ref>.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

The project has had credential churn; if `assets/.env` is stale, either update it or override via shell export. The script imports configuration from `import_pcso_bookings.py`, so it honors `PCSO_BOOKINGS_TABLE`, `PCSO_CHARGES_TABLE`, `PCSO_PHOTOS_BUCKET`, etc.

### Common invocations

```bash
# One day — dry run, no writes
python3 backfill_pcso_bookings.py --start-date 2025-06-15 --end-date 2025-06-15 --dry-run

# One year, day-by-day, photos inline (default)
python3 backfill_pcso_bookings.py --start-date 2025-01-01 --end-date 2025-12-31

# Re-run the same range — completed days are skipped via scrape_runs resume
python3 backfill_pcso_bookings.py --start-date 2025-01-01 --end-date 2025-12-31

# Data only, skip photo fetch (do a photo-only pass later)
python3 backfill_pcso_bookings.py --start-date 2024-01-01 --end-date 2024-12-31 --no-photos

# Leave the hourly cron running (e.g., if you're running in parallel)
python3 backfill_pcso_bookings.py --start-date 2024-01-01 --end-date 2024-12-31 --no-cron-toggle
```

### Year-by-year intended cadence

Run one year, verify counts in the dashboard / app, then run the next year. There is no hurry — spacing runs out avoids looking like an automated bot to PCSO's server.

```bash
# After 2025 completes:
python3 backfill_pcso_bookings.py --start-date 2024-01-01 --end-date 2024-12-31
# Then 2023, 2022, 2021, 2020, 2019, …
```

## Recovery scenarios

| What happened | What to do |
|---|---|
| Process finished normally | Done. Check counts in Supabase dashboard. Cron re-enabled automatically. |
| Ctrl+C'd / kill | Cron auto-re-enabled via signal handler. Re-run same command to resume. |
| Uncaught Python exception | `try/finally` re-enabled cron. Re-run same command; it'll skip completed days and retry the failed one. |
| SIGKILL / OOM / power loss | Cron does NOT re-enable automatically. Fix manually: `bash /tmp/pcso_restore_cron.sh`. Or just log back in — `RunAtLoad: true` in the plist handles it. Re-run the backfill. |
| Network flake mid-chunk | Chunk logged as failed (`ok=false` in `scrape_runs`). Re-run same command — failed day isn't considered "completed" so it'll be retried. |

## Related files

- [import_pcso_bookings.py](import_pcso_bookings.py) — hourly live-page importer. Backfill imports its parser/upsert/photo functions to stay DRY.
- [PCSO_JAIL_LOG_README.md](PCSO_JAIL_LOG_README.md) — hourly importer docs.
- [zAgencyStatsUpdate/agency_stats_fix_charges_agency.sql](zAgencyStatsUpdate/agency_stats_fix_charges_agency.sql) — original one-shot SQL that inspired the agency normalization logic now baked into the Python parser.
