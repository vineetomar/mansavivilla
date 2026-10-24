-- MOO ERP v0.1: Supabase SQL. Run once in a NEW Supabase project's SQL Editor.
-- No secret or service-role key belongs in the GitHub website.
-- Supabase email authentication must be enabled; only verified users should publish.

create table if not exists public.moo_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 2 and 80),
  headline text not null default '' check (char_length(headline) <= 130),
  organization text not null default '' check (char_length(organization) <= 120),
  city text not null default '' check (char_length(city) <= 100),
  about text not null default '' check (char_length(about) <= 1200),
  linkedin_url text not null default '' check (char_length(linkedin_url) <= 400),
  public_profile boolean not null default false,
  consented_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint moo_public_requires_consent check (not public_profile or consented_at is not null)
);

create table if not exists public.moo_opportunities (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.moo_profiles(user_id) on delete cascade,
  kind text not null check (kind in ('offer','seek','build')),
  category text not null default 'Other' check (char_length(category) <= 80),
  title text not null check (char_length(trim(title)) between 5 and 120),
  description text not null check (char_length(trim(description)) between 15 and 1800),
  status text not null default 'active' check (status in ('active','paused')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.moo_introductions (
  id uuid primary key default gen_random_uuid(),
  from_user uuid not null references public.moo_profiles(user_id) on delete cascade,
  to_user uuid not null references public.moo_profiles(user_id) on delete cascade,
  opportunity_id uuid references public.moo_opportunities(id) on delete set null,
  message text not null check (char_length(trim(message)) between 10 and 1000),
  created_at timestamptz not null default now(),
  constraint not_to_self check (from_user <> to_user)
);

create index if not exists moo_opps_owner_idx on public.moo_opportunities(owner_id);
create index if not exists moo_opps_status_idx on public.moo_opportunities(status, created_at desc);
create index if not exists moo_intro_recipient_idx on public.moo_introductions(to_user, created_at desc);
create index if not exists moo_intro_sender_idx on public.moo_introductions(from_user, created_at desc);

alter table public.moo_profiles enable row level security;
alter table public.moo_opportunities enable row level security;
alter table public.moo_introductions enable row level security;

revoke all on public.moo_profiles from anon, authenticated;
revoke all on public.moo_opportunities from anon, authenticated;
revoke all on public.moo_introductions from anon, authenticated;

grant select on public.moo_profiles to anon, authenticated;
grant insert, update, delete on public.moo_profiles to authenticated;
grant select on public.moo_opportunities to anon, authenticated;
grant insert, update, delete on public.moo_opportunities to authenticated;
grant select, insert on public.moo_introductions to authenticated;

-- Public profile data contains NO phone number or email.
create policy "moo_profiles_select_public_or_self"
  on public.moo_profiles for select to anon, authenticated
  using (public_profile or user_id = (select auth.uid()));
create policy "moo_profiles_insert_self"
  on public.moo_profiles for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "moo_profiles_update_self"
  on public.moo_profiles for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "moo_profiles_delete_self"
  on public.moo_profiles for delete to authenticated
  using (user_id = (select auth.uid()));

-- Only active opportunities belonging to published members are publicly visible.
create policy "moo_opps_select_public_or_self"
  on public.moo_opportunities for select to anon, authenticated
  using (
    owner_id = (select auth.uid())
    or (status = 'active' and exists (
      select 1 from public.moo_profiles p
      where p.user_id = owner_id and p.public_profile = true
    ))
  );
create policy "moo_opps_insert_self"
  on public.moo_opportunities for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy "moo_opps_update_self"
  on public.moo_opportunities for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
create policy "moo_opps_delete_self"
  on public.moo_opportunities for delete to authenticated
  using (owner_id = (select auth.uid()));

-- Only sender/recipient can view introductions; no public contact list.
create policy "moo_intro_read_participants"
  on public.moo_introductions for select to authenticated
  using (from_user = (select auth.uid()) or to_user = (select auth.uid()));
create policy "moo_intro_insert_sender"
  on public.moo_introductions for insert to authenticated
  with check (
    from_user = (select auth.uid())
    and to_user <> (select auth.uid())
    and exists (
      select 1 from public.moo_profiles p
      where p.user_id = to_user and p.public_profile = true
    )
  );

-- Member data is not a bankable identity/credential verification service.
-- Do not add public phone/email columns without privacy and RLS redesign.
