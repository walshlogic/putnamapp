# PCSO Jail Log Automation

This workflow downloads the Putnam County Sheriff's Office (PCSO) jail log,
parses booking data, syncs charges, and optionally syncs booking photos into
Supabase storage.

## Files

- `import_pcso_bookings.py`
  - Main importer (scrapes PCSO, upserts `bookings`, syncs `charges`, uploads photos).
- `setup_hourly_pcso_cron.sh`
  - Installs the hourly cron job.
- Logs
  - `logs/pcso_bookings_import.log`

## Environment variables

Required:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

Optional (defaults shown):
- `PCSO_JAIL_LOG_URL=https://smartweb.pcso.us/smartwebclient/jail.aspx`
- `PCSO_BOOKINGS_TABLE=bookings`
- `PCSO_CHARGES_TABLE=charges`
- `PCSO_SKIP_INCOMPLETE=true`
- `PCSO_SYNC_CHARGES=true`
- `PCSO_PHOTO_BASE_URL=https://smartweb.pcso.us/smartwebclient/ViewImage.aspx?bookno=`
- `PCSO_PHOTOS_BUCKET=pcso-booking-photos`
- `PCSO_SYNC_PHOTOS=true`

## Running manually

```
cd /Users/willwalsh/PutnamApp/App
python3 import_pcso_bookings.py
```

## Hourly cron job

Install/update the cron entry (runs hourly at :05):

```
bash /Users/willwalsh/PutnamApp/App/setup_hourly_pcso_cron.sh
```

Confirm:

```
crontab -l | grep import_pcso_bookings.py
```

## Cleanups (optional)

If the site publishes incomplete rows, you can remove them:

```
delete from public.bookings
where booking_date is null
   or name is null
   or name = '';
```

To refresh recent records:

```
delete from public.charges
where booking_no in (
  select booking_no from public.bookings
  where booking_date >= now() - interval '3 days'
);

delete from public.bookings
where booking_date >= now() - interval '3 days';
```

Then rerun the importer.

## Notes

- The app reads charges from `recent_bookings_with_charges`, which joins
  `bookings` with `charges`. If charges are missing, the list cards will be blank.
- Photos are pulled into `pcso-booking-photos` and `bookings.photo_url` is updated
  to point to the Supabase public URL.
