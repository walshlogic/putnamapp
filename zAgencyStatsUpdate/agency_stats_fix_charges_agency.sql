-- =====================================================
-- FIX AGENCY STATS UNDERCOUNT (ADD AGENCY TO CHARGES)
-- =====================================================
-- 1) Add agency column to charges table
-- 2) Backfill agency from existing view JSON (best-effort)
-- 3) Recreate recent_bookings_with_charges view to include agency
-- 4) Optional: validate counts after running
-- =====================================================

-- 1) Add agency column if missing
ALTER TABLE public.charges
ADD COLUMN IF NOT EXISTS agency text;

-- 2) Backfill agency from bookings.raw_card_text (best-effort)
-- This aligns charge_order with charge rows parsed from raw_card_text.
WITH charge_source AS (
  SELECT
    b.booking_no,
    m.ord AS charge_order,
    m.match[3] AS agency
  FROM public.bookings b
  CROSS JOIN LATERAL regexp_matches(
    b.raw_card_text,
    '(\\d+\\.\\d+(?:\\.\\d+)?[a-z]?)\\s+([^\\s]+)\\s+\\(([^)]+)\\)',
    'g'
  ) WITH ORDINALITY AS m(match, ord)
  WHERE b.raw_card_text IS NOT NULL
)
UPDATE public.charges c
SET agency = s.agency
FROM charge_source s
WHERE c.booking_no = s.booking_no
  AND c.charge_order = s.charge_order
  AND (c.agency IS NULL OR c.agency = '');

-- 2b) Backfill agency from case_number if it contains "(AGENCY NAME)"
-- Also normalize common abbreviations to match app search terms.
WITH extracted AS (
  SELECT
    booking_no,
    charge_order,
    NULLIF(trim(both ' ' from regexp_replace(case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') AS raw_agency
  FROM public.charges
  WHERE case_number ~ '\\([^)]*\\)'
)
UPDATE public.charges c
SET agency = CASE
  WHEN e.raw_agency IN ('PCS', 'PCSO') THEN 'PUTNAM COUNTY SHERIFF'
  WHEN e.raw_agency IN ('PPD') THEN 'PALATKA POLICE DEPARTMENT'
  WHEN e.raw_agency IN ('IPD') THEN 'INTERLACHEN POLICE DEPARTMENT'
  WHEN e.raw_agency IN ('WPD') THEN 'WELAKA POLICE DEPARTMENT'
  WHEN e.raw_agency IN ('FHP') THEN 'FLORIDA HIGHWAY PATROL'
  WHEN e.raw_agency IN ('FWC') THEN 'FISH AND WILDLIFE'
  WHEN e.raw_agency ILIKE '%PUTNAM COUNTY SHERIFF%' THEN 'PUTNAM COUNTY SHERIFF'
  WHEN e.raw_agency ILIKE '%PALATKA POLICE%' THEN 'PALATKA POLICE DEPARTMENT'
  WHEN e.raw_agency ILIKE '%INTERLACHEN POLICE%' THEN 'INTERLACHEN POLICE DEPARTMENT'
  WHEN e.raw_agency ILIKE '%WELAKA POLICE%' THEN 'WELAKA POLICE DEPARTMENT'
  WHEN e.raw_agency ILIKE '%FLORIDA HIGHWAY PATROL%' THEN 'FLORIDA HIGHWAY PATROL'
  WHEN e.raw_agency ILIKE '%FISH AND WILDLIFE%' THEN 'FISH AND WILDLIFE'
  ELSE e.raw_agency
END
FROM extracted e
WHERE c.booking_no = e.booking_no
  AND c.charge_order = e.charge_order
  AND (c.agency IS NULL OR c.agency = '');

-- 3) Recreate view with agency in charge JSON
DROP VIEW IF EXISTS public.recent_bookings_with_charges;
CREATE VIEW public.recent_bookings_with_charges AS
SELECT
  b.booking_no,
  b.mni_no,
  b.name,
  b.status,
  b.booking_date,
  b.age_on_booking_date,
  b.bond_amount,
  b.address_given,
  b.holds_text,
  b.photo_path,
  b.photo_url,
  b.raw_card_text,
  b.released_date,
  b.race,
  b.gender,
  b.inserted_at AS booked_at,
  COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'charge', c.charge,
        'statute', c.statute,
        'case_number', c.case_number,
        'agency', COALESCE(
          NULLIF(c.agency, ''),
          CASE
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') IN ('PCS', 'PCSO')
              THEN 'PUTNAM COUNTY SHERIFF'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') IN ('PPD')
              THEN 'PALATKA POLICE DEPARTMENT'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') IN ('IPD')
              THEN 'INTERLACHEN POLICE DEPARTMENT'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') IN ('WPD')
              THEN 'WELAKA POLICE DEPARTMENT'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') IN ('FHP')
              THEN 'FLORIDA HIGHWAY PATROL'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') IN ('FWC')
              THEN 'FISH AND WILDLIFE'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') ILIKE '%PUTNAM COUNTY SHERIFF%'
              THEN 'PUTNAM COUNTY SHERIFF'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') ILIKE '%PALATKA POLICE%'
              THEN 'PALATKA POLICE DEPARTMENT'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') ILIKE '%INTERLACHEN POLICE%'
              THEN 'INTERLACHEN POLICE DEPARTMENT'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') ILIKE '%WELAKA POLICE%'
              THEN 'WELAKA POLICE DEPARTMENT'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') ILIKE '%FLORIDA HIGHWAY PATROL%'
              THEN 'FLORIDA HIGHWAY PATROL'
            WHEN NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '') ILIKE '%FISH AND WILDLIFE%'
              THEN 'FISH AND WILDLIFE'
            ELSE NULLIF(trim(both ' ' from regexp_replace(c.case_number, '^[^(]*\\(([^)]*)\\).*$', '\\1')), '')
          END
        ),
        'degree', c.degree,
        'level', c.level,
        'bond', c.bond
      )
      ORDER BY c.charge_order
    ) FILTER (WHERE (c.case_number IS NOT NULL OR c.charge IS NOT NULL)),
    '[]'::jsonb
  ) AS charges
FROM public.bookings b
LEFT JOIN public.charges c ON (b.booking_no = c.booking_no)
GROUP BY
  b.booking_no, b.mni_no, b.name, b.status, b.booking_date, b.age_on_booking_date,
  b.bond_amount, b.address_given, b.holds_text, b.photo_path, b.photo_url,
  b.raw_card_text,
  b.released_date, b.race, b.gender, b.inserted_at;

-- 4) Quick validation (optional)
-- SELECT COUNT(*) FROM public.charges WHERE agency IS NOT NULL AND agency <> '';
