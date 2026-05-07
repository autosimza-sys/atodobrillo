-- A Todo Brillo - Supabase produccion definitiva
-- Pegar completo en Supabase > SQL Editor > Run.
-- Este archivo NO borra clientes, turnos, servicios ni gastos.

create extension if not exists pgcrypto;

create table if not exists public.settings (
  id text primary key default 'business',
  business_name text not null default 'A Todo Brillo',
  country text not null default 'AR',
  province text not null default 'Mendoza',
  business_address text not null default '8085 Rodríguez, Luján de Cuyo, Mendoza',
  map_url text not null default 'https://www.google.com/maps/search/?api=1&query=8085%20Rodriguez%2C%20Lujan%20de%20Cuyo%2C%20Mendoza',
  contact_phone text not null default '',
  currency text not null default 'ARS',
  locale text not null default 'es-AR',
  timezone text not null default 'America/Argentina/Mendoza',
  loyalty_target_services integer not null default 8,
  loyalty_allowed_targets integer[] not null default array[5, 6, 7, 8, 9, 10],
  whatsapp_mode text not null default 'manual_staff_click',
  updated_by text,
  updated_at timestamptz not null default now()
);

create table if not exists public.services (
  id text primary key,
  name text not null,
  description text not null default '',
  price numeric(12, 2) not null default 0,
  estimated_minutes integer not null default 60,
  category text not null default 'wash',
  is_active boolean not null default true,
  sort_order integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.users (
  uid text primary key,
  role text not null default 'client',
  display_name text not null,
  phone text not null,
  normalized_phone text not null,
  email text,
  vehicle_name text,
  vehicle_plate text,
  loyalty_points integer not null default 0,
  lifetime_services integer not null default 0,
  courtesy_wash_available boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_appointment_at timestamptz
);

create table if not exists public.appointments (
  id text primary key,
  client_uid text references public.users(uid) on delete set null,
  client_name text not null,
  client_phone text not null,
  normalized_phone text not null,
  vehicle_name text not null,
  vehicle_plate text,
  service_id text references public.services(id) on delete set null,
  service_name text not null,
  service_price numeric(12, 2) not null default 0,
  scheduled_at timestamptz not null,
  status text not null default 'pending',
  payment_status text not null default 'unpaid',
  paid_amount numeric(12, 2) not null default 0,
  staff_notes text,
  whatsapp_opened_at timestamptz,
  whatsapp_opened_by text,
  loyalty_point_awarded boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.expenses (
  id text primary key,
  title text not null,
  amount numeric(12, 2) not null default 0,
  category text not null default 'other',
  expense_date timestamptz not null,
  notes text,
  created_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.loyalty_events (
  id text primary key,
  user_uid text references public.users(uid) on delete cascade,
  appointment_id text references public.appointments(id) on delete set null,
  type text not null,
  points integer not null,
  reason text not null default '',
  created_by text,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id text primary key,
  appointment_id text references public.appointments(id) on delete cascade,
  user_uid text references public.users(uid) on delete set null,
  channel text not null default 'whatsapp',
  type text not null default 'job_done',
  status text not null default 'opened',
  message_preview text not null default '',
  created_at timestamptz not null default now(),
  opened_at timestamptz
);

create table if not exists public.staff_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null,
  role text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.settings
  add column if not exists business_name text not null default 'A Todo Brillo',
  add column if not exists country text not null default 'AR',
  add column if not exists province text not null default 'Mendoza',
  add column if not exists business_address text not null default '8085 Rodríguez, Luján de Cuyo, Mendoza',
  add column if not exists map_url text not null default 'https://www.google.com/maps/search/?api=1&query=8085%20Rodriguez%2C%20Lujan%20de%20Cuyo%2C%20Mendoza',
  add column if not exists contact_phone text not null default '',
  add column if not exists currency text not null default 'ARS',
  add column if not exists locale text not null default 'es-AR',
  add column if not exists timezone text not null default 'America/Argentina/Mendoza',
  add column if not exists loyalty_target_services integer not null default 8,
  add column if not exists loyalty_allowed_targets integer[] not null default array[5, 6, 7, 8, 9, 10],
  add column if not exists whatsapp_mode text not null default 'manual_staff_click',
  add column if not exists updated_by text,
  add column if not exists updated_at timestamptz not null default now();

alter table public.services
  add column if not exists name text not null default 'Servicio',
  add column if not exists description text not null default '',
  add column if not exists price numeric(12, 2) not null default 0,
  add column if not exists estimated_minutes integer not null default 60,
  add column if not exists category text not null default 'wash',
  add column if not exists is_active boolean not null default true,
  add column if not exists sort_order integer not null default 1,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.users
  add column if not exists role text not null default 'client',
  add column if not exists display_name text not null default 'Cliente',
  add column if not exists phone text not null default '',
  add column if not exists normalized_phone text not null default '',
  add column if not exists email text,
  add column if not exists vehicle_name text,
  add column if not exists vehicle_plate text,
  add column if not exists loyalty_points integer not null default 0,
  add column if not exists lifetime_services integer not null default 0,
  add column if not exists courtesy_wash_available boolean not null default false,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists last_appointment_at timestamptz;

alter table public.appointments
  add column if not exists client_uid text references public.users(uid) on delete set null,
  add column if not exists client_name text not null default 'Cliente',
  add column if not exists client_phone text not null default '',
  add column if not exists normalized_phone text not null default '',
  add column if not exists vehicle_name text not null default 'Vehiculo',
  add column if not exists vehicle_plate text,
  add column if not exists service_id text references public.services(id) on delete set null,
  add column if not exists service_name text not null default 'Servicio',
  add column if not exists service_price numeric(12, 2) not null default 0,
  add column if not exists scheduled_at timestamptz not null default now(),
  add column if not exists status text not null default 'pending',
  add column if not exists payment_status text not null default 'unpaid',
  add column if not exists paid_amount numeric(12, 2) not null default 0,
  add column if not exists staff_notes text,
  add column if not exists whatsapp_opened_at timestamptz,
  add column if not exists whatsapp_opened_by text,
  add column if not exists loyalty_point_awarded boolean not null default false,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists completed_at timestamptz;

alter table public.expenses
  add column if not exists title text not null default 'Egreso',
  add column if not exists amount numeric(12, 2) not null default 0,
  add column if not exists category text not null default 'other',
  add column if not exists expense_date timestamptz not null default now(),
  add column if not exists notes text,
  add column if not exists created_by text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.loyalty_events
  add column if not exists user_uid text references public.users(uid) on delete cascade,
  add column if not exists appointment_id text references public.appointments(id) on delete set null,
  add column if not exists type text not null default 'earned',
  add column if not exists points integer not null default 0,
  add column if not exists reason text not null default '',
  add column if not exists created_by text,
  add column if not exists created_at timestamptz not null default now();

alter table public.notifications
  add column if not exists appointment_id text references public.appointments(id) on delete cascade,
  add column if not exists user_uid text references public.users(uid) on delete set null,
  add column if not exists channel text not null default 'whatsapp',
  add column if not exists type text not null default 'job_done',
  add column if not exists status text not null default 'opened',
  add column if not exists message_preview text not null default '',
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists opened_at timestamptz;

alter table public.staff_profiles
  add column if not exists email text not null default '',
  add column if not exists display_name text not null default 'Usuario interno',
  add column if not exists role text not null default 'staff',
  add column if not exists is_active boolean not null default true,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create index if not exists appointments_status_scheduled_idx on public.appointments(status, scheduled_at);
create index if not exists appointments_phone_scheduled_idx on public.appointments(normalized_phone, scheduled_at desc);
create index if not exists services_active_sort_idx on public.services(is_active, sort_order);
create index if not exists expenses_date_idx on public.expenses(expense_date desc);
create index if not exists loyalty_events_user_created_idx on public.loyalty_events(user_uid, created_at desc);
create index if not exists users_phone_idx on public.users(normalized_phone);

insert into public.settings (id)
values ('business')
on conflict (id) do nothing;

update public.settings
set business_address = '8085 Rodríguez, Luján de Cuyo, Mendoza',
    map_url = coalesce(nullif(map_url, ''), 'https://www.google.com/maps/search/?api=1&query=8085%20Rodriguez%2C%20Lujan%20de%20Cuyo%2C%20Mendoza'),
    updated_at = now()
where id = 'business';

alter table public.settings enable row level security;
alter table public.services enable row level security;
alter table public.users enable row level security;
alter table public.appointments enable row level security;
alter table public.expenses enable row level security;
alter table public.loyalty_events enable row level security;
alter table public.notifications enable row level security;
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

do $$
declare
  r record;
begin
  for r in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in (
        'settings',
        'services',
        'users',
        'appointments',
        'expenses',
        'loyalty_events',
        'notifications',
        'staff_profiles'
      )
  loop
    execute format('drop policy if exists %I on %I.%I', r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;

create policy "settings_read_public"
on public.settings
for select
to anon, authenticated
using (true);

create policy "settings_write_admin"
on public.settings
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

create policy "services_read_public_active"
on public.services
for select
to anon, authenticated
using (is_active = true or public.is_internal_staff());

create policy "services_write_admin"
on public.services
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

create policy "users_read_staff"
on public.users
for select
to authenticated
using (public.is_internal_staff());

create policy "users_write_staff"
on public.users
for all
to authenticated
using (public.is_internal_staff())
with check (public.is_internal_staff());

create policy "appointments_read_staff"
on public.appointments
for select
to authenticated
using (public.is_internal_staff());

create policy "appointments_write_staff"
on public.appointments
for all
to authenticated
using (public.is_internal_staff())
with check (public.is_internal_staff());

create policy "expenses_read_admin"
on public.expenses
for select
to authenticated
using (public.is_internal_admin());

create policy "expenses_write_admin"
on public.expenses
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

create policy "loyalty_events_read_staff"
on public.loyalty_events
for select
to authenticated
using (public.is_internal_staff());

create policy "loyalty_events_write_staff"
on public.loyalty_events
for all
to authenticated
using (public.is_internal_staff())
with check (public.is_internal_staff());

create policy "notifications_read_staff"
on public.notifications
for select
to authenticated
using (public.is_internal_staff());

create policy "notifications_write_staff"
on public.notifications
for all
to authenticated
using (public.is_internal_staff())
with check (public.is_internal_staff());

create policy "staff_profiles_read_self_or_admin"
on public.staff_profiles
for select
to authenticated
using (user_id = auth.uid() or public.is_internal_admin());

create policy "staff_profiles_write_admin"
on public.staff_profiles
for all
to authenticated
using (public.is_internal_admin())
with check (public.is_internal_admin());

grant usage on schema public to anon, authenticated;
grant select on public.settings to anon, authenticated;
grant select on public.services to anon, authenticated;
grant select on public.users to authenticated;
grant select on public.appointments to authenticated;
grant select on public.expenses to authenticated;
grant select on public.loyalty_events to authenticated;
grant select on public.notifications to authenticated;
grant select on public.staff_profiles to authenticated;

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

drop function if exists public.create_public_booking(text, text, text, text, text, text, timestamptz);
drop function if exists public.create_public_booking(text, text, text, text, text, text, text, numeric, timestamptz);

create function public.create_public_booking(
  p_client_name text,
  p_client_phone text,
  p_normalized_phone text,
  p_vehicle_name text,
  p_vehicle_plate text,
  p_service_id text,
  p_service_name text,
  p_service_price numeric,
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
  v_service_id text := null;
  v_service_name text;
  v_service_price numeric;
begin
  if length(trim(coalesce(p_client_name, ''))) < 2 then
    raise exception 'Nombre de cliente invalido';
  end if;

  if length(trim(coalesce(p_normalized_phone, ''))) < 10 then
    raise exception 'WhatsApp invalido';
  end if;

  if length(trim(coalesce(p_vehicle_name, ''))) < 2 then
    raise exception 'Vehiculo invalido';
  end if;

  select s.id, s.name, s.price
  into v_service
  from public.services s
  where s.id = p_service_id
    and s.is_active = true
  limit 1;

  if v_service.id is not null then
    v_service_id := v_service.id;
    v_service_name := v_service.name;
    v_service_price := v_service.price;
  else
    v_service_name := coalesce(nullif(trim(p_service_name), ''), 'Servicio');
    v_service_price := greatest(coalesce(p_service_price, 0), 0);
  end if;

  if v_service_price <= 0 then
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
    v_service_id,
    v_service_name,
    v_service_price,
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
  select v_appointment_id, v_user_uid, v_service_name, v_service_price;
end;
$$;

drop function if exists public.admin_save_service(text, text, text, numeric, integer, text, boolean, integer);

create function public.admin_save_service(
  p_id text,
  p_name text,
  p_description text,
  p_price numeric,
  p_estimated_minutes integer,
  p_category text,
  p_is_active boolean,
  p_sort_order integer
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id text := coalesce(nullif(trim(p_id), ''), 'srv_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 14));
begin
  if not public.is_internal_admin() then
    raise exception 'Solo admin puede gestionar servicios';
  end if;

  if length(trim(coalesce(p_name, ''))) < 2 or coalesce(p_price, 0) <= 0 then
    raise exception 'Completa nombre y precio del servicio';
  end if;

  insert into public.services (
    id,
    name,
    description,
    price,
    estimated_minutes,
    category,
    is_active,
    sort_order,
    created_at,
    updated_at
  )
  values (
    v_id,
    trim(p_name),
    coalesce(p_description, ''),
    p_price,
    coalesce(p_estimated_minutes, 60),
    coalesce(nullif(trim(p_category), ''), 'wash'),
    coalesce(p_is_active, true),
    coalesce(p_sort_order, 1),
    now(),
    now()
  )
  on conflict (id) do update
  set name = excluded.name,
      description = excluded.description,
      price = excluded.price,
      estimated_minutes = excluded.estimated_minutes,
      category = excluded.category,
      is_active = excluded.is_active,
      sort_order = excluded.sort_order,
      updated_at = now();

  return v_id;
end;
$$;

drop function if exists public.admin_delete_service(text);

create function public.admin_delete_service(p_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_internal_admin() then
    raise exception 'Solo admin puede eliminar servicios';
  end if;

  delete from public.services
  where id = p_id;
end;
$$;

drop function if exists public.admin_save_expense(text, text, numeric, text, timestamptz, text);

create function public.admin_save_expense(
  p_id text,
  p_title text,
  p_amount numeric,
  p_category text,
  p_expense_date timestamptz,
  p_notes text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id text := coalesce(nullif(trim(p_id), ''), 'exp_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 14));
begin
  if not public.is_internal_admin() then
    raise exception 'Solo admin puede cargar egresos';
  end if;

  if length(trim(coalesce(p_title, ''))) < 2 or coalesce(p_amount, 0) <= 0 then
    raise exception 'Completa concepto y monto';
  end if;

  insert into public.expenses (
    id,
    title,
    amount,
    category,
    expense_date,
    notes,
    created_by,
    created_at,
    updated_at
  )
  values (
    v_id,
    trim(p_title),
    p_amount,
    coalesce(nullif(trim(p_category), ''), 'other'),
    p_expense_date,
    nullif(trim(coalesce(p_notes, '')), ''),
    auth.uid()::text,
    now(),
    now()
  )
  on conflict (id) do update
  set title = excluded.title,
      amount = excluded.amount,
      category = excluded.category,
      expense_date = excluded.expense_date,
      notes = excluded.notes,
      updated_at = now();

  return v_id;
end;
$$;

drop function if exists public.admin_delete_expense(text);

create function public.admin_delete_expense(p_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_internal_admin() then
    raise exception 'Solo admin puede eliminar egresos';
  end if;

  delete from public.expenses
  where id = p_id;
end;
$$;

drop function if exists public.admin_save_settings(text, text, text, text, text, text, text, text, text, integer);

create function public.admin_save_settings(
  p_business_name text,
  p_country text,
  p_province text,
  p_business_address text,
  p_map_url text,
  p_contact_phone text,
  p_currency text,
  p_locale text,
  p_timezone text,
  p_loyalty_target_services integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_internal_admin() then
    raise exception 'Solo admin puede cambiar configuracion';
  end if;

  if p_loyalty_target_services not in (5, 6, 7, 8, 9, 10) then
    raise exception 'Premio invalido';
  end if;

  insert into public.settings (
    id,
    business_name,
    country,
    province,
    business_address,
    map_url,
    contact_phone,
    currency,
    locale,
    timezone,
    loyalty_target_services,
    loyalty_allowed_targets,
    whatsapp_mode,
    updated_by,
    updated_at
  )
  values (
    'business',
    coalesce(nullif(trim(p_business_name), ''), 'A Todo Brillo'),
    coalesce(nullif(trim(p_country), ''), 'AR'),
    coalesce(nullif(trim(p_province), ''), 'Mendoza'),
    coalesce(nullif(trim(p_business_address), ''), '8085 Rodríguez, Luján de Cuyo, Mendoza'),
    coalesce(p_map_url, ''),
    coalesce(p_contact_phone, ''),
    coalesce(nullif(trim(p_currency), ''), 'ARS'),
    coalesce(nullif(trim(p_locale), ''), 'es-AR'),
    coalesce(nullif(trim(p_timezone), ''), 'America/Argentina/Mendoza'),
    p_loyalty_target_services,
    array[5, 6, 7, 8, 9, 10],
    'manual_staff_click',
    auth.uid()::text,
    now()
  )
  on conflict (id) do update
  set business_name = excluded.business_name,
      country = excluded.country,
      province = excluded.province,
      business_address = excluded.business_address,
      map_url = excluded.map_url,
      contact_phone = excluded.contact_phone,
      currency = excluded.currency,
      locale = excluded.locale,
      timezone = excluded.timezone,
      loyalty_target_services = excluded.loyalty_target_services,
      loyalty_allowed_targets = excluded.loyalty_allowed_targets,
      whatsapp_mode = excluded.whatsapp_mode,
      updated_by = excluded.updated_by,
      updated_at = now();

  update public.users
  set courtesy_wash_available = loyalty_points >= p_loyalty_target_services,
      updated_at = now()
  where role = 'client';
end;
$$;

drop function if exists public.staff_update_appointment_status(text, text);

create function public.staff_update_appointment_status(
  p_appointment_id text,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_appt public.appointments%rowtype;
  v_target integer;
  v_new_points integer;
begin
  if not public.is_internal_staff() then
    raise exception 'Solo staff/admin puede cambiar estados';
  end if;

  if p_status not in ('pending', 'confirmed', 'in_progress', 'done', 'cancelled') then
    raise exception 'Estado invalido';
  end if;

  select *
  into v_appt
  from public.appointments
  where id = p_appointment_id
  for update;

  if not found then
    raise exception 'Turno no encontrado';
  end if;

  update public.appointments
  set status = p_status,
      updated_at = now(),
      completed_at = case when p_status = 'done' then coalesce(completed_at, now()) else completed_at end,
      payment_status = case when p_status = 'done' then 'paid' else payment_status end,
      paid_amount = case when p_status = 'done' then service_price else paid_amount end,
      loyalty_point_awarded = case when p_status = 'done' then true else loyalty_point_awarded end
  where id = p_appointment_id;

  if p_status = 'done'
    and coalesce(v_appt.loyalty_point_awarded, false) = false
    and v_appt.client_uid is not null then

    select loyalty_target_services
    into v_target
    from public.settings
    where id = 'business'
    limit 1;

    v_target := coalesce(v_target, 8);

    update public.users
    set loyalty_points = loyalty_points + 1,
        lifetime_services = lifetime_services + 1,
        last_appointment_at = now(),
        updated_at = now(),
        courtesy_wash_available = (loyalty_points + 1) >= v_target
    where uid = v_appt.client_uid
    returning loyalty_points into v_new_points;

    insert into public.loyalty_events (
      id,
      user_uid,
      appointment_id,
      type,
      points,
      reason,
      created_by,
      created_at
    )
    values (
      'loy_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 14),
      v_appt.client_uid,
      p_appointment_id,
      'earned',
      1,
      'Servicio completado',
      auth.uid()::text,
      now()
    );
  end if;
end;
$$;

drop function if exists public.staff_log_whatsapp_opened(text, text);

create function public.staff_log_whatsapp_opened(
  p_appointment_id text,
  p_message_preview text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_appt public.appointments%rowtype;
begin
  if not public.is_internal_staff() then
    raise exception 'Solo staff/admin puede registrar WhatsApp';
  end if;

  select *
  into v_appt
  from public.appointments
  where id = p_appointment_id
  for update;

  if not found then
    raise exception 'Turno no encontrado';
  end if;

  update public.appointments
  set whatsapp_opened_at = now(),
      whatsapp_opened_by = auth.uid()::text,
      updated_at = now()
  where id = p_appointment_id;

  insert into public.notifications (
    id,
    appointment_id,
    user_uid,
    channel,
    type,
    status,
    message_preview,
    created_at,
    opened_at
  )
  values (
    'ntf_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 14),
    p_appointment_id,
    v_appt.client_uid,
    'whatsapp',
    'job_done',
    'opened',
    coalesce(p_message_preview, ''),
    now(),
    now()
  );
end;
$$;

drop function if exists public.redeem_loyalty_admin(text, integer, text);

create function public.redeem_loyalty_admin(
  p_user_uid text,
  p_points integer,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_target integer;
begin
  if not public.is_internal_admin() then
    raise exception 'Solo admin puede registrar canjes';
  end if;

  select loyalty_target_services
  into v_target
  from public.settings
  where id = 'business'
  limit 1;

  v_target := coalesce(v_target, abs(coalesce(p_points, 0)), 8);

  update public.users
  set loyalty_points = 0,
      courtesy_wash_available = false,
      updated_at = now()
  where uid = p_user_uid
    and role = 'client';

  if not found then
    raise exception 'Cliente no encontrado';
  end if;

  insert into public.loyalty_events (
    id,
    user_uid,
    appointment_id,
    type,
    points,
    reason,
    created_by,
    created_at
  )
  values (
    'loy_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 14),
    p_user_uid,
    null,
    'redeemed',
    -abs(v_target),
    coalesce(nullif(trim(p_reason), ''), 'Lavado de cortesia'),
    auth.uid()::text,
    now()
  );
end;
$$;

grant execute on function public.current_staff_role() to anon, authenticated;
grant execute on function public.is_internal_staff() to anon, authenticated;
grant execute on function public.is_internal_admin() to anon, authenticated;
grant execute on function public.lookup_loyalty_by_phone(text) to anon, authenticated;
grant execute on function public.create_public_booking(text, text, text, text, text, text, text, numeric, timestamptz) to anon, authenticated;
grant execute on function public.admin_save_service(text, text, text, numeric, integer, text, boolean, integer) to authenticated;
grant execute on function public.admin_delete_service(text) to authenticated;
grant execute on function public.admin_save_expense(text, text, numeric, text, timestamptz, text) to authenticated;
grant execute on function public.admin_delete_expense(text) to authenticated;
grant execute on function public.admin_save_settings(text, text, text, text, text, text, text, text, text, integer) to authenticated;
grant execute on function public.staff_update_appointment_status(text, text) to authenticated;
grant execute on function public.staff_log_whatsapp_opened(text, text) to authenticated;
grant execute on function public.redeem_loyalty_admin(text, integer, text) to authenticated;
