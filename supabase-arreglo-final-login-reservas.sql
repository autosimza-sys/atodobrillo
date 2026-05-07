-- ARREGLO FINAL: login admin + reservas + RLS de trabajos.
-- Pegar completo en Supabase > SQL Editor > Run.
-- Si tu email admin no es este, cambia autosimza@gmail.com antes de ejecutar.

create extension if not exists pgcrypto;

create table if not exists public.staff_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null,
  role text not null check (role in ('staff', 'admin')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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

insert into public.staff_profiles (
  user_id,
  email,
  display_name,
  role,
  is_active,
  created_at,
  updated_at
)
select
  u.id,
  u.email,
  'Admin A Todo Brillo',
  'admin',
  true,
  now(),
  now()
from auth.users u
where lower(u.email) = lower('autosimza@gmail.com')
on conflict (user_id) do update
set email = excluded.email,
    display_name = excluded.display_name,
    role = 'admin',
    is_active = true,
    updated_at = now();

alter table public.settings
  add column if not exists business_address text not null default 'Direccion a confirmar, Mendoza',
  add column if not exists map_url text not null default '',
  add column if not exists contact_phone text not null default '';

drop policy if exists "appointments_staff_insert" on public.appointments;
drop policy if exists "appointments_staff_update" on public.appointments;
drop policy if exists "appointments_staff_read" on public.appointments;
drop policy if exists "settings_admin_write" on public.settings;
drop policy if exists "services_admin_write" on public.services;
drop policy if exists "expenses_admin_all" on public.expenses;
drop policy if exists "users_staff_update" on public.users;
drop policy if exists "users_staff_read" on public.users;
drop policy if exists "loyalty_events_staff_insert" on public.loyalty_events;
drop policy if exists "notifications_staff_all" on public.notifications;
drop policy if exists "staff_profiles_select_self_or_admin" on public.staff_profiles;
drop policy if exists "staff_profiles_admin_all" on public.staff_profiles;

create policy "appointments_staff_read"
on public.appointments
for select
to authenticated
using (public.is_internal_staff());

create policy "appointments_staff_insert"
on public.appointments
for insert
to authenticated
with check (public.is_internal_staff());

create policy "appointments_staff_update"
on public.appointments
for update
to authenticated
using (public.is_internal_staff())
with check (public.is_internal_staff());

create policy "settings_admin_write"
on public.settings
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

create policy "services_admin_write"
on public.services
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

create policy "expenses_admin_all"
on public.expenses
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

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

create policy "loyalty_events_staff_insert"
on public.loyalty_events
for insert
to authenticated
with check (public.is_internal_staff());

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
grant all on public.staff_profiles to authenticated;
grant all on public.settings to authenticated;
grant all on public.services to authenticated;
grant all on public.appointments to authenticated;
grant all on public.expenses to authenticated;
grant all on public.users to authenticated;
grant all on public.loyalty_events to authenticated;
grant all on public.notifications to authenticated;
grant execute on function public.current_staff_role() to anon, authenticated;
grant execute on function public.is_internal_staff() to anon, authenticated;
grant execute on function public.is_internal_admin() to anon, authenticated;

drop function if exists public.create_public_booking(
  text,
  text,
  text,
  text,
  text,
  text,
  timestamptz
);

create function public.create_public_booking(
  p_client_name text,
  p_client_phone text,
  p_normalized_phone text,
  p_vehicle_name text,
  p_vehicle_plate text,
  p_service_id text,
  p_scheduled_at timestamptz
)
returns table (
  appointment_id text,
  user_uid text,
  service_name text,
  service_price numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := now();
  v_service record;
  v_user_uid text;
  v_appointment_id text := 'apt_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 14);
begin
  select s.id, s.name, s.price
  into v_service
  from public.services s
  where s.id = p_service_id
    and s.is_active = true
  limit 1;

  if v_service.id is null then
    raise exception 'Servicio no disponible';
  end if;

  select u.uid
  into v_user_uid
  from public.users u
  where u.role = 'client'
    and u.normalized_phone = p_normalized_phone
  order by u.updated_at desc
  limit 1;

  if v_user_uid is null then
    v_user_uid := 'usr_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 14);

    insert into public.users (
      uid,
      role,
      display_name,
      phone,
      normalized_phone,
      email,
      vehicle_name,
      vehicle_plate,
      loyalty_points,
      lifetime_services,
      courtesy_wash_available,
      created_at,
      updated_at,
      last_appointment_at
    )
    values (
      v_user_uid,
      'client',
      trim(p_client_name),
      trim(p_client_phone),
      trim(p_normalized_phone),
      null,
      trim(p_vehicle_name),
      nullif(trim(coalesce(p_vehicle_plate, '')), ''),
      0,
      0,
      false,
      v_now,
      v_now,
      p_scheduled_at
    );
  else
    update public.users
    set display_name = trim(p_client_name),
        phone = trim(p_client_phone),
        vehicle_name = trim(p_vehicle_name),
        vehicle_plate = nullif(trim(coalesce(p_vehicle_plate, '')), ''),
        updated_at = v_now,
        last_appointment_at = p_scheduled_at
    where uid = v_user_uid;
  end if;

  insert into public.appointments (
    id,
    client_uid,
    client_name,
    client_phone,
    normalized_phone,
    vehicle_name,
    vehicle_plate,
    service_id,
    service_name,
    service_price,
    scheduled_at,
    status,
    payment_status,
    paid_amount,
    staff_notes,
    whatsapp_opened_at,
    whatsapp_opened_by,
    loyalty_point_awarded,
    created_at,
    updated_at,
    completed_at
  )
  values (
    v_appointment_id,
    v_user_uid,
    trim(p_client_name),
    trim(p_client_phone),
    trim(p_normalized_phone),
    trim(p_vehicle_name),
    nullif(trim(coalesce(p_vehicle_plate, '')), ''),
    v_service.id,
    v_service.name,
    v_service.price,
    p_scheduled_at,
    'pending',
    'unpaid',
    0,
    null,
    null,
    null,
    false,
    v_now,
    v_now,
    null
  );

  return query
  select v_appointment_id, v_user_uid, v_service.name, v_service.price;
end;
$$;

grant execute on function public.create_public_booking(text, text, text, text, text, text, timestamptz) to anon, authenticated;
