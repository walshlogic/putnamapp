-- =====================================================
-- AGENCY STATS DIAGNOSTIC QUERIES
-- =====================================================
-- Run these queries in Supabase SQL Editor to diagnose
-- why agency stats are showing as '0'
-- =====================================================

-- 1. Check if agency_stats table exists and has any data
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT agency_id) as unique_agencies,
    MIN(calculated_at) as oldest_calculation,
    MAX(calculated_at) as latest_calculation
FROM public.agency_stats;

-- 2. Check latest stats for each agency
SELECT 
    agency_id,
    agency_name,
    total_bookings,
    total_charges,
    unique_persons,
    average_charges_per_booking,
    calculated_at
FROM public.agency_stats
WHERE (agency_id, calculated_at) IN (
    SELECT agency_id, MAX(calculated_at)
    FROM public.agency_stats
    GROUP BY agency_id
)
ORDER BY agency_id;

-- 3. Check all records (to see if there are multiple calculations)
SELECT 
    agency_id,
    agency_name,
    total_bookings,
    total_charges,
    calculated_at
FROM public.agency_stats
ORDER BY agency_id, calculated_at DESC;

-- 4. Check if source table (recent_bookings_with_charges) has data
SELECT 
    COUNT(*) as total_bookings,
    MIN(booking_date) as earliest_booking,
    MAX(booking_date) as latest_booking
FROM public.recent_bookings_with_charges;

-- 5. Check sample bookings to verify data structure
SELECT 
    booking_date,
    name,
    gender,
    race,
    charges
FROM public.recent_bookings_with_charges
ORDER BY booking_date DESC
LIMIT 5;

-- 6. Check if any bookings match agency search terms
-- (This helps verify the Python script logic)
SELECT 
    COUNT(*) as matching_bookings,
    'PUTNAM COUNTY SHERIFF' as search_term
FROM public.recent_bookings_with_charges
WHERE EXISTS (
    SELECT 1 
    FROM jsonb_array_elements(charges) AS charge
    WHERE UPPER(charge->>'case_number') LIKE '%PUTNAM COUNTY SHERIFF%'
)
UNION ALL
SELECT 
    COUNT(*) as matching_bookings,
    'PALATKA POLICE DEPARTMENT' as search_term
FROM public.recent_bookings_with_charges
WHERE EXISTS (
    SELECT 1 
    FROM jsonb_array_elements(charges) AS charge
    WHERE UPPER(charge->>'case_number') LIKE '%PALATKA POLICE DEPARTMENT%'
);

-- 7. Check RLS policies on agency_stats table
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
WHERE tablename = 'agency_stats';

-- 8. Verify table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'agency_stats'
ORDER BY ordinal_position;

-- 9. Check for any recent insert errors (if you have error logging)
-- This query checks the last 24 hours of calculations
SELECT 
    agency_id,
    agency_name,
    total_bookings,
    total_charges,
    calculated_at,
    CASE 
        WHEN total_bookings = 0 AND total_charges = 0 THEN 'EMPTY DATA'
        ELSE 'HAS DATA'
    END as status
FROM public.agency_stats
WHERE calculated_at >= NOW() - INTERVAL '24 hours'
ORDER BY calculated_at DESC;

-- 10. Count records per agency (to see if all agencies have data)
SELECT 
    agency_id,
    COUNT(*) as calculation_count,
    MAX(calculated_at) as latest_calculation,
    MAX(total_bookings) as max_bookings,
    MAX(total_charges) as max_charges
FROM public.agency_stats
GROUP BY agency_id
ORDER BY agency_id;

