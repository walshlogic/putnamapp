-- =====================================================
-- ACKNOWLEDGE LOG TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.acknowledge_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  acknowledged_at timestamptz NOT NULL DEFAULT now(),
  ack_version text NOT NULL DEFAULT 'v1',
  platform text NULL
);

ALTER TABLE public.acknowledge_log ENABLE ROW LEVEL SECURITY;

-- Allow anyone (including anon) to insert acknowledgements
CREATE POLICY "Anyone can insert acknowledgements"
  ON public.acknowledge_log
  FOR INSERT
  TO public
  WITH CHECK (true);

-- Optional: allow authenticated users to read their own logs
CREATE POLICY "Users can read their acknowledgements"
  ON public.acknowledge_log
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());
