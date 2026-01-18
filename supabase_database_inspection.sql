-- ============================================================================
-- SUPABASE DATABASE INSPECTION QUERIES
-- Run these queries in Supabase SQL Editor to diagnose Clerk of Court issues
-- ============================================================================

-- ============================================================================
-- 1. LIST ALL TABLES IN PUBLIC SCHEMA
-- ============================================================================
SELECT 
  table_schema,
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- ============================================================================
-- 2. DETAILED TABLE INFORMATION WITH ROW COUNTS
-- ============================================================================
SELECT 
  t.table_name,
  t.table_type,
  CASE 
    WHEN t.table_type = 'BASE TABLE' THEN 
      (SELECT COUNT(*) 
       FROM information_schema.columns c 
       WHERE c.table_name = t.table_name 
       AND c.table_schema = 'public')
    ELSE NULL
  END as column_count,
  CASE 
    WHEN t.table_type = 'BASE TABLE' THEN
      pg_size_pretty(pg_total_relation_size(quote_ident(t.table_schema)||'.'||quote_ident(t.table_name)))
    ELSE NULL
  END as table_size
FROM information_schema.tables t
WHERE t.table_schema = 'public'
ORDER BY t.table_name;

-- ============================================================================
-- 3. ALL COLUMNS FOR ALL TABLES (Detailed Schema)
-- ============================================================================
SELECT 
  t.table_name,
  c.column_name,
  c.data_type,
  c.character_maximum_length,
  c.is_nullable,
  c.column_default,
  c.ordinal_position
FROM information_schema.tables t
JOIN information_schema.columns c 
  ON t.table_name = c.table_name 
  AND t.table_schema = c.table_schema
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name, c.ordinal_position;

-- ============================================================================
-- 4. ROW COUNTS FOR ALL TABLES
-- ============================================================================
-- Run each query separately, or comment out tables that don't exist
-- Start with the critical Clerk of Court tables:

-- CRITICAL: Traffic Citations
SELECT 
  'traffic_citations' as table_name,
  COUNT(*) as row_count
FROM traffic_citations;

-- CRITICAL: Criminal Back History
SELECT 
  'criminal_back_history' as table_name,
  COUNT(*) as row_count
FROM criminal_back_history;

-- CRITICAL: Bookings (working reference)
SELECT 
  'recent_bookings_with_charges' as table_name,
  COUNT(*) as row_count
FROM recent_bookings_with_charges;

