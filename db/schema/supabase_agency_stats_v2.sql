-- Rebuilt calculate_agency_stats() to handle multiple agencies.
-- The arresting agency is embedded in charges.case_number as "... (AGENCY NAME)".
-- A booking is attributed to every agency that appears in any of its charges.

CREATE OR REPLACE FUNCTION public.calculate_agency_stats()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    r RECORD;
    v_total_bookings INTEGER;
    v_total_charges INTEGER;
    v_unique_persons INTEGER;
    v_by_year JSONB;
    v_by_gender JSONB;
    v_by_race JSONB;
    v_by_level JSONB;
BEGIN
    -- Agency registry: (agency_id, agency_name, match_pattern for case_number)
    -- Stats: one row per agency using ILIKE against the embedded agency name.
    FOR r IN
        SELECT * FROM (VALUES
            ('pcso',           'Putnam County Sheriff''s Office',                    'PUTNAM COUNTY SHERIFF%'),
            ('palatka_pd',     'Palatka Police Department',                          'PALATKA POLICE DEPARTMENT%'),
            ('interlachen_pd', 'Interlachen Police Department',                      'INTERLACHEN POLICE DEPARTMENT%'),
            ('welaka_pd',      'Welaka Police Department',                           'WELAKA POLICE DEPARTMENT%'),
            ('school_pd',      'Putnam County School District Police Department',    'PUTNAM COUNTY SCHOOL%'),
            ('fhp',            'Florida Highway Patrol',                             'FLORIDA HIGHWAY PATROL%'),
            ('fwc',            'Florida Fish and Wildlife Conservation Commission',  'FLORIDA FISH AND WILDLIFE%')
        ) AS t(agency_id, agency_name, match_pattern)
    LOOP
        -- Distinct bookings that have at least one charge from this agency.
        WITH agency_bookings AS (
            SELECT DISTINCT c.booking_no
            FROM public.charges c
            WHERE substring(c.case_number FROM '\(([^)]+)\)') ILIKE r.match_pattern
        ),
        -- The actual booking rows for those bookings.
        b AS (
            SELECT bk.*
            FROM public.bookings bk
            INNER JOIN agency_bookings ab ON ab.booking_no = bk.booking_no
        ),
        -- Charges filed under this agency (for total_charges + level breakdown).
        ac AS (
            SELECT c.*
            FROM public.charges c
            WHERE substring(c.case_number FROM '\(([^)]+)\)') ILIKE r.match_pattern
        )
        SELECT
            (SELECT COUNT(*) FROM b),
            (SELECT COUNT(*) FROM ac),
            (SELECT COUNT(DISTINCT NULLIF(b.mni_no, '')) FROM b),
            COALESCE((
                SELECT jsonb_object_agg(year::TEXT, cnt) FROM (
                    SELECT EXTRACT(YEAR FROM b.booking_date)::INT AS year, COUNT(*) AS cnt
                    FROM b WHERE b.booking_date IS NOT NULL
                    GROUP BY EXTRACT(YEAR FROM b.booking_date)
                ) y
            ), '{}'::jsonb),
            COALESCE((
                SELECT jsonb_object_agg(g, cnt) FROM (
                    SELECT UPPER(TRIM(b.gender)) AS g, COUNT(*) AS cnt
                    FROM b WHERE b.gender IS NOT NULL AND TRIM(b.gender) <> ''
                    GROUP BY UPPER(TRIM(b.gender))
                ) g
            ), '{}'::jsonb),
            COALESCE((
                SELECT jsonb_object_agg(race, cnt) FROM (
                    SELECT UPPER(TRIM(b.race)) AS race, COUNT(*) AS cnt
                    FROM b WHERE b.race IS NOT NULL AND TRIM(b.race) <> ''
                    GROUP BY UPPER(TRIM(b.race))
                ) r
            ), '{}'::jsonb),
            COALESCE((
                SELECT jsonb_agg(jsonb_build_object(
                    'level', level_group,
                    'totalCount', total_count,
                    'byDegree', by_degree
                ) ORDER BY total_count DESC)
                FROM (
                    SELECT
                        level_group,
                        SUM(cnt)::INT AS total_count,
                        jsonb_object_agg(degree_group, cnt) AS by_degree
                    FROM (
                        SELECT
                            COALESCE(NULLIF(UPPER(TRIM(ac.level)), ''), 'UNKNOWN') AS level_group,
                            COALESCE(NULLIF(UPPER(TRIM(ac.degree)), ''), 'UNKNOWN') AS degree_group,
                            COUNT(*) AS cnt
                        FROM ac
                        GROUP BY level_group, degree_group
                    ) per_cell
                    GROUP BY level_group
                ) per_level
            ), '[]'::jsonb)
        INTO v_total_bookings, v_total_charges, v_unique_persons,
             v_by_year, v_by_gender, v_by_race, v_by_level;

        INSERT INTO public.agency_stats (
            agency_id, agency_name, total_bookings, total_charges, unique_persons,
            average_charges_per_booking,
            bookings_by_year, bookings_by_gender, bookings_by_race,
            charges_by_level_and_degree, calculated_at
        ) VALUES (
            r.agency_id,
            r.agency_name,
            v_total_bookings,
            v_total_charges,
            v_unique_persons,
            CASE WHEN v_total_bookings > 0
                THEN ROUND(v_total_charges::NUMERIC / v_total_bookings, 2)
                ELSE 0 END,
            v_by_year, v_by_gender, v_by_race, v_by_level,
            NOW()
        );
    END LOOP;
END;
$$;
