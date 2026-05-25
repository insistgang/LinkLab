-- LinkAble RealMode Phase-3: minimal authenticated CRUD.
-- Scope: profiles, help_requests, volunteer_profiles only.
-- This migration uses Supabase Auth users and anon-key RLS isolation.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'seeker'
    check (role in ('seeker', 'volunteer', 'admin')),
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.help_requests (
  id uuid primary key default gen_random_uuid(),
  seeker_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null default '',
  status text not null default 'created'
    check (
      status in (
        'created',
        'ai_processing',
        'ai_resolved',
        'matching',
        'connected',
        'expired',
        'cancelled',
        'completed'
      )
    ),
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.volunteer_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  service_radius_m integer not null default 3000
    check (service_radius_m >= 0 and service_radius_m <= 100000),
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint volunteer_profiles_user_id_unique unique (user_id)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists help_requests_set_updated_at on public.help_requests;
create trigger help_requests_set_updated_at
before update on public.help_requests
for each row execute function public.set_updated_at();

drop trigger if exists volunteer_profiles_set_updated_at on public.volunteer_profiles;
create trigger volunteer_profiles_set_updated_at
before update on public.volunteer_profiles
for each row execute function public.set_updated_at();

create index if not exists profiles_role_idx
  on public.profiles (role);

create index if not exists help_requests_seeker_created_at_idx
  on public.help_requests (seeker_id, created_at desc);

create index if not exists help_requests_open_status_created_at_idx
  on public.help_requests (status, created_at desc)
  where status in ('created', 'matching');

create index if not exists volunteer_profiles_available_idx
  on public.volunteer_profiles (is_available, updated_at desc);

alter table public.profiles enable row level security;
alter table public.help_requests enable row level security;
alter table public.volunteer_profiles enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists help_requests_seeker_select_own on public.help_requests;
create policy help_requests_seeker_select_own
on public.help_requests
for select
to authenticated
using ((select auth.uid()) = seeker_id);

drop policy if exists help_requests_seeker_insert_own on public.help_requests;
create policy help_requests_seeker_insert_own
on public.help_requests
for insert
to authenticated
with check ((select auth.uid()) = seeker_id);

drop policy if exists help_requests_seeker_update_own on public.help_requests;
create policy help_requests_seeker_update_own
on public.help_requests
for update
to authenticated
using ((select auth.uid()) = seeker_id)
with check ((select auth.uid()) = seeker_id);

drop policy if exists help_requests_seeker_delete_own on public.help_requests;
create policy help_requests_seeker_delete_own
on public.help_requests
for delete
to authenticated
using ((select auth.uid()) = seeker_id);

drop policy if exists help_requests_volunteer_read_open on public.help_requests;
create policy help_requests_volunteer_read_open
on public.help_requests
for select
to authenticated
using (
  status in ('created', 'matching')
  and exists (
    select 1
    from public.volunteer_profiles vp
    where vp.user_id = (select auth.uid())
      and vp.is_available = true
  )
);

drop policy if exists volunteer_profiles_select_own on public.volunteer_profiles;
create policy volunteer_profiles_select_own
on public.volunteer_profiles
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists volunteer_profiles_insert_own on public.volunteer_profiles;
create policy volunteer_profiles_insert_own
on public.volunteer_profiles
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists volunteer_profiles_update_own on public.volunteer_profiles;
create policy volunteer_profiles_update_own
on public.volunteer_profiles
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists volunteer_profiles_delete_own on public.volunteer_profiles;
create policy volunteer_profiles_delete_own
on public.volunteer_profiles
for delete
to authenticated
using ((select auth.uid()) = user_id);
