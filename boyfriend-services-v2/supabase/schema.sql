-- Run once in the Supabase SQL Editor.
-- Both accounts should be created manually in Authentication > Users.
-- Disable public signups in Authentication > Providers > Email.

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 role text not null check (role in ('sarah', 'boyfriend')),
 display_name text not null,
 created_at timestamptz not null default now()
);

create table if not exists public.bookings (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references public.profiles(id),
 provider_id uuid not null references public.profiles(id),
 service_id text not null,
 service_name text not null,
 addons text[] not null default '{}',
 requested_at timestamptz,
 notes text not null default '',
 status text not null default 'pending' check (status in ('pending','approved','declined','cancelled')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.bookings enable row level security;

-- Authenticated members may see the two role IDs to address requests.
create policy "members can read profiles" on public.profiles for select to authenticated using (true);
create policy "members can read their bookings" on public.bookings for select to authenticated using (auth.uid() = customer_id or auth.uid() = provider_id);
create policy "sarah can create a pending request" on public.bookings for insert to authenticated with check (
 auth.uid() = customer_id and status = 'pending'
 and exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'sarah')
 and exists(select 1 from public.profiles p where p.id = provider_id and p.role = 'boyfriend')
);
create policy "boyfriend can decide requests" on public.bookings for update to authenticated using (
 auth.uid() = provider_id and status = 'pending'
) with check (auth.uid() = provider_id and status in ('approved','declined'));
create policy "sarah can cancel own requests" on public.bookings for update to authenticated using (
 auth.uid() = customer_id and status = 'pending'
) with check (auth.uid() = customer_id and status = 'cancelled');

-- Prevent any booking content / ownership being modified during an approval decision.
create or replace function public.protect_booking_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
 if new.customer_id is distinct from old.customer_id or new.provider_id is distinct from old.provider_id
 or new.service_id is distinct from old.service_id or new.service_name is distinct from old.service_name
 or new.addons is distinct from old.addons or new.requested_at is distinct from old.requested_at
 or new.notes is distinct from old.notes or new.created_at is distinct from old.created_at then
  raise exception 'Booking details cannot be modified after submission';
 end if;
 if old.status <> 'pending' then raise exception 'This booking has already been decided'; end if;
 if auth.uid() = old.provider_id and new.status not in ('approved','declined') then raise exception 'Invalid provider decision'; end if;
 if auth.uid() = old.customer_id and new.status <> 'cancelled' then raise exception 'Invalid customer decision'; end if;
 new.updated_at = now();
 return new;
end $$;
create trigger protect_booking_update before update on public.bookings for each row execute function public.protect_booking_update();

-- AFTER creating both Supabase Authentication users, find their UUIDs in the
-- Authentication > Users panel, then execute these TWO lines with those UUIDs:
-- insert into public.profiles (id, role, display_name) values ('SARAH_AUTH_USER_UUID','sarah','Sarah') on conflict(id) do update set role='sarah',display_name='Sarah';
-- insert into public.profiles (id, role, display_name) values ('BOYFRIEND_AUTH_USER_UUID','boyfriend','Boyfriend') on conflict(id) do update set role='boyfriend',display_name='Boyfriend';
