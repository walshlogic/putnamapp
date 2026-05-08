# Job Scripts and Cron Summary

Index of automated jobs that keep this app's data fresh. For manual update
workflows (FDLE registry, Clerk weekly/yearly downloads), see
[DATA_UPDATE_SCHEDULE.md](DATA_UPDATE_SCHEDULE.md).

## Active scheduled jobs

### 1) PCSO Jail Log scrape
Source: live `jail.aspx` page → upserts `bookings`, `charges`, photos.
Runs from a **separate repo** at `/Users/walshwill/pcso-scraper/`, NOT from
this project. See `~/pcso-scraper/README.md` for that codebase.

- Mechanism: launchd agent `com.pcso.scrape.hourly`
- Schedule: hourly at :54 (with `RunAtLoad: true` for catch-up after reboot)
- Log: `~/pcso-scraper/logs/launchd.{out,err}.log`

The `scripts/import_pcso_bookings.py` and `scripts/backfill_pcso_bookings.py`
in *this* repo are kept for ad-hoc / historical-backfill use only — they are
not on a cron in this checkout.

### 2) News import
- Script: `scripts/import_news.py`
- Cron setup: `scripts/setup_hourly_news_cron.sh`
- Schedule: hourly at :03
- Log: `logs/news_import.log`

Run manually:
```bash
cd /Users/walshwill/Putnam+Life/App/putnamlife
.venv/bin/python3 scripts/import_news.py
```

Verify cron:
```bash
crontab -l | grep import_news.py
```

### 3) Clerk of Court — daily combined runner
- Script: `zClerkDataUpdate/clerk_data_update_all.py` (handles traffic + criminal in one pass)
- Cron setup: `scripts/setup_daily_cron.sh`
- Schedule: 3:30 AM daily
- Log: `logs/clerk_update.log`

Drop the Clerk ZIPs (`traffYR.zip`, `traffWK.zip`, `criminal_HS.zip`,
`criminal_YR.zip`) into `zClerkDataUpdate/` per
[DATA_UPDATE_SCHEDULE.md](DATA_UPDATE_SCHEDULE.md). The runner extracts
ZIPs found in that folder, upserts to Supabase, and auto-deletes processed
files. Safe to run with no files present (it logs "no files" and exits).

Run manually:
```bash
cd /Users/walshwill/Putnam+Life/App/putnamlife/zClerkDataUpdate
/Users/walshwill/Putnam+Life/App/putnamlife/.venv/bin/python3 clerk_data_update_all.py
```

### 4) Top 100 lists refresh
- Helper: `ingest/ppa_trim/scripts/mgmt_api_load.sh`
- SQL: `select public.calculate_top_100_lists();`
- Cron setup: `scripts/setup_daily_cron.sh` (installs both #3 and #4)
- Schedule: 4:00 AM daily (after the Clerk import)
- Log: `logs/top_100_refresh.log`

The Postgres function is `EXECUTE`-restricted to `service_role` only;
the helper script authenticates via the Supabase Personal Access Token
and runs against the `postgres` superuser.

## Not on cron in this repo

### Agency Stats
The hourly PCSO scraper (in `~/pcso-scraper/`) handles agency-stat
recomputation as part of its run. The `agency` column on `public.charges`
is populated inline by the scraper's parser. There is no separate
agency-stats cron in this repo.

### FL Sex Offender Registry (`fl_sor` table)
Updated manually each month — see the FDLE section in
[DATA_UPDATE_SCHEDULE.md](DATA_UPDATE_SCHEDULE.md). No cron.

## One-line "check all jobs"
```bash
crontab -l
launchctl list | grep -E "(pcso|com\.putnam)"
```
