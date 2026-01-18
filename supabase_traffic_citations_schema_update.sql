-- =====================================================
-- TRAFFIC CITATIONS TABLE SCHEMA UPDATE
-- Update schema to match NEW file layout from Clerk of Court
-- =====================================================

-- Add new columns for updated file format
ALTER TABLE public.traffic_citations 
  ADD COLUMN IF NOT EXISTS citation_number TEXT,
  ADD COLUMN IF NOT EXISTS check_digit TEXT,
  ADD COLUMN IF NOT EXISTS fine_amount TEXT,
  ADD COLUMN IF NOT EXISTS dl_state TEXT;

-- Create index on citation_number for lookups
CREATE INDEX IF NOT EXISTS idx_traffic_citations_citation_number 
  ON public.traffic_citations(citation_number);

-- Create index on dl_state for filtering
CREATE INDEX IF NOT EXISTS idx_traffic_citations_dl_state 
  ON public.traffic_citations(dl_state);

-- Update comments
COMMENT ON COLUMN public.traffic_citations.citation_number IS 'Citation number (7 characters) - replaces license_plate in new format';
COMMENT ON COLUMN public.traffic_citations.check_digit IS 'Check digit (1 character) - new field in updated format';
COMMENT ON COLUMN public.traffic_citations.fine_amount IS 'Fine amount in dollars - new field in updated format';
COMMENT ON COLUMN public.traffic_citations.dl_state IS 'Driver license state (2 characters) - new field in updated format';
COMMENT ON COLUMN public.traffic_citations.full_case_number IS 'Uniform Case Number (20 alpha) - updated field name in new format';

-- Note: license_plate column is kept for backward compatibility but will be NULL for new records
-- The citation_number field replaces license_plate in the new file format

