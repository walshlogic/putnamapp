# Person Profile — Project Notes

**Status:** Not started. Designed during the 2026-05-10 session. Saved here so the
full reasoning is available if/when work begins.

## What it is

A "Master Name Search" style feature: when a user is viewing one record about a
person (a booking, a traffic citation, a criminal case, an Official Records
document, or an Incident Log entry), they should be able to see **all other
records in the app's database that belong to the same person** — across every
source we've ingested. Plus a clearly-labeled "Possible Matches" section for
records we *think* may be the same person but aren't sure.

User-facing name: **Person Profile**.
Internal / DB / admin name: keep "Master Name Index" terminology, like LE.
(The user is a former police officer; MNI is familiar to them.)

## The data we'd unify

| Source | Person identifier | Has DOB? | Quality |
|---|---|---|---|
| `bookings` (PCSO) | `mni_no` (PCSO's own MNI) + name + race + gender | Indirect — age + `booked_persons` window | Standardized names |
| `traffic_citations` (Clerk of Court) | Case # | Usually yes | Slightly different format |
| `criminal_back_history` (Clerk of Court) | Case # | Usually yes | Slightly different format |
| `ori_records` (Clerk of Court) | Document # + party names | **Rarely** | Free-form party text |
| `incidents` (in-app) | Linked via `incident_persons` (booking_no / mni_no / label) | n/a | Admin-curated |

PCSO MNI is gold inside PCSO data. It does NOT extend to Clerk data. Clerk
records have no equivalent. ORI is the hardest because party text is free-form
and rarely has a DOB anchor.

## Design rules (settled)

1. **No cross-source auto-linking, ever.** Even Strong-confidence cross-source
   matches are *suggestions* until a user or admin acts on them.
2. **Within a single source, auto-link is fine.** Two PCSO bookings with the
   same `mni_no` are obviously the same person per PCSO's own definition. That
   is not cross-linking, it's respecting the source's existing identity. So
   the per-person record is keyed off PCSO MNI for the booking side.
3. **Three confidence tiers** for cross-source suggestions: **Strong / Medium /
   Weak**. User-friendly labels (not HIGH/MEDIUM/LOW).
4. **End-users see Strong + Medium suggestions** (with clear "possible match"
   labeling) **plus admin-confirmed links**. They do NOT see Weak suggestions.
5. **Admins see everything**: Strong, Medium, Weak, plus user-submitted
   decisions awaiting their review.
6. **Decisions are sticky**: confirmed stays confirmed, rejected stays
   rejected, forever (until an admin explicitly un-decides). The matching job
   never re-suggests a rejected pair.
7. **Users can flag** suggestions as "yes same" or "no not same", but those
   are *pending admin approval* — they don't directly modify what other users
   see. Goes into the admin queue.

## Initial confidence thresholds (proposal)

These are starting points; the matching algorithm is iterative software and
the thresholds get tuned against real data.

| Tier | Trigger |
|---|---|
| **Strong** | Normalized name **exact** + DOB year **exact** (or DOB falls within a 1-year window from `booked_persons`) |
| **Medium** | Normalized name exact + DOB year within ±2 years **OR** strong fuzzy name (Levenshtein ≤ 2) + DOB year exact **OR** name + race + gender match (no DOB) |
| **Weak** | Phonetic name match (Soundex / Metaphone) **OR** name-only with no other signal |

User concern: Medium needs to be inclusive enough that real matches don't fall
to Weak. Calibrate by inspecting sample matches in each tier after the first
algorithm run; expect tuning passes.

## Data model sketch

### Three tables, beyond the existing sources

**`persons`** — the canonical identity row
```
id              uuid PK
canonical_name  text                -- best-known formatted name
pcso_mni_no     text unique nullable -- when applicable
created_at, updated_at
```

**`person_links`** — confirmed links (admin-decided "this record belongs to this person")
```
id              uuid PK
person_id       uuid REFERENCES persons(id) ON DELETE CASCADE
source_table    text  -- 'bookings','traffic_citations','criminal_back_history','ori_records','incidents'
source_id       text  -- the record's PK in its own table
linked_by       uuid REFERENCES auth.users(id) -- the admin who confirmed
linked_at       timestamptz
UNIQUE (source_table, source_id)
```

**`person_link_decisions`** — every system suggestion + every user/admin call
```
id              uuid PK
source_a_table  text
source_a_id     text
source_b_table  text
source_b_id     text
decision        text CHECK IN ('suggested','user_yes','user_no','admin_yes','admin_no')
confidence_tier text CHECK IN ('strong','medium','weak') -- for system suggestions; nullable for manual user flags
decided_by      uuid REFERENCES auth.users(id) NULL  -- null if system-generated
decided_at      timestamptz default now()
UNIQUE (source_a_table, source_a_id, source_b_table, source_b_id)
```

The matching job inserts `suggested` rows with a tier. Users insert `user_yes`
or `user_no` rows. Admins insert `admin_yes` or `admin_no` rows.

When admin makes a decision, append a `person_links` row (for yes) and update
the decision row to `admin_yes` (for the audit trail). Or for `admin_no`, just
update the decision row — the suggestion is suppressed everywhere.

## UI sketch

### On any record (booking, citation, criminal case, ORI doc, incident)

A new section at the bottom of the detail screen:

```
SAME PERSON (3 confirmed)
├─ Bookings: 5 records (admin-confirmed)
├─ Criminal History: 2 cases
└─ Traffic Citations: 1

POSSIBLE MATCHES (signed-in users)
├─ ▌ Strong (2)
│   ├─ Booking #25-1234 — same name, exact DOB
│   └─ Criminal case 2023-CR-456 — same name, exact DOB
└─ ▌ Medium (1)
    └─ Traffic citation 2024-TR-789 — same name, DOB within 1 year
       [User can tap: "Same person" / "Not the same"]

(Weak tier hidden from non-admins)
```

For **admins**, an additional:
```
POSSIBLE MATCHES (admin)
├─ ▌ Strong (2)
├─ ▌ Medium (1)
└─ ▌ Weak (4)  [collapsed]
   [Inline ✓ "Confirm" / ✗ "Reject" buttons]
```

### Admin Queue screen

Surfaces everything pending admin review:

- Side-by-side card layout showing record A vs record B (name, DOB if known, race/gender, agency, date of activity)
- Buttons: "Same person" / "Not same" / "Open both side-by-side"
- Sort by: confidence tier first, then user-submitted age (oldest first)
- Filter: show only user-submitted, only system, only Strong, etc.
- Batch action: "Approve all Strong matches" for confident users

## Auth / public visibility

Already settled tonight:

- The app **requires login** for every screen except the auth pages
  (current `app_router.dart` behavior). No change needed.
- **Anonymous users will never see** Person Profile content — but anonymous
  users don't exist anyway under the current router.
- For un-signed-in visitors evaluating the app: a separate "Preview / What's
  inside" button on the login screen. Three options to choose from when
  building:
  1. **Static screen tour** — curated screenshots, no live data. Lowest risk.
  2. **Anonymous Supabase auth session** — real data, read-only. Requires
     reviewing every RLS policy to make sure nothing privileged leaks.
  3. **Demo data subset** — maintain a separate "demo" set the preview
     surfaces. Most polished, most maintenance.

  Recommend option 1 for the first pass.

## Monetization context

The app's monetization plumbing is already in place — no rewrite needed
when the team decides to flip pricing on:

- `purchases_flutter` + `purchases_ui_flutter` (RevenueCat) in `pubspec.yaml`
- `auth_providers.dart` has `isPremiumUserProvider`, `subscriptionTierProvider`
  ('free' / 'silver' / 'gold'), `startTrial` flow
- `TierSelectionScreen` already exists

Going from "free for everyone" to tiered pricing is a settings-change in
RevenueCat + a few `ref.watch(isPremiumUserProvider)` checks at gate points.
Person Profile is a natural candidate for a paid-tier feature later.

## Prerequisites — what's already in place

- **`booked_persons` table populated** (11,605 persons; 1,912 with single-year
  DOB window; 118 with single-month-and-year). Critical anchor for matching.
  See `~/.claude/projects/-Users-walshwill-Putnam-Life-App-putnamlife/memory/project_birthdate_calc.md`.
- **`user_roles` + `is_admin()` + `is_elevated_or_admin()`** RLS helpers
  (built for Incident Log; can be reused here).
- **Admin gating UI pattern** (built for Incident Log: floating "+" button,
  three-dot menu with Edit/Delete — same pattern works for Person Profile
  admin actions).

## What's hard / where it bites

1. **False merges are worse than missed merges.** Defaults must lean
   conservative. We never silently merge cross-source records.
2. **Name normalization isn't trivial.** "JONES, ROBERT" vs "ROBERT JONES" vs
   "R. JONES" vs "BOB JONES". Build a normalizer; it will never catch
   everything.
3. **Legal / ethical**: collating arrest + civil + court records into one
   searchable profile carries a higher bar than each source on its own.
   Anonymous users should not see suggestions (already decided — they won't
   exist). Authenticated user view still needs careful labeling for "possible"
   vs "confirmed".
4. **Re-matching on new data**: when the hourly PCSO scrape adds a booking,
   the matching job needs to re-evaluate that person's existing clerk links.
   Easy if we run the matcher daily; harder if real-time is needed (probably
   not needed v1).

## Effort estimate (rough)

| Phase | Scope | Estimate |
|---|---|---|
| **1 — Foundation** | `persons` schema, PCSO MNI clustering, basic Person Profile screen showing same-source bookings | ~3 days |
| **2 — Suggestions** | Matching pipeline (daily pg_cron), `person_link_decisions` table, admin confirm/reject UI, user flag UI | ~1 week |
| **3 — Cross-source + ORI + Incidents** | Clerk traffic/criminal matching, ORI fuzzy matching, Incident Log linkage, tier-based visibility gating | ~3–4 days |

Total: **~2 weeks** of focused work, broken into ship-able phases.

## When we revisit

Worth doing first, in this order:

1. Decide visibility policy for **non-admin signed-in users** — see Strong+Medium
   (current plan) vs. paid-only.
2. Decide whether **users can flag** at all in v1, or whether v1 is admin-only
   curation (simpler; defer user-flag UI to v2).
3. Read up on the `booked_persons` table once more to make sure the DOB
   windows are as tight as they should be after another year of bookings.

Then start Phase 1.
