-- Incident Log v2 schema changes:
--   1. incident_attachments.display_type (with CHECK + backfill from mime_type)
--   2. incidents.agency_ids text[] (replaces single agency_id column)
--   3. incidents.occurred_at -> date (no time component)
--   4. incident_persons junction table (replaces incidents.related_booking_no)
--   5. incident-media bucket allowed_mime_types expanded for audio
--
-- Idempotent where reasonable; uses IF NOT EXISTS / IF EXISTS so re-runs
-- don't fail. Data migration steps preserve everything from v1.

-- =============================================================
-- 1) incident_attachments.display_type
-- =============================================================
ALTER TABLE public.incident_attachments
  ADD COLUMN IF NOT EXISTS display_type text;

-- Backfill from existing rows: derive from mime_type for files,
-- default to 'other' for URLs (user can re-tag).
UPDATE public.incident_attachments SET display_type =
  CASE
    WHEN mime_type LIKE 'video/%'         THEN 'video'
    WHEN mime_type LIKE 'audio/%'         THEN 'audio'
    WHEN mime_type LIKE 'image/%'         THEN 'image'
    WHEN mime_type = 'application/pdf'    THEN 'document'
    WHEN url ILIKE '%youtube.com%' OR
         url ILIKE '%youtu.be%' OR
         url ILIKE '%vimeo.com%'          THEN 'video'
    WHEN url ILIKE '%facebook.com%' OR
         url ILIKE '%twitter.com%' OR
         url ILIKE '%x.com%' OR
         url ILIKE '%instagram.com%' OR
         url ILIKE '%tiktok.com%'         THEN 'social'
    ELSE 'other'
  END
WHERE display_type IS NULL;

ALTER TABLE public.incident_attachments
  ALTER COLUMN display_type SET DEFAULT 'other';
ALTER TABLE public.incident_attachments
  ALTER COLUMN display_type SET NOT NULL;

-- CHECK constraint — drop first in case re-running
ALTER TABLE public.incident_attachments
  DROP CONSTRAINT IF EXISTS incident_attachments_display_type_check;
ALTER TABLE public.incident_attachments
  ADD CONSTRAINT incident_attachments_display_type_check
  CHECK (display_type IN ('video','audio','image','document','news','social','other'));

-- =============================================================
-- 2) incidents.agency_ids text[]  (replaces agency_id)
-- =============================================================
ALTER TABLE public.incidents
  ADD COLUMN IF NOT EXISTS agency_ids text[] NOT NULL DEFAULT '{}';

-- Migrate existing single agency_id values into the array.
UPDATE public.incidents
   SET agency_ids = ARRAY[agency_id]
 WHERE agency_id IS NOT NULL AND array_length(agency_ids, 1) IS NULL;

-- Drop the old single-value column + its index.
DROP INDEX IF EXISTS public.incidents_agency_id_idx;
ALTER TABLE public.incidents DROP COLUMN IF EXISTS agency_id;

-- New GIN index supports `'pcso' = ANY(agency_ids)` lookups.
CREATE INDEX IF NOT EXISTS incidents_agency_ids_idx
  ON public.incidents USING GIN (agency_ids);

-- =============================================================
-- 3) incidents.occurred_at -> date
-- =============================================================
-- Drop the partial index that references the old column type, alter the
-- column, then recreate the index.
DROP INDEX IF EXISTS public.incidents_occurred_at_idx;
ALTER TABLE public.incidents
  ALTER COLUMN occurred_at TYPE date USING (occurred_at::date);
CREATE INDEX incidents_occurred_at_idx
  ON public.incidents (occurred_at DESC)
  WHERE is_active = true;

-- =============================================================
-- 4) incident_persons junction table  (replaces related_booking_no)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.incident_persons (
  id           uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id  uuid          NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  booking_no   text,
  mni_no       text,
  label        text,                                              -- free-form: "John Doe — driver", "Jane Smith — witness"
  sort_order   integer       NOT NULL DEFAULT 0,
  created_at   timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT incident_persons_at_least_one_id_or_label
    CHECK (booking_no IS NOT NULL OR mni_no IS NOT NULL OR label IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS incident_persons_incident_id_idx
  ON public.incident_persons (incident_id, sort_order);
CREATE INDEX IF NOT EXISTS incident_persons_booking_no_idx
  ON public.incident_persons (booking_no)
  WHERE booking_no IS NOT NULL;
CREATE INDEX IF NOT EXISTS incident_persons_mni_no_idx
  ON public.incident_persons (mni_no)
  WHERE mni_no IS NOT NULL;

ALTER TABLE public.incident_persons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read persons of active incidents"
  ON public.incident_persons;
DROP POLICY IF EXISTS "Admins can read all persons" ON public.incident_persons;
DROP POLICY IF EXISTS "Admins can insert persons"  ON public.incident_persons;
DROP POLICY IF EXISTS "Admins can update persons"  ON public.incident_persons;
DROP POLICY IF EXISTS "Admins can delete persons"  ON public.incident_persons;

CREATE POLICY "Public can read persons of active incidents"
  ON public.incident_persons FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.incidents i
      WHERE i.id = incident_persons.incident_id AND i.is_active = true
    )
  );

CREATE POLICY "Admins can read all persons"
  ON public.incident_persons FOR SELECT
  TO authenticated
  USING (public.is_elevated_or_admin());

CREATE POLICY "Admins can insert persons"
  ON public.incident_persons FOR INSERT
  TO authenticated
  WITH CHECK (public.is_elevated_or_admin());

CREATE POLICY "Admins can update persons"
  ON public.incident_persons FOR UPDATE
  TO authenticated
  USING       (public.is_elevated_or_admin())
  WITH CHECK  (public.is_elevated_or_admin());

CREATE POLICY "Admins can delete persons"
  ON public.incident_persons FOR DELETE
  TO authenticated
  USING (public.is_elevated_or_admin());

-- Migrate the old related_booking_no values into incident_persons rows.
INSERT INTO public.incident_persons (incident_id, booking_no, sort_order)
SELECT id, related_booking_no, 0
FROM public.incidents
WHERE related_booking_no IS NOT NULL AND related_booking_no <> ''
ON CONFLICT DO NOTHING;

-- Drop the old single-value column.
ALTER TABLE public.incidents DROP COLUMN IF EXISTS related_booking_no;

-- =============================================================
-- 5) Expand incident-media bucket MIME types to include audio
-- =============================================================
UPDATE storage.buckets
SET allowed_mime_types = ARRAY[
  'image/jpeg','image/png','image/heic','image/webp',
  'video/mp4','video/quicktime','video/x-m4v',
  'audio/mpeg','audio/mp4','audio/wav','audio/x-wav','audio/x-m4a','audio/aac',
  'application/pdf'
]
WHERE id = 'incident-media';
