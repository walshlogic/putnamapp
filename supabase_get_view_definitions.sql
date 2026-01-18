-- ============================================================================
-- Helper script to get view definitions for fixing SECURITY DEFINER views
-- Run this first to get the actual view definitions, then use them to recreate
-- views with SECURITY INVOKER
-- ============================================================================

-- Get all view definitions that need to be fixed
SELECT 
    schemaname,
    viewname,
    pg_get_viewdef((schemaname || '.' || viewname)::regclass, true) as definition,
    '-- Fix: ' || viewname || ' view' || E'\n' ||
    'DROP VIEW IF EXISTS ' || schemaname || '.' || viewname || ' CASCADE;' || E'\n' ||
    'CREATE VIEW ' || schemaname || '.' || viewname || E'\n' ||
    'WITH (security_invoker = true) AS' || E'\n' ||
    pg_get_viewdef((schemaname || '.' || viewname)::regclass, true) || ';' || E'\n' as fix_sql
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

-- Alternative: Check which views are SECURITY DEFINER
-- This query helps identify views that need fixing
SELECT 
    n.nspname as schema_name,
    c.relname as view_name,
    CASE 
        WHEN c.relkind = 'v' THEN 'VIEW'
        ELSE 'OTHER'
    END as object_type
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
    AND c.relkind = 'v'
    AND c.relname IN (
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
ORDER BY c.relname;

