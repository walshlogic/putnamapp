# Diagnostic Guide: Clerk of Court Records Not Showing

## Data Source Confirmation

✅ **Data sources are Supabase tables, NOT temp folders:**
- Traffic Citations: `traffic_citations` table
- Criminal Back History: `criminal_back_history` table  
- Bookings: `recent_bookings_with_charges` table (✅ working)

## Code Review Summary

✅ **Code is correct:**
- Repositories query Supabase correctly
- Table names match: `traffic_citations` and `criminal_back_history`
- Providers are set up identically to bookings (which works)
- No references to temp folders or local files

## What to Check in Supabase

### 1. Verify Table Names Exist
Run these queries in Supabase SQL Editor:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('traffic_citations', 'criminal_back_history', 'recent_bookings_with_charges');
```

**Expected:** All 3 tables should exist

### 2. Check Table Row Counts
```sql
-- Count records in each table
SELECT 
  'traffic_citations' as table_name, 
  COUNT(*) as row_count 
FROM traffic_citations
UNION ALL
SELECT 
  'criminal_back_history' as table_name, 
  COUNT(*) as row_count 
FROM criminal_back_history
UNION ALL
SELECT 
  'recent_bookings_with_charges' as table_name, 
  COUNT(*) as row_count 
FROM recent_bookings_with_charges;
```

**Expected:** Tables should have data (bookings works, so that should have data)

### 3. Check RLS Policies
```sql
-- Check RLS status and policies
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('traffic_citations', 'criminal_back_history', 'recent_bookings_with_charges');

-- Check policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename IN ('traffic_citations', 'criminal_back_history', 'recent_bookings_with_charges');
```

**Expected:** 
- RLS should be enabled on all tables
- There should be SELECT policies allowing public/anonymous access (like bookings)

### 4. Test Direct Queries (as anonymous user)
```sql
-- Test if you can query the tables directly
SELECT COUNT(*) FROM traffic_citations LIMIT 1;
SELECT COUNT(*) FROM criminal_back_history LIMIT 1;
SELECT COUNT(*) FROM recent_bookings_with_charges LIMIT 1;
```

**Expected:** All should return counts without errors

### 5. Check for Date Filter Issues
The default filter is "1 YEAR" which filters by date. Check if there's data in the past year:

```sql
-- Check date ranges in tables
SELECT 
  'traffic_citations' as table_name,
  MIN(citation_date) as earliest_date,
  MAX(citation_date) as latest_date,
  COUNT(*) as total_count,
  COUNT(*) FILTER (WHERE citation_date >= CURRENT_DATE - INTERVAL '1 year') as last_year_count
FROM traffic_citations
UNION ALL
SELECT 
  'criminal_back_history' as table_name,
  MIN(clerk_file_date) as earliest_date,
  MAX(clerk_file_date) as latest_date,
  COUNT(*) as total_count,
  COUNT(*) FILTER (WHERE clerk_file_date >= CURRENT_DATE - INTERVAL '1 year') as last_year_count
FROM criminal_back_history;
```

**Issue Found?** If `last_year_count` is 0, that's why no data shows! The default filter is "1 YEAR".

## Most Likely Issues

### Issue 1: RLS Policies Missing or Too Restrictive
**Symptom:** Tables exist, have data, but queries return empty
**Fix:** Add RLS policies similar to bookings table:

```sql
-- For traffic_citations
CREATE POLICY "Public can read traffic citations" 
ON public.traffic_citations 
FOR SELECT 
TO public 
USING (true);

-- For criminal_back_history  
CREATE POLICY "Public can read criminal back history" 
ON public.criminal_back_history 
FOR SELECT 
TO public 
USING (true);
```

### Issue 2: No Data in Past Year
**Symptom:** Tables have data, but default "1 YEAR" filter shows nothing
**Fix:** 
- Try selecting "5 YEARS" or "ALL" filter in the app
- Or import more recent data

### Issue 3: Table Names Don't Match
**Symptom:** Tables exist but with different names
**Fix:** Check actual table names and update `AppConfig` if needed

## Quick Test in App

1. **Try "ALL" filter** - If data appears, it's a date filter issue
2. **Try "5 YEARS" filter** - If data appears, it's a date filter issue  
3. **Check app logs** - Look for error messages in debug console

## Next Steps

1. ✅ Check table names match
2. ✅ Check tables have data
3. ✅ Check RLS policies allow SELECT
4. ✅ Check date ranges of data
5. ✅ Test with "ALL" filter in app

Let me know what you find in Supabase!
