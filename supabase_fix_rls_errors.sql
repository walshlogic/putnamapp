-- ============================================================================
-- Supabase RLS Security Fixes
-- Fixes 33 security errors reported by Supabase database linter
-- ============================================================================

-- ============================================================================
-- PART 1: Enable RLS on tables that have policies but RLS is disabled
-- ============================================================================

-- Fix: place_reviews table has RLS policies but RLS is not enabled
ALTER TABLE public.place_reviews ENABLE ROW LEVEL SECURITY;

-- Fix: places table has RLS policies but RLS is not enabled
ALTER TABLE public.places ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PART 2: Enable RLS on all public tables that don't have it enabled
-- ============================================================================

-- Enable RLS on people table
ALTER TABLE public.people ENABLE ROW LEVEL SECURITY;

-- Enable RLS on fl_sor_geo table
ALTER TABLE public.fl_sor_geo ENABLE ROW LEVEL SECURITY;

-- Enable RLS on tattoo_locations table
ALTER TABLE public.tattoo_locations ENABLE ROW LEVEL SECURITY;

-- Enable RLS on fl_sex_offender_registry table
ALTER TABLE public.fl_sex_offender_registry ENABLE ROW LEVEL SECURITY;

-- Enable RLS on person_tattoos table
ALTER TABLE public.person_tattoos ENABLE ROW LEVEL SECURITY;

-- Enable RLS on fl_sor_ingest_raw table
ALTER TABLE public.fl_sor_ingest_raw ENABLE ROW LEVEL SECURITY;

-- Enable RLS on booking_stats table
ALTER TABLE public.booking_stats ENABLE ROW LEVEL SECURITY;

-- Enable RLS on fl_sor table
ALTER TABLE public.fl_sor ENABLE ROW LEVEL SECURITY;

-- Enable RLS on holds table
ALTER TABLE public.holds ENABLE ROW LEVEL SECURITY;

-- Enable RLS on user_profiles table
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Enable RLS on places_backup_20241112 table (backup table, but should still have RLS)
ALTER TABLE public.places_backup_20241112 ENABLE ROW LEVEL SECURITY;

-- Enable RLS on directory_categories table
ALTER TABLE public.directory_categories ENABLE ROW LEVEL SECURITY;

-- Enable RLS on community_places table
ALTER TABLE public.community_places ENABLE ROW LEVEL SECURITY;

-- Enable RLS on community_reviews table
ALTER TABLE public.community_reviews ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PART 3: Create basic RLS policies for tables that now have RLS enabled
-- but may not have appropriate policies
-- ============================================================================

-- Note: These tables may need more specific policies based on your app's requirements.
-- The following are basic policies to prevent complete lockout. You should review
-- and customize these based on your security requirements.

-- Basic policies for people table (public read, authenticated write)
-- Adjust based on your requirements
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'people' 
        AND policyname = 'Public can read people'
    ) THEN
        CREATE POLICY "Public can read people"
            ON public.people
            FOR SELECT
            TO public
            USING (true);
    END IF;
END $$;

-- Basic policies for fl_sor_geo table (public read)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'fl_sor_geo' 
        AND policyname = 'Public can read fl_sor_geo'
    ) THEN
        CREATE POLICY "Public can read fl_sor_geo"
            ON public.fl_sor_geo
            FOR SELECT
            TO public
            USING (true);
    END IF;
END $$;

-- Basic policies for tattoo_locations table (public read)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'tattoo_locations' 
        AND policyname = 'Public can read tattoo_locations'
    ) THEN
        CREATE POLICY "Public can read tattoo_locations"
            ON public.tattoo_locations
            FOR SELECT
            TO public
            USING (true);
    END IF;
END $$;

-- Basic policies for fl_sex_offender_registry table (public read)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'fl_sex_offender_registry' 
        AND policyname = 'Public can read fl_sex_offender_registry'
    ) THEN
        CREATE POLICY "Public can read fl_sex_offender_registry"
            ON public.fl_sex_offender_registry
            FOR SELECT
            TO public
            USING (true);
    END IF;
END $$;

