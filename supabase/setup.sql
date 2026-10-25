-- ============================================================================
--  APEX COMPUTERS — Supabase one-time setup
--  Run this in: Supabase Dashboard -> SQL Editor -> New query -> Run
--  (Safe to run more than once.)
-- ============================================================================

-- pgcrypto gives us digest() for the password hash.
-- On Supabase it already exists in the "extensions" schema.
create extension if not exists pgcrypto with schema extensions;
set search_path = public, extensions;

-- ---------------------------------------------------------------------------
-- 1) TABLE: one row that holds the whole website content as JSON
-- ---------------------------------------------------------------------------
create table if not exists public.site_content (
  id         text primary key,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.site_content enable row level security;

-- anyone may READ the website content
drop policy if exists "site_content read" on public.site_content;
create policy "site_content read"
  on public.site_content for select
  to anon, authenticated
  using (true);

-- writes are blocked for everyone; the functions below (SECURITY DEFINER)
-- do the writing after checking the admin password
drop policy if exists "site_content write" on public.site_content;
revoke insert, update, delete on public.site_content from anon, authenticated;

-- make sure the main row exists
insert into public.site_content (id, data)
values ('main', '{}'::jsonb)
on conflict (id) do nothing;

-- reading needs a table privilege (RLS still applies)
grant usage on schema public to anon, authenticated;
grant select on public.site_content to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2) SETTINGS TABLE: stores the hashed admin password
-- ---------------------------------------------------------------------------
create table if not exists public.site_settings (
  key   text primary key,
  value text
);

alter table public.site_settings enable row level security;
revoke all on public.site_settings from anon, authenticated;

-- default password: 7939015601   (change it later from Admin > Settings)
insert into public.site_settings (key, value)
values ('admin_pass', encode(digest('7939015601', 'sha256'), 'hex'))
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- 3) FUNCTIONS used by the admin panel
-- ---------------------------------------------------------------------------

-- 3a) check the password (used to unlock the panel)
create or replace function public.apex_check(pass text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare stored text;
begin
  select value into stored from public.site_settings where key = 'admin_pass';
  if stored is null then
    return pass = '7939015601';
  end if;
  return stored = encode(digest(coalesce(pass, ''), 'sha256'), 'hex');
end;
$$;

-- 3b) save the whole website content (only with the right password)
create or replace function public.apex_save(payload jsonb, pass text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare stored text;
begin
  select value into stored from public.site_settings where key = 'admin_pass';
  if stored is null or stored <> encode(digest(coalesce(pass, ''), 'sha256'), 'hex') then
    raise exception 'wrong password' using errcode = '28000';
  end if;

  insert into public.site_content (id, data, updated_at)
  values ('main', payload, now())
  on conflict (id) do update
     set data = excluded.data, updated_at = now();

  return true;
end;
$$;

-- 3c) change the password (asks for the old one)
create or replace function public.apex_change_pass(oldp text, newp text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare stored text;
begin
  select value into stored from public.site_settings where key = 'admin_pass';
  if length(coalesce(newp, '')) < 6 then
    raise exception 'password too short';
  end if;
  if stored is null then
    if oldp <> '7939015601' then
      raise exception 'wrong password';
    end if;
  elsif stored <> encode(digest(coalesce(oldp, ''), 'sha256'), 'hex') then
    raise exception 'wrong password';
  end if;

  insert into public.site_settings (key, value)
  values ('admin_pass', encode(digest(newp, 'sha256'), 'hex'))
  on conflict (key) do update set value = excluded.value;

  return true;
end;
$$;

-- let the public anon key call these three functions
grant execute on function public.apex_check(text)               to anon, authenticated;
grant execute on function public.apex_save(jsonb, text)         to anon, authenticated;
grant execute on function public.apex_change_pass(text, text)   to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4) STORAGE: public bucket "media" for product images
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do update set public = true;

-- everyone can view images
drop policy if exists "media public read" on storage.objects;
create policy "media public read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'media');

-- upload / replace / delete images from the admin panel
drop policy if exists "media upload"  on storage.objects;
create policy "media upload"
  on storage.objects for insert
  to anon, authenticated
  with check (bucket_id = 'media');

drop policy if exists "media update"  on storage.objects;
create policy "media update"
  on storage.objects for update
  to anon, authenticated
  using (bucket_id = 'media');

drop policy if exists "media delete"  on storage.objects;
create policy "media delete"
  on storage.objects for delete
  to anon, authenticated
  using (bucket_id = 'media');

-- ---------------------------------------------------------------------------
-- 5) (OPTIONAL) If uploads still fail with "permission denied", your project
--    has extra restrictions on storage. Run these two lines:
-- ---------------------------------------------------------------------------
-- grant all on table storage.objects to anon, authenticated;
-- grant select on table storage.buckets to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 6) (OPTIONAL, for testing only) allow the anon key to write the table
--    directly — needed only if you disable the functions above.
--    NOT recommended for production.
-- ---------------------------------------------------------------------------
-- create policy "site_content write open" on public.site_content
--   for all to anon using (true) with check (true);

-- ============================================================================
--  Done. Now open the website -> type 7939015601 in any search bar ->
--  Admin > Settings > Database connection -> paste URL + anon key -> Save.
-- ============================================================================
