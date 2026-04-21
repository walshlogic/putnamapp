-- Florida Sex Offender Registry (FSOR)
-- Populated from FDLE's PublicDataFile.csv via ingest_fl_sor_supabase.py.
-- App reads this via SupabaseSexOffenderRepository.

CREATE TABLE IF NOT EXISTS public.fl_sor (
    id BIGSERIAL PRIMARY KEY,
    person_nbr TEXT UNIQUE NOT NULL,

    first_name TEXT,
    middle_name TEXT,
    last_name TEXT,
    suffix_name TEXT,

    status TEXT,
    subject_type TEXT,
    race TEXT,
    sex TEXT,
    eye_color TEXT,
    hair TEXT,

    height_raw TEXT,
    weight_raw TEXT,
    height_in INTEGER,
    weight_lbs INTEGER,

    birth_date_raw TEXT,
    birth_date DATE,
    dc_number TEXT,

    perm_address_added TEXT,
    perm_address_added_date DATE,
    perm_address_line_1 TEXT,
    perm_address_line_2 TEXT,
    perm_city TEXT,
    perm_state TEXT,
    perm_zip5 TEXT,
    perm_zip4 TEXT,
    perm_county TEXT,

    temp_address_added TEXT,
    temp_address_added_date DATE,
    temp_address_line_1 TEXT,
    temp_address_line_2 TEXT,
    temp_city TEXT,
    temp_state TEXT,
    temp_zip5 TEXT,
    temp_zip4 TEXT,
    temp_county TEXT,

    trans_address_added TEXT,
    trans_address_added_date DATE,
    trans_address_line_1 TEXT,
    trans_address_line_2 TEXT,
    trans_city TEXT,
    trans_state TEXT,
    trans_zip5 TEXT,
    trans_zip4 TEXT,
    trans_county TEXT,

    victim_minor_raw TEXT,
    victim_minor BOOLEAN,
    image_url TEXT,

    source_file TEXT,
    source_downloaded_at TIMESTAMPTZ,
    raw_row JSONB,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fl_sor_state_county
    ON public.fl_sor (perm_state, perm_county);
CREATE INDEX IF NOT EXISTS idx_fl_sor_last_name
    ON public.fl_sor (last_name);
CREATE INDEX IF NOT EXISTS idx_fl_sor_city
    ON public.fl_sor (perm_city);

ALTER TABLE public.fl_sor ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "fl_sor_read_all" ON public.fl_sor;
CREATE POLICY "fl_sor_read_all"
    ON public.fl_sor FOR SELECT
    TO authenticated
    USING (true);
