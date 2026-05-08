-- =====================================================
-- PUTNAM.APP - CALCULATE TOP 100 LISTS WITH TIME RANGES
-- =====================================================
-- This function calculates all top 100 lists for THREE time ranges:
-- - THISYEAR (from Jan 1 of current year)
-- - 5YEARS (past 5 years)
-- - ALL (all time)
-- Should be run twice daily.
-- =====================================================

CREATE OR REPLACE FUNCTION public.calculate_top_100_lists()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  calculation_time TIMESTAMPTZ := NOW();
  current_year_start DATE;
  five_years_ago DATE;
BEGIN
  -- Calculate date boundaries
  current_year_start := DATE_TRUNC('year', CURRENT_DATE);
  five_years_ago := CURRENT_DATE - INTERVAL '5 years';
  
  RAISE NOTICE 'Calculating top 100 lists for all time ranges...';
  RAISE NOTICE 'Current year start: %', current_year_start;
  RAISE NOTICE 'Five years ago: %', five_years_ago;
  
  -- ============================================
  -- CALCULATE FOR EACH TIME RANGE
  -- ============================================
  
  -- THISYEAR
  PERFORM _calculate_category_for_time_range('arrested_persons', 'THISYEAR', current_year_start, calculation_time);
  PERFORM _calculate_category_for_time_range('felony_charges', 'THISYEAR', current_year_start, calculation_time);
  PERFORM _calculate_category_for_time_range('misdemeanor_charges', 'THISYEAR', current_year_start, calculation_time);
  PERFORM _calculate_category_for_time_range('all_charges', 'THISYEAR', current_year_start, calculation_time);
  PERFORM _calculate_category_for_time_range('booking_days', 'THISYEAR', current_year_start, calculation_time);
  
  -- 5YEARS
  PERFORM _calculate_category_for_time_range('arrested_persons', '5YEARS', five_years_ago, calculation_time);
  PERFORM _calculate_category_for_time_range('felony_charges', '5YEARS', five_years_ago, calculation_time);
  PERFORM _calculate_category_for_time_range('misdemeanor_charges', '5YEARS', five_years_ago, calculation_time);
  PERFORM _calculate_category_for_time_range('all_charges', '5YEARS', five_years_ago, calculation_time);
  PERFORM _calculate_category_for_time_range('booking_days', '5YEARS', five_years_ago, calculation_time);
  
  -- ALL (no date filter - pass NULL)
  PERFORM _calculate_category_for_time_range('arrested_persons', 'ALL', NULL, calculation_time);
  PERFORM _calculate_category_for_time_range('felony_charges', 'ALL', NULL, calculation_time);
  PERFORM _calculate_category_for_time_range('misdemeanor_charges', 'ALL', NULL, calculation_time);
  PERFORM _calculate_category_for_time_range('all_charges', 'ALL', NULL, calculation_time);
  PERFORM _calculate_category_for_time_range('booking_days', 'ALL', NULL, calculation_time);
  
  RAISE NOTICE 'All top 100 lists calculated successfully at %', calculation_time;
END;
$$;

