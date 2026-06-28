-- GaleriPro Supabase schema and RLS setup
-- Safe to re-run: this script avoids DROP TABLE and preserves existing data.
-- Run in Supabase SQL Editor, then test with two different users.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  galeri_adi text not null default '',
  telefon text,
  adres text,
  created_at timestamptz not null default now()
);

create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plaka text not null,
  marka text not null,
  model text not null,
  yil integer,
  renk text,
  kilometre integer,
  alis_fiyati numeric not null default 0,
  alis_tarihi date,
  satis_fiyati numeric,
  satis_tarihi date,
  kar numeric generated always as (
    case
      when satis_fiyati is not null then satis_fiyati - alis_fiyati
      else null
    end
  ) stored,
  durum text not null default 'stokta',
  notlar text,
  satici_adi text,
  satici_telefon text,
  satici_adres text,
  alici_adi text,
  alici_telefon text,
  alici_adres text,
  created_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  tur text not null default 'diger',
  tutar numeric not null default 0,
  aciklama text,
  tarih date default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.price_estimates (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references public.vehicles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  kaynak text,
  tahmini_fiyat numeric not null,
  aciklama text,
  created_at timestamptz not null default now()
);

-- Existing projects may have been created from an older script. Add missing
-- columns without touching current rows.
alter table public.vehicles add column if not exists satici_adi text;
alter table public.vehicles add column if not exists satici_telefon text;
alter table public.vehicles add column if not exists satici_adres text;
alter table public.vehicles add column if not exists alici_adi text;
alter table public.vehicles add column if not exists alici_telefon text;
alter table public.vehicles add column if not exists alici_adres text;

-- ---------------------------------------------------------------------------
-- Constraints and indexes
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'vehicles_durum_check'
      and conrelid = 'public.vehicles'::regclass
  ) then
    alter table public.vehicles
      add constraint vehicles_durum_check
      check (durum in ('stokta', 'satildi', 'rezerve'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'vehicles_non_negative_values_check'
      and conrelid = 'public.vehicles'::regclass
  ) then
    alter table public.vehicles
      add constraint vehicles_non_negative_values_check
      check (
        alis_fiyati >= 0
        and (satis_fiyati is null or satis_fiyati >= 0)
        and (kilometre is null or kilometre >= 0)
        and (yil is null or yil between 1900 and 2100)
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'expenses_tur_check'
      and conrelid = 'public.expenses'::regclass
  ) then
    alter table public.expenses
      add constraint expenses_tur_check
      check (tur in ('bakim', 'boya', 'sigorta', 'vergi', 'diger'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'expenses_tutar_non_negative_check'
      and conrelid = 'public.expenses'::regclass
  ) then
    alter table public.expenses
      add constraint expenses_tutar_non_negative_check
      check (tutar >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'vehicles_user_plaka_unique'
      and conrelid = 'public.vehicles'::regclass
  ) then
    alter table public.vehicles
      add constraint vehicles_user_plaka_unique unique (user_id, plaka);
  end if;
end $$;

create index if not exists vehicles_user_id_idx
  on public.vehicles(user_id);

create index if not exists vehicles_user_durum_idx
  on public.vehicles(user_id, durum);

create index if not exists vehicles_created_at_idx
  on public.vehicles(created_at desc);

create index if not exists expenses_user_id_idx
  on public.expenses(user_id);

create index if not exists expenses_vehicle_id_idx
  on public.expenses(vehicle_id);

create index if not exists price_estimates_user_id_idx
  on public.price_estimates(user_id);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.vehicles enable row level security;
alter table public.expenses enable row level security;
alter table public.price_estimates enable row level security;

drop policy if exists "profiles_own" on public.profiles;
drop policy if exists "vehicles_own" on public.vehicles;
drop policy if exists "expenses_own" on public.expenses;
drop policy if exists "price_estimates_own" on public.price_estimates;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_delete_own" on public.profiles;

create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "profiles_insert_own"
  on public.profiles
  for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "profiles_delete_own"
  on public.profiles
  for delete
  to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "vehicles_select_own" on public.vehicles;
drop policy if exists "vehicles_insert_own" on public.vehicles;
drop policy if exists "vehicles_update_own" on public.vehicles;
drop policy if exists "vehicles_delete_own" on public.vehicles;

create policy "vehicles_select_own"
  on public.vehicles
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "vehicles_insert_own"
  on public.vehicles
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "vehicles_update_own"
  on public.vehicles
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "vehicles_delete_own"
  on public.vehicles
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "expenses_select_own" on public.expenses;
drop policy if exists "expenses_insert_own" on public.expenses;
drop policy if exists "expenses_update_own" on public.expenses;
drop policy if exists "expenses_delete_own" on public.expenses;

create policy "expenses_select_own"
  on public.expenses
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "expenses_insert_own"
  on public.expenses
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "expenses_update_own"
  on public.expenses
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "expenses_delete_own"
  on public.expenses
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "price_estimates_select_own" on public.price_estimates;
drop policy if exists "price_estimates_insert_own" on public.price_estimates;
drop policy if exists "price_estimates_update_own" on public.price_estimates;
drop policy if exists "price_estimates_delete_own" on public.price_estimates;

create policy "price_estimates_select_own"
  on public.price_estimates
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "price_estimates_insert_own"
  on public.price_estimates
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "price_estimates_update_own"
  on public.price_estimates
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "price_estimates_delete_own"
  on public.price_estimates
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- Auth trigger: create profile row when a user signs up
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, galeri_adi)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'galeri_adi', '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public;
revoke all on function public.handle_new_user() from anon;
revoke all on function public.handle_new_user() from authenticated;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

