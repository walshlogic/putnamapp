# PCSO Manual Run — How to Force the Booking Log Update

The hourly PCSO jail-log scrape runs automatically at minute `:54` of every
hour via `com.pcso.scrape.hourly` (launchd). It lives in a **separate
codebase at `~/pcso-scraper/`**, not in this repo. This doc covers how to
kick it off manually — useful after the laptop has been off for a while or
when you want fresh bookings right now instead of waiting for the next :54.

Related docs:
- [PCSO_JAIL_LOG_README.md](PCSO_JAIL_LOG_README.md) — automation overview
- [PCSO_BACKFILL_README.md](PCSO_BACKFILL_README.md) — historical year-by-year backfill
- [JOB_SCRIPTS_NOTE.md](JOB_SCRIPTS_NOTE.md) — index of all scheduled jobs

---

## Run it manually

```bash
~/pcso-scraper/run_hourly.sh
```

Same script launchd calls. It will:

- Wake the display + `caffeinate` the process so the Mac can't sleep mid-run
- Spin up Chromium (Playwright)
- Read `~/pcso-scraper/state/last_run_utc.txt` to decide which dates need catching up
- Iterate each missing calendar day with a 1-day overlap (avoids midnight gaps)
- Upsert bookings + charges + photos into Supabase

Runtime: 30 seconds for a single quiet day → several minutes when catching up multiple days.

---

## Monitor while it runs

```bash
tail -f ~/pcso-scraper/logs/launchd.out.log
```

Typical lines:

```
[+] Expansion finished after 6 loop(s). Found 80 booking cards (ResultsReturned=11).
```

Plus per-photo upload progress.

---

## Quick health checks

```bash
# Is the launchd agent loaded?
launchctl list | grep pcso.scrape

# When did the scraper last succeed?
cat ~/pcso-scraper/state/last_run_utc.txt

# Recent bookings in Supabase, sanity check (from the Putnam+Life repo):
psql "$SUPABASE_DIRECT_URL" \
  -c "SELECT booking_no, name, booking_date FROM bookings ORDER BY booking_date DESC LIMIT 5;"
# or just open the Jail Log in the app — newest entries should match the scraper run
```

---

## If something's stuck

```bash
# Force-kill any running scrape + leftover Chromium
pkill -f "scrape_pcso_jail"
pkill -f "chromium"

# Then re-run
~/pcso-scraper/run_hourly.sh
```

The state file makes the scraper idempotent — re-running won't duplicate
bookings (everything upserts by `booking_no`). If a single day's scrape
crashed mid-way, the state file won't advance past it, so the next run
retries the same date.

---

## When the laptop has been off for days

The catch-up loop iterates each missing calendar day one by one, with a
date filter on each request to PCSO's `jail.aspx`. Long catch-ups can take
10+ minutes. Symptoms of a healthy catch-up:

- Multiple `[+] Expansion finished after N loop(s)` lines, one per date
- Booking counts vary day-to-day (5–30 typical, 0 is fine for quiet days)
- `state/last_run_utc.txt` updates at the end of every successful run

If a specific date stalls or errors out repeatedly (PCSO occasionally
returns HTTP 500 for individual days — see
[IMPORT_ISSUES.md](IMPORT_ISSUES.md)), the script logs `ok=false` for
that date in `public.scrape_runs`. To retry just those days later, use the
historical backfill script (`scripts/backfill_pcso_bookings.py`) with the
specific date range — see [PCSO_BACKFILL_README.md](PCSO_BACKFILL_README.md).
