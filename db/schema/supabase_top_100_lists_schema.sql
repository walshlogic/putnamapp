-- =====================================================
-- PUTNAM.APP - TOP 100 LISTS PRE-CALCULATED DATA
-- =====================================================
-- This table stores pre-calculated top 100 lists to avoid
-- expensive on-the-fly calculations when users view the lists.
-- Data is refreshed twice daily via scheduled job.
-- =====================================================

-- Create table to store pre-calculated top 100 lists
CREATE TABLE IF NOT EXISTS public.top_100_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Category: arrested_persons, felony_charges, misdemeanor_charges, all_charges, booking_days
  category TEXT NOT NULL,
  
  -- Rank (1-100)
  rank INTEGER NOT NULL CHECK (rank >= 1 AND rank <= 100),
  
  -- Label (person name, charge name, or date)
  label TEXT NOT NULL,
  
  -- Count (number of bookings or charges)
  count INTEGER NOT NULL CHECK (count >= 0),
  
  -- Optional subtitle or extra data (stored as JSONB)
  subtitle TEXT,
  extra_data JSONB,
  
  -- Timestamp when this data was calculated
  calculated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Unique constraint: one rank per category per calculation
  CONSTRAINT unique_category_rank UNIQUE (category, rank, calculated_at)
);

-- Create indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_top_100_lists_category 
  ON public.top_100_lists(category);

CREATE INDEX IF NOT EXISTS idx_top_100_lists_category_rank 
  ON public.top_100_lists(category, rank);

CREATE INDEX IF NOT EXISTS idx_top_100_lists_calculated_at 
  ON public.top_100_lists(calculated_at DESC);

-- Index for getting latest calculation per category
CREATE INDEX IF NOT EXISTS idx_top_100_lists_category_latest 
  ON public.top_100_lists(category, calculated_at DESC);

-- Enable Row Level Security
ALTER TABLE public.top_100_lists ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read top 100 lists (public data)
CREATE POLICY "Anyone can read top 100 lists"
  ON public.top_100_lists
  FOR SELECT
  TO public
  USING (true);

-- Policy: Only service role can insert/update (for scheduled jobs)
-- Note: This requires service role, so scheduled jobs must use service role key

-- Add comment for documentation
COMMENT ON TABLE public.top_100_lists IS 'Pre-calculated top 100 lists refreshed twice daily';
COMMENT ON COLUMN public.top_100_lists.category IS 'Category: arrested_persons, felony_charges, misdemeanor_charges, all_charges, booking_days';
COMMENT ON COLUMN public.top_100_lists.rank IS 'Rank from 1-100';
COMMENT ON COLUMN public.top_100_lists.label IS 'Person name, charge name, or date string';
COMMENT ON COLUMN public.top_100_lists.count IS 'Number of bookings or charges';
COMMENT ON COLUMN public.top_100_lists.calculated_at IS 'When this data was calculated';

