-- PASO 2 - Cerrar permisos para produccion.
-- Ejecutar SOLO despues de:
-- 1. Subir el codigo con login a GitHub/Vercel.
-- 2. Crear tu usuario en Supabase Auth.
-- 3. Agregar tu usuario a staff_profiles como admin.
-- 4. Probar que podes entrar desde la web.

create table if not exists public.staff_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null,
  role text not null check (role in ('staff', 'admin')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.settings
  add column if not exists business_address text not null default 'Direccion a confirmar, Mendoza',
  add column if not exists map_url text not null default '',
  add column if not exists contact_phone text not null default '';

alter table public.staff_profiles enable row level security;

create or replace function public.current_staff_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role
  from public.staff_profiles
  where user_id = auth.uid()
    and is_active = true
  limit 1
$$;

create or replace function public.is_internal_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_staff_role() in ('staff', 'admin')
$$;

create or replace function public.is_internal_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_staff_role() = 'admin'
$$;

drop policy if exists "mvp_public_settings_all" on public.settings;
drop policy if exists "mvp_public_services_all" on public.services;
drop policy if exists "mvp_public_users_all" on public.users;
drop policy if exists "mvp_public_appointments_all" on public.appointments;
drop policy if exists "mvp_public_expenses_all" on public.expenses;
drop policy if exists "mvp_public_loyalty_events_all" on public.loyalty_events;
drop policy if exists "mvp_public_notifications_all" on public.notifications;

drop policy if exists "settings_public_read" on public.settings;
drop policy if exists "settings_admin_write" on public.settings;
drop policy if exists "services_public_read_active" on public.services;
drop policy if exists "services_admin_write" on public.services;
drop policy if exists "users_public_insert_clients" on public.users;
drop policy if exists "users_staff_read" on public.users;
drop policy if exists "users_staff_update" on public.users;
drop policy if exists "appointments_public_insert_pending" on public.appointments;
drop policy if exists "appointments_staff_read" on public.appointments;
drop policy if exists "appointments_staff_update" on public.appointments;
drop policy if exists "appointments_admin_delete" on public.appointments;
drop policy if exists "expenses_admin_all" on public.expenses;
drop policy if exists "loyalty_events_staff_read" on public.loyalty_events;
drop policy if exists "loyalty_events_staff_insert" on public.loyalty_events;
drop policy if exists "loyalty_events_admin_all" on public.loyalty_events;
drop policy if exists "notifications_staff_all" on public.notifications;
drop policy if exists "staff_profiles_select_self_or_admin" on public.staff_profiles;
drop policy if exists "staff_profiles_admin_all" on public.staff_profiles;

create policy "settings_public_read"
on public.settings
for select
to anon, authenticated
using (true);

create policy "settings_admin_write"
on public.settings
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

create policy "services_public_read_active"
on public.services
for select
to anon, authenticated
using (is_active = true or public.is_internal_staff());

create policy "services_admin_write"
on public.services
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

create policy "users_public_insert_clients"
on public.users
for insert
to anon, authenticated
with check (role = 'client');

create policy "users_staff_read"
on public.users
for select
to authenticated
using (public.is_internal_staff());

create policy "users_staff_update"
on public.users
for update
to authenticated
using (public.is_internal_staff())
with check (public.is_internal_staff());

create policy "appointments_public_insert_pending"
on public.appointments
for insert
to anon, authenticated
with check (status = 'pending');

create policy "appointments_staff_read"
on public.appointments
for select
to authenticated
using (public.is_internal_staff());

create policy "appointments_staff_update"
on public.appointments
for update
to authenticated
using (public.is_internal_staff())
with check (public.is_internal_staff());

create policy "appointments_admin_delete"
on public.appointments
for delete
to authenticated
using (public.is_internal_admin());

create policy "expenses_admin_all"
on public.expenses
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

create policy "loyalty_events_staff_read"
on public.loyalty_events
for select
to authenticated
using (public.is_internal_staff());

create policy "loyalty_events_staff_insert"
on public.loyalty_events
for insert
to authenticated
with check (public.is_internal_staff());

create policy "loyalty_events_admin_all"
on public.loyalty_events
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

create policy "notifications_staff_all"
on public.notifications
for all
to authenticated
using (public.is_internal_staff())
with check (public.is_internal_staff());

create policy "staff_profiles_select_self_or_admin"
on public.staff_profiles
for select
to authenticated
using (user_id = auth.uid() or public.is_internal_admin());

create policy "staff_profiles_admin_all"
on public.staff_profiles
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

grant usage on schema public to anon, authenticated;
grant select on public.settings to anon, authenticated;
grant select on public.services to anon, authenticated;
grant insert on public.users to anon, authenticated;
grant insert on public.appointments to anon, authenticated;

grant all on public.settings to authenticated;
grant all on public.services to authenticated;
grant all on public.users to authenticated;
grant all on public.appointments to authenticated;
grant all on public.expenses to authenticated;
grant all on public.loyalty_events to authenticated;
grant all on public.notifications to authenticated;
grant select on public.staff_profiles to authenticated;

grant execute on function public.current_staff_role() to anon, authenticated;
grant execute on function public.is_internal_staff() to anon, authenticated;
grant execute on function public.is_internal_admin() to anon, authenticated;

drop function if exists public.lookup_loyalty_by_phone(text);

create function public.lookup_loyalty_by_phone(phone_digits text)
returns table (
  display_name text,
  vehicle_name text,
  loyalty_points integer,
  lifetime_services integer,
  courtesy_wash_available boolean,
  latest_vehicle_name text,
  latest_service_name text,
  latest_status text,
  latest_scheduled_at timestamptz,
  latest_completed_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    u.display_name,
    u.vehicle_name,
    u.loyalty_points,
    u.lifetime_services,
    u.courtesy_wash_available,
    a.vehicle_name as latest_vehicle_name,
    a.service_name as latest_service_name,
    a.status as latest_status,
    a.scheduled_at as latest_scheduled_at,
    a.completed_at as latest_completed_at
  from public.users u
  left join lateral (
    select
      ap.vehicle_name,
      ap.service_name,
      ap.status,
      ap.scheduled_at,
      ap.completed_at,
      ap.created_at
    from public.appointments ap
    where ap.normalized_phone = phone_digits
    order by ap.scheduled_at desc, ap.created_at desc
    limit 1
  ) a on true
  where u.role = 'client'
    and u.normalized_phone = phone_digits
  order by u.updated_at desc
  limit 1
$$;

grant execute on function public.lookup_loyalty_by_phone(text) to anon, authenticated;
