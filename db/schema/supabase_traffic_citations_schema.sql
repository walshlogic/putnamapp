-- =====================================================
-- TRAFFIC CITATIONS TABLE SCHEMA
-- Clerk of Court Traffic Citations Data
-- =====================================================

-- Create the traffic_citations table
CREATE TABLE IF NOT EXISTS public.traffic_citations (
  id BIGSERIAL PRIMARY KEY,
  
  -- Citation Information
  citation_date DATE NOT NULL,
  case_number TEXT NOT NULL,
  full_case_number TEXT NOT NULL,
  violation_description TEXT NOT NULL,
  
  -- Vehicle Information
  license_plate TEXT,
  
  -- Person Information
  last_name TEXT NOT NULL,
  first_name TEXT NOT NULL,
  middle_name TEXT,
  date_of_birth DATE,
  gender TEXT, -- M, F, or NULL
  license_number TEXT,
  
  -- Address Information
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  
  -- Disposition
  disposition_date DATE,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Indexes for common queries
  CONSTRAINT traffic_citations_case_number_unique UNIQUE (case_number),
  CONSTRAINT traffic_citations_full_case_number_unique UNIQUE (full_case_number)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_traffic_citations_citation_date ON public.traffic_citations(citation_date DESC);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_last_name ON public.traffic_citations(last_name);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_first_name ON public.traffic_citations(first_name);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_license_plate ON public.traffic_citations(license_plate);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_violation ON public.traffic_citations(violation_description);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_city ON public.traffic_citations(city);
CREATE INDEX IF NOT EXISTS idx_traffic_citations_date_of_birth ON public.traffic_citations(date_of_birth);

-- Composite index for name searches
CREATE INDEX IF NOT EXISTS idx_traffic_citations_name_search ON public.traffic_citations(last_name, first_name);

-- Full text search index for violation descriptions
CREATE INDEX IF NOT EXISTS idx_traffic_citations_violation_search ON public.traffic_citations USING gin(to_tsvector('english', violation_description));

-- Enable Row Level Security
ALTER TABLE public.traffic_citations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Policy: Allow authenticated users to read all traffic citations
DROP POLICY IF EXISTS "Allow authenticated users to read traffic citations" ON public.traffic_citations;
CREATE POLICY "Allow authenticated users to read traffic citations"
  ON public.traffic_citations
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Allow service role to insert/update/delete (for data imports)
DROP POLICY IF EXISTS "Allow service role to manage traffic citations" ON public.traffic_citations;
CREATE POLICY "Allow service role to manage traffic citations"
  ON public.traffic_citations
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_traffic_citations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_traffic_citations_updated_at
  BEFORE UPDATE ON public.traffic_citations
  FOR EACH ROW
  EXECUTE FUNCTION update_traffic_citations_updated_at();

-- =====================================================
-- HELPER VIEWS
-- =====================================================

-- View for recent citations (last 30 days)
CREATE OR REPLACE VIEW public.recent_traffic_citations AS
SELECT *
FROM public.traffic_citations
WHERE citation_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY citation_date DESC;

-- View for citations by violation type
CREATE OR REPLACE VIEW public.traffic_citations_by_violation AS
SELECT 
  violation_description,
  COUNT(*) as citation_count,
  MIN(citation_date) as first_citation,
  MAX(citation_date) as last_citation
FROM public.traffic_citations
GROUP BY violation_description
ORDER BY citation_count DESC;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE public.traffic_citations IS 'Traffic citations from Clerk of Court records';
COMMENT ON COLUMN public.traffic_citations.citation_date IS 'Date the citation was issued (YYYYMMDD format from CSV)';
COMMENT ON COLUMN public.traffic_citations.case_number IS 'Short case number (e.g., 2018001720TRAXMX)';
COMMENT ON COLUMN public.traffic_citations.full_case_number IS 'Full case number (e.g., 542018TR001720TRAXMX)';
COMMENT ON COLUMN public.traffic_citations.violation_description IS 'Description of the traffic violation';
COMMENT ON COLUMN public.traffic_citations.disposition_date IS 'Date case was disposed (if available)';

