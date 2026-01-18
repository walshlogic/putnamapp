-- =====================================================
-- AGENCY STATS DATABASE DIAGNOSTIC
-- =====================================================
-- Run in Supabase SQL Editor. This will output:
-- - Table definitions (columns, types, defaults)
-- - Indexes and constraints
-- - RLS status and policies
-- - View definitions (if any)
-- - Recent data health checks
-- =====================================================

-- 1) Table existence and basic metadata
SELECT
  table_schema,
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('agency_stats', 'bookings', 'charges', 'recent_bookings_with_charges')
ORDER BY table_name;

-- 2) Column definitions (schema + data types)
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('agency_stats', 'bookings', 'charges', 'recent_bookings_with_charges')
ORDER BY table_name, ordinal_position;

-- 3) Indexes
SELECT
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('agency_stats', 'bookings', 'charges', 'recent_bookings_with_charges')
ORDER BY tablename, indexname;

-- 4) Constraints (PKs, FKs, uniques)
SELECT
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
LEFT JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
  AND tc.table_name IN ('agency_stats', 'bookings', 'charges', 'recent_bookings_with_charges')
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;

-- 5) RLS status
SELECT
  schemaname,
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('agency_stats', 'bookings', 'charges', 'recent_bookings_with_charges')
ORDER BY tablename;

-- 6) RLS policies
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
WHERE schemaname = 'public'
  AND tablename IN ('agency_stats', 'bookings', 'charges', 'recent_bookings_with_charges')
ORDER BY tablename, policyname;

-- 7) View definitions (if recent_bookings_with_charges is a view)
SELECT
  table_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name = 'recent_bookings_with_charges';

-- 8) Data health: latest stats per agency
SELECT
  agency_id,
  agency_name,
  total_bookings,
  total_charges,
  unique_persons,
  calculated_at
FROM public.agency_stats
WHERE (agency_id, calculated_at) IN (
  SELECT agency_id, MAX(calculated_at)
  FROM public.agency_stats
  GROUP BY agency_id
)
ORDER BY agency_id;

-- 9) Data health: bookings window
SELECT
  COUNT(*) AS total_bookings,
  MIN(booking_date) AS earliest_booking,
  MAX(booking_date) AS latest_booking
FROM public.recent_bookings_with_charges;

-- 10) Quick match check by agency (search term matches in charges JSONB)
WITH agency_searches AS (
  SELECT 'PUTNAM COUNTY SHERIFF' AS search_term, 'pcso' AS agency_id
  UNION ALL SELECT 'PALATKA POLICE DEPARTMENT', 'palatka_pd'
  UNION ALL SELECT 'INTERLACHEN POLICE DEPARTMENT', 'interlachen_pd'
  UNION ALL SELECT 'WELAKA POLICE DEPARTMENT', 'welaka_pd'
  UNION ALL SELECT 'SCHOOL DISTRICT POLICE', 'school_pd'
  UNION ALL SELECT 'FLORIDA HIGHWAY PATROL', 'fhp'
  UNION ALL SELECT 'FISH AND WILDLIFE', 'fwc'
)
SELECT
  a.agency_id,
  a.search_term,
  COUNT(DISTINCT b.booking_no) AS matching_bookings
FROM agency_searches a
LEFT JOIN public.recent_bookings_with_charges b ON EXISTS (
  SELECT 1
  FROM jsonb_array_elements(b.charges) AS charge
  WHERE UPPER(charge->>'case_number') LIKE '%' || UPPER(a.search_term) || '%'
     OR UPPER(charge->>'agency') LIKE '%' || UPPER(a.search_term) || '%'
)
WHERE b.booking_date >= (CURRENT_DATE - INTERVAL '5 years')
GROUP BY a.agency_id, a.search_term
ORDER BY a.agency_id;
