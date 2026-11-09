-- SocietyManagement Supabase schema
-- Run once in the Supabase SQL Editor. Row Level Security limits records to the signed-in user's society.

create extension if not exists pgcrypto;

create table if not exists public.societies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  contact_name text not null,
  contact_email text not null,
  contact_mobile text not null,
  app_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.societies add column if not exists app_data jsonb not null default '{}'::jsonb;
create unique index if not exists societies_name_unique on public.societies (lower(btrim(name)));

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  society_id uuid not null references public.societies(id) on delete cascade,
  full_name text not null,
  email text not null,
  mobile text not null,
  role text not null default 'admin' check (role in ('admin','manager','accountant','committee','owner','tenant')),
  member_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  society_id uuid not null references public.societies(id) on delete cascade,
  name text not null,
  type text not null check (type in ('Owner','Tenant')),
  apartment text not null,
  occupancy text not null check (occupancy in ('Occupied','Non-occupied')),
  mobile text not null,
  email text not null,
  parking integer not null default 0 check (parking >= 0),
  created_at timestamptz not null default now()
);
create unique index if not exists members_email_unique on public.members (society_id, lower(btrim(email)));
create unique index if not exists members_mobile_unique on public.members (society_id, regexp_replace(mobile, '\D', '', 'g'));
alter table public.profiles drop constraint if exists profiles_member_id_fkey;
alter table public.profiles add constraint profiles_member_id_fkey foreign key (member_id) references public.members(id) on delete set null;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(), society_id uuid not null references public.societies(id) on delete cascade,
  name text not null, category text not null, billing text not null check (billing in ('Recurring monthly','One-time')),
  rate numeric(12,2) not null default 0 check (rate >= 0), tax numeric(5,2) not null default 0 check (tax >= 0),
  status text not null default 'Active' check (status in ('Active','Inactive')), created_at timestamptz not null default now()
);

create table if not exists public.billing_settings (
  society_id uuid primary key references public.societies(id) on delete cascade,
  occupied numeric(12,2) not null default 0 check (occupied >= 0),
  non_occupied numeric(12,2) not null default 0 check (non_occupied >= 0),
  parking numeric(12,2) not null default 0 check (parking >= 0),
  extra_parking numeric(12,2) not null default 0 check (extra_parking >= 0),
  late_rate numeric(7,3) not null default 0 check (late_rate >= 0),
  billing_day smallint not null default 1 check (billing_day between 1 and 28),
  currency text not null default 'INR' check (currency in ('INR','USD')),
  updated_at timestamptz not null default now()
);

create table if not exists public.billing_cycles (
  id uuid primary key default gen_random_uuid(), society_id uuid not null references public.societies(id) on delete cascade,
  month text not null, count integer not null default 0, total numeric(12,2) not null default 0, late numeric(12,2) not null default 0,
  date text not null, created_at timestamptz not null default now(), unique (society_id, month)
);

create table if not exists public.bills (
  id uuid primary key default gen_random_uuid(), society_id uuid not null references public.societies(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete restrict,
  cycle text not null, member text not null, apartment text not null,
  base numeric(12,2) not null default 0, prior numeric(12,2) not null default 0, late numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0, paid numeric(12,2) not null default 0,
  status text not null check (status in ('No charge','Unpaid','Part paid','Paid')),
  created_at timestamptz not null default now(), unique (member_id, cycle)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(), society_id uuid not null references public.societies(id) on delete cascade,
  bill_id uuid references public.bills(id) on delete set null, receipt_no text not null,
  member text not null, apartment text not null, amount numeric(12,2) not null check (amount > 0),
  method text not null, date text not null, cycle text not null, created_at timestamptz not null default now(),
  unique (society_id, receipt_no)
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(), society_id uuid not null references public.societies(id) on delete cascade,
  date text not null, category text not null, vendor text not null, description text not null, method text not null,
  amount numeric(12,2) not null check (amount >= 0), created_at timestamptz not null default now()
);

create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(), society_id uuid not null references public.societies(id) on delete cascade,
  title text not null, member text not null, apartment text not null, category text not null, priority text not null,
  details text not null, date text not null, status text not null check (status in ('Open','In progress','Resolved')),
  created_at timestamptz not null default now()
);

