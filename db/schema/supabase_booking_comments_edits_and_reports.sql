-- Add edit history, publish state, and report tracking to booking comments.
-- Safe to run multiple times.

ALTER TABLE public.booking_comments
  ADD COLUMN IF NOT EXISTS root_comment_id uuid,
  ADD COLUMN IF NOT EXISTS parent_comment_id uuid,
  ADD COLUMN IF NOT EXISTS is_published boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS edited_at timestamptz,
  ADD COLUMN IF NOT EXISTS is_flagged boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS flag_reason text,
  ADD COLUMN IF NOT EXISTS flagged_at timestamptz,
  ADD COLUMN IF NOT EXISTS flagged_reviewed_at timestamptz,
  ADD COLUMN IF NOT EXISTS flagged_review_outcome text;

-- Backfill root_comment_id for existing rows.
UPDATE public.booking_comments
SET root_comment_id = id
WHERE root_comment_id IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'booking_comments_root_comment_fk'
  ) THEN
    ALTER TABLE public.booking_comments
      ADD CONSTRAINT booking_comments_root_comment_fk
      FOREIGN KEY (root_comment_id)
      REFERENCES public.booking_comments(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'booking_comments_parent_comment_fk'
  ) THEN
    ALTER TABLE public.booking_comments
      ADD CONSTRAINT booking_comments_parent_comment_fk
      FOREIGN KEY (parent_comment_id)
      REFERENCES public.booking_comments(id);
  END IF;
END $$;

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

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'booking_comments_set_root_comment'
  ) THEN
    CREATE TRIGGER booking_comments_set_root_comment
    BEFORE INSERT ON public.booking_comments
    FOR EACH ROW
    EXECUTE FUNCTION public.booking_comments_set_root_comment();
  END IF;
END $$;

CREATE OR REPLACE VIEW public.booking_comments_latest AS
SELECT *
FROM (
  SELECT DISTINCT ON (root_comment_id)
    *
  FROM public.booking_comments
  ORDER BY root_comment_id, created_at DESC
) AS latest
WHERE is_published = true;

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
  SET is_flagged = true,
      flag_reason = p_reason,
      flagged_at = now()
  WHERE id = p_comment_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.report_booking_comment(uuid, text) TO authenticated;
