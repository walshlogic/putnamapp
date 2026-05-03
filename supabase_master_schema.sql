-- ============================================================
-- PUTNAM.APP — MASTER DATABASE SCHEMA
-- ============================================================
-- Run this entire script in the Supabase SQL Editor
-- after creating a new project (Project Settings → SQL Editor).
--
-- Execution order matters. Run top to bottom as a single batch.
--
-- After this script completes, go to Storage in the dashboard
-- and create a PUBLIC bucket named: pcso-booking-photos
-- ============================================================


-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;


-- ============================================================
-- SECTION 1: USER PROFILES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_profiles (
  id                  uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email               text,
  display_name        text,
  avatar_url          text,
  subscription_tier   text        NOT NULL DEFAULT 'free',
  premium_expires_at  timestamptz,
  trial_started_at    timestamptz,
  comment_anonymous   boolean     NOT NULL DEFAULT false,
  app_user_id         text        NOT NULL DEFAULT upper(substr(encode(gen_random_bytes(5), 'hex'), 1, 10)),
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_profiles_app_user_id_unique UNIQUE (app_user_id)
);

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Service role manages all profiles"
  ON public.user_profiles FOR ALL TO service_role
  USING (true) WITH CHECK (true);

-- Auto-create profile row when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, display_name)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'display_name', new.email)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Prevent app_user_id from ever being changed
CREATE OR REPLACE FUNCTION public.prevent_app_user_id_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.app_user_id IS DISTINCT FROM OLD.app_user_id THEN
    RAISE EXCEPTION 'app_user_id is immutable';
  END IF;
  RETURN NEW;
END;
$$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'prevent_app_user_id_update'
  ) THEN
    CREATE TRIGGER prevent_app_user_id_update
      BEFORE UPDATE ON public.user_profiles
      FOR EACH ROW EXECUTE FUNCTION public.prevent_app_user_id_update();
  END IF;
END $$;


-- ============================================================
-- SECTION 2: BOOKINGS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.bookings (
  booking_no           text        PRIMARY KEY,
  mni_no               text,
  name                 text,
  race                 text,
  gender               text,
  status               text,
  booking_date         timestamptz,
  released_date        timestamptz,
  age_on_booking_date  integer,
  bond_amount          text,
  address_given        text,
  holds_text           text,
  photo_path           text,
  photo_url            text,
  raw_card_text        text,
  updated_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bookings_name         ON public.bookings(name);
CREATE INDEX IF NOT EXISTS idx_bookings_mni_no       ON public.bookings(mni_no);
CREATE INDEX IF NOT EXISTS idx_bookings_booking_date ON public.bookings(booking_date DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_status       ON public.bookings(status);

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read bookings"
  ON public.bookings FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Service role manages bookings"
  ON public.bookings FOR ALL TO service_role
  USING (true) WITH CHECK (true);


-- ============================================================
-- SECTION 3: CHARGES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.charges (
  id           bigserial   PRIMARY KEY,
  booking_no   text        NOT NULL REFERENCES public.bookings(booking_no) ON DELETE CASCADE,
  statute      text,
  case_number  text,
  charge       text,
  degree       text,
  level        text,       -- 'F' = Felony, 'M' = Misdemeanor
  bond         text,
  charge_order integer
);

CREATE INDEX IF NOT EXISTS idx_charges_booking_no ON public.charges(booking_no);
CREATE INDEX IF NOT EXISTS idx_charges_charge     ON public.charges(charge);
CREATE INDEX IF NOT EXISTS idx_charges_level      ON public.charges(level);

ALTER TABLE public.charges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read charges"
  ON public.charges FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Service role manages charges"
  ON public.charges FOR ALL TO service_role
  USING (true) WITH CHECK (true);


-- ============================================================
-- SECTION 4: SCRAPE RUNS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.scrape_runs (
  id                  bigserial   PRIMARY KEY,
  begin_date          text,
  end_date            text,
  ok                  boolean,
  finished_at         timestamptz DEFAULT now(),
  bookings_upserted   integer     DEFAULT 0,
  charges_written     integer     DEFAULT 0,
  error_text          text
);

ALTER TABLE public.scrape_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role manages scrape_runs"
  ON public.scrape_runs FOR ALL TO service_role
  USING (true) WITH CHECK (true);


-- ============================================================
-- SECTION 5: RECENT BOOKINGS WITH CHARGES VIEW
-- The primary view used by the app and all analytics functions.
-- ============================================================

CREATE OR REPLACE VIEW public.recent_bookings_with_charges AS
SELECT
  b.booking_no,
  b.mni_no,
  b.name,
  b.race,
  b.gender,
  b.status,
  b.booking_date,
  b.released_date,
  b.age_on_booking_date,
  b.bond_amount,
  b.address_given,
  b.holds_text,
  b.photo_url,
  b.updated_at,
  COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'statute',      c.statute,
        'case_number',  c.case_number,
        'charge',       c.charge,
        'degree',       c.degree,
        'level',        c.level,
        'bond',         c.bond,
        'charge_order', c.charge_order
      ) ORDER BY COALESCE(c.charge_order, 0)
    ) FILTER (WHERE c.id IS NOT NULL),
    '[]'::jsonb
  ) AS charges
