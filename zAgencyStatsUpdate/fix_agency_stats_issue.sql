-- =====================================================
-- FIX AGENCY STATS ISSUE
-- =====================================================
-- This script helps identify and fix common issues
-- with agency stats showing as '0'
-- =====================================================

-- STEP 1: Check current state
-- Run this first to see what's in the table
SELECT 
    'Current State' as check_type,
    agency_id,
    agency_name,
    total_bookings,
    total_charges,
    calculated_at
FROM public.agency_stats
WHERE (agency_id, calculated_at) IN (
    SELECT agency_id, MAX(calculated_at)
    FROM public.agency_stats
    GROUP BY agency_id
)
ORDER BY agency_id;

-- STEP 2: If table is empty or has no recent data, you need to run the Python script
-- The script should be run with:
-- python3 calculate_agency_stats.py
-- 
-- Make sure assets/.env has:
-- SUPABASE_URL=your_url
-- SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

-- STEP 3: Verify RLS policies allow reading
-- Check if the SELECT policy exists and is correct
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'agency_stats';

-- If no SELECT policy exists, create it:
-- CREATE POLICY "Anyone can read agency stats"
-- ON public.agency_stats
-- FOR SELECT
-- TO public
-- USING (true);

-- STEP 4: Check if there's a data mismatch
-- Verify agency_ids match between Python script and Dart code
-- Python script uses: pcso, palatka_pd, interlachen_pd, welaka_pd, school_pd, fhp, fwc
-- Dart code expects the same IDs

SELECT 
    'Expected Agencies' as check_type,
    'pcso' as agency_id,
    'PUTNAM COUNTY SHERIFF''S OFFICE' as expected_name
UNION ALL
SELECT 'Expected Agencies', 'palatka_pd', 'PALATKA POLICE DEPARTMENT'
UNION ALL
SELECT 'Expected Agencies', 'interlachen_pd', 'INTERLACHEN POLICE DEPARTMENT'
UNION ALL
SELECT 'Expected Agencies', 'welaka_pd', 'WELAKA POLICE DEPARTMENT'
UNION ALL
SELECT 'Expected Agencies', 'school_pd', 'PUTNAM COUNTY SCHOOL DISTRICT POLICE DEPARTMENT'
UNION ALL
SELECT 'Expected Agencies', 'fhp', 'FLORIDA HIGHWAY PATROL'
UNION ALL
SELECT 'Expected Agencies', 'fwc', 'FLORIDA FISH AND WILDLIFE CONSERVATION COMMISSION (FWC)';

-- STEP 5: If you need to manually test the calculation
-- This shows how many bookings would match each agency search term
WITH agency_searches AS (
    SELECT 'PUTNAM COUNTY SHERIFF' as search_term, 'pcso' as agency_id
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
    COUNT(DISTINCT b.booking_no) as matching_bookings
FROM agency_searches a
LEFT JOIN public.recent_bookings_with_charges b ON EXISTS (
    SELECT 1 
    FROM jsonb_array_elements(b.charges) AS charge
    WHERE UPPER(charge->>'case_number') LIKE '%' || UPPER(a.search_term) || '%'
)
WHERE b.booking_date >= (CURRENT_DATE - INTERVAL '5 years')
GROUP BY a.agency_id, a.search_term
ORDER BY a.agency_id;

-- STEP 6: Clean up old calculations (optional)
-- If you have multiple old calculations and want to keep only the latest:
-- DELETE FROM public.agency_stats
-- WHERE (agency_id, calculated_at) NOT IN (
--     SELECT agency_id, MAX(calculated_at)
--     FROM public.agency_stats
--     GROUP BY agency_id
-- );

