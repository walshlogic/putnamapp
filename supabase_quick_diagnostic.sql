-- ============================================================================
-- QUICK DIAGNOSTIC: Clerk of Court Tables
-- Run these queries first to diagnose the issue
-- ============================================================================

-- ============================================================================
-- 1. CHECK IF TABLES EXIST
-- ============================================================================
SELECT 
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
  AND table_name IN ('traffic_citations', 'criminal_back_history', 'recent_bookings_with_charges')
ORDER BY table_name;

-- ============================================================================
-- 2. ROW COUNTS (Critical Tables Only)
-- ============================================================================
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

-- ============================================================================
-- 3. RLS STATUS
-- ============================================================================
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN ('traffic_citations', 'criminal_back_history', 'recent_bookings_with_charges')
ORDER BY tablename;

-- ============================================================================
-- 4. RLS POLICIES (THIS IS LIKELY THE ISSUE!)
-- ============================================================================
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
-- 5. TABLE COLUMNS (Schema)
-- ============================================================================
-- Traffic Citations Columns
SELECT 
  'traffic_citations' as table_name,
  column_name,
  data_type,
  is_nullable,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'traffic_citations'
ORDER BY ordinal_position;

-- Criminal Back History Columns
SELECT 
  'criminal_back_history' as table_name,
  column_name,
  data_type,
  is_nullable,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'criminal_back_history'
ORDER BY ordinal_position;

-- ============================================================================
-- 6. DATE RANGES (Check if data exists in past year)
-- ============================================================================
-- Traffic Citations Date Analysis
SELECT 
  'traffic_citations' as table_name,
  MIN(citation_date) as earliest_date,
  MAX(citation_date) as latest_date,
  COUNT(*) as total_records,
  COUNT(*) FILTER (WHERE citation_date >= CURRENT_DATE - INTERVAL '1 year') as records_last_year,
  COUNT(*) FILTER (WHERE citation_date >= CURRENT_DATE - INTERVAL '5 years') as records_last_5_years
FROM traffic_citations;

-- Criminal Back History Date Analysis
SELECT 
  'criminal_back_history' as table_name,
  MIN(clerk_file_date) as earliest_date,
  MAX(clerk_file_date) as latest_date,
  COUNT(*) as total_records,
  COUNT(*) FILTER (WHERE clerk_file_date >= CURRENT_DATE - INTERVAL '1 year') as records_last_year,
  COUNT(*) FILTER (WHERE clerk_file_date >= CURRENT_DATE - INTERVAL '5 years') as records_last_5_years
FROM criminal_back_history;

-- ============================================================================
-- 7. TEST QUERIES (Simulate what the app does)
-- ============================================================================
-- Test Traffic Citations with 1 YEAR filter (default)
SELECT 
  COUNT(*) as count_with_1_year_filter
FROM traffic_citations
WHERE citation_date >= CURRENT_DATE - INTERVAL '365 days';

-- Test Criminal Back History with 1 YEAR filter (default)
SELECT 
  COUNT(*) as count_with_1_year_filter
FROM criminal_back_history
WHERE clerk_file_date >= CURRENT_DATE - INTERVAL '365 days';

-- Test Traffic Citations with ALL filter
SELECT 
  COUNT(*) as count_with_all_filter
FROM traffic_citations;

-- Test Criminal Back History with ALL filter
SELECT 
  COUNT(*) as count_with_all_filter
FROM criminal_back_history;

-- ============================================================================
-- 8. SAMPLE DATA (First 3 records)
-- ============================================================================
-- Sample Traffic Citations
SELECT *
FROM traffic_citations
ORDER BY citation_date DESC NULLS LAST
LIMIT 3;

-- Sample Criminal Back History
SELECT *
FROM criminal_back_history
ORDER BY clerk_file_date DESC NULLS LAST
LIMIT 3;

-- ============================================================================
-- END OF QUICK DIAGNOSTIC
-- ============================================================================
-- 
-- FOCUS ON SECTION 4 (RLS POLICIES) - This is most likely the issue!
-- If there are no SELECT policies for 'public' or 'anon' role,
-- that's why the app can't see the data!
-- 
-- ============================================================================