FROM public.bookings b
LEFT JOIN public.charges c ON c.booking_no = b.booking_no
WHERE UPPER(COALESCE(b.name, '')) != 'ORDER, COURT EXPUNGED'
GROUP BY
  b.booking_no, b.mni_no, b.name, b.race, b.gender, b.status,
  b.booking_date, b.released_date, b.age_on_booking_date, b.bond_amount,
  b.address_given, b.holds_text, b.photo_url, b.updated_at;


-- ============================================================
-- SECTION 6: BOOKED PERSONS
-- Aggregated person-level stats, calculated by calculate_birth_dates.ts
-- ============================================================

CREATE TABLE IF NOT EXISTS public.booked_persons (
  name                text        PRIMARY KEY,
  mni_no              text,
  total_bookings      integer     DEFAULT 0,
  total_charges       integer     DEFAULT 0,
  first_booking_date  timestamptz,
  last_booking_date   timestamptz,
  birth_month_low     integer,
  birth_year_low      integer,
  birth_month_high    integer,
  birth_year_high     integer,
  race                text,
  gender              text,
  calculated_at       timestamptz DEFAULT now(),
  updated_at          timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_booked_persons_mni_no         ON public.booked_persons(mni_no);
CREATE INDEX IF NOT EXISTS idx_booked_persons_total_bookings ON public.booked_persons(total_bookings DESC);

ALTER TABLE public.booked_persons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read booked_persons"
  ON public.booked_persons FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Service role manages booked_persons"
  ON public.booked_persons FOR ALL TO service_role
  USING (true) WITH CHECK (true);


-- ============================================================
-- SECTION 7: TRAFFIC CITATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.traffic_citations (
  id                    bigserial   PRIMARY KEY,
  citation_date         date        NOT NULL,
  case_number           text        NOT NULL,
  full_case_number      text        NOT NULL,
  violation_description text        NOT NULL,
  license_plate         text,
  citation_number       text,
  check_digit           text,
  fine_amount           text,
  dl_state              text,
  last_name             text        NOT NULL,
  first_name            text        NOT NULL,
  middle_name           text,
  date_of_birth         date,
  gender                text,
  license_number        text,
  address               text,
  city                  text,
  state                 text,
  zip_code              text,
  disposition_date      date,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT traffic_citations_case_number_unique      UNIQUE (case_number),
  CONSTRAINT traffic_citations_full_case_number_unique UNIQUE (full_case_number)
);

CREATE INDEX IF NOT EXISTS idx_traffic_citations_citation_date  ON public.traffic_citations(citation_date DESC);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_last_name      ON public.traffic_citations(last_name);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_first_name     ON public.traffic_citations(first_name);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_license_plate  ON public.traffic_citations(license_plate);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_citation_number ON public.traffic_citations(citation_number);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_violation      ON public.traffic_citations(violation_description);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_city           ON public.traffic_citations(city);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_date_of_birth  ON public.traffic_citations(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_dl_state       ON public.traffic_citations(dl_state);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_name_search    ON public.traffic_citations(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_violation_search
  ON public.traffic_citations USING gin(to_tsvector('english', violation_description));

ALTER TABLE public.traffic_citations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read traffic citations"
  ON public.traffic_citations FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Service role manages traffic citations"
  ON public.traffic_citations FOR ALL TO service_role
  USING (true) WITH CHECK (true);

CREATE OR REPLACE FUNCTION update_traffic_citations_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_traffic_citations_updated_at ON public.traffic_citations;
CREATE TRIGGER update_traffic_citations_updated_at
  BEFORE UPDATE ON public.traffic_citations
  FOR EACH ROW EXECUTE FUNCTION update_traffic_citations_updated_at();


-- ============================================================
-- SECTION 8: CRIMINAL BACK HISTORY
-- ============================================================

CREATE TABLE IF NOT EXISTS public.criminal_back_history (
  id                              bigserial   PRIMARY KEY,
  case_number                     text        NOT NULL,
  uniform_case_number             text        NOT NULL,
  defendant_last_name             text        NOT NULL,
  defendant_first_name            text        NOT NULL,
  defendant_middle_name           text,
  date_of_birth                   date,
  address_line_1                  text,
  city                            text,
  state                           text,
  zipcode                         text,
  clerk_file_date                 date,
  pros_decision_date              date,
  court_decision_date             date,
  statute_description             text,
  court_action_description        text,
  prosecutor_action_description   text,
  created_at                      timestamptz NOT NULL DEFAULT now(),
  updated_at                      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT criminal_back_history_case_number_unique         UNIQUE (case_number),
  CONSTRAINT criminal_back_history_uniform_case_number_unique UNIQUE (uniform_case_number)
);

CREATE INDEX IF NOT EXISTS idx_criminal_back_history_last_name    ON public.criminal_back_history(defendant_last_name);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_first_name   ON public.criminal_back_history(defendant_first_name);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_dob          ON public.criminal_back_history(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_clerk_date   ON public.criminal_back_history(clerk_file_date DESC);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_city         ON public.criminal_back_history(city);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_name_search  ON public.criminal_back_history(defendant_last_name, defendant_first_name);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_statute_search
  ON public.criminal_back_history USING gin(to_tsvector('english', COALESCE(statute_description, '')));

ALTER TABLE public.criminal_back_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read criminal back history"
  ON public.criminal_back_history FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Service role manages criminal back history"
  ON public.criminal_back_history FOR ALL TO service_role
  USING (true) WITH CHECK (true);

CREATE OR REPLACE FUNCTION update_criminal_back_history_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_criminal_back_history_updated_at ON public.criminal_back_history;
CREATE TRIGGER update_criminal_back_history_updated_at
  BEFORE UPDATE ON public.criminal_back_history
  FOR EACH ROW EXECUTE FUNCTION update_criminal_back_history_updated_at();


-- ============================================================
-- SECTION 9: NEWS
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS public.news_sources (
  id          uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id   text    UNIQUE NOT NULL,
  name        text    NOT NULL,
  description text,
  url         text,
  category    text,
  language    text    DEFAULT 'en',
  country     text    DEFAULT 'us',
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

ALTER TABLE public.news_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read news sources"
  ON public.news_sources FOR SELECT USING (true);

CREATE POLICY "Service role manages news sources"
  ON public.news_sources FOR ALL
  USING (auth.role() = 'service_role');

DROP TRIGGER IF EXISTS update_news_sources_updated_at ON public.news_sources;
CREATE TRIGGER update_news_sources_updated_at
  BEFORE UPDATE ON public.news_sources
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE IF NOT EXISTS public.news_articles (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id    uuid        NOT NULL REFERENCES public.news_sources(id) ON DELETE CASCADE,
  external_id  text        NOT NULL,
  title        text        NOT NULL,
  description  text,
  content      text,
  url          text        NOT NULL,
  image_url    text,
  author       text,
  published_at timestamptz NOT NULL,
  category     text,
  tags         text[],
  language     text        DEFAULT 'en',
  country      text        DEFAULT 'us',
  fetched_at   timestamptz DEFAULT now(),
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now(),
  UNIQUE(source_id, external_id)
);

CREATE INDEX IF NOT EXISTS idx_news_articles_published_at ON public.news_articles(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_articles_category     ON public.news_articles(category);
CREATE INDEX IF NOT EXISTS idx_news_articles_source_id    ON public.news_articles(source_id);
CREATE INDEX IF NOT EXISTS idx_news_articles_tags         ON public.news_articles USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_news_articles_created_at   ON public.news_articles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_articles_search
  ON public.news_articles USING GIN(
    to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(description, ''))
  );

ALTER TABLE public.news_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read news articles"
  ON public.news_articles FOR SELECT USING (true);

CREATE POLICY "Service role manages news articles"
  ON public.news_articles FOR ALL
  USING (auth.role() = 'service_role');

DROP TRIGGER IF EXISTS update_news_articles_updated_at ON public.news_articles;
CREATE TRIGGER update_news_articles_updated_at
  BEFORE UPDATE ON public.news_articles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Seed the default NewsAPI source
INSERT INTO public.news_sources (source_id, name, description, url, category, language, country)
VALUES ('newsapi', 'NewsAPI', 'NewsAPI.org - Free news API', 'https://newsapi.org', 'general', 'en', 'us')
ON CONFLICT (source_id) DO NOTHING;


-- ============================================================
-- SECTION 10: BOOKING COMMENTS
-- (Includes all columns from both schema files in one pass)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.booking_comments (
  id                      uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_no              text        NOT NULL,
  booking_date            timestamptz,
  mni_no                  text,
  person_name             text        NOT NULL,
  user_id                 uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  comment                 text        NOT NULL,
  root_comment_id         uuid,
  parent_comment_id       uuid,
  is_published            boolean     NOT NULL DEFAULT true,
  edited_at               timestamptz,
  is_flagged              boolean     NOT NULL DEFAULT false,
  flag_reason             text,
  flagged_at              timestamptz,
  flagged_reviewed_at     timestamptz,
  flagged_review_outcome  text,
  created_at              timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.booking_comments
  ADD CONSTRAINT booking_comments_root_comment_fk
    FOREIGN KEY (root_comment_id) REFERENCES public.booking_comments(id)
    DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE public.booking_comments
  ADD CONSTRAINT booking_comments_parent_comment_fk
    FOREIGN KEY (parent_comment_id) REFERENCES public.booking_comments(id)
    DEFERRABLE INITIALLY DEFERRED;

CREATE INDEX IF NOT EXISTS booking_comments_mni_no_idx      ON public.booking_comments(mni_no);
CREATE INDEX IF NOT EXISTS booking_comments_person_name_idx ON public.booking_comments(person_name);
CREATE INDEX IF NOT EXISTS booking_comments_booking_no_idx  ON public.booking_comments(booking_no);
CREATE INDEX IF NOT EXISTS booking_comments_created_at_idx  ON public.booking_comments(created_at DESC);

ALTER TABLE public.booking_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "booking_comments_select_all"
  ON public.booking_comments FOR SELECT USING (true);

CREATE POLICY "booking_comments_insert_own"
  ON public.booking_comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "booking_comments_update_own"
  ON public.booking_comments FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "booking_comments_delete_own"
  ON public.booking_comments FOR DELETE
  USING (auth.uid() = user_id);

-- Auto-set root_comment_id on insert
CREATE OR REPLACE FUNCTION public.booking_comments_set_root_comment()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.id IS NULL THEN
    NEW.id := gen_random_uuid();
  END IF;
  IF NEW.root_comment_id IS NULL THEN
    NEW.root_comment_id := NEW.id;
  END IF;
  IF NEW.parent_comment_id IS NOT NULL AND NEW.edited_at IS NULL THEN
    NEW.edited_at := now();
  END IF;
  RETURN NEW;
END;
$$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'booking_comments_set_root_comment'
  ) THEN
    CREATE TRIGGER booking_comments_set_root_comment
      BEFORE INSERT ON public.booking_comments
      FOR EACH ROW EXECUTE FUNCTION public.booking_comments_set_root_comment();
  END IF;
END $$;

CREATE OR REPLACE VIEW public.booking_comments_latest AS
SELECT * FROM (
  SELECT DISTINCT ON (root_comment_id) *
  FROM public.booking_comments
  ORDER BY root_comment_id, created_at DESC
) AS latest
WHERE is_published = true;

-- Allows any authenticated user to report a comment
CREATE OR REPLACE FUNCTION public.report_booking_comment(
  p_comment_id uuid,
  p_reason text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.booking_comments
  SET is_flagged   = true,
      flag_reason  = p_reason,
      flagged_at   = now()
  WHERE id = p_comment_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.report_booking_comment(uuid, text) TO authenticated;


-- ============================================================
-- SECTION 11: TOP 100 LISTS
-- NOTE: time_range column added (was missing from original schema)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.top_100_lists (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  category      text        NOT NULL,
  time_range    text        NOT NULL DEFAULT 'ALL',  -- THISYEAR, 5YEARS, ALL
  rank          integer     NOT NULL CHECK (rank >= 1 AND rank <= 100),
  label         text        NOT NULL,
  count         integer     NOT NULL CHECK (count >= 0),
  subtitle      text,
  extra_data    jsonb,
  calculated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT unique_category_time_range_rank UNIQUE (category, time_range, rank, calculated_at)
);

CREATE INDEX IF NOT EXISTS idx_top_100_lists_category        ON public.top_100_lists(category);
CREATE INDEX IF NOT EXISTS idx_top_100_lists_category_rank   ON public.top_100_lists(category, rank);
CREATE INDEX IF NOT EXISTS idx_top_100_lists_calculated_at   ON public.top_100_lists(calculated_at DESC);
CREATE INDEX IF NOT EXISTS idx_top_100_lists_category_latest ON public.top_100_lists(category, calculated_at DESC);

ALTER TABLE public.top_100_lists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read top 100 lists"
  ON public.top_100_lists FOR SELECT TO public
  USING (true);


-- ============================================================
-- SECTION 13: CALCULATE TOP 100 LISTS FUNCTION
-- Calculates all lists for THISYEAR, 5YEARS, and ALL.
-- Call: SELECT calculate_top_100_lists();
-- Schedule twice daily via pg_cron.
-- ============================================================

CREATE OR REPLACE FUNCTION _calculate_category_for_time_range(
  p_category         TEXT,
  p_time_range       TEXT,
  p_start_date       DATE,
  p_calculation_time TIMESTAMPTZ
)
RETURNS void
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  CASE p_category
    WHEN 'arrested_persons' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT
        'arrested_persons', p_time_range,
        ROW_NUMBER() OVER (ORDER BY booking_count DESC)::integer,
        person_name, booking_count::integer, NULL,
        jsonb_build_object('name', person_name),
        p_calculation_time
      FROM (
        SELECT name AS person_name, COUNT(*) AS booking_count
        FROM public.recent_bookings_with_charges
        WHERE UPPER(name) != 'ORDER, COURT EXPUNGED'
          AND (p_start_date IS NULL OR booking_date >= p_start_date)
        GROUP BY name ORDER BY booking_count DESC LIMIT 100
      ) ranked;

    WHEN 'felony_charges' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT
        'felony_charges', p_time_range,
        ROW_NUMBER() OVER (ORDER BY charge_count DESC)::integer,
        charge_name, charge_count::integer, NULL,
        jsonb_build_object('charge', charge_name, 'level', 'FELONY'),
        p_calculation_time
      FROM (
        SELECT charge->>'charge' AS charge_name, COUNT(*) AS charge_count
        FROM public.recent_bookings_with_charges b,
             jsonb_array_elements(b.charges) AS charge
        WHERE charge->>'level' = 'F'
          AND charge->>'charge' IS NOT NULL AND charge->>'charge' != ''
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY charge->>'charge' ORDER BY charge_count DESC LIMIT 100
      ) ranked;

    WHEN 'misdemeanor_charges' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT
        'misdemeanor_charges', p_time_range,
        ROW_NUMBER() OVER (ORDER BY charge_count DESC)::integer,
        charge_name, charge_count::integer, NULL,
        jsonb_build_object('charge', charge_name, 'level', 'MISDEMEANOR'),
        p_calculation_time
      FROM (
        SELECT charge->>'charge' AS charge_name, COUNT(*) AS charge_count
        FROM public.recent_bookings_with_charges b,
             jsonb_array_elements(b.charges) AS charge
        WHERE charge->>'level' = 'M'
          AND charge->>'charge' IS NOT NULL AND charge->>'charge' != ''
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY charge->>'charge' ORDER BY charge_count DESC LIMIT 100
      ) ranked;

    WHEN 'all_charges' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT
        'all_charges', p_time_range,
        ROW_NUMBER() OVER (ORDER BY charge_count DESC)::integer,
        charge_name, charge_count::integer,
        COALESCE(charge_level, ''),
        jsonb_build_object('charge', charge_name, 'level', COALESCE(charge_level, '')),
        p_calculation_time
      FROM (
        SELECT charge->>'charge' AS charge_name, charge->>'level' AS charge_level, COUNT(*) AS charge_count
        FROM public.recent_bookings_with_charges b,
             jsonb_array_elements(b.charges) AS charge
        WHERE charge->>'charge' IS NOT NULL AND charge->>'charge' != ''
          AND (p_start_date IS NULL OR b.booking_date >= p_start_date)
        GROUP BY charge->>'charge', charge->>'level' ORDER BY charge_count DESC LIMIT 100
      ) ranked;

    WHEN 'booking_days' THEN
      INSERT INTO public.top_100_lists (category, time_range, rank, label, count, subtitle, extra_data, calculated_at)
      SELECT
        'booking_days', p_time_range,
        ROW_NUMBER() OVER (ORDER BY booking_count DESC)::integer,
        TO_CHAR(booking_date, 'YYYY-MM-DD'), booking_count::integer,
        TO_CHAR(booking_date, 'Day, Month DD, YYYY'),
        jsonb_build_object('date', booking_date::text),
        p_calculation_time
      FROM (
        SELECT DATE(booking_date) AS booking_date, COUNT(*) AS booking_count
        FROM public.recent_bookings_with_charges
        WHERE booking_date IS NOT NULL
          AND (p_start_date IS NULL OR booking_date >= p_start_date)
        GROUP BY DATE(booking_date) ORDER BY booking_count DESC LIMIT 100
      ) ranked;
  END CASE;
END;
$$;

CREATE OR REPLACE FUNCTION public.calculate_top_100_lists()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  calc_time          TIMESTAMPTZ := NOW();
  current_year_start DATE;
  five_years_ago     DATE;
BEGIN
  current_year_start := DATE_TRUNC('year', CURRENT_DATE);
  five_years_ago     := CURRENT_DATE - INTERVAL '5 years';

  -- THISYEAR
  PERFORM _calculate_category_for_time_range('arrested_persons',    'THISYEAR', current_year_start, calc_time);
  PERFORM _calculate_category_for_time_range('felony_charges',      'THISYEAR', current_year_start, calc_time);
  PERFORM _calculate_category_for_time_range('misdemeanor_charges', 'THISYEAR', current_year_start, calc_time);
  PERFORM _calculate_category_for_time_range('all_charges',         'THISYEAR', current_year_start, calc_time);
  PERFORM _calculate_category_for_time_range('booking_days',        'THISYEAR', current_year_start, calc_time);

  -- 5YEARS
  PERFORM _calculate_category_for_time_range('arrested_persons',    '5YEARS', five_years_ago, calc_time);
  PERFORM _calculate_category_for_time_range('felony_charges',      '5YEARS', five_years_ago, calc_time);
  PERFORM _calculate_category_for_time_range('misdemeanor_charges', '5YEARS', five_years_ago, calc_time);
  PERFORM _calculate_category_for_time_range('all_charges',         '5YEARS', five_years_ago, calc_time);
  PERFORM _calculate_category_for_time_range('booking_days',        '5YEARS', five_years_ago, calc_time);

  -- ALL TIME
  PERFORM _calculate_category_for_time_range('arrested_persons',    'ALL', NULL, calc_time);
  PERFORM _calculate_category_for_time_range('felony_charges',      'ALL', NULL, calc_time);
  PERFORM _calculate_category_for_time_range('misdemeanor_charges', 'ALL', NULL, calc_time);
  PERFORM _calculate_category_for_time_range('all_charges',         'ALL', NULL, calc_time);
  PERFORM _calculate_category_for_time_range('booking_days',        'ALL', NULL, calc_time);

  RAISE NOTICE 'All top 100 lists calculated at %', calc_time;
END;
$$;

GRANT EXECUTE ON FUNCTION public.calculate_top_100_lists() TO service_role;
GRANT EXECUTE ON FUNCTION _calculate_category_for_time_range(TEXT, TEXT, DATE, TIMESTAMPTZ) TO service_role;


-- ============================================================
-- DONE
-- ============================================================
-- Next steps after running this script:
--
-- 1. Storage: Go to Supabase → Storage → Create bucket
--    Name: pcso-booking-photos   Visibility: PUBLIC
--
-- 2. Configure the app: copy flutter_env.example.json to
--    assets/flutter_env.json and fill in your new project's
--    SUPABASE_URL and SUPABASE_ANON_KEY.
--
-- 3. Import traffic citations:
--    python3 import_traffic_citations_upsert.py \
--      "putnam app files/traffic_20180101_20251101.csv"
--
-- 4. Run the PCSO scraper (from pcso-scraper/ folder):
--    npx tsx scrape_pcso_jail.ts --headless --supabase \
--      --begin 01/01/2020 --end 04/17/2026 --photos --upload-photos
--
-- 5. After scraper completes, populate analytics tables:
--    npx tsx calculate_birth_dates.ts
--    SELECT calculate_top_100_lists();  -- run in SQL editor
-- ============================================================