-- Basic policies for person_tattoos table (public read)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'person_tattoos' 
        AND policyname = 'Public can read person_tattoos'
    ) THEN
        CREATE POLICY "Public can read person_tattoos"
            ON public.person_tattoos
            FOR SELECT
            TO public
            USING (true);
    END IF;
END $$;

-- Basic policies for fl_sor_ingest_raw table (service_role only - likely internal)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'fl_sor_ingest_raw' 
        AND policyname = 'Service role can manage fl_sor_ingest_raw'
    ) THEN
        CREATE POLICY "Service role can manage fl_sor_ingest_raw"
            ON public.fl_sor_ingest_raw
            FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

-- Basic policies for booking_stats table (public read)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'booking_stats' 
        AND policyname = 'Public can read booking_stats'
    ) THEN
        CREATE POLICY "Public can read booking_stats"
            ON public.booking_stats
            FOR SELECT
            TO public
            USING (true);
    END IF;
END $$;

-- Basic policies for fl_sor table (public read)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'fl_sor' 
        AND policyname = 'Public can read fl_sor'
    ) THEN
        CREATE POLICY "Public can read fl_sor"
            ON public.fl_sor
            FOR SELECT
            TO public
            USING (true);
    END IF;
END $$;

-- Basic policies for holds table (public read)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'holds' 
        AND policyname = 'Public can read holds'
    ) THEN
        CREATE POLICY "Public can read holds"
            ON public.holds
            FOR SELECT
            TO public
            USING (true);
    END IF;
END $$;

-- Basic policies for user_profiles table (users can read/update own profile)
-- Note: user_profiles uses 'id' column (not 'user_id') which matches auth.uid()
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles' 
        AND policyname = 'Users can read own profile'
    ) THEN
        CREATE POLICY "Users can read own profile"
            ON public.user_profiles
            FOR SELECT
            TO authenticated
            USING (auth.uid() = id);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles' 
        AND policyname = 'Users can update own profile'
    ) THEN
        CREATE POLICY "Users can update own profile"
            ON public.user_profiles
            FOR UPDATE
            TO authenticated
            USING (auth.uid() = id)
            WITH CHECK (auth.uid() = id);
    END IF;
    
    -- Allow users to insert their own profile (for initial profile creation)
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles' 
        AND policyname = 'Users can insert own profile'
    ) THEN
        CREATE POLICY "Users can insert own profile"
            ON public.user_profiles
            FOR INSERT
            TO authenticated
            WITH CHECK (auth.uid() = id);
    END IF;
END $$;

-- Basic policies for places_backup_20241112 table (service_role only - backup table)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'places_backup_20241112' 
        AND policyname = 'Service role can manage places_backup_20241112'
    ) THEN
        CREATE POLICY "Service role can manage places_backup_20241112"
            ON public.places_backup_20241112
            FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

-- Basic policies for directory_categories table (public read)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'directory_categories' 
        AND policyname = 'Public can read directory_categories'
    ) THEN
        CREATE POLICY "Public can read directory_categories"
            ON public.directory_categories
            FOR SELECT
            TO public
            USING (true);
    END IF;
END $$;

-- Basic policies for community_places table (public read, authenticated write)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'community_places' 
        AND policyname = 'Public can read community_places'
    ) THEN
        CREATE POLICY "Public can read community_places"
            ON public.community_places
            FOR SELECT
            TO public
            USING (true);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'community_places' 
        AND policyname = 'Authenticated users can create community_places'
    ) THEN
        CREATE POLICY "Authenticated users can create community_places"
            ON public.community_places
            FOR INSERT
            TO authenticated
            WITH CHECK (true);
    END IF;
END $$;

