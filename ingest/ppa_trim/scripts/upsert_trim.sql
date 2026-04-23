-- =====================================================================
-- Upsert TRIM CSVs into ppa.* tables.
-- Call from a shell script that first \copy's the CSVs into staging tables.
-- Safe to re-run; PK is (roll_year, parcel_number).
-- =====================================================================

begin;

-- ---------- staging ----------
create temp table stg_parcels (like ppa.parcels including defaults) on commit drop;
alter table stg_parcels drop column id, drop column created_at, drop column updated_at;

create temp table stg_ar  (parcel_number text, roll_year smallint, seq smallint, description text, tax_district text, amount numeric) on commit drop;
create temp table stg_ex  (parcel_number text, roll_year smallint, seq smallint, description text, tax_district text, amount numeric) on commit drop;
create temp table stg_ta  (parcel_number text, roll_year smallint, authority_type text, authority_label text,
                           taxable_ly numeric, millage_ly numeric, taxes_ly numeric,
                           taxable_cy numeric, millage_proposed numeric, taxes_proposed numeric,
                           millage_rollback numeric, taxes_rollback numeric) on commit drop;
create temp table stg_nav (parcel_number text, roll_year smallint, seq smallint, description text,
                           rate numeric, units numeric, amount numeric) on commit drop;
create temp table stg_ph  (roll_year smallint, county_meeting text, county_place text,
                           schools_meeting text, schools_place text,
                           wmd_meeting text, wmd_place text,
                           municipality_meeting text, municipality_place text) on commit drop;

-- ---------- load CSVs (called from shell: \copy ... from 'file' csv header) ----------
\copy stg_parcels from 'out/parcels.csv' csv header
\copy stg_ar      from 'out/assessment_reductions.csv' csv header
\copy stg_ex      from 'out/exemptions.csv' csv header
\copy stg_ta      from 'out/taxing_authorities.csv' csv header
\copy stg_nav     from 'out/non_ad_valorem.csv' csv header
\copy stg_ph      from 'out/public_hearings.csv' csv header

-- ---------- parcels upsert ----------
insert into ppa.parcels (
  roll_year, parcel_number, continued_on_roll,
  physical_address, legal_description,
  owner_name, co_owner_name, mailing_addr1, mailing_addr2,
  mailing_city, mailing_state, mailing_zip, petition_deadline,
  co_market_ly, co_assmt_red_ly, co_assessed_ly, co_exempt_ly, co_taxable_ly,
  sch_market_ly, sch_assmt_red_ly, sch_assessed_ly, sch_exempt_ly, sch_taxable_ly,
  oth_market_ly, oth_assmt_red_ly, oth_assessed_ly, oth_exempt_ly, oth_taxable_ly,
  mun_market_ly, mun_assmt_red_ly, mun_assessed_ly, mun_exempt_ly, mun_taxable_ly,
  co_market, co_assmt_red, co_assessed, co_exempt, co_taxable,
  sch_market, sch_assmt_red, sch_assessed, sch_exempt, sch_taxable,
  oth_market, oth_assmt_red, oth_assessed, oth_exempt, oth_taxable,
  mun_market, mun_assmt_red, mun_assessed, mun_exempt, mun_taxable,
  total_ad_val_ly, total_ad_val_proposed, total_ad_val_rollback,
  total_non_ad_val, total_non_ad_val_ly,
  total_all_ly, total_all_proposed, total_all_rollback
)
select * from stg_parcels
on conflict (roll_year, parcel_number) do update set
  continued_on_roll = excluded.continued_on_roll,
  physical_address  = excluded.physical_address,
  legal_description = excluded.legal_description,
  owner_name        = excluded.owner_name,
  co_owner_name     = excluded.co_owner_name,
  mailing_addr1     = excluded.mailing_addr1,
  mailing_addr2     = excluded.mailing_addr2,
  mailing_city      = excluded.mailing_city,
  mailing_state     = excluded.mailing_state,
  mailing_zip       = excluded.mailing_zip,
  petition_deadline = excluded.petition_deadline,
  co_market_ly = excluded.co_market_ly, co_assmt_red_ly = excluded.co_assmt_red_ly,
  co_assessed_ly = excluded.co_assessed_ly, co_exempt_ly = excluded.co_exempt_ly, co_taxable_ly = excluded.co_taxable_ly,
  sch_market_ly = excluded.sch_market_ly, sch_assmt_red_ly = excluded.sch_assmt_red_ly,
  sch_assessed_ly = excluded.sch_assessed_ly, sch_exempt_ly = excluded.sch_exempt_ly, sch_taxable_ly = excluded.sch_taxable_ly,
  oth_market_ly = excluded.oth_market_ly, oth_assmt_red_ly = excluded.oth_assmt_red_ly,
  oth_assessed_ly = excluded.oth_assessed_ly, oth_exempt_ly = excluded.oth_exempt_ly, oth_taxable_ly = excluded.oth_taxable_ly,
  mun_market_ly = excluded.mun_market_ly, mun_assmt_red_ly = excluded.mun_assmt_red_ly,
  mun_assessed_ly = excluded.mun_assessed_ly, mun_exempt_ly = excluded.mun_exempt_ly, mun_taxable_ly = excluded.mun_taxable_ly,
  co_market = excluded.co_market, co_assmt_red = excluded.co_assmt_red,
  co_assessed = excluded.co_assessed, co_exempt = excluded.co_exempt, co_taxable = excluded.co_taxable,
  sch_market = excluded.sch_market, sch_assmt_red = excluded.sch_assmt_red,
  sch_assessed = excluded.sch_assessed, sch_exempt = excluded.sch_exempt, sch_taxable = excluded.sch_taxable,
  oth_market = excluded.oth_market, oth_assmt_red = excluded.oth_assmt_red,
  oth_assessed = excluded.oth_assessed, oth_exempt = excluded.oth_exempt, oth_taxable = excluded.oth_taxable,
  mun_market = excluded.mun_market, mun_assmt_red = excluded.mun_assmt_red,
  mun_assessed = excluded.mun_assessed, mun_exempt = excluded.mun_exempt, mun_taxable = excluded.mun_taxable,
  total_ad_val_ly = excluded.total_ad_val_ly, total_ad_val_proposed = excluded.total_ad_val_proposed,
  total_ad_val_rollback = excluded.total_ad_val_rollback,
  total_non_ad_val = excluded.total_non_ad_val, total_non_ad_val_ly = excluded.total_non_ad_val_ly,
  total_all_ly = excluded.total_all_ly, total_all_proposed = excluded.total_all_proposed,
  total_all_rollback = excluded.total_all_rollback,
  updated_at = now();

