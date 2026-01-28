-- Add comments preferences and immutable app user ID for user_profiles.
-- Safe to run multiple times.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS comment_anonymous boolean NOT NULL DEFAULT false;

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS app_user_id text;

UPDATE public.user_profiles
SET app_user_id = upper(substr(encode(gen_random_bytes(5), 'hex'), 1, 10))
WHERE app_user_id IS NULL OR app_user_id = '';

ALTER TABLE public.user_profiles
  ALTER COLUMN app_user_id SET DEFAULT (
    upper(substr(encode(gen_random_bytes(5), 'hex'), 1, 10))
  );

ALTER TABLE public.user_profiles
  ALTER COLUMN app_user_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'user_profiles'
      AND indexname = 'user_profiles_app_user_id_key'
  ) THEN
    CREATE UNIQUE INDEX user_profiles_app_user_id_key
      ON public.user_profiles (app_user_id);
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.prevent_app_user_id_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.app_user_id IS DISTINCT FROM OLD.app_user_id THEN
    RAISE EXCEPTION 'app_user_id is immutable';
  END IF;
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'prevent_app_user_id_update'
  ) THEN
    CREATE TRIGGER prevent_app_user_id_update
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_app_user_id_update();
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'prevent_internal_username_update'
  ) THEN
    DROP TRIGGER prevent_internal_username_update ON public.user_profiles;
  END IF;
END $$;

DROP FUNCTION IF EXISTS public.prevent_internal_username_update();

ALTER TABLE public.user_profiles
  DROP COLUMN IF EXISTS internal_username;
