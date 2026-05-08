# Data Update Schedule

Manual update tasks for Putnam+Life. Drop downloaded files in the matching
folder, then run the listed command. Scripts are idempotent — safe to re-run.

## Folder map

| Source | Drop location |
|---|---|
| FDLE sex offender CSV | anywhere — pass path on command line (script clears + reinserts) |
| Clerk of Court ZIPs | `zClerkDataUpdate/` |

## Running automatically (no action needed)

- **Hourly (:54)** — PCSO jail log scrape (in separate `~/pcso-scraper/`
  repo) → upserts bookings + charges. Runs via launchd when the MacBook
  is powered on. If offline at :54, it catches up on next boot/login via
  the state file.
- **Hourly (:03)** — News import (`scripts/import_news.py`). Cron from
  this repo.
- **Daily 3:30 AM** — Clerk of Court combined runner
  (`zClerkDataUpdate/clerk_data_update_all.py`). Picks up any ZIPs you
  dropped in `zClerkDataUpdate/`, imports them, deletes them.
- **Daily 4:00 AM** — Top 100 list refresh (Postgres function via
  `ingest/ppa_trim/scripts/mgmt_api_load.sh`).

See [JOB_SCRIPTS_NOTE.md](JOB_SCRIPTS_NOTE.md) for the cron index.

---

## Monthly — FL Sex Offender Registry

Recommended: 1st of every month.

1. Visit <https://offender.fdle.state.fl.us/offender/sops/home.jsf>
2. Search: **County = Putnam**, **State = Florida** → Submit.
3. Download the results as CSV (lands in `~/Downloads/` by default).
4. Run from the repo root:
   ```bash
   cd /Users/walshwill/Putnam+Life/App/putnamlife
   .venv/bin/python3 zClerkDataUpdate/ingest_fl_sor_supabase.py ~/Downloads/PublicDataFile.csv
   ```
5. Confirm output: `X rows read, X upserted, 0 skipped`.
6. The script clears all prior rows before inserting, so the table always
   matches the current download. Archive or delete the CSV when done.

---

## Weekly — Clerk of Court weekly data

Recommended: every Monday.

1. Log in at <https://apps.putnam-fl.com/bocc/putsubs/main.php>
2. Download these files to `zClerkDataUpdate/`:
   - Traffic Citations — Weekly → `traffWK.zip`
   - Criminal Back History — Year → `criminal_YR.zip`
   - Official Records — Weekly → `oriweekly.zip`
3. Wait for the 3:30 AM cron to pick them up, **or** run manually:
   ```bash
   cd /Users/walshwill/Putnam+Life/App/putnamlife/zClerkDataUpdate
   /Users/walshwill/Putnam+Life/App/putnamlife/.venv/bin/python3 clerk_data_update_all.py
   /Users/walshwill/Putnam+Life/App/putnamlife/.venv/bin/python3 ingest_ori_records.py
   ```
4. Scripts auto-delete the ZIPs after successful import.

---

## Quarterly — Clerk of Court year-to-date data

Recommended: 1st of Jan / Apr / Jul / Oct.

1. Log in at Clerk portal.
2. Download to `zClerkDataUpdate/`:
   - Traffic Citations — Year → `traffYR.zip`
   - Official Records — Year → `oriyear.zip`
3. Run the same two scripts as the weekly task (or wait for the 3:30 AM cron).

Data grows, doesn't shrink. Running monthly is also fine — these imports are
idempotent.

---

## Yearly — Clerk of Court historical data

Recommended: each January after the Clerk republishes.

1. Log in at Clerk portal.
2. Download to `zClerkDataUpdate/`:
   - Criminal Back History — History → `criminal_HS.zip`
   - Official Records — History → `orimaster.zip`
3. Run:
   ```bash
   cd /Users/walshwill/Putnam+Life/App/putnamlife/zClerkDataUpdate
   /Users/walshwill/Putnam+Life/App/putnamlife/.venv/bin/python3 clerk_data_update_all.py      # imports criminal history
   /Users/walshwill/Putnam+Life/App/putnamlife/.venv/bin/python3 ingest_ori_records.py         # imports ORI master — ~60 minutes
   ```

`orimaster.zip` expands to ~258 MB and contains ~3.5 million rows. Let the
import run to completion; it retries on Supabase statement timeouts.
