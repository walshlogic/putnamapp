-- Booking comments for jail records/person history
create table if not exists public.booking_comments (
  id uuid primary key default gen_random_uuid(),
  booking_no text not null,
  booking_date timestamptz null,
  mni_no text null,
  person_name text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  comment text not null,
  created_at timestamptz not null default now()
);

create index if not exists booking_comments_mni_no_idx
  on public.booking_comments (mni_no);
create index if not exists booking_comments_person_name_idx
  on public.booking_comments (person_name);
create index if not exists booking_comments_booking_no_idx
  on public.booking_comments (booking_no);
create index if not exists booking_comments_created_at_idx
  on public.booking_comments (created_at desc);

alter table public.booking_comments enable row level security;

-- Anyone can read comments
create policy "booking_comments_select_all"
  on public.booking_comments
  for select
  using (true);

-- Only authenticated users can insert their own comments
create policy "booking_comments_insert_own"
  on public.booking_comments
  for insert
  with check (auth.uid() = user_id);

-- Users can update/delete their own comments (optional)
create policy "booking_comments_update_own"
  on public.booking_comments
  for update
  using (auth.uid() = user_id);

create policy "booking_comments_delete_own"
  on public.booking_comments
  for delete
  using (auth.uid() = user_id);
