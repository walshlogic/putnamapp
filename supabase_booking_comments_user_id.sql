-- Store app-issued user ID on booking_comments and backfill existing rows.
-- Safe to run multiple times.

ALTER TABLE public.booking_comments
  ADD COLUMN IF NOT EXISTS app_user_id text;

UPDATE public.booking_comments bc
SET app_user_id = up.app_user_id
FROM public.user_profiles up
WHERE bc.user_id = up.id
  AND (bc.app_user_id IS NULL OR bc.app_user_id = '');

CREATE OR REPLACE FUNCTION public.booking_comments_set_app_user_id()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.app_user_id IS NULL OR NEW.app_user_id = '' THEN
    SELECT app_user_id
    INTO NEW.app_user_id
    FROM public.user_profiles
    WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'booking_comments_set_app_user_id'
  ) THEN
    CREATE TRIGGER booking_comments_set_app_user_id
    BEFORE INSERT ON public.booking_comments
    FOR EACH ROW
    EXECUTE FUNCTION public.booking_comments_set_app_user_id();
  END IF;
END $$;
