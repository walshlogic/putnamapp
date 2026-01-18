-- =====================================================
-- PALATKA 2026 DEBUG QUERIES
-- =====================================================

-- 1) List distinct Palatka booking numbers counted by the view (2026)
WITH palatka AS (
  SELECT DISTINCT b.booking_no
  FROM public.recent_bookings_with_charges b
  CROSS JOIN LATERAL jsonb_array_elements(b.charges) AS c
  WHERE b.booking_date >= '2026-01-01'::date
    AND b.booking_date < '2027-01-01'::date
    AND (
      c->>'agency' ILIKE '%PALATKA POLICE%'
      OR c->>'case_number' ILIKE '%PALATKA POLICE%'
    )
)
SELECT booking_no
FROM palatka
ORDER BY booking_no;

-- 2) Bookings whose raw_card_text mentions Palatka but charges JSON does not
WITH raw_mentions AS (
  SELECT booking_no
  FROM public.recent_bookings_with_charges
  WHERE booking_date >= '2026-01-01'::date
    AND booking_date < '2027-01-01'::date
    AND raw_card_text ILIKE '%PALATKA POLICE%'
),
json_mentions AS (
  SELECT DISTINCT b.booking_no
  FROM public.recent_bookings_with_charges b
  CROSS JOIN LATERAL jsonb_array_elements(b.charges) AS c
  WHERE b.booking_date >= '2026-01-01'::date
    AND b.booking_date < '2027-01-01'::date
    AND (
      c->>'agency' ILIKE '%PALATKA POLICE%'
      OR c->>'case_number' ILIKE '%PALATKA POLICE%'
    )
)
SELECT r.booking_no
FROM raw_mentions r
LEFT JOIN json_mentions j ON j.booking_no = r.booking_no
WHERE j.booking_no IS NULL
ORDER BY r.booking_no;
