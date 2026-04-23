#!/usr/bin/env python3
"""
Parse Putnam County TRIM Data Package into CSVs ready for Supabase ingest.

Input : RE_Trim_Notice_Export.txt  (pipe-delimited, 182 or 183 fields)
Output: parcels.csv, assessment_reductions.csv, exemptions.csv,
        taxing_authorities.csv, non_ad_valorem.csv, public_hearings.csv

Usage: python parse_trim.py /path/to/RE_Trim_Notice_Export.txt ./out
"""
import csv, os, re, sys
from pathlib import Path

# 1-based field indexes per the DR-474 layout (RP TRIM Field Descriptions r2024)
F = lambda n: n - 1  # convert 1-based f### to 0-based list index

AUTHORITY_MAP = [
    # (authority_type, label_idx, taxable_ly, mill_ly, tax_ly, taxable_cy, mill_prop, tax_prop, mill_rb, tax_rb)
    ("county",         76,  77,  78,  79,  80,  81,  82,  83,  84),
    ("fire_mstu",      85,  86,  87,  88,  89,  90,  91,  92,  93),
    ("school_state",   95,  96,  97,  98,  99, 100, 101, 102, 103),
    ("school_local",  104, 105, 106, 107, 108, 109, 110, 111, 112),
    ("wmd",           113, 114, 115, 116, 117, 118, 119, 120, 121),
    ("municipality",  122, 123, 124, 125, 126, 127, 128, 129, 130),
    ("school_debt",   174, 175, 176, 177, 178, 179, 180, 181, 182),
]

NUM_RE = re.compile(r"[\s,]")

def num(v):
    v = (v or "").strip()
    if not v: return None
    v = NUM_RE.sub("", v)
    if v in ("-", ""): return None
    try:
        return float(v) if "." in v else int(v)
    except ValueError:
        return None

def text(v):
    return (v or "").strip() or None

def split_city_state(v):
    v = text(v)
    if not v: return (None, None)
    if "," in v:
        c, s = v.rsplit(",", 1)
        return (c.strip() or None, s.strip() or None)
    return (v, None)

def legal_desc(flds):
    parts = [text(flds[F(i)]) for i in (5, 6, 7, 8)]
    parts = [p for p in parts if p and "*** Continued" not in p]
    return "; ".join(parts) if parts else None

