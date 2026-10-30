-- Family Construction Timekeeping - Supabase setup
-- Run in Supabase Dashboard > SQL Editor. Safe to re-run.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'employee' check (role in ('employee','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.job_sites (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.time_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  job_site_id uuid references public.job_sites(id),
  clock_in timestamptz not null default now(),
  clock_out timestamptz,
  in_lat double precision, in_lng double precision,
  out_lat double precision, out_lng double precision,
  photo_path text,
  notes text,
  created_at timestamptz not null default now()
);
create index if not exists time_cards_user_idx on public.time_cards(user_id, clock_in desc);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Admin helper
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

alter table public.profiles enable row level security;
alter table public.job_sites enable row level security;
alter table public.time_cards enable row level security;

-- profiles
drop policy if exists "profiles read own" on public.profiles;
create policy "profiles read own" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "profiles admin all" on public.profiles;
create policy "profiles admin all" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- job_sites
drop policy if exists "job_sites read active" on public.job_sites;
create policy "job_sites read active" on public.job_sites for select to authenticated using (active or public.is_admin());
drop policy if exists "job_sites admin write" on public.job_sites;
create policy "job_sites admin write" on public.job_sites for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- time_cards
drop policy if exists "time_cards read own" on public.time_cards;
create policy "time_cards read own" on public.time_cards for select to authenticated using (user_id = auth.uid());
drop policy if exists "time_cards insert own" on public.time_cards;
create policy "time_cards insert own" on public.time_cards for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "time_cards update own" on public.time_cards;
create policy "time_cards update own" on public.time_cards for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "time_cards admin all" on public.time_cards;
create policy "time_cards admin all" on public.time_cards for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Storage: private 'photos' bucket, files stored as <user_id>/<file>
insert into storage.buckets (id, name, public) values ('photos', 'photos', false)
on conflict (id) do nothing;
drop policy if exists "photos upload own" on storage.objects;
create policy "photos upload own" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "photos read own" on storage.objects;
create policy "photos read own" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- Make a user admin (run after they sign up):
-- update public.profiles set role = 'admin' where email = 'you@example.com';
