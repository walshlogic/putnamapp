-- Incident Log feature.
-- Adds: user_roles + role-helper functions, incidents, incident_attachments,
-- and the 'incident-media' storage bucket. Public read; admin/elevated write.
-- Seeds the project owner (will.walsh@walshlogic.com) as the first admin.

-- =============================================================
-- user_roles + role helpers
-- =============================================================
CREATE TABLE public.user_roles (
  user_id     uuid          PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role        text          NOT NULL CHECK (role IN ('admin','elevated')),
  granted_at  timestamptz   NOT NULL DEFAULT now(),
  granted_by  uuid          REFERENCES auth.users(id) ON DELETE SET NULL,
  notes       text
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- A user can read their OWN role row (so the app can ask "am I admin?").
-- They can't see anyone else's row.
CREATE POLICY "Users can read own role"
  ON public.user_roles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- No public INSERT/UPDATE/DELETE policies. Role assignment goes through
-- the dashboard / Management API as service_role.

-- Helper: is the given user (defaults to current caller) an admin?
CREATE OR REPLACE FUNCTION public.is_admin(p_user_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_user_id AND role = 'admin'
  );
$$;

-- Helper: is the given user elevated OR admin? Used by RLS on incidents
-- so the elevated-user group can be granted later without rewriting policies.
CREATE OR REPLACE FUNCTION public.is_elevated_or_admin(p_user_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_user_id AND role IN ('admin','elevated')
  );
$$;

-- Lock down: callable by signed-in users (so they can check their own role
-- via RPC) but never by anon. SECURITY DEFINER bypasses user_roles RLS so
-- callers don't need direct SELECT on the table.
REVOKE EXECUTE ON FUNCTION public.is_admin(uuid)             FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.is_elevated_or_admin(uuid) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.is_admin(uuid)             TO authenticated;
GRANT  EXECUTE ON FUNCTION public.is_elevated_or_admin(uuid) TO authenticated;

-- =============================================================
-- incidents
-- =============================================================
CREATE TABLE public.incidents (
  id                  uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  title               text          NOT NULL,
  description         text          NOT NULL,
  occurred_at         timestamptz   NOT NULL,
  location_text       text          NOT NULL,
  latitude            double precision,
  longitude           double precision,
  category            text,                                    -- free-form for v1; e.g. 'officer_involved_shooting', 'use_of_force', 'traffic_incident', 'community_event', 'fire', 'weather'
  agency_id           text,                                    -- matches agency_stats.agency_id values ('pcso', 'palatka_pd', etc.) — optional
  related_booking_no  text,                                    -- optional pointer to public.bookings.booking_no
  is_active           boolean       NOT NULL DEFAULT true,
  created_by          uuid          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  updated_at          timestamptz   NOT NULL DEFAULT now()
);

CREATE INDEX incidents_occurred_at_idx ON public.incidents (occurred_at DESC) WHERE is_active = true;
CREATE INDEX incidents_category_idx    ON public.incidents (category)         WHERE is_active = true;
CREATE INDEX incidents_agency_id_idx   ON public.incidents (agency_id)        WHERE is_active = true;

CREATE TRIGGER incidents_set_updated_at
  BEFORE UPDATE ON public.incidents
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;

-- Public read: active incidents visible to anon + authenticated.
CREATE POLICY "Public can read active incidents"
  ON public.incidents FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Admins/elevated can read soft-deleted rows too.
CREATE POLICY "Admins can read all incidents"
  ON public.incidents FOR SELECT
  TO authenticated
  USING (public.is_elevated_or_admin());

-- Admin/elevated writes only. INSERT also requires created_by = auth.uid()
-- so an admin can't impersonate another user.
CREATE POLICY "Admins can insert incidents"
  ON public.incidents FOR INSERT
  TO authenticated
  WITH CHECK (public.is_elevated_or_admin() AND created_by = auth.uid());

CREATE POLICY "Admins can update incidents"
  ON public.incidents FOR UPDATE
  TO authenticated
  USING       (public.is_elevated_or_admin())
  WITH CHECK  (public.is_elevated_or_admin());

CREATE POLICY "Admins can delete incidents"
  ON public.incidents FOR DELETE
  TO authenticated
  USING (public.is_elevated_or_admin());

-- =============================================================
-- incident_attachments — one row per video/file/external link
-- =============================================================
CREATE TABLE public.incident_attachments (
  id            uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id   uuid          NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  kind          text          NOT NULL CHECK (kind IN ('url','file')),
  title         text,                                          -- display label
  url           text          NOT NULL,                        -- external URL when kind='url'; public-bucket URL when kind='file'
  bucket_path   text,                                          -- only set when kind='file' — path inside the 'incident-media' bucket
  mime_type     text,                                          -- only set when kind='file'
  file_size     bigint,                                        -- only set when kind='file' (bytes)
  sort_order    integer       NOT NULL DEFAULT 0,
  created_at    timestamptz   NOT NULL DEFAULT now()
);

CREATE INDEX incident_attachments_incident_id_idx
  ON public.incident_attachments (incident_id, sort_order);

ALTER TABLE public.incident_attachments ENABLE ROW LEVEL SECURITY;

-- Public can read attachments of active incidents.
CREATE POLICY "Public can read attachments of active incidents"
  ON public.incident_attachments FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.incidents i
      WHERE i.id = incident_attachments.incident_id AND i.is_active = true
    )
  );

