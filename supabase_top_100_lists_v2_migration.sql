-- =====================================================
-- TOP 100 LISTS — v2 migration
-- =====================================================
-- Replaces the THISYEAR / 5YEARS / ALL time ranges with:
--   YTD       — Jan 1 of current year through today
--   12MONTHS  — rolling 12 months back from today
--   24MONTHS  — rolling 24 months back from today
--   36MONTHS  — rolling 36 months back from today
--
-- Adds `charges_count` to extra_data for the arrested_persons category
-- so each card can show both Bookings and Charges totals; the app
-- offers an "Order By" client-side toggle that re-sorts the returned
-- list (the LIST stays the same — top 100 by bookings — only the
-- order changes).
--
-- Also adds public.top_100_for_custom_range() — a live SQL function
-- the app calls when the user picks a custom date range. Returns
-- the same row shape; not pre-calculated since custom ranges are
-- unbounded.
--
-- Atomic refresh: each (category, time_range) does DELETE then INSERT
-- inside one outer transaction, so readers always see a complete set.
-- =====================================================

CREATE OR REPLACE FUNCTION _calculate_category_for_time_range(
  p_category TEXT,
  p_time_range TEXT,
  p_start_date DATE,
  p_calculation_time TIMESTAMPTZ
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Atomic refresh: clear stale rows for this slice before inserting fresh ones.
  DELETE FROM public.top_100_lists
  WHERE category = p_category AND time_range = p_time_range;

  CASE p_category
    WHEN 'arrested_persons' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT
        'arrested_persons',
        p_time_range,
        ROW_NUMBER() OVER (ORDER BY booking_count DESC, person_name ASC)::INTEGER,
        person_name,
        booking_count::INTEGER,
        NULL,
        jsonb_build_object('name', person_name, 'charges_count', charge_count),
        p_calculation_time
      FROM (
        SELECT
          b.name AS person_name,
          COUNT(DISTINCT b.booking_no) AS booking_count,
          COUNT(c.id) AS charge_count
        FROM public.bookings b
        LEFT JOIN public.charges c ON c.booking_no = b.booking_no
        WHERE UPPER(COALESCE(b.name, '')) <> 'ORDER, COURT EXPUNGED'
          AND b.name IS NOT NULL AND b.name <> ''
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY b.name
        ORDER BY booking_count DESC, b.name ASC
        LIMIT 100
      ) ranked;

    WHEN 'felony_charges' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT
        'felony_charges',
        p_time_range,
        ROW_NUMBER() OVER (ORDER BY charge_count DESC, charge_name ASC)::INTEGER,
        charge_name,
        charge_count::INTEGER,
        NULL,
        jsonb_build_object('charge', charge_name, 'level', 'FELONY'),
        p_calculation_time
      FROM (
        SELECT
          c.charge AS charge_name,
          COUNT(*) AS charge_count
        FROM public.charges c
        JOIN public.bookings b ON b.booking_no = c.booking_no
        WHERE c.level = 'F'
          AND c.charge IS NOT NULL AND c.charge <> ''
          AND UPPER(COALESCE(b.name, '')) <> 'ORDER, COURT EXPUNGED'
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY c.charge
        ORDER BY charge_count DESC, c.charge ASC
        LIMIT 100
      ) ranked;

    WHEN 'misdemeanor_charges' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT
        'misdemeanor_charges',
        p_time_range,
        ROW_NUMBER() OVER (ORDER BY charge_count DESC, charge_name ASC)::INTEGER,
        charge_name,
        charge_count::INTEGER,
        NULL,
        jsonb_build_object('charge', charge_name, 'level', 'MISDEMEANOR'),
        p_calculation_time
      FROM (
        SELECT
          c.charge AS charge_name,
          COUNT(*) AS charge_count
        FROM public.charges c
        JOIN public.bookings b ON b.booking_no = c.booking_no
        WHERE c.level = 'M'
          AND c.charge IS NOT NULL AND c.charge <> ''
          AND UPPER(COALESCE(b.name, '')) <> 'ORDER, COURT EXPUNGED'
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY c.charge
        ORDER BY charge_count DESC, c.charge ASC
        LIMIT 100
      ) ranked;

    WHEN 'all_charges' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT
        'all_charges',
        p_time_range,
        ROW_NUMBER() OVER (ORDER BY charge_count DESC, charge_name ASC)::INTEGER,
        charge_name,
        charge_count::INTEGER,
        COALESCE(charge_level, ''),
        jsonb_build_object('charge', charge_name, 'level', COALESCE(charge_level, '')),
        p_calculation_time
      FROM (
        SELECT
          c.charge AS charge_name,
          c.level AS charge_level,
          COUNT(*) AS charge_count
        FROM public.charges c
        JOIN public.bookings b ON b.booking_no = c.booking_no
        WHERE c.charge IS NOT NULL AND c.charge <> ''
          AND UPPER(COALESCE(b.name, '')) <> 'ORDER, COURT EXPUNGED'
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY c.charge, c.level
        ORDER BY charge_count DESC, c.charge ASC
        LIMIT 100
      ) ranked;

    WHEN 'booking_days' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT
        'booking_days',
        p_time_range,
        ROW_NUMBER() OVER (ORDER BY booking_count DESC, day ASC)::INTEGER,
        TO_CHAR(day, 'YYYY-MM-DD'),
        booking_count::INTEGER,
        TO_CHAR(day, 'FMDay, FMMonth FMDD, YYYY'),
        jsonb_build_object('date', day::TEXT),
        p_calculation_time
      FROM (
        SELECT
          DATE(b.booking_date) AS day,
          COUNT(*) AS booking_count
        FROM public.bookings b
        WHERE b.booking_date IS NOT NULL
          AND UPPER(COALESCE(b.name, '')) <> 'ORDER, COURT EXPUNGED'
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY DATE(b.booking_date)
        ORDER BY booking_count DESC, DATE(b.booking_date) ASC
        LIMIT 100
      ) ranked;
  END CASE;
END;
$$;


CREATE OR REPLACE FUNCTION public.calculate_top_100_lists()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  calculation_time TIMESTAMPTZ := NOW();
  ytd_start DATE := DATE_TRUNC('year', CURRENT_DATE)::DATE;
  m12_start DATE := (CURRENT_DATE - INTERVAL '12 months')::DATE;
  m24_start DATE := (CURRENT_DATE - INTERVAL '24 months')::DATE;
  m36_start DATE := (CURRENT_DATE - INTERVAL '36 months')::DATE;
  cat TEXT;
BEGIN
  FOREACH cat IN ARRAY ARRAY['arrested_persons','felony_charges','misdemeanor_charges','all_charges','booking_days'] LOOP
    PERFORM _calculate_category_for_time_range(cat, 'YTD',      ytd_start, calculation_time);
    PERFORM _calculate_category_for_time_range(cat, '12MONTHS', m12_start, calculation_time);
    PERFORM _calculate_category_for_time_range(cat, '24MONTHS', m24_start, calculation_time);
    PERFORM _calculate_category_for_time_range(cat, '36MONTHS', m36_start, calculation_time);
  END LOOP;
END;
$$;


-- =====================================================
-- LIVE CUSTOM RANGE — called from app when user picks dates
-- =====================================================
-- Returns the same shape as a top_100_lists row but is computed live.
-- The caller passes category + start/end dates; for most categories
-- this runs in well under 1 sec on current data sizes.
-- =====================================================
CREATE OR REPLACE FUNCTION public.top_100_for_custom_range(
  p_category TEXT,
  p_start DATE,
  p_end DATE
)
RETURNS TABLE (
  rank        INTEGER,
  label       TEXT,
  count       INTEGER,
  subtitle    TEXT,
  extra_data  JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  CASE p_category
    WHEN 'arrested_persons' THEN
      RETURN QUERY
      SELECT
        ROW_NUMBER() OVER (ORDER BY t.booking_count DESC, t.person_name ASC)::INTEGER,
        t.person_name,
        t.booking_count::INTEGER,
        NULL::TEXT,
        jsonb_build_object('name', t.person_name, 'charges_count', t.charge_count)
      FROM (
        SELECT
          b.name AS person_name,
          COUNT(DISTINCT b.booking_no) AS booking_count,
          COUNT(c.id) AS charge_count
        FROM public.bookings b
        LEFT JOIN public.charges c ON c.booking_no = b.booking_no
        WHERE UPPER(COALESCE(b.name, '')) <> 'ORDER, COURT EXPUNGED'
          AND b.name IS NOT NULL AND b.name <> ''
          AND b.booking_date >= p_start
          AND b.booking_date < (p_end + INTERVAL '1 day')
        GROUP BY b.name
        ORDER BY COUNT(DISTINCT b.booking_no) DESC, b.name ASC
        LIMIT 100
      ) t;

    WHEN 'felony_charges' THEN
      RETURN QUERY
      SELECT
        ROW_NUMBER() OVER (ORDER BY t.charge_count DESC, t.charge_name ASC)::INTEGER,
        t.charge_name,
        t.charge_count::INTEGER,
        NULL::TEXT,
        jsonb_build_object('charge', t.charge_name, 'level', 'FELONY')
      FROM (
        SELECT c.charge AS charge_name, COUNT(*) AS charge_count
        FROM public.charges c
        JOIN public.bookings b ON b.booking_no = c.booking_no
        WHERE c.level = 'F' AND c.charge IS NOT NULL AND c.charge <> ''
          AND UPPER(COALESCE(b.name, '')) <> 'ORDER, COURT EXPUNGED'
          AND b.booking_date >= p_start
          AND b.booking_date < (p_end + INTERVAL '1 day')
        GROUP BY c.charge
        ORDER BY COUNT(*) DESC, c.charge ASC
        LIMIT 100
      ) t;

    WHEN 'misdemeanor_charges' THEN
      RETURN QUERY
      SELECT
        ROW_NUMBER() OVER (ORDER BY t.charge_count DESC, t.charge_name ASC)::INTEGER,
        t.charge_name,
        t.charge_count::INTEGER,
        NULL::TEXT,
        jsonb_build_object('charge', t.charge_name, 'level', 'MISDEMEANOR')
      FROM (
        SELECT c.charge AS charge_name, COUNT(*) AS charge_count
        FROM public.charges c
        JOIN public.bookings b ON b.booking_no = c.booking_no
        WHERE c.level = 'M' AND c.charge IS NOT NULL AND c.charge <> ''
          AND UPPER(COALESCE(b.name, '')) <> 'ORDER, COURT EXPUNGED'
          AND b.booking_date >= p_start
          AND b.booking_date < (p_end + INTERVAL '1 day')
        GROUP BY c.charge
        ORDER BY COUNT(*) DESC, c.charge ASC
        LIMIT 100
      ) t;

    WHEN 'all_charges' THEN
      RETURN QUERY
      SELECT
        ROW_NUMBER() OVER (ORDER BY t.charge_count DESC, t.charge_name ASC)::INTEGER,
        t.charge_name,
        t.charge_count::INTEGER,
        COALESCE(t.charge_level, ''),
        jsonb_build_object('charge', t.charge_name, 'level', COALESCE(t.charge_level, ''))
      FROM (
        SELECT c.charge AS charge_name, c.level AS charge_level, COUNT(*) AS charge_count
        FROM public.charges c
        JOIN public.bookings b ON b.booking_no = c.booking_no
        WHERE c.charge IS NOT NULL AND c.charge <> ''
          AND UPPER(COALESCE(b.name, '')) <> 'ORDER, COURT EXPUNGED'
          AND b.booking_date >= p_start
          AND b.booking_date < (p_end + INTERVAL '1 day')
        GROUP BY c.charge, c.level
        ORDER BY COUNT(*) DESC, c.charge ASC
        LIMIT 100
      ) t;

    WHEN 'booking_days' THEN
      RETURN QUERY
      SELECT
        ROW_NUMBER() OVER (ORDER BY t.booking_count DESC, t.day ASC)::INTEGER,
        TO_CHAR(t.day, 'YYYY-MM-DD'),
        t.booking_count::INTEGER,
        TO_CHAR(t.day, 'FMDay, FMMonth FMDD, YYYY'),
        jsonb_build_object('date', t.day::TEXT)
      FROM (
        SELECT DATE(b.booking_date) AS day, COUNT(*) AS booking_count
        FROM public.bookings b
        WHERE b.booking_date IS NOT NULL
          AND UPPER(COALESCE(b.name, '')) <> 'ORDER, COURT EXPUNGED'
          AND b.booking_date >= p_start
          AND b.booking_date < (p_end + INTERVAL '1 day')
        GROUP BY DATE(b.booking_date)
        ORDER BY COUNT(*) DESC, DATE(b.booking_date) ASC
        LIMIT 100
      ) t;
  END CASE;
END;
$$;


GRANT EXECUTE ON FUNCTION public.calculate_top_100_lists()                      TO service_role;
GRANT EXECUTE ON FUNCTION _calculate_category_for_time_range(TEXT, TEXT, DATE, TIMESTAMPTZ) TO service_role;
GRANT EXECUTE ON FUNCTION public.top_100_for_custom_range(TEXT, DATE, DATE)    TO anon, authenticated, service_role;

COMMENT ON FUNCTION public.calculate_top_100_lists() IS
  'Refreshes top_100_lists for YTD / 12MONTHS / 24MONTHS / 36MONTHS across all 5 categories. Run nightly via cron.';
COMMENT ON FUNCTION public.top_100_for_custom_range(TEXT, DATE, DATE) IS
  'Live (non-cached) top-100 query for an arbitrary date range — called when user picks a custom range in the app.';

-- ---------------------------------------------------------
-- Drop obsolete pre-calculated rows (THISYEAR / 5YEARS / ALL)
-- ---------------------------------------------------------
DELETE FROM public.top_100_lists
WHERE time_range IN ('THISYEAR', '5YEARS', 'ALL');

-- ---------------------------------------------------------
-- Run a fresh calculation now so the new ranges are populated
-- ---------------------------------------------------------
SELECT public.calculate_top_100_lists();
