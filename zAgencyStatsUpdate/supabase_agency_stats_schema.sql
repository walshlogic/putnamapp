-- =====================================================
-- PUTNAM.APP - AGENCY STATS PRE-CALCULATED DATA
-- =====================================================
-- This table stores pre-calculated agency statistics to avoid
-- expensive on-the-fly calculations when users view agency stats.
-- Data is refreshed twice daily via scheduled Python script.
-- =====================================================

-- Create table to store pre-calculated agency statistics
CREATE TABLE IF NOT EXISTS public.agency_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Agency identifier (pcso, palatka_pd, etc.)
  agency_id TEXT NOT NULL,
  
  -- Agency display name
  agency_name TEXT NOT NULL,
  
  -- Statistics
  total_bookings INTEGER NOT NULL DEFAULT 0 CHECK (total_bookings >= 0),
  total_charges INTEGER NOT NULL DEFAULT 0 CHECK (total_charges >= 0),
  unique_persons INTEGER NOT NULL DEFAULT 0 CHECK (unique_persons >= 0),
  average_charges_per_booking NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
  
  -- JSONB fields for complex data structures
  bookings_by_year JSONB NOT NULL DEFAULT '{}'::jsonb, -- {2025: 150, 2024: 1200, ...}
  bookings_by_gender JSONB NOT NULL DEFAULT '{}'::jsonb, -- {MALE: 800, FEMALE: 200, ...}
  bookings_by_race JSONB NOT NULL DEFAULT '{}'::jsonb, -- {WHITE: 500, BLACK: 300, ...}
  charges_by_level_and_degree JSONB NOT NULL DEFAULT '[]'::jsonb, -- [{level: "FELONY", totalCount: 100, byDegree: {FIRST: 50, SECOND: 50}}, ...]
  
  -- Timestamp when this data was calculated
  calculated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Unique constraint: one record per agency per calculation
  CONSTRAINT unique_agency_calculation UNIQUE (agency_id, calculated_at)
);

-- Create indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_agency_stats_agency_id 
  ON public.agency_stats(agency_id);

CREATE INDEX IF NOT EXISTS idx_agency_stats_calculated_at 
  ON public.agency_stats(calculated_at DESC);

-- Index for getting latest calculation per agency
CREATE INDEX IF NOT EXISTS idx_agency_stats_agency_latest 
  ON public.agency_stats(agency_id, calculated_at DESC);

-- Enable Row Level Security
ALTER TABLE public.agency_stats ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read agency stats (public data)
CREATE POLICY "Anyone can read agency stats"
  ON public.agency_stats
  FOR SELECT
  TO public
  USING (true);

-- Policy: Only service role can insert/update (for scheduled jobs)
-- Note: Python script must use service role key

-- Add comment for documentation
COMMENT ON TABLE public.agency_stats IS 'Pre-calculated agency statistics refreshed twice daily';
COMMENT ON COLUMN public.agency_stats.agency_id IS 'Agency identifier: pcso, palatka_pd, interlachen_pd, welaka_pd, school_pd, fhp, fwc';
COMMENT ON COLUMN public.agency_stats.bookings_by_year IS 'JSON object mapping year to booking count: {2025: 150, 2024: 1200}';
COMMENT ON COLUMN public.agency_stats.bookings_by_gender IS 'JSON object mapping gender to booking count: {MALE: 800, FEMALE: 200}';
COMMENT ON COLUMN public.agency_stats.bookings_by_race IS 'JSON object mapping race to booking count: {WHITE: 500, BLACK: 300}';
COMMENT ON COLUMN public.agency_stats.charges_by_level_and_degree IS 'JSON array of charge statistics: [{"level": "FELONY", "totalCount": 100, "byDegree": {"FIRST": 50, "SECOND": 50}}, ...]';
COMMENT ON COLUMN public.agency_stats.calculated_at IS 'When this data was calculated';

