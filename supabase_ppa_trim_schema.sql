-- =====================================================================
-- Putnam County Property Appraiser (PPA) TRIM data
-- Target: Putnam+Life Supabase project
-- =====================================================================

create extension if not exists pg_trgm;
create schema if not exists ppa;

-- ---------- parcels (one row per parcel per roll year) ----------
create table ppa.parcels (
  id                bigserial primary key,
  roll_year         smallint not null,
  parcel_number     text not null,
  continued_on_roll boolean not null default false,

  physical_address  text,
  legal_description text,

  owner_name        text,
  co_owner_name     text,
  mailing_addr1     text,
  mailing_addr2     text,
  mailing_city      text,
  mailing_state     text,
  mailing_zip       text,

  petition_deadline text,

  co_market_ly      numeric(14,0),
  co_assmt_red_ly   numeric(14,0),
  co_assessed_ly    numeric(14,0),
  co_exempt_ly      numeric(14,0),
  co_taxable_ly     numeric(14,0),
  sch_market_ly     numeric(14,0),
  sch_assmt_red_ly  numeric(14,0),
  sch_assessed_ly   numeric(14,0),
  sch_exempt_ly     numeric(14,0),
  sch_taxable_ly    numeric(14,0),
  oth_market_ly     numeric(14,0),
  oth_assmt_red_ly  numeric(14,0),
  oth_assessed_ly   numeric(14,0),
  oth_exempt_ly     numeric(14,0),
  oth_taxable_ly    numeric(14,0),
  mun_market_ly     numeric(14,0),
  mun_assmt_red_ly  numeric(14,0),
  mun_assessed_ly   numeric(14,0),
  mun_exempt_ly     numeric(14,0),
  mun_taxable_ly    numeric(14,0),

  co_market         numeric(14,0),
  co_assmt_red      numeric(14,0),
  co_assessed       numeric(14,0),
  co_exempt         numeric(14,0),
  co_taxable        numeric(14,0),
  sch_market        numeric(14,0),
  sch_assmt_red     numeric(14,0),
  sch_assessed      numeric(14,0),
  sch_exempt        numeric(14,0),
  sch_taxable       numeric(14,0),
  oth_market        numeric(14,0),
  oth_assmt_red     numeric(14,0),
  oth_assessed      numeric(14,0),
  oth_exempt        numeric(14,0),
  oth_taxable       numeric(14,0),
  mun_market        numeric(14,0),
  mun_assmt_red     numeric(14,0),
  mun_assessed      numeric(14,0),
  mun_exempt        numeric(14,0),
  mun_taxable       numeric(14,0),

  total_ad_val_ly           numeric(14,2),
  total_ad_val_proposed     numeric(14,2),
  total_ad_val_rollback     numeric(14,2),
  total_non_ad_val          numeric(14,2),
  total_non_ad_val_ly       numeric(14,2),
  total_all_ly              numeric(14,2),
  total_all_proposed        numeric(14,2),
  total_all_rollback        numeric(14,2),

  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint parcels_uk unique (roll_year, parcel_number)
);

create index parcels_owner_trgm on ppa.parcels using gin (owner_name gin_trgm_ops);
create index parcels_addr_trgm  on ppa.parcels using gin (physical_address gin_trgm_ops);
create index parcels_city_idx   on ppa.parcels (mailing_city);
create index parcels_zip_idx    on ppa.parcels (mailing_zip);
create index parcels_parcel_idx on ppa.parcels (parcel_number);

-- ---------- child tables ----------
create table ppa.assessment_reductions (
  id            bigserial primary key,
  parcel_id     bigint not null references ppa.parcels(id) on delete cascade,
  seq           smallint not null check (seq between 1 and 3),
  description   text,
  tax_district  text,
  amount        numeric(14,0),
  unique (parcel_id, seq)
);

create table ppa.exemptions (
  id            bigserial primary key,
  parcel_id     bigint not null references ppa.parcels(id) on delete cascade,
  seq           smallint not null check (seq between 1 and 7),
  description   text,
  tax_district  text,
  amount        numeric(14,0),
  unique (parcel_id, seq)
);

create table ppa.taxing_authorities (
  id                  bigserial primary key,
  parcel_id           bigint not null references ppa.parcels(id) on delete cascade,
  authority_type      text not null,
  authority_label     text,
  taxable_ly          numeric(14,0),
  millage_ly          numeric(8,4),
  taxes_ly            numeric(14,2),
  taxable_cy          numeric(14,0),
  millage_proposed    numeric(8,4),
  taxes_proposed      numeric(14,2),
  millage_rollback    numeric(8,4),
  taxes_rollback      numeric(14,2),
  unique (parcel_id, authority_type)
);

create index tax_auth_type_idx on ppa.taxing_authorities (authority_type);

create table ppa.non_ad_valorem (
  id            bigserial primary key,
  parcel_id     bigint not null references ppa.parcels(id) on delete cascade,
  seq           smallint not null check (seq between 1 and 4),
  description   text,
  rate          numeric(10,4),
  units         numeric(10,2),
  amount        numeric(14,2),
  unique (parcel_id, seq)
);

create index nav_desc_idx on ppa.non_ad_valorem (description);

create table ppa.public_hearings (
  roll_year               smallint primary key,
  county_meeting          text,
  county_place            text,
  schools_meeting         text,
  schools_place           text,
  wmd_meeting             text,
  wmd_place               text,
  municipality_meeting    text,
  municipality_place      text
);

-- ---------- trigger: updated_at ----------
create or replace function ppa.set_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at := now(); return new; end $$;

create trigger parcels_set_updated_at
  before update on ppa.parcels
  for each row execute function ppa.set_updated_at();

-- ---------- summary view ----------
create or replace view ppa.v_parcel_summary as
select
  p.id,
  p.roll_year,
  p.parcel_number,
  p.physical_address,
  p.owner_name,
  p.mailing_city,
  p.co_market           as market_value,
  p.co_assessed         as assessed_value,
  p.co_taxable          as county_taxable,
  p.total_all_proposed  as proposed_tax_total,
  p.total_all_ly        as tax_last_year,
  (p.total_all_proposed - p.total_all_ly)             as yoy_tax_change,
  case when p.total_all_ly > 0
       then round(((p.total_all_proposed - p.total_all_ly) / p.total_all_ly) * 100, 2)
       else null end                                   as yoy_tax_pct
from ppa.parcels p;

-- ---------- RLS ----------
alter table ppa.parcels              enable row level security;
alter table ppa.assessment_reductions enable row level security;
alter table ppa.exemptions           enable row level security;
alter table ppa.taxing_authorities   enable row level security;
alter table ppa.non_ad_valorem       enable row level security;
alter table ppa.public_hearings      enable row level security;

create policy parcels_read on ppa.parcels              for select to anon, authenticated using (true);
create policy ar_read      on ppa.assessment_reductions for select to anon, authenticated using (true);
create policy ex_read      on ppa.exemptions           for select to anon, authenticated using (true);
create policy ta_read      on ppa.taxing_authorities   for select to anon, authenticated using (true);
create policy nav_read     on ppa.non_ad_valorem       for select to anon, authenticated using (true);
create policy ph_read      on ppa.public_hearings      for select to anon, authenticated using (true);

-- Expose ppa schema over PostgREST (optional; otherwise read via RPC or add to api schema)
grant usage on schema ppa to anon, authenticated;
grant select on all tables in schema ppa to anon, authenticated;
grant select on all sequences in schema ppa to anon, authenticated;
alter default privileges in schema ppa grant select on tables to anon, authenticated;