-- =====================================================
-- HELPER FUNCTION: Calculate one category for one time range
-- =====================================================
CREATE OR REPLACE FUNCTION _calculate_category_for_time_range(
  p_category TEXT,
  p_time_range TEXT,
  p_start_date DATE,
  p_calculation_time TIMESTAMPTZ
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE NOTICE 'Calculating % for time range %', p_category, p_time_range;
  
  -- Calculate based on category
  CASE p_category
    WHEN 'arrested_persons' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT 
        'arrested_persons'::TEXT,
        p_time_range::TEXT,
        ROW_NUMBER() OVER (ORDER BY booking_count DESC)::INTEGER as rank,
        person_name::TEXT as label,
        booking_count::INTEGER as count,
        NULL::TEXT as subtitle,
        jsonb_build_object('name', person_name) as extra_data,
        p_calculation_time
      FROM (
        SELECT 
          name as person_name,
          COUNT(*) as booking_count
        FROM public.recent_bookings_with_charges
        WHERE UPPER(name) != 'ORDER, COURT EXPUNGED'
          AND (p_start_date IS NULL OR booking_date >= p_start_date)
        GROUP BY name
        ORDER BY booking_count DESC
        LIMIT 100
      ) ranked_persons;
      
    WHEN 'felony_charges' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT 
        'felony_charges'::TEXT,
        p_time_range::TEXT,
        ROW_NUMBER() OVER (ORDER BY charge_count DESC)::INTEGER as rank,
        charge_name::TEXT as label,
        charge_count::INTEGER as count,
        NULL::TEXT as subtitle,
        jsonb_build_object('charge', charge_name, 'level', 'FELONY') as extra_data,
        p_calculation_time
      FROM (
        SELECT 
          charge->>'charge' as charge_name,
          COUNT(*) as charge_count
        FROM public.recent_bookings_with_charges b,
             jsonb_array_elements(b.charges) as charge
        WHERE charge->>'level' = 'F'
          AND charge->>'charge' IS NOT NULL
          AND charge->>'charge' != ''
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY charge->>'charge'
        ORDER BY charge_count DESC
        LIMIT 100
      ) ranked_felonies;
      
    WHEN 'misdemeanor_charges' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT 
        'misdemeanor_charges'::TEXT,
        p_time_range::TEXT,
        ROW_NUMBER() OVER (ORDER BY charge_count DESC)::INTEGER as rank,
        charge_name::TEXT as label,
        charge_count::INTEGER as count,
        NULL::TEXT as subtitle,
        jsonb_build_object('charge', charge_name, 'level', 'MISDEMEANOR') as extra_data,
        p_calculation_time
      FROM (
        SELECT 
          charge->>'charge' as charge_name,
          COUNT(*) as charge_count
        FROM public.recent_bookings_with_charges b,
             jsonb_array_elements(b.charges) as charge
        WHERE charge->>'level' = 'M'
          AND charge->>'charge' IS NOT NULL
          AND charge->>'charge' != ''
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY charge->>'charge'
        ORDER BY charge_count DESC
        LIMIT 100
      ) ranked_misdemeanors;
      
    WHEN 'all_charges' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT 
        'all_charges'::TEXT,
        p_time_range::TEXT,
        ROW_NUMBER() OVER (ORDER BY charge_count DESC)::INTEGER as rank,
        charge_name::TEXT as label,
        charge_count::INTEGER as count,
        COALESCE(charge_level, '')::TEXT as subtitle,
        jsonb_build_object('charge', charge_name, 'level', COALESCE(charge_level, '')) as extra_data,
        p_calculation_time
      FROM (
        SELECT 
          charge->>'charge' as charge_name,
          charge->>'level' as charge_level,
          COUNT(*) as charge_count
        FROM public.recent_bookings_with_charges b,
             jsonb_array_elements(b.charges) as charge
        WHERE charge->>'charge' IS NOT NULL
          AND charge->>'charge' != ''
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY charge->>'charge', charge->>'level'
        ORDER BY charge_count DESC
        LIMIT 100
      ) ranked_all_charges;
      
    WHEN 'booking_days' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT 
        'booking_days'::TEXT,
        p_time_range::TEXT,
        ROW_NUMBER() OVER (ORDER BY booking_count DESC)::INTEGER as rank,
        TO_CHAR(booking_date, 'YYYY-MM-DD')::TEXT as label,
        booking_count::INTEGER as count,
        TO_CHAR(booking_date, 'Day, Month DD, YYYY')::TEXT as subtitle,
        jsonb_build_object('date', booking_date::TEXT) as extra_data,
        p_calculation_time
      FROM (
        SELECT 
          DATE(booking_date) as booking_date,
          COUNT(*) as booking_count
        FROM public.recent_bookings_with_charges
        WHERE booking_date IS NOT NULL
          AND (p_start_date IS NULL OR booking_date >= p_start_date)
        GROUP BY DATE(booking_date)
        ORDER BY booking_count DESC
        LIMIT 100
      ) ranked_days;
  END CASE;
  
  RAISE NOTICE 'Completed % for time range %', p_category, p_time_range;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.calculate_top_100_lists() TO service_role;
GRANT EXECUTE ON FUNCTION _calculate_category_for_time_range(TEXT, TEXT, DATE, TIMESTAMPTZ) TO service_role;

-- Add comment
COMMENT ON FUNCTION public.calculate_top_100_lists() IS 'Calculates and stores all top 100 lists for THISYEAR, 5YEARS, and ALL time ranges. Should be run twice daily via pg_cron.';
