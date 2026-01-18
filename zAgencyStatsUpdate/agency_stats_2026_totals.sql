-- =====================================================
-- AGENCY BOOKING TOTALS (2026)
-- =====================================================
-- Counts distinct bookings per agency for 2026, using
-- recent_bookings_with_charges JSON (agency field).
-- =====================================================

WITH charges_expanded AS (
  SELECT
    b.booking_no,
    b.booking_date,
    (charge->>'agency') AS agency
  FROM public.recent_bookings_with_charges b
  CROSS JOIN LATERAL jsonb_array_elements(b.charges) AS charge
  WHERE b.booking_date >= '2026-01-01'::date
    AND b.booking_date < '2027-01-01'::date
),
normalized AS (
  SELECT
    booking_no,
    CASE
      WHEN agency ILIKE '%PUTNAM COUNTY SHERIFF%' THEN 'pcso'
      WHEN agency ILIKE '%PALATKA POLICE%' THEN 'palatka_pd'
      WHEN agency ILIKE '%INTERLACHEN POLICE%' THEN 'interlachen_pd'
      WHEN agency ILIKE '%WELAKA POLICE%' THEN 'welaka_pd'
      WHEN agency ILIKE '%SCHOOL DISTRICT POLICE%' THEN 'school_pd'
      WHEN agency ILIKE '%FLORIDA HIGHWAY PATROL%' THEN 'fhp'
      WHEN agency ILIKE '%FISH AND WILDLIFE%' THEN 'fwc'
      ELSE NULL
    END AS agency_id
  FROM charges_expanded
  WHERE agency IS NOT NULL AND agency <> ''
)
SELECT
  agency_id,
  COUNT(DISTINCT booking_no) AS total_bookings_2026
FROM normalized
WHERE agency_id IS NOT NULL
GROUP BY agency_id
ORDER BY agency_id;
