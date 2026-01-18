-- ============================================================================
-- CRITICAL CHECKS: Dates and RLS Policies
-- ============================================================================

-- ============================================================================
-- CHECK 1: RLS POLICIES (MOST IMPORTANT!)
-- ============================================================================
-- If this returns NO ROWS for traffic_citations or criminal_back_history,
-- that's the problem! The app can't read the data.

SELECT 
  tablename,
  policyname,
  permissive,
  roles,
  cmd as command_type,
  qual as using_expression
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('traffic_citations', 'criminal_back_history', 'recent_bookings_with_charges')
ORDER BY tablename, policyname;

-- ============================================================================
-- CHECK 2: DATE ISSUE - Check if dates are in the future
-- ============================================================================
-- If clerk_file_date or citation_date are in the future, they won't show
-- with the "1 YEAR" filter (which looks for past 12 months)

SELECT 
  'criminal_back_history' as table_name,
  COUNT(*) as total_records,
  COUNT(*) FILTER (WHERE clerk_file_date > CURRENT_DATE) as future_dates,
  COUNT(*) FILTER (WHERE clerk_file_date >= CURRENT_DATE - INTERVAL '1 year') as in_past_year,
  COUNT(*) FILTER (WHERE clerk_file_date < CURRENT_DATE - INTERVAL '1 year') as older_than_year,
  MIN(clerk_file_date) as earliest_date,
  MAX(clerk_file_date) as latest_date,
  CURRENT_DATE as today
FROM criminal_back_history;

SELECT 
  'traffic_citations' as table_name,
  COUNT(*) as total_records,
  COUNT(*) FILTER (WHERE citation_date > CURRENT_DATE) as future_dates,
  COUNT(*) FILTER (WHERE citation_date >= CURRENT_DATE - INTERVAL '1 year') as in_past_year,
  COUNT(*) FILTER (WHERE citation_date < CURRENT_DATE - INTERVAL '1 year') as older_than_year,
  MIN(citation_date) as earliest_date,
  MAX(citation_date) as latest_date,
  CURRENT_DATE as today
FROM traffic_citations;

-- ============================================================================
-- CHECK 3: TEST THE EXACT QUERY THE APP RUNS
-- ============================================================================
-- This simulates what happens when the app opens with default "1 YEAR" filter

-- Criminal Back History with 1 YEAR filter (what app does on open)
SELECT 
  COUNT(*) as records_found,
  'criminal_back_history with 1 YEAR filter' as query_description
FROM criminal_back_history
WHERE clerk_file_date >= (CURRENT_DATE - INTERVAL '365 days');

-- Traffic Citations with 1 YEAR filter (what app does on open)
SELECT 
  COUNT(*) as records_found,
  'traffic_citations with 1 YEAR filter' as query_description
FROM traffic_citations
WHERE citation_date >= (CURRENT_DATE - INTERVAL '365 days');

-- ============================================================================
-- CHECK 4: RLS STATUS
-- ============================================================================
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN ('traffic_citations', 'criminal_back_history', 'recent_bookings_with_charges')
ORDER BY tablename;

-- ============================================================================
-- CHECK 5: PERMISSIONS
-- ============================================================================
SELECT 
  grantee,
  table_name,
  privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN ('traffic_citations', 'criminal_back_history', 'recent_bookings_with_charges')
ORDER BY table_name, grantee;