-- Other tables (comment out if they don't exist):
SELECT 
  'news_articles' as table_name,
  COUNT(*) as row_count
FROM news_articles;

SELECT 
  'agency_stats' as table_name,
  COUNT(*) as row_count
FROM agency_stats;

SELECT 
  'fl_sor' as table_name,
  COUNT(*) as row_count
FROM fl_sor;

SELECT 
  'booking_stats' as table_name,
  COUNT(*) as row_count
FROM booking_stats;

SELECT 
  'places' as table_name,
  COUNT(*) as row_count
FROM places;

SELECT 
  'place_reviews' as table_name,
  COUNT(*) as row_count
FROM place_reviews;

SELECT 
  'user_profiles' as table_name,
  COUNT(*) as row_count
FROM user_profiles;

SELECT 
  'top_100_lists' as table_name,
  COUNT(*) as row_count
FROM top_100_lists;

-- Uncomment if this table exists:
-- SELECT 
--   'government_places' as table_name,
--   COUNT(*) as row_count
-- FROM government_places;

-- ============================================================================
-- 5. RLS (Row Level Security) STATUS FOR ALL TABLES
-- ============================================================================
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================================================
-- 6. RLS POLICIES FOR ALL TABLES
-- ============================================================================
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd as command_type,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================================
-- 7. CLERK OF COURT TABLES: DETAILED COLUMN INFO
-- ============================================================================
-- Traffic Citations Table Structure
SELECT 
  'traffic_citations' as table_name,
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'traffic_citations'
ORDER BY ordinal_position;

-- Criminal Back History Table Structure
SELECT 
  'criminal_back_history' as table_name,
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'criminal_back_history'
ORDER BY ordinal_position;

-- ============================================================================
-- 8. DATE RANGES AND DATA DISTRIBUTION
-- ============================================================================
-- Traffic Citations Date Analysis
SELECT 
  'traffic_citations' as table_name,
  MIN(citation_date) as earliest_date,
  MAX(citation_date) as latest_date,
  COUNT(*) as total_records,
  COUNT(*) FILTER (WHERE citation_date >= CURRENT_DATE - INTERVAL '1 year') as records_last_year,
  COUNT(*) FILTER (WHERE citation_date >= CURRENT_DATE - INTERVAL '5 years') as records_last_5_years,
  COUNT(*) FILTER (WHERE citation_date IS NULL) as null_dates
FROM traffic_citations;

-- Criminal Back History Date Analysis
SELECT 
  'criminal_back_history' as table_name,
  MIN(clerk_file_date) as earliest_date,
  MAX(clerk_file_date) as latest_date,
  COUNT(*) as total_records,
  COUNT(*) FILTER (WHERE clerk_file_date >= CURRENT_DATE - INTERVAL '1 year') as records_last_year,
  COUNT(*) FILTER (WHERE clerk_file_date >= CURRENT_DATE - INTERVAL '5 years') as records_last_5_years,
  COUNT(*) FILTER (WHERE clerk_file_date IS NULL) as null_dates
FROM criminal_back_history;

-- ============================================================================
-- 9. SAMPLE DATA FROM CLERK OF COURT TABLES
-- ============================================================================
-- Sample Traffic Citations (first 5 records)
SELECT *
FROM traffic_citations
ORDER BY citation_date DESC NULLS LAST
LIMIT 5;

-- Sample Criminal Back History (first 5 records)
SELECT *
FROM criminal_back_history
ORDER BY clerk_file_date DESC NULLS LAST
LIMIT 5;

-- ============================================================================
-- 10. INDEXES ON CLERK OF COURT TABLES
-- ============================================================================
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('traffic_citations', 'criminal_back_history')
ORDER BY tablename, indexname;

-- ============================================================================
-- 11. FOREIGN KEYS AND CONSTRAINTS
-- ============================================================================
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('traffic_citations', 'criminal_back_history')
ORDER BY tc.table_name;

-- ============================================================================
-- 12. CHECK FOR VIEWS THAT MIGHT BE USED
-- ============================================================================
SELECT 
  table_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

-- ============================================================================
-- 13. FUNCTIONS AND TRIGGERS
-- ============================================================================
SELECT 
  routine_name,
  routine_type,
  data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- ============================================================================
-- 14. TEST QUERIES (Simulate what the app does)
-- ============================================================================
-- Test Traffic Citations Query (with 1 YEAR filter - default)
SELECT 
  COUNT(*) as count_with_1_year_filter,
  MIN(citation_date) as min_date,
  MAX(citation_date) as max_date
FROM traffic_citations
WHERE citation_date >= CURRENT_DATE - INTERVAL '365 days';

-- Test Criminal Back History Query (with 1 YEAR filter - default)
SELECT 
  COUNT(*) as count_with_1_year_filter,
  MIN(clerk_file_date) as min_date,
  MAX(clerk_file_date) as max_date
FROM criminal_back_history
WHERE clerk_file_date >= CURRENT_DATE - INTERVAL '365 days';

-- Test Traffic Citations Query (with ALL filter)
SELECT 
  COUNT(*) as count_with_all_filter
FROM traffic_citations;

-- Test Criminal Back History Query (with ALL filter)
SELECT 
  COUNT(*) as count_with_all_filter
FROM criminal_back_history;

-- ============================================================================
-- 15. PERMISSIONS CHECK (What roles can access tables)
-- ============================================================================
SELECT 
  grantee,
  table_schema,
  table_name,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN ('traffic_citations', 'criminal_back_history', 'recent_bookings_with_charges')
ORDER BY table_name, grantee, privilege_type;

-- ============================================================================
-- END OF INSPECTION QUERIES
-- ============================================================================
-- 
-- INSTRUCTIONS:
-- 1. Copy and paste each section into Supabase SQL Editor
-- 2. Run each query separately (or run all at once if supported)
-- 3. Copy the results and paste them here
-- 4. Focus especially on sections 1, 3, 5, 6, 7, 8, and 14
-- 
-- ============================================================================
