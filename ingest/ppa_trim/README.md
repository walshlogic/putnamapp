# Putnam+Life — PPA TRIM Ingest

End-to-end pipeline for loading the Putnam County Property Appraiser's annual
TRIM (Truth in Millage) data into the `ppa` schema of the Putnam+Life Supabase
project.

## Layout

```
supabase_ppa_trim_schema.sql          <- repo root: DDL (schema/tables/indexes/RLS/view)
ingest/ppa_trim/
├── README.md                         <- this file
├── parse_trim.py                     <- stdlib-only parser: TRIM export → 6 CSVs
└── scripts/
    ├── ingest_trim.sh                <- one-shot driver (unzip → parse → load)
    └── upsert_trim.sql               <- staging + idempotent upsert into ppa.*
```

This repo does **not** use the Supabase CLI migration workflow (no
`supabase/config.toml`, no `supabase/migrations/` directory). DDL is applied
manually via the Supabase dashboard SQL editor or `psql`, following the
convention of the other `supabase_*_schema.sql` files at the repo root.

## 1 — Apply the schema

Open **[supabase_ppa_trim_schema.sql](../../supabase_ppa_trim_schema.sql)** in
your Supabase dashboard SQL editor and run it, or pipe it through `psql`:

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase_ppa_trim_schema.sql
```

## 2 — Expose `ppa` over PostgREST

Supabase's REST layer only serves schemas on the **Exposed schemas** list.
Go to **Supabase Dashboard → Project Settings → API → Exposed schemas** and
add `ppa` to the comma-separated list alongside `public`. Without this step,
`supabase.schema('ppa').from(...)` calls from the Flutter client will 404.

## 3 — Set the DB connection

Get the URI from **Supabase → Project Settings → Database → Connection string
→ URI**. Use the **session pooler (port 5432)** or a **direct connection** —
the transaction pooler on 6543 rejects the prepared statements `\copy` needs.

```bash
export SUPABASE_DB_URL='postgresql://postgres.<ref>:<PASSWORD>@aws-0-us-east-1.pooler.supabase.com:5432/postgres'
```

## 4 — Run the ingest

```bash
cd ingest/ppa_trim
./scripts/ingest_trim.sh /path/to/TRIM_Data_Package2025.zip
```

Expected runtime: ~2–3 min parse + ~3–5 min load over the pooler. Re-runs are
idempotent — parcels upsert on `(roll_year, parcel_number)`, child tables
wipe-and-reload for the affected roll years only. Older roll years remain
untouched for year-over-year comparisons.

Expected counts for the 2025 package (98,398 parcels):

```
parcels                ≈ 98,398
taxing_authorities     ≈ 601,037
exemptions             ≈ 53,793
assessment_reductions  ≈ 75,414
non_ad_valorem         ≈ 56,081
public_hearings        = 1
```

## 5 — Verify

```sql
select roll_year, count(*) from ppa.parcels group by 1;
select * from ppa.v_parcel_summary where owner_name ilike '%walsh%' limit 20;
```

Flutter-side sample (uses `lib/services/ppa_service.dart`):

```dart
final hits = await PpaService.instance.searchByAddress('hillsborough', limit: 25);
final detail = await PpaService.instance.getParcelDetail('13-08-24-0010-0000-0010');
```

## Notes / gotchas

- Source file is **latin-1** encoded, not UTF-8. The parser handles this — don't
  "fix" the encoding declaration.
- 278 rows in the 2025 source carry a trailing empty 183rd field. The parser
  tolerates `len(flds) >= 182`; don't tighten that check.
- Parcel numbers may carry a trailing `*` continuation marker
  (e.g. `13-08-24-0010-0000-0010*`). The parser strips it; the DB stores
  the un-suffixed form. Any external callers passing parcel numbers should do
  the same.
- RLS: `ppa.*` tables are readable by `anon` + `authenticated`. Writes only via
  `service_role` (which is what `SUPABASE_DB_URL` uses).
- Annual refresh: drop next year's zip in and re-run the script. A new
  `roll_year` produces a new set of rows; prior years remain queryable.
- Geometry, sales history, and building characteristics are **not** in TRIM.
  Pull the CAMA extract or join the county GIS parcel layer on `parcel_number`
  for maps.
