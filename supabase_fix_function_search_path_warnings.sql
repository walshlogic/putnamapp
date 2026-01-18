-- ============================================================================
-- Fix Function Search Path Warnings
-- Sets search_path on all functions to prevent security vulnerabilities
-- ============================================================================
-- 
-- This fixes the "Function Search Path Mutable" warnings by setting
-- search_path = '' on all functions. This prevents search_path injection
-- attacks where malicious users could manipulate the search_path to execute
-- malicious code.
--
-- The fix uses ALTER FUNCTION ... SET search_path = '' which sets an empty
-- search_path, forcing PostgreSQL to use fully qualified names.
-- ============================================================================

-- Fix all functions with mutable search_path
-- Note: This preserves the function definitions but adds security settings

ALTER FUNCTION public.find_places_nearby SET search_path = '';
ALTER FUNCTION public.update_place_checkin_count SET search_path = '';
ALTER FUNCTION public.get_main_categories SET search_path = '';
ALTER FUNCTION public.canonicalize_zip5 SET search_path = '';
ALTER FUNCTION public.calculate_top_100_lists SET search_path = '';
ALTER FUNCTION public.has_tier_benefit SET search_path = '';
ALTER FUNCTION public.sor_search_candidates SET search_path = '';
ALTER FUNCTION public.set_updated_at SET search_path = '';
ALTER FUNCTION public.update_places_search_vector SET search_path = '';
ALTER FUNCTION public.update_categories_updated_at SET search_path = '';
ALTER FUNCTION public.refresh_booked_persons SET search_path = '';
ALTER FUNCTION public._set_updated_at SET search_path = '';
ALTER FUNCTION public.update_places_updated_at SET search_path = '';
ALTER FUNCTION public.calc_height_total_inches SET search_path = '';
ALTER FUNCTION public.is_premium_active SET search_path = '';
ALTER FUNCTION public.record_geocode_success SET search_path = '';
ALTER FUNCTION public.record_geocode_failure SET search_path = '';
ALTER FUNCTION public.update_updated_at_column SET search_path = '';
ALTER FUNCTION public.update_social_media_posts_updated_at SET search_path = '';
ALTER FUNCTION public.get_user_favorite_count SET search_path = '';
ALTER FUNCTION public.update_place_favorite_count SET search_path = '';
ALTER FUNCTION public.set_people_tattoos_updated_at SET search_path = '';
ALTER FUNCTION public.get_subcategories SET search_path = '';
ALTER FUNCTION public.cleanup_expired_premiums SET search_path = '';
ALTER FUNCTION public.touch_bookings_updated_at SET search_path = '';
ALTER FUNCTION public.submit_contact_message SET search_path = '';
ALTER FUNCTION public.update_place_review_stats SET search_path = '';
ALTER FUNCTION public.compose_address SET search_path = '';
ALTER FUNCTION public.to_date_2digit_year SET search_path = '';
ALTER FUNCTION public.update_criminal_back_history_updated_at SET search_path = '';
ALTER FUNCTION public.refresh_booking_stats SET search_path = '';
ALTER FUNCTION public.fl_sor_touch_updated_at SET search_path = '';
ALTER FUNCTION public.update_traffic_citations_updated_at SET search_path = '';
ALTER FUNCTION public.get_place_reviews SET search_path = '';
ALTER FUNCTION public.days_until_premium_expires SET search_path = '';
ALTER FUNCTION public._calculate_category_for_time_range SET search_path = '';
ALTER FUNCTION public.null_if_junk_address SET search_path = '';
ALTER FUNCTION public.increment_place_views SET search_path = '';
ALTER FUNCTION public.canonicalize_state SET search_path = '';
ALTER FUNCTION public.handle_new_user SET search_path = '';

-- ============================================================================
-- Verification Query
-- Run this to verify all functions now have search_path set
-- ============================================================================
-- SELECT 
--     p.proname as function_name,
--     pg_get_functiondef(p.oid) LIKE '%SET search_path%' as has_search_path_set
-- FROM pg_proc p
-- JOIN pg_namespace n ON n.oid = p.pronamespace
-- WHERE n.nspname = 'public'
--     AND p.proname IN (
--         'find_places_nearby',
--         'update_place_checkin_count',
--         'get_main_categories',
--         'canonicalize_zip5',
--         'calculate_top_100_lists',
--         'has_tier_benefit',
--         'sor_search_candidates',
--         'set_updated_at',
--         'update_places_search_vector',
--         'update_categories_updated_at',
--         'refresh_booked_persons',
--         '_set_updated_at',
--         'update_places_updated_at',
--         'calc_height_total_inches',
--         'is_premium_active',
--         'record_geocode_success',
--         'record_geocode_failure',
--         'update_updated_at_column',
--         'update_social_media_posts_updated_at',
--         'get_user_favorite_count',
--         'update_place_favorite_count',
--         'set_people_tattoos_updated_at',
--         'get_subcategories',
--         'cleanup_expired_premiums',
--         'touch_bookings_updated_at',
--         'submit_contact_message',
--         'update_place_review_stats',
--         'compose_address',
--         'to_date_2digit_year',
--         'update_criminal_back_history_updated_at',
--         'refresh_booking_stats',
--         'fl_sor_touch_updated_at',
--         'update_traffic_citations_updated_at',
--         'get_place_reviews',
--         'days_until_premium_expires',
--         '_calculate_category_for_time_range',
--         'null_if_junk_address',
--         'increment_place_views',
--         'canonicalize_state',
--         'handle_new_user'
--     )
-- ORDER BY p.proname;