create table if not exists public.amenities (
  id uuid primary key default gen_random_uuid(), society_id uuid not null references public.societies(id) on delete cascade,
  name text not null, hours text not null, fee numeric(12,2) not null default 0 check (fee >= 0),
  description text not null default '', created_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(), society_id uuid not null references public.societies(id) on delete cascade,
  amenity text not null, member text not null, date text not null, time text not null,
  amount numeric(12,2) not null default 0, status text not null default 'Booked', created_at timestamptz not null default now()
);

create table if not exists public.visitors (
  id uuid primary key default gen_random_uuid(), society_id uuid not null references public.societies(id) on delete cascade,
  name text not null, member text not null, purpose text not null, entry text not null, exit text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.notices (
  id uuid primary key default gen_random_uuid(), society_id uuid not null references public.societies(id) on delete cascade,
  title text not null, audience text not null, message text not null, date text not null, created_at timestamptz not null default now()
);

create or replace function public.current_society_id() returns uuid
language sql stable security definer set search_path = public
as $$ select society_id from public.profiles where user_id = (select auth.uid()) limit 1 $$;

create or replace function public.current_society_role() returns text
language sql stable security definer set search_path = public
as $$ select role from public.profiles where user_id = (select auth.uid()) limit 1 $$;

create or replace function public.can_manage_society() returns boolean
language sql stable security definer set search_path = public
as $$ select coalesce(public.current_society_role() in ('admin','manager','accountant'), false) $$;

create or replace function public.handle_new_society_admin() returns trigger
language plpgsql security definer set search_path = public
as $$
declare v_society_id uuid; v_name text; v_contact text; v_mobile text;
begin
  v_name := nullif(btrim(new.raw_user_meta_data->>'society_name'), '');
  v_contact := nullif(btrim(new.raw_user_meta_data->>'contact_name'), '');
  v_mobile := nullif(btrim(new.raw_user_meta_data->>'mobile'), '');
  if v_name is null or v_contact is null or v_mobile is null then
    raise exception 'Society name, contact name and mobile are required';
  end if;
  insert into public.societies(name, contact_name, contact_email, contact_mobile)
  values (v_name, v_contact, coalesce(new.email, ''), v_mobile) returning id into v_society_id;
  insert into public.profiles(user_id, society_id, full_name, email, mobile, role)
  values (new.id, v_society_id, v_contact, coalesce(new.email, ''), v_mobile, 'admin');
  insert into public.billing_settings(society_id) values (v_society_id);
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_society on auth.users;
create trigger on_auth_user_created_society after insert on auth.users
for each row execute function public.handle_new_society_admin();

alter table public.societies enable row level security;
alter table public.profiles enable row level security;
alter table public.billing_settings enable row level security;
drop policy if exists society_read_own on public.societies;
drop policy if exists society_update_own on public.societies;
drop policy if exists profile_read_own_society on public.profiles;
drop policy if exists billing_settings_read on public.billing_settings;
drop policy if exists billing_settings_manage on public.billing_settings;
create policy society_read_own on public.societies for select to authenticated using (id = (select public.current_society_id()));
create policy society_update_own on public.societies for update to authenticated using (id = (select public.current_society_id()) and (select public.current_society_role()) = 'admin') with check (id = (select public.current_society_id()) and (select public.current_society_role()) = 'admin');
create policy profile_read_own_society on public.profiles for select to authenticated using (user_id = (select auth.uid()) or (society_id = (select public.current_society_id()) and (select public.current_society_role()) = 'admin'));
create policy billing_settings_read on public.billing_settings for select to authenticated using (society_id = (select public.current_society_id()));
create policy billing_settings_manage on public.billing_settings for all to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));

alter table public.members enable row level security;
alter table public.products enable row level security;
alter table public.billing_cycles enable row level security;
alter table public.bills enable row level security;
alter table public.payments enable row level security;
alter table public.expenses enable row level security;
alter table public.complaints enable row level security;
alter table public.amenities enable row level security;
alter table public.bookings enable row level security;
alter table public.visitors enable row level security;
alter table public.notices enable row level security;

