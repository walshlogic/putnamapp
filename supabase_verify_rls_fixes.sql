-- ============================================================================
-- Verification Script for RLS Fixes
-- Run this to verify all security fixes were applied correctly
-- ============================================================================

-- ============================================================================
-- PART 1: Verify RLS is enabled on all tables
-- ============================================================================
SELECT 
    'RLS Status Check' as check_type,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Enabled'
        ELSE '❌ RLS Disabled'
    END as status
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename IN (
        'place_reviews',
        'places',
        'people',
        'fl_sor_geo',
        'tattoo_locations',
        'fl_sex_offender_registry',
        'person_tattoos',
        'fl_sor_ingest_raw',
        'booking_stats',
        'fl_sor',
        'holds',
        'user_profiles',
        'places_backup_20241112',
        'directory_categories',
        'community_places',
        'community_reviews'
    )
ORDER BY tablename;

-- ============================================================================
-- PART 2: Verify RLS policies exist for all tables
-- ============================================================================
SELECT 
    'Policy Count Check' as check_type,
    tablename,
    COUNT(*) as policy_count,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Has Policies'
        ELSE '❌ No Policies'
    END as status
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename IN (
        'place_reviews',
        'places',
        'people',
        'fl_sor_geo',
        'tattoo_locations',
        'fl_sex_offender_registry',
        'person_tattoos',
        'fl_sor_ingest_raw',
        'booking_stats',
        'fl_sor',
        'holds',
        'user_profiles',
        'places_backup_20241112',
        'directory_categories',
        'community_places',
        'community_reviews'
    )
GROUP BY tablename
ORDER BY tablename;

-- ============================================================================
-- PART 3: List all policies for review
-- ============================================================================
SELECT 
    'Policy Details' as check_type,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as operation,
    CASE 
        WHEN qual IS NOT NULL THEN 'Has USING clause'
        ELSE 'No USING clause'
    END as using_clause,
    CASE 
        WHEN with_check IS NOT NULL THEN 'Has WITH CHECK clause'
        ELSE 'No WITH CHECK clause'
    END as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================================
-- PART 4: Check for SECURITY DEFINER views (should be none)
-- ============================================================================
-- Note: This query checks if views still use SECURITY DEFINER
-- In PostgreSQL, we can't directly query this, but we can check view owners
-- Views should use SECURITY INVOKER (default) which runs as the querying user
SELECT 
    'View Security Check' as check_type,
    schemaname,
    viewname,
    viewowner,
    'Review manually - check if SECURITY DEFINER is still set' as note
FROM pg_views
WHERE schemaname = 'public'
    AND viewname IN (
        'recent_bookings_with_charges',
        'place_stats',
        'fl_sor_norm_v1',
        'v_bookings_latest',
        'recent_traffic_citations',
        'criminal_back_history_by_statute',
        'sor_with_geo_v1',
        'directory_categories_tree',
        'v_booking_with_charges',
        'fl_sor_best_address_v1',
        'sor_geocode_candidates_v1',
        'user_stats',
        'recent_criminal_back_history',
        'sor_best_address_v1',
        'traffic_citations_by_violation'
    )
ORDER BY viewname;

-- ============================================================================
-- PART 5: Summary - Tables that might need attention
-- ============================================================================
SELECT 
    'Summary' as check_type,
    t.tablename,
    CASE 
        WHEN t.rowsecurity = false THEN '❌ RLS Not Enabled'
        WHEN p.policy_count = 0 THEN '⚠️ RLS Enabled but No Policies'
        ELSE '✅ OK'
    END as status,
    COALESCE(p.policy_count, 0) as policy_count
FROM pg_tables t
LEFT JOIN (
    SELECT tablename, COUNT(*) as policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    GROUP BY tablename
) p ON p.tablename = t.tablename
WHERE t.schemaname = 'public'
    AND t.tablename IN (
        'place_reviews',
        'places',
        'people',
        'fl_sor_geo',
        'tattoo_locations',
        'fl_sex_offender_registry',
        'person_tattoos',
        'fl_sor_ingest_raw',
        'booking_stats',
        'fl_sor',
        'holds',
        'user_profiles',
        'places_backup_20241112',
        'directory_categories',
        'community_places',
        'community_reviews'
    )
ORDER BY 
    CASE 
        WHEN t.rowsecurity = false THEN 1
        WHEN p.policy_count = 0 THEN 2
        ELSE 3
    END,
    t.tablename;

