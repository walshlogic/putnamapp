-- =====================================================
-- CRIMINAL BACK HISTORY TABLE SCHEMA
-- Clerk of Court Criminal Back History Data
-- =====================================================

-- Create the criminal_back_history table
CREATE TABLE IF NOT EXISTS public.criminal_back_history (
  id BIGSERIAL PRIMARY KEY,
  
  -- Case Information
  case_number TEXT NOT NULL,
  uniform_case_number TEXT NOT NULL,
  
  -- Defendant Information
  defendant_last_name TEXT NOT NULL,
  defendant_first_name TEXT NOT NULL,
  defendant_middle_name TEXT,
  date_of_birth DATE,
  
  -- Address Information
  address_line_1 TEXT,
  city TEXT,
  state TEXT,
  zipcode TEXT,
  
  -- Date Information
  clerk_file_date DATE,
  pros_decision_date DATE,
  court_decision_date DATE,
  
  -- Description Fields
  statute_description TEXT,
  court_action_description TEXT,
  prosecutor_action_description TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Unique constraints
  CONSTRAINT criminal_back_history_case_number_unique UNIQUE (case_number),
  CONSTRAINT criminal_back_history_uniform_case_number_unique UNIQUE (uniform_case_number)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_case_number ON public.criminal_back_history(case_number);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_uniform_case_number ON public.criminal_back_history(uniform_case_number);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_last_name ON public.criminal_back_history(defendant_last_name);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_first_name ON public.criminal_back_history(defendant_first_name);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_date_of_birth ON public.criminal_back_history(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_clerk_file_date ON public.criminal_back_history(clerk_file_date DESC);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_city ON public.criminal_back_history(city);
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_statute ON public.criminal_back_history(statute_description);

-- Composite index for name searches
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_name_search ON public.criminal_back_history(defendant_last_name, defendant_first_name);

-- Composite index for date range queries
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_file_date ON public.criminal_back_history(clerk_file_date DESC, court_decision_date DESC);

-- Full text search index for descriptions
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_statute_search ON public.criminal_back_history USING gin(to_tsvector('english', statute_description));
CREATE INDEX IF NOT EXISTS idx_criminal_back_history_court_action_search ON public.criminal_back_history USING gin(to_tsvector('english', court_action_description));

-- Enable Row Level Security
ALTER TABLE public.criminal_back_history ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Policy: Allow authenticated users to read all criminal back history
DROP POLICY IF EXISTS "Allow authenticated users to read criminal back history" ON public.criminal_back_history;
CREATE POLICY "Allow authenticated users to read criminal back history"
  ON public.criminal_back_history
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Allow service role to insert/update/delete (for data imports)
DROP POLICY IF EXISTS "Allow service role to manage criminal back history" ON public.criminal_back_history;
CREATE POLICY "Allow service role to manage criminal back history"
  ON public.criminal_back_history
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_criminal_back_history_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_criminal_back_history_updated_at ON public.criminal_back_history;
CREATE TRIGGER update_criminal_back_history_updated_at
  BEFORE UPDATE ON public.criminal_back_history
  FOR EACH ROW
  EXECUTE FUNCTION update_criminal_back_history_updated_at();

-- =====================================================
-- HELPER VIEWS
-- =====================================================

-- View for recent cases (last 30 days)
CREATE OR REPLACE VIEW public.recent_criminal_back_history AS
SELECT *
FROM public.criminal_back_history
WHERE clerk_file_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY clerk_file_date DESC;

-- View for cases by statute
CREATE OR REPLACE VIEW public.criminal_back_history_by_statute AS
SELECT 
  statute_description,
  COUNT(*) as case_count,
  MIN(clerk_file_date) as first_case,
  MAX(clerk_file_date) as last_case
FROM public.criminal_back_history
WHERE statute_description IS NOT NULL
GROUP BY statute_description
ORDER BY case_count DESC;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE public.criminal_back_history IS 'Criminal back history from Clerk of Court records';
COMMENT ON COLUMN public.criminal_back_history.case_number IS 'Case number (14 alpha characters)';
COMMENT ON COLUMN public.criminal_back_history.uniform_case_number IS 'Uniform Case Number (20 alpha characters)';
COMMENT ON COLUMN public.criminal_back_history.clerk_file_date IS 'Date case was filed with clerk (YYYYMMDD format from CSV)';
COMMENT ON COLUMN public.criminal_back_history.pros_decision_date IS 'Prosecutor decision date (YYYYMMDD format from CSV)';
COMMENT ON COLUMN public.criminal_back_history.court_decision_date IS 'Court decision date (YYYYMMDD format from CSV)';
COMMENT ON COLUMN public.criminal_back_history.statute_description IS 'Description of the statute/charge';
COMMENT ON COLUMN public.criminal_back_history.court_action_description IS 'Description of court action taken';
COMMENT ON COLUMN public.criminal_back_history.prosecutor_action_description IS 'Description of prosecutor action taken';

