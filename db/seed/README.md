# db/seed/

CSV templates for bulk-importing data into Supabase.

## places_import_template.csv

Column layout for `public.places`. Three sample rows are included for reference;
their addresses and phone numbers (`555-XXXX`) are placeholders, not real
businesses. Replace with real data before any import.

### Columns
Matches `public.places` (see `db/schema/supabase_places_schema.sql`):

| Column | Type | Notes |
|---|---|---|
| name | text | required |
| category | text | required, one of: `restaurant`, `retail`, `faith`, `entertainment`, `lodging`, `services`, `health`, `business`, `outdoors` |
| subcategory | text | free-form (e.g. `fast-food`, `casual-dining`) |
| description | text | |
| address | text | |
| city | text | defaults to `Palatka` if blank |
| state | text | defaults to `FL` if blank |
| zip_code | text | |
| phone | text | |
| email | text | |
| website | text | |
| latitude | double | |
| longitude | double | |
| price_range | text | `$`, `$$`, `$$$`, or `$$$$` (NOT integer) |
| is_verified | boolean | true = officially verified place |
| is_active | boolean | true = visible in the app directory |

Auto-populated columns NOT included in this template (set by Postgres):
`id`, `view_count`, `created_at`, `updated_at`. Optional Dart-loaded columns
also omitted: `hours`, `logo_url`, `cover_photo_url`, `photo_urls`. Add these
later via SQL UPDATE or admin UI.

### Importing

Use the Supabase Dashboard CSV import UI (Table Editor → Import data from CSV)
or write a one-shot SQL `COPY ... FROM STDIN` via the Management API.