-- ---------- child tables: wipe & reload for the affected roll years ----------
-- Collect roll years present in this import
create temp table stg_years(y smallint) on commit drop;
insert into stg_years select distinct roll_year from stg_parcels;

-- Delete existing child rows that belong to parcels in those roll years
delete from ppa.assessment_reductions a using ppa.parcels p
  where a.parcel_id = p.id and p.roll_year in (select y from stg_years);
delete from ppa.exemptions e using ppa.parcels p
  where e.parcel_id = p.id and p.roll_year in (select y from stg_years);
delete from ppa.taxing_authorities t using ppa.parcels p
  where t.parcel_id = p.id and p.roll_year in (select y from stg_years);
delete from ppa.non_ad_valorem n using ppa.parcels p
  where n.parcel_id = p.id and p.roll_year in (select y from stg_years);

-- Reload children via join to parcels on (roll_year, parcel_number)
insert into ppa.assessment_reductions (parcel_id, seq, description, tax_district, amount)
select p.id, s.seq, s.description, s.tax_district, s.amount
from stg_ar s
join ppa.parcels p on p.roll_year = s.roll_year and p.parcel_number = s.parcel_number;

insert into ppa.exemptions (parcel_id, seq, description, tax_district, amount)
select p.id, s.seq, s.description, s.tax_district, s.amount
from stg_ex s
join ppa.parcels p on p.roll_year = s.roll_year and p.parcel_number = s.parcel_number;

insert into ppa.taxing_authorities (
  parcel_id, authority_type, authority_label,
  taxable_ly, millage_ly, taxes_ly,
  taxable_cy, millage_proposed, taxes_proposed,
  millage_rollback, taxes_rollback
)
select p.id, s.authority_type, s.authority_label,
  s.taxable_ly, s.millage_ly, s.taxes_ly,
  s.taxable_cy, s.millage_proposed, s.taxes_proposed,
  s.millage_rollback, s.taxes_rollback
from stg_ta s
join ppa.parcels p on p.roll_year = s.roll_year and p.parcel_number = s.parcel_number;

insert into ppa.non_ad_valorem (parcel_id, seq, description, rate, units, amount)
select p.id, s.seq, s.description, s.rate, s.units, s.amount
from stg_nav s
join ppa.parcels p on p.roll_year = s.roll_year and p.parcel_number = s.parcel_number;

-- ---------- public hearings upsert ----------
insert into ppa.public_hearings
  select * from stg_ph
on conflict (roll_year) do update set
  county_meeting = excluded.county_meeting,
  county_place   = excluded.county_place,
  schools_meeting = excluded.schools_meeting,
  schools_place   = excluded.schools_place,
  wmd_meeting = excluded.wmd_meeting, wmd_place = excluded.wmd_place,
  municipality_meeting = excluded.municipality_meeting,
  municipality_place   = excluded.municipality_place;

-- ---------- sanity counts ----------
select 'parcels'              as tbl, count(*) from ppa.parcels
union all select 'exemptions',          count(*) from ppa.exemptions
union all select 'assessment_reductions', count(*) from ppa.assessment_reductions
union all select 'taxing_authorities',  count(*) from ppa.taxing_authorities
union all select 'non_ad_valorem',      count(*) from ppa.non_ad_valorem
union all select 'public_hearings',     count(*) from ppa.public_hearings;

commit;

-- After-load tuning (run once, not strictly necessary for temp-tabled staging)
analyze ppa.parcels;
analyze ppa.taxing_authorities;
analyze ppa.non_ad_valorem;
analyze ppa.exemptions;
analyze ppa.assessment_reductions;
