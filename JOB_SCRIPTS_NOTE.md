# Job Scripts and Cron Summary

## 1) Jail Log (PCSO bookings)
Purpose: Scrape PCSO jail log and upsert bookings/charges/photos.  
Script: `import_pcso_bookings.py`  
Cron setup: `setup_hourly_pcso_cron.sh`  
Schedule: Hourly at :05 (from `setup_hourly_pcso_cron.sh`)  
Log: `logs/pcso_bookings_import.log`

Run manually:
```
cd /Users/willwalsh/PutnamApp/App
python3 import_pcso_bookings.py
```

View history:
```
tail -f /Users/willwalsh/PutnamApp/App/logs/pcso_bookings_import.log
grep "$(date +%Y-%m-%d)" /Users/willwalsh/PutnamApp/App/logs/pcso_bookings_import.log
```

Verify cron:
```
crontab -l | grep import_pcso_bookings.py
```

---

## 2) Clerk of Court — Traffic Citations
Purpose: Download + UPSERT traffic citations.  
Script: `zClerkDataUpdate/daily_traffic_citations_update.py`  
Cron setup: `setup_daily_cron.sh`  
Schedule: Daily at 2:00 AM  
Log: `logs/traffic_citations_import.log`

Run manually:
```
cd /Users/willwalsh/PutnamApp/App
python3 zClerkDataUpdate/daily_traffic_citations_update.py
```

View history:
```
tail -f /Users/willwalsh/PutnamApp/App/logs/traffic_citations_import.log
grep "$(date +%Y-%m-%d)" /Users/willwalsh/PutnamApp/App/logs/traffic_citations_import.log
```

Verify cron:
```
crontab -l | grep daily_traffic_citations_update.py
```

---

## 3) Clerk of Court — Criminal Back History
Purpose: Download + UPSERT criminal back history.  
Script: `zClerkDataUpdate/daily_criminal_back_history_update.py`  
Cron setup: `setup_daily_cron.sh`  
Schedule: Daily at 3:00 AM  
Log: `logs/criminal_back_history_import.log`

Run manually:
```
cd /Users/willwalsh/PutnamApp/App
python3 zClerkDataUpdate/daily_criminal_back_history_update.py
```

View history:
```
tail -f /Users/willwalsh/PutnamApp/App/logs/criminal_back_history_import.log
grep "$(date +%Y-%m-%d)" /Users/willwalsh/PutnamApp/App/logs/criminal_back_history_import.log
```

Verify cron:
```
crontab -l | grep daily_criminal_back_history_update.py
```

---

## 4) Law & Order — Agency Stats
Purpose: Recalculate agency stats and store in Supabase.  
Script: `zAgencyStatsUpdate/calculate_agency_stats.py`  
Cron setup: `zAgencyStatsUpdate/setup_agency_stats_cron.sh`  
Schedule (from script): Hourly at minute 0 + @reboot catch-up  
Wrapper: `zAgencyStatsUpdate/run_agency_stats_if_needed.sh`  
Log: `logs/agency_stats_cron.log`

Run manually:
```
cd /Users/willwalsh/PutnamApp/App/zAgencyStatsUpdate
python3 calculate_agency_stats.py
```

View history:
```
tail -f /Users/willwalsh/PutnamApp/App/logs/agency_stats_cron.log
grep "$(date +%Y-%m-%d)" /Users/willwalsh/PutnamApp/App/logs/agency_stats_cron.log
```

Verify cron:
```
crontab -l | grep run_agency_stats_if_needed.sh
```

Note: `AGENCY_STATS_README.md` mentions 6 AM / 6 PM, but the current cron script
installs hourly. The script is the source of truth right now.

---

## 5) Law & Order — Offender Registry (Sex Offenders)
App table: `fl_sor` (from `lib/config/app_config.dart`)  
Cron/script status: No cron setup or import script found in this repo.

What this means:
- The app reads from Supabase table `fl_sor`.
- There is no scheduled job in this repo to update it.

---

## One-line "Check All Jobs"
```
crontab -l
```
