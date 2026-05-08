-- Agency Stats: pre-calculated cache per agency
-- Populated by calculate_agency_stats() function

CREATE TABLE IF NOT EXISTS public.agency_stats (
    id BIGSERIAL PRIMARY KEY,
    agency_id TEXT NOT NULL,
    agency_name TEXT NOT NULL,
    total_bookings INTEGER NOT NULL,
    total_charges INTEGER NOT NULL,
    unique_persons INTEGER NOT NULL,
    average_charges_per_booking NUMERIC(10, 2) NOT NULL,
    bookings_by_year JSONB NOT NULL DEFAULT '{}'::jsonb,
    bookings_by_gender JSONB NOT NULL DEFAULT '{}'::jsonb,
    bookings_by_race JSONB NOT NULL DEFAULT '{}'::jsonb,
    charges_by_level_and_degree JSONB NOT NULL DEFAULT '[]'::jsonb,
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agency_stats_agency_calculated
    ON public.agency_stats (agency_id, calculated_at DESC);

ALTER TABLE public.agency_stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_stats_read_all" ON public.agency_stats;
CREATE POLICY "agency_stats_read_all"
    ON public.agency_stats FOR SELECT
    TO authenticated
    USING (true);

-- Calculate stats for the PCSO agency from bookings + charges
CREATE OR REPLACE FUNCTION public.calculate_agency_stats()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total_bookings INTEGER;
    v_total_charges INTEGER;
    v_unique_persons INTEGER;
    v_by_year JSONB;
    v_by_gender JSONB;
    v_by_race JSONB;
    v_by_level JSONB;
BEGIN
    SELECT COUNT(*) INTO v_total_bookings FROM public.bookings;
    SELECT COUNT(*) INTO v_total_charges FROM public.charges;
    SELECT COUNT(DISTINCT NULLIF(mni_no, ''))
        INTO v_unique_persons FROM public.bookings WHERE mni_no IS NOT NULL;

    SELECT COALESCE(jsonb_object_agg(year::TEXT, cnt), '{}'::jsonb)
        INTO v_by_year
    FROM (
        SELECT EXTRACT(YEAR FROM booking_date)::INT AS year, COUNT(*) AS cnt
        FROM public.bookings
        WHERE booking_date IS NOT NULL
        GROUP BY EXTRACT(YEAR FROM booking_date)
    ) y;

    SELECT COALESCE(jsonb_object_agg(gender_upper, cnt), '{}'::jsonb)
        INTO v_by_gender
    FROM (
        SELECT UPPER(TRIM(gender)) AS gender_upper, COUNT(*) AS cnt
        FROM public.bookings
        WHERE gender IS NOT NULL AND TRIM(gender) <> ''
        GROUP BY UPPER(TRIM(gender))
    ) g;

    SELECT COALESCE(jsonb_object_agg(race_upper, cnt), '{}'::jsonb)
        INTO v_by_race
    FROM (
        SELECT UPPER(TRIM(race)) AS race_upper, COUNT(*) AS cnt
        FROM public.bookings
        WHERE race IS NOT NULL AND TRIM(race) <> ''
        GROUP BY UPPER(TRIM(race))
    ) r;

    -- Build charges_by_level_and_degree as an array of {level, totalCount, byDegree}
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'level', level_group,
        'totalCount', total_count,
        'byDegree', by_degree
    ) ORDER BY total_count DESC), '[]'::jsonb)
        INTO v_by_level
    FROM (
        SELECT
            level_group,
            SUM(cnt)::INT AS total_count,
            jsonb_object_agg(degree_group, cnt) AS by_degree
        FROM (
            SELECT
                COALESCE(NULLIF(UPPER(TRIM(level)), ''), 'UNKNOWN') AS level_group,
                COALESCE(NULLIF(UPPER(TRIM(degree)), ''), 'UNKNOWN') AS degree_group,
                COUNT(*) AS cnt
            FROM public.charges
            GROUP BY level_group, degree_group
        ) per_cell
        GROUP BY level_group
    ) per_level;

    INSERT INTO public.agency_stats (
        agency_id,
        agency_name,
        total_bookings,
        total_charges,
        unique_persons,
        average_charges_per_booking,
        bookings_by_year,
        bookings_by_gender,
        bookings_by_race,
        charges_by_level_and_degree,
        calculated_at
    ) VALUES (
        'pcso',
        'Putnam County Sheriff''s Office',
        v_total_bookings,
        v_total_charges,
        v_unique_persons,
        CASE WHEN v_total_bookings > 0
            THEN ROUND(v_total_charges::NUMERIC / v_total_bookings, 2)
            ELSE 0 END,
        v_by_year,
        v_by_gender,
        v_by_race,
        v_by_level,
        NOW()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.calculate_agency_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_agency_stats() TO service_role;