CREATE POLICY "Admins can read all attachments"
  ON public.incident_attachments FOR SELECT
  TO authenticated
  USING (public.is_elevated_or_admin());

CREATE POLICY "Admins can insert attachments"
  ON public.incident_attachments FOR INSERT
  TO authenticated
  WITH CHECK (public.is_elevated_or_admin());

CREATE POLICY "Admins can update attachments"
  ON public.incident_attachments FOR UPDATE
  TO authenticated
  USING       (public.is_elevated_or_admin())
  WITH CHECK  (public.is_elevated_or_admin());

CREATE POLICY "Admins can delete attachments"
  ON public.incident_attachments FOR DELETE
  TO authenticated
  USING (public.is_elevated_or_admin());

-- =============================================================
-- Storage bucket: incident-media
-- =============================================================
-- Public bucket so URLs in incident_attachments.url work without signing.
-- 500 MB per-file limit (incident videos can be large).
-- Allowed MIME types: common photo and video formats + PDF for police reports.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'incident-media',
  'incident-media',
  true,
  524288000,
  ARRAY[
    'image/jpeg','image/png','image/heic','image/webp',
    'video/mp4','video/quicktime','video/x-m4v',
    'application/pdf'
  ]
)
ON CONFLICT (id) DO NOTHING;

-- We deliberately do NOT add a SELECT policy on storage.objects for this
-- bucket — public buckets serve files via /storage/v1/object/public/... URLs
-- which bypass RLS. Adding a broad SELECT trips advisor lint 0025.
CREATE POLICY "Admins can upload incident media"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'incident-media' AND public.is_elevated_or_admin());

CREATE POLICY "Admins can update incident media"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING       (bucket_id = 'incident-media' AND public.is_elevated_or_admin())
  WITH CHECK  (bucket_id = 'incident-media' AND public.is_elevated_or_admin());

CREATE POLICY "Admins can delete incident media"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'incident-media' AND public.is_elevated_or_admin());

-- =============================================================
-- Seed: make the project owner the first admin
-- =============================================================
INSERT INTO public.user_roles (user_id, role, granted_by, notes)
VALUES (
  '805231d8-f18a-4753-8b70-18dfe145fa5e',  -- will.walsh@walshlogic.com
  'admin',
  '805231d8-f18a-4753-8b70-18dfe145fa5e',
  'Initial admin (project owner)'
)
ON CONFLICT (user_id) DO UPDATE SET role = EXCLUDED.role;