def parse_file(src: Path, outdir: Path):
    outdir.mkdir(parents=True, exist_ok=True)

    f_parcels = open(outdir / "parcels.csv", "w", newline="", encoding="utf-8")
    f_ar      = open(outdir / "assessment_reductions.csv", "w", newline="", encoding="utf-8")
    f_ex      = open(outdir / "exemptions.csv", "w", newline="", encoding="utf-8")
    f_ta      = open(outdir / "taxing_authorities.csv", "w", newline="", encoding="utf-8")
    f_nav     = open(outdir / "non_ad_valorem.csv", "w", newline="", encoding="utf-8")
    f_ph      = open(outdir / "public_hearings.csv", "w", newline="", encoding="utf-8")

    w_parcels = csv.writer(f_parcels)
    w_ar      = csv.writer(f_ar)
    w_ex      = csv.writer(f_ex)
    w_ta      = csv.writer(f_ta)
    w_nav     = csv.writer(f_nav)
    w_ph      = csv.writer(f_ph)

    w_parcels.writerow([
        "roll_year","parcel_number","continued_on_roll",
        "physical_address","legal_description",
        "owner_name","co_owner_name","mailing_addr1","mailing_addr2",
        "mailing_city","mailing_state","mailing_zip","petition_deadline",
        "co_market_ly","co_assmt_red_ly","co_assessed_ly","co_exempt_ly","co_taxable_ly",
        "sch_market_ly","sch_assmt_red_ly","sch_assessed_ly","sch_exempt_ly","sch_taxable_ly",
        "oth_market_ly","oth_assmt_red_ly","oth_assessed_ly","oth_exempt_ly","oth_taxable_ly",
        "mun_market_ly","mun_assmt_red_ly","mun_assessed_ly","mun_exempt_ly","mun_taxable_ly",
        "co_market","co_assmt_red","co_assessed","co_exempt","co_taxable",
        "sch_market","sch_assmt_red","sch_assessed","sch_exempt","sch_taxable",
        "oth_market","oth_assmt_red","oth_assessed","oth_exempt","oth_taxable",
        "mun_market","mun_assmt_red","mun_assessed","mun_exempt","mun_taxable",
        "total_ad_val_ly","total_ad_val_proposed","total_ad_val_rollback",
        "total_non_ad_val","total_non_ad_val_ly",
        "total_all_ly","total_all_proposed","total_all_rollback",
    ])
    w_ar.writerow(["parcel_number","roll_year","seq","description","tax_district","amount"])
    w_ex.writerow(["parcel_number","roll_year","seq","description","tax_district","amount"])
    w_ta.writerow([
        "parcel_number","roll_year","authority_type","authority_label",
        "taxable_ly","millage_ly","taxes_ly",
        "taxable_cy","millage_proposed","taxes_proposed",
        "millage_rollback","taxes_rollback",
    ])
    w_nav.writerow(["parcel_number","roll_year","seq","description","rate","units","amount"])
    w_ph.writerow([
        "roll_year","county_meeting","county_place","schools_meeting","schools_place",
        "wmd_meeting","wmd_place","municipality_meeting","municipality_place"
    ])

    hearings_seen = set()
    total = 0
    with open(src, "r", encoding="latin-1") as fh:
        for line in fh:
            flds = line.rstrip("\n").split("|")
            # tolerate 182/183 length variants
            if len(flds) < 182:
                continue
            roll_year = num(flds[F(2)])
            parcel    = text(flds[F(3)]).rstrip("*") if flds[F(3)] else None
            if not parcel: continue
            continued = "*** Continued" in (flds[F(8)] or "")

            city, state = split_city_state(flds[F(12)])
            w_parcels.writerow([
                roll_year, parcel, continued,
                text(flds[F(4)]), legal_desc(flds),
                text(flds[F(9)]), text(flds[F(173)]),
                text(flds[F(10)]), text(flds[F(11)]),
                city, state, text(flds[F(13)]),
                text(flds[F(74)]),
                *(num(flds[F(i)]) for i in range(14, 29)),      # LY co/sch/oth
                num(flds[F(163)]), num(flds[F(164)]), num(flds[F(165)]), num(flds[F(166)]), num(flds[F(167)]),  # muni LY
                *(num(flds[F(i)]) for i in range(29, 44)),      # CY co/sch/oth
                num(flds[F(168)]), num(flds[F(169)]), num(flds[F(170)]), num(flds[F(171)]), num(flds[F(172)]),  # muni CY
                num(flds[F(131)]), num(flds[F(132)]), num(flds[F(133)]),
                num(flds[F(150)]), num(flds[F(162)]),
                num(flds[F(151)]), num(flds[F(152)]), num(flds[F(153)]),
            ])

            # Assessment reductions (block 3)
            for seq, base in enumerate([44, 47, 50], start=1):
                desc = text(flds[F(base)])
                if desc:
                    w_ar.writerow([parcel, roll_year, seq, desc, text(flds[F(base+1)]), num(flds[F(base+2)])])

            # Exemptions (block 4): 7 slots at 53, 56, 59, 62, 65, 68, 71
            for seq, base in enumerate([53, 56, 59, 62, 65, 68, 71], start=1):
                desc = text(flds[F(base)])
                if desc:
                    w_ex.writerow([parcel, roll_year, seq, desc, text(flds[F(base+1)]), num(flds[F(base+2)])])

            # Taxing authorities (block 6)
            for auth_type, li, tly, mly, xly, tcy, mp, xp, mrb, xrb in AUTHORITY_MAP:
                label = text(flds[F(li)])
                if not label or label.endswith(":"):  # skip "Public Schools:" header cell
                    continue
                w_ta.writerow([
                    parcel, roll_year, auth_type, label,
                    num(flds[F(tly)]), num(flds[F(mly)]), num(flds[F(xly)]),
                    num(flds[F(tcy)]), num(flds[F(mp)]),  num(flds[F(xp)]),
                    num(flds[F(mrb)]), num(flds[F(xrb)]),
                ])

            # Non-ad-valorem (block 7): 4 slots at 134, 138, 142, 146 (desc, rate, units, amount)
            for seq, base in enumerate([134, 138, 142, 146], start=1):
                desc = text(flds[F(base)])
                if desc:
                    w_nav.writerow([parcel, roll_year, seq, desc,
                                    num(flds[F(base+1)]), num(flds[F(base+2)]), num(flds[F(base+3)])])

            # Public hearings (block 9) - dedupe per roll year
            if roll_year not in hearings_seen:
                w_ph.writerow([
                    roll_year,
                    text(flds[F(154)]), text(flds[F(155)]),
                    text(flds[F(156)]), text(flds[F(157)]),
                    text(flds[F(158)]), text(flds[F(159)]),
                    text(flds[F(160)]), text(flds[F(161)]),
                ])
                hearings_seen.add(roll_year)

            total += 1
            if total % 10000 == 0:
                print(f"  parsed {total:,} records...", file=sys.stderr)

    for fh in (f_parcels, f_ar, f_ex, f_ta, f_nav, f_ph):
        fh.close()
    print(f"Done. {total:,} parcels written to {outdir}", file=sys.stderr)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: parse_trim.py <input.txt> <out_dir>")
    parse_file(Path(sys.argv[1]), Path(sys.argv[2]))
