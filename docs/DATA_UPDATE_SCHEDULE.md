# Data Update Schedule

Manual update tasks for Putnam+Life. Drop downloaded files in the matching
folder, then run the listed command. Scripts are idempotent — safe to re-run.

## Folder map

| Source | Drop folder |
|---|---|
| FDLE sex offender CSVs | `zFDLEUpdate/` |
| Clerk of Court ZIPs | `zClerkDataUpdate/` |

## Running automatically (no action needed)

- **Hourly (:54)** — PCSO jail log scrape → upserts bookings + charges, then
  recalculates Top 100 and Agency Stats. Runs on this MacBook via launchd when
  it's powered on and online. If the Mac is offline at :54, the job catches up
  on next boot/login via the state file.

---

## Monthly — FL Sex Offender Registry

Recommended: 1st of every month.

1. Visit <https://offender.fdle.state.fl.us/offender/sops/home.jsf>
2. Search: **County = Putnam**, **State = Florida** → Submit.
3. Download the results as CSV.
4. Save to `zFDLEUpdate/`.
5. Run:
   ```bash
   cd /Users/walshwill/Cowork/projects/putnamapp
   python3 zClerkDataUpdate/ingest_fl_sor_supabase.py zFDLEUpdate/*.csv
   ```
6. Confirm output: `X rows read, X upserted, 0 skipped`.
7. The script clears all prior rows before inserting, so the table always
   matches the current download. Archive or delete the CSV when done.

---

## Weekly — Clerk of Court weekly data

Recommended: every Monday.

1. Log in at <https://apps.putnam-fl.com/bocc/putsubs/main.php>
2. Download these files to `zClerkDataUpdate/`:
   - Traffic Citations — Weekly → `traffWK.zip`
   - Criminal Back History — Year → `criminal_YR.zip`
   - Official Records — Weekly → `oriweekly.zip`
3. Run:
   ```bash
   cd /Users/walshwill/Cowork/projects/putnamapp/zClerkDataUpdate
   python3 clerk_data_update_all.py
   python3 ingest_ori_records.py
   ```
4. Scripts auto-delete the ZIPs after successful import.

---

## Quarterly — Clerk of Court year-to-date data

Recommended: 1st of Jan / Apr / Jul / Oct.

1. Log in at Clerk portal.
2. Download to `zClerkDataUpdate/`:
   - Traffic Citations — Year → `traffYR.zip`
   - Official Records — Year → `oriyear.zip`
3. Run the same two scripts as the weekly task.

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
   cd /Users/walshwill/Cowork/projects/putnamapp/zClerkDataUpdate
   python3 clerk_data_update_all.py      # imports criminal history
   python3 ingest_ori_records.py         # imports ORI master — ~60 minutes
   ```

`orimaster.zip` expands to ~258 MB and contains ~3.5 million rows. Let the
import run to completion; it retries on Supabase statement timeouts.
