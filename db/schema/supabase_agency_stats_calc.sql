-- Per-agency 5-year statistics, written into public.agency_stats.
-- Matches the structure the Flutter AgencyStatsRepository expects:
--   total_bookings, total_charges, unique_persons, average_charges_per_booking,
--   bookings_by_year (jsonb), bookings_by_gender (jsonb), bookings_by_race (jsonb),
--   charges_by_level_and_degree (jsonb array of {level, totalCount, byDegree})
--
-- Replaces the deleted zAgencyStatsUpdate/calculate_agency_stats.py. Same logic,
-- runs server-side, no Python dependency. Truncates and rewrites in one
-- transaction so each call leaves exactly one row per agency.

CREATE OR REPLACE FUNCTION public.calculate_agency_stats()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_now        timestamptz := now();
  v_start_date date        := make_date(EXTRACT(YEAR FROM now())::int - 4, 1, 1);
  agency       record;
BEGIN
  TRUNCATE TABLE public.agency_stats RESTART IDENTITY;

  FOR agency IN
    SELECT * FROM (VALUES
      ('pcso',           'PUTNAM COUNTY SHERIFF''S OFFICE',                         'PUTNAM COUNTY SHERIFF'),
      ('palatka_pd',     'PALATKA POLICE DEPARTMENT',                               'PALATKA POLICE DEPARTMENT'),
      ('interlachen_pd', 'INTERLACHEN POLICE DEPARTMENT',                           'INTERLACHEN POLICE DEPARTMENT'),
      ('welaka_pd',      'WELAKA POLICE DEPARTMENT',                                'WELAKA POLICE DEPARTMENT'),
      ('school_pd',      'PUTNAM COUNTY SCHOOL DISTRICT POLICE DEPARTMENT',         'SCHOOL DISTRICT POLICE'),
      ('fhp',            'FLORIDA HIGHWAY PATROL',                                  'FLORIDA HIGHWAY PATROL'),
      ('fwc',            'FLORIDA FISH AND WILDLIFE CONSERVATION COMMISSION (FWC)', 'FISH AND WILDLIFE')
    ) AS t(id, name, search)
  LOOP
    INSERT INTO public.agency_stats (
      agency_id, agency_name,
      total_bookings, total_charges, unique_persons, average_charges_per_booking,
      bookings_by_year, bookings_by_gender, bookings_by_race,
      charges_by_level_and_degree,
      calculated_at
    )
    WITH agency_bookings AS (
      SELECT b.booking_no, b.name, b.gender, b.race, b.booking_date, b.charges
      FROM public.recent_bookings_with_charges b
      WHERE b.booking_date::date >= v_start_date
        AND EXISTS (
          SELECT 1
          FROM jsonb_array_elements(coalesce(b.charges, '[]'::jsonb)) c
          WHERE upper(coalesce(c->>'agency', '')) LIKE '%' || upper(agency.search) || '%'
             OR upper(coalesce(c->>'case_number', '')) LIKE '%' || upper(agency.search) || '%'
        )
    ),
    matching_charges AS (
      SELECT c
      FROM agency_bookings b,
           jsonb_array_elements(coalesce(b.charges, '[]'::jsonb)) AS c
      WHERE upper(coalesce(c->>'agency', '')) LIKE '%' || upper(agency.search) || '%'
         OR upper(coalesce(c->>'case_number', '')) LIKE '%' || upper(agency.search) || '%'
    ),
    totals AS (
      SELECT
        (SELECT count(*) FROM agency_bookings)                                    AS total_bookings,
        (SELECT count(DISTINCT nullif(trim(name), '')) FROM agency_bookings)      AS unique_persons,
        (SELECT count(*) FROM matching_charges)                                   AS total_charges
    ),
    year_agg AS (
      SELECT coalesce(jsonb_object_agg(yr::text, cnt), '{}'::jsonb) AS j
      FROM (
        SELECT EXTRACT(YEAR FROM booking_date)::int AS yr, count(*) AS cnt
        FROM agency_bookings GROUP BY yr
      ) y
    ),
    gender_agg AS (
      SELECT coalesce(jsonb_object_agg(g, cnt), '{}'::jsonb) AS j
      FROM (
        SELECT coalesce(nullif(upper(trim(gender)), ''), 'UNKNOWN') AS g, count(*) AS cnt
        FROM agency_bookings GROUP BY g
      ) gg
    ),
    race_agg AS (
      SELECT coalesce(jsonb_object_agg(r, cnt), '{}'::jsonb) AS j
      FROM (
        SELECT
          CASE upper(trim(coalesce(race, '')))
            WHEN 'B' THEN 'BLACK'
            WHEN 'W' THEN 'WHITE'
            WHEN 'H' THEN 'HISPANIC'
            WHEN 'A' THEN 'ASIAN'
            WHEN 'I' THEN 'NATIVE AMERICAN'
            WHEN ''  THEN 'UNKNOWN'
            ELSE upper(trim(race))
          END AS r,
          count(*) AS cnt
        FROM agency_bookings GROUP BY r
      ) rr
    ),
    level_degree_agg AS (
      SELECT coalesce(
        jsonb_agg(jsonb_build_object(
          'level', level,
          'totalCount', total_count,
          'byDegree', by_degree
        )),
        '[]'::jsonb
      ) AS j
      FROM (
        SELECT
          level,
          sum(cnt) AS total_count,
          jsonb_object_agg(degree, cnt) AS by_degree
        FROM (
          SELECT
            CASE upper(coalesce(c->>'level', ''))
              WHEN 'F' THEN 'FELONY'
              WHEN 'M' THEN 'MISDEMEANOR'
              WHEN ''  THEN 'UNKNOWN'
              ELSE upper(c->>'level')
            END AS level,
            coalesce(nullif(upper(trim(c->>'degree')), ''), 'UNKNOWN') AS degree,
            count(*) AS cnt
          FROM matching_charges
          GROUP BY level, degree
        ) ld
        GROUP BY level
      ) per_level
    )
    SELECT
      agency.id, agency.name,
      t.total_bookings, t.total_charges, t.unique_persons,
      CASE WHEN t.total_bookings > 0
        THEN round(t.total_charges::numeric / t.total_bookings::numeric, 2)
        ELSE 0
      END,
      year_agg.j, gender_agg.j, race_agg.j,
      level_degree_agg.j,
      v_now
    FROM totals t, year_agg, gender_agg, race_agg, level_degree_agg;
  END LOOP;
END;
$$;

-- Lock down: cron + service_role only. Anon/authenticated should NEVER trigger
-- a 5-year recompute via REST. (Same pattern we use for calculate_top_100_lists.)
REVOKE EXECUTE ON FUNCTION public.calculate_agency_stats() FROM PUBLIC, anon, authenticated;

-- Schedule daily at 4:30 AM (30 min after Top 100 refresh at 4:00).
-- Idempotent: drop any prior schedule, then re-add.
SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname = 'refresh-agency-stats';
SELECT cron.schedule(
  'refresh-agency-stats',
  '30 4 * * *',
  $cron$ SELECT public.calculate_agency_stats(); $cron$
);
