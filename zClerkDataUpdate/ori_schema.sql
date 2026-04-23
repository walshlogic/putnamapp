-- ORI (Official Records Index) table
-- Official records from Putnam County Clerk of Court
-- Data sources: oriweekly.zip (last 4 weeks), oriyear.zip (YTD), orimaster.zip (1983-last year)

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS public.ori_records (
    id BIGSERIAL PRIMARY KEY,
    book_number INTEGER NOT NULL,
    page_number INTEGER NOT NULL,
    file_date DATE,
    from_party TEXT,
    to_party TEXT,
    instrument_number TEXT NOT NULL,
    transaction_code VARCHAR(5),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ori_records_natural_key UNIQUE NULLS NOT DISTINCT
        (instrument_number, book_number, page_number, from_party, to_party)
);

-- Trigram indexes for fast fuzzy name search on parties
CREATE INDEX IF NOT EXISTS idx_ori_from_party_trgm
    ON public.ori_records USING gin (from_party gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_ori_to_party_trgm
    ON public.ori_records USING gin (to_party gin_trgm_ops);

-- Standard indexes for filtering/lookup
CREATE INDEX IF NOT EXISTS idx_ori_instrument
    ON public.ori_records (instrument_number);
CREATE INDEX IF NOT EXISTS idx_ori_file_date
    ON public.ori_records (file_date DESC);
CREATE INDEX IF NOT EXISTS idx_ori_transaction_code
    ON public.ori_records (transaction_code);
CREATE INDEX IF NOT EXISTS idx_ori_book_page
    ON public.ori_records (book_number, page_number);

-- RLS: read-only for authenticated users
ALTER TABLE public.ori_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ori_records_read_authenticated"
    ON public.ori_records FOR SELECT
    TO authenticated
    USING (true);
