-- ============================================================================
-- TEST EXACT QUERIES THE APP RUNS
-- This simulates exactly what the Flutter app does
-- ============================================================================

-- ============================================================================
-- TEST 1: Traffic Citations with "1 YEAR" filter (default when screen opens)
-- ============================================================================
-- This is what happens when traffic_citations_screen.dart opens
-- Default filter: AppConfig.timeRangeThisYear = '1 YEAR'

-- Step 1: Calculate cutoff date (exactly as app does)
-- App code: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 365))
-- Then formats as: cutoff.toIso8601String().split('T')[0]

WITH cutoff_date AS (
  SELECT (CURRENT_DATE - INTERVAL '365 days')::date as cutoff
)
SELECT 
  'traffic_citations' as table_name,
  (SELECT cutoff FROM cutoff_date) as filter_cutoff_date,
  CURRENT_DATE as today,
  COUNT(*) as total_records,
  COUNT(*) FILTER (WHERE citation_date >= (SELECT cutoff FROM cutoff_date)) as records_matching_filter,
  COUNT(*) FILTER (WHERE citation_date IS NULL) as null_dates,
  MIN(citation_date) as earliest_date,
  MAX(citation_date) as latest_date
FROM traffic_citations;

-- Step 2: Actual query the app runs (with pagination)
SELECT 
  *
FROM traffic_citations
WHERE citation_date >= (CURRENT_DATE - INTERVAL '365 days')::date
ORDER BY citation_date DESC
LIMIT 50;  -- App uses pageSize = 50

-- ============================================================================
-- TEST 2: Criminal Back History with "1 YEAR" filter (default when screen opens)
-- ============================================================================
-- This is what happens when criminal_back_history_screen.dart opens
-- Default filter: AppConfig.timeRangeThisYear = '1 YEAR'

WITH cutoff_date AS (
  SELECT (CURRENT_DATE - INTERVAL '365 days')::date as cutoff
)
SELECT 
  'criminal_back_history' as table_name,
  (SELECT cutoff FROM cutoff_date) as filter_cutoff_date,
  CURRENT_DATE as today,
  COUNT(*) as total_records,
  COUNT(*) FILTER (WHERE clerk_file_date >= (SELECT cutoff FROM cutoff_date)) as records_matching_filter,
  COUNT(*) FILTER (WHERE clerk_file_date IS NULL) as null_dates,
  MIN(clerk_file_date) as earliest_date,
  MAX(clerk_file_date) as latest_date
FROM criminal_back_history;

-- Step 2: Actual query the app runs (with pagination)
SELECT 
  *
FROM criminal_back_history
WHERE clerk_file_date >= (CURRENT_DATE - INTERVAL '365 days')::date
ORDER BY clerk_file_date DESC
LIMIT 50;  -- App uses pageSize = 50

-- ============================================================================
-- TEST 3: Check RLS Policies (CRITICAL!)
-- ============================================================================
-- Even if permissions exist, RLS policies can block queries
SELECT 
  tablename,
  policyname,
  permissive,
  roles,
  cmd as command_type,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('traffic_citations', 'criminal_back_history')
ORDER BY tablename, policyname;

-- ============================================================================
-- TEST 4: Test as anonymous user (what the app uses)
-- ============================================================================
-- The app uses SupabaseService.client which connects as 'anon' role
-- Let's see if we can query as anon (you may need to run this in a different context)

-- Note: In Supabase SQL Editor, you're running as postgres role
-- But the app runs as 'anon' role. RLS policies might block 'anon' even if they allow 'postgres'

-- ============================================================================
-- DIAGNOSIS SUMMARY
-- ============================================================================
-- If TEST 1 or TEST 2 shows records_matching_filter = 0:
--   → Date filter is excluding all records (dates are too old or in wrong format)
--
-- If TEST 1 or TEST 2 shows records_matching_filter > 0 but app shows nothing:
--   → RLS policies are blocking the 'anon' role (most likely!)
--
-- If TEST 3 shows NO policies for traffic_citations or criminal_back_history:
--   → Need to create RLS policies (this is the fix!)