-- Basic policies for community_reviews table (public read, authenticated write)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'community_reviews' 
        AND policyname = 'Public can read community_reviews'
    ) THEN
        CREATE POLICY "Public can read community_reviews"
            ON public.community_reviews
            FOR SELECT
            TO public
            USING (true);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'community_reviews' 
        AND policyname = 'Authenticated users can create community_reviews'
    ) THEN
        CREATE POLICY "Authenticated users can create community_reviews"
            ON public.community_reviews
            FOR INSERT
            TO authenticated
            WITH CHECK (true);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'community_reviews' 
        AND policyname = 'Users can update own community_reviews'
    ) THEN
        CREATE POLICY "Users can update own community_reviews"
            ON public.community_reviews
            FOR UPDATE
            TO authenticated
            USING (auth.uid() = user_id)
            WITH CHECK (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'community_reviews' 
        AND policyname = 'Users can delete own community_reviews'
    ) THEN
        CREATE POLICY "Users can delete own community_reviews"
            ON public.community_reviews
            FOR DELETE
            TO authenticated
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- PART 4: Fix SECURITY DEFINER views - Change to SECURITY INVOKER
-- ============================================================================
-- 
-- IMPORTANT: PostgreSQL doesn't support ALTER VIEW to change security definer.
-- Views must be recreated. Run the query below to get view definitions first,
-- then recreate each view with SECURITY INVOKER.
--
-- To get view definitions, run this query in Supabase SQL Editor:
-- SELECT 
--     schemaname,
--     viewname,
--     pg_get_viewdef(viewname::regclass, true) as definition
-- FROM pg_views
-- WHERE schemaname = 'public'
--     AND viewname IN (
--         'recent_bookings_with_charges',
--         'place_stats',
--         'fl_sor_norm_v1',
--         'v_bookings_latest',
--         'recent_traffic_citations',
--         'criminal_back_history_by_statute',
--         'sor_with_geo_v1',
--         'directory_categories_tree',
--         'v_booking_with_charges',
--         'fl_sor_best_address_v1',
--         'sor_geocode_candidates_v1',
--         'user_stats',
--         'recent_criminal_back_history',
--         'sor_best_address_v1',
--         'traffic_citations_by_violation'
--     )
-- ORDER BY viewname;
--
-- Then for each view, recreate it like this:
-- DROP VIEW IF EXISTS public.view_name CASCADE;
-- CREATE VIEW public.view_name
-- WITH (security_invoker = true) AS
-- [paste the definition from pg_get_viewdef here];
--
-- ============================================================================
-- Automated fix using pg_get_viewdef (may not work for all complex views)
-- ============================================================================

-- Function to recreate a view with SECURITY INVOKER
CREATE OR REPLACE FUNCTION fix_view_security(view_schema text, view_name text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    view_def text;
BEGIN
    -- Get the view definition
    SELECT pg_get_viewdef((view_schema || '.' || view_name)::regclass, true)
    INTO view_def;
    
    -- Drop the view
    EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', view_schema, view_name);
    
    -- Recreate with SECURITY INVOKER
    EXECUTE format('CREATE VIEW %I.%I WITH (security_invoker = true) AS %s', 
                   view_schema, view_name, view_def);
END;
$$;

-- Fix all SECURITY DEFINER views
SELECT fix_view_security('public', 'recent_bookings_with_charges');
SELECT fix_view_security('public', 'place_stats');
SELECT fix_view_security('public', 'fl_sor_norm_v1');
SELECT fix_view_security('public', 'v_bookings_latest');
SELECT fix_view_security('public', 'recent_traffic_citations');
SELECT fix_view_security('public', 'criminal_back_history_by_statute');
SELECT fix_view_security('public', 'sor_with_geo_v1');
SELECT fix_view_security('public', 'directory_categories_tree');
SELECT fix_view_security('public', 'v_booking_with_charges');
SELECT fix_view_security('public', 'fl_sor_best_address_v1');
SELECT fix_view_security('public', 'sor_geocode_candidates_v1');
SELECT fix_view_security('public', 'user_stats');
SELECT fix_view_security('public', 'recent_criminal_back_history');
SELECT fix_view_security('public', 'sor_best_address_v1');
SELECT fix_view_security('public', 'traffic_citations_by_violation');

-- Clean up the helper function
DROP FUNCTION IF EXISTS fix_view_security(text, text);

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Check which tables have RLS enabled
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- ORDER BY tablename;

-- Check which views use SECURITY DEFINER
-- SELECT schemaname, viewname, viewowner
-- FROM pg_views
-- WHERE schemaname = 'public'
-- ORDER BY viewname;

-- Check all RLS policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

