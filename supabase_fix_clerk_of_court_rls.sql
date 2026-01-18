-- ============================================================================
-- FIX CLERK OF COURT RLS POLICIES
-- Add missing policies for 'anon' role so the app can read the data
-- ============================================================================

-- ============================================================================
-- 1. ENABLE RLS (if not already enabled)
-- ============================================================================
ALTER TABLE traffic_citations ENABLE ROW LEVEL SECURITY;
ALTER TABLE criminal_back_history ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. CREATE POLICIES FOR ANON ROLE (Public Read Access)
-- ============================================================================

-- Traffic Citations: Allow anonymous users to read
CREATE POLICY "Allow anonymous users to read traffic citations"
ON public.traffic_citations
FOR SELECT
TO anon
USING (true);

-- Criminal Back History: Allow anonymous users to read
CREATE POLICY "Allow anonymous users to read criminal back history"
ON public.criminal_back_history
FOR SELECT
TO anon
USING (true);

-- ============================================================================
-- 3. VERIFY POLICIES WERE CREATED
-- ============================================================================
SELECT 
  tablename,
  policyname,
  permissive,
  roles,
  cmd as command_type
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('traffic_citations', 'criminal_back_history')
ORDER BY tablename, policyname;

-- ============================================================================
-- 4. TEST QUERIES AS ANON ROLE (Simulate what app does)
-- ============================================================================
-- Note: These queries run as 'postgres' role in SQL Editor,
-- but they verify the policies exist and should work for 'anon' role

-- Test Traffic Citations query (what app does)
SELECT 
  COUNT(*) as record_count,
  'traffic_citations with 1 YEAR filter' as test_description
FROM traffic_citations
WHERE citation_date >= (CURRENT_DATE - INTERVAL '365 days')::date;

-- Test Criminal Back History query (what app does)
SELECT 
  COUNT(*) as record_count,
  'criminal_back_history with 1 YEAR filter' as test_description
FROM criminal_back_history
WHERE clerk_file_date >= (CURRENT_DATE - INTERVAL '365 days')::date;

-- ============================================================================
-- DONE!
-- ============================================================================
-- After running this script:
-- 1. The app should now be able to read traffic citations and criminal back history
-- 2. Test the app - records should appear when screens open
-- 3. If still not working, check app logs for any error messages
-- ============================================================================
