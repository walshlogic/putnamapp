-- Places directory schema.
-- Tables: places, place_reviews, user_favorites.
-- RPC:    increment_place_views(place_id_param uuid).
-- All RLS-enabled. Anon/authenticated reads on public-facing rows;
-- writes restricted to row owner via auth.uid().

-- ============================================================
-- shared utility: updated_at auto-bump trigger function
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- ============================================================
-- places
-- ============================================================
CREATE TABLE public.places (
  id                  uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  name                text          NOT NULL,
  category            text          NOT NULL CHECK (category IN (
                        'restaurant','retail','faith','entertainment',
                        'lodging','services','health','business','outdoors')),
  subcategory         text,
  description         text,
  address             text,
  city                text          NOT NULL DEFAULT 'Palatka',
  state               text          NOT NULL DEFAULT 'FL',
  zip_code            text,
  phone               text,
  email               text,
  website             text,
  latitude            double precision,
  longitude           double precision,
  hours               jsonb,
  price_range         text          CHECK (price_range IS NULL OR price_range IN ('$','$$','$$$','$$$$')),
  logo_url            text,
  cover_photo_url     text,
  photo_urls          text[]        NOT NULL DEFAULT '{}',
  is_verified         boolean       NOT NULL DEFAULT false,
  is_active           boolean       NOT NULL DEFAULT true,
  view_count          integer       NOT NULL DEFAULT 0,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  updated_at          timestamptz   NOT NULL DEFAULT now()
);

CREATE INDEX places_category_active_idx
  ON public.places (category)
  WHERE is_active = true;

CREATE INDEX places_is_active_idx
  ON public.places (is_active)
  WHERE is_active = true;

CREATE TRIGGER places_set_updated_at
  BEFORE UPDATE ON public.places
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.places ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read active places"
  ON public.places
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- INSERT/UPDATE/DELETE: no public policies. service_role bypasses RLS,
-- so admin writes happen via the Management API or service-role client.

-- ============================================================
-- place_reviews
-- ============================================================
CREATE TABLE public.place_reviews (
  id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id        uuid          NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
  user_id         uuid          NOT NULL REFERENCES auth.users(id)    ON DELETE CASCADE,
  rating          integer       NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title           text,
  comment         text          NOT NULL,
  photo_urls      text[]        NOT NULL DEFAULT '{}',
  is_approved     boolean       NOT NULL DEFAULT false,
  is_flagged      boolean       NOT NULL DEFAULT false,
  flag_reason     text,
  helpful_count   integer       NOT NULL DEFAULT 0,
  created_at      timestamptz   NOT NULL DEFAULT now(),
  updated_at      timestamptz   NOT NULL DEFAULT now()
);

CREATE INDEX place_reviews_place_approved_idx
  ON public.place_reviews (place_id)
  WHERE is_approved = true;

CREATE INDEX place_reviews_user_id_idx
  ON public.place_reviews (user_id);

CREATE TRIGGER place_reviews_set_updated_at
  BEFORE UPDATE ON public.place_reviews
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.place_reviews ENABLE ROW LEVEL SECURITY;

-- Public can read approved reviews only.
CREATE POLICY "Public can read approved reviews"
  ON public.place_reviews
  FOR SELECT
  TO anon, authenticated
  USING (is_approved = true);

-- Signed-in users can read their OWN reviews regardless of approval state
-- (so the reviewer sees their own submission while it's pending moderation).
CREATE POLICY "Users can read own reviews"
  ON public.place_reviews
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Signed-in users can submit reviews under their own user_id.
CREATE POLICY "Users can insert own reviews"
  ON public.place_reviews
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Signed-in users can edit their own reviews while pending.
CREATE POLICY "Users can update own pending reviews"
  ON public.place_reviews
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id AND is_approved = false)
  WITH CHECK (auth.uid() = user_id);

-- Signed-in users can delete their own reviews.
CREATE POLICY "Users can delete own reviews"
  ON public.place_reviews
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================
-- user_favorites
-- ============================================================
CREATE TABLE public.user_favorites (
  id          uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid          NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  place_id    uuid          NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
  created_at  timestamptz   NOT NULL DEFAULT now(),
  UNIQUE (user_id, place_id)
);

CREATE INDEX user_favorites_user_id_idx ON public.user_favorites (user_id);
CREATE INDEX user_favorites_place_id_idx ON public.user_favorites (place_id);

ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

-- Users can only see / modify their own favorites.
CREATE POLICY "Users read own favorites"
  ON public.user_favorites FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own favorites"
  ON public.user_favorites FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users delete own favorites"
  ON public.user_favorites FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================
-- increment_place_views RPC
-- ============================================================
-- SECURITY DEFINER so anon/authenticated can bump view_count without
-- needing direct UPDATE on places.view_count. Locked down via REVOKE
-- FROM PUBLIC + explicit GRANT (anon + authenticated).
CREATE OR REPLACE FUNCTION public.increment_place_views(place_id_param uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.places
     SET view_count = view_count + 1
   WHERE id = place_id_param
     AND is_active = true;
$$;

REVOKE EXECUTE ON FUNCTION public.increment_place_views(uuid) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.increment_place_views(uuid) TO anon, authenticated;