drop policy if exists tenant_read on public.members; drop policy if exists tenant_insert on public.members; drop policy if exists tenant_update on public.members; drop policy if exists tenant_delete on public.members;
drop policy if exists tenant_read on public.products; drop policy if exists tenant_insert on public.products; drop policy if exists tenant_update on public.products; drop policy if exists tenant_delete on public.products;
drop policy if exists tenant_read on public.billing_cycles; drop policy if exists tenant_insert on public.billing_cycles; drop policy if exists tenant_update on public.billing_cycles; drop policy if exists tenant_delete on public.billing_cycles;
drop policy if exists tenant_read on public.bills; drop policy if exists tenant_insert on public.bills; drop policy if exists tenant_update on public.bills; drop policy if exists tenant_delete on public.bills;
drop policy if exists tenant_read on public.payments; drop policy if exists tenant_insert on public.payments; drop policy if exists tenant_update on public.payments; drop policy if exists tenant_delete on public.payments;
drop policy if exists tenant_read on public.expenses; drop policy if exists tenant_insert on public.expenses; drop policy if exists tenant_update on public.expenses; drop policy if exists tenant_delete on public.expenses;
drop policy if exists tenant_read on public.complaints; drop policy if exists tenant_insert on public.complaints; drop policy if exists tenant_update on public.complaints; drop policy if exists tenant_delete on public.complaints;
drop policy if exists tenant_read on public.amenities; drop policy if exists tenant_insert on public.amenities; drop policy if exists tenant_update on public.amenities; drop policy if exists tenant_delete on public.amenities;
drop policy if exists tenant_read on public.bookings; drop policy if exists tenant_insert on public.bookings; drop policy if exists tenant_update on public.bookings; drop policy if exists tenant_delete on public.bookings;
drop policy if exists tenant_read on public.visitors; drop policy if exists tenant_insert on public.visitors; drop policy if exists tenant_update on public.visitors; drop policy if exists tenant_delete on public.visitors;
drop policy if exists tenant_read on public.notices; drop policy if exists tenant_insert on public.notices; drop policy if exists tenant_update on public.notices; drop policy if exists tenant_delete on public.notices;

create policy tenant_read on public.members for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.members for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.members for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.members for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

create policy tenant_read on public.products for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.products for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.products for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.products for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

create policy tenant_read on public.billing_cycles for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.billing_cycles for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.billing_cycles for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.billing_cycles for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

create policy tenant_read on public.bills for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.bills for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.bills for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.bills for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

create policy tenant_read on public.payments for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.payments for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.payments for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.payments for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

create policy tenant_read on public.expenses for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.expenses for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.expenses for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.expenses for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

create policy tenant_read on public.complaints for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.complaints for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.complaints for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.complaints for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

create policy tenant_read on public.amenities for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.amenities for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.amenities for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.amenities for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

create policy tenant_read on public.bookings for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.bookings for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.bookings for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.bookings for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

create policy tenant_read on public.visitors for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.visitors for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.visitors for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.visitors for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

create policy tenant_read on public.notices for select to authenticated using (society_id = (select public.current_society_id()));
create policy tenant_insert on public.notices for insert to authenticated with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_update on public.notices for update to authenticated using (society_id = (select public.current_society_id()) and (select public.can_manage_society())) with check (society_id = (select public.current_society_id()) and (select public.can_manage_society()));
create policy tenant_delete on public.notices for delete to authenticated using (society_id = (select public.current_society_id()) and (select public.current_society_role()) in ('admin','manager'));

grant usage on schema public to authenticated;
grant select, update on public.societies to authenticated;
grant select on public.profiles to authenticated;
grant select, insert, update, delete on public.members, public.products, public.billing_cycles, public.bills, public.payments, public.expenses, public.complaints, public.amenities, public.bookings, public.visitors, public.notices to authenticated;
grant select, insert, update on public.billing_settings to authenticated;

revoke all on function public.current_society_id() from public, anon;
revoke all on function public.current_society_role() from public, anon;
revoke all on function public.can_manage_society() from public, anon;
grant execute on function public.current_society_id() to authenticated;
grant execute on function public.current_society_role() to authenticated;
grant execute on function public.can_manage_society() to authenticated;
revoke all on function public.handle_new_society_admin() from public, anon, authenticated;

-- Only a publishable key may be configured in browser code. Never expose service-role or secret keys.

