-- A Todo Brillo - Supabase MVP schema
-- Pegar completo en Supabase > SQL Editor > New query > Run.
--
-- IMPORTANTE:
-- Este esquema deja politicas abiertas para que el MVP funcione sin login real.
-- Sirve para demo, pruebas y validacion. Para produccion hay que cerrar RLS
-- con Supabase Auth y roles reales antes de publicar datos sensibles.

create extension if not exists pgcrypto;

create table if not exists public.settings (
  id text primary key default 'business',
  business_name text not null default 'A Todo Brillo',
  country text not null default 'AR',
  province text not null default 'Mendoza',
  business_address text not null default 'Direccion a confirmar, Mendoza',
  map_url text not null default '',
  contact_phone text not null default '',
  currency text not null default 'ARS',
  locale text not null default 'es-AR',
  timezone text not null default 'America/Argentina/Mendoza',
  loyalty_target_services integer not null default 8 check (loyalty_target_services in (5, 6, 7, 8, 9, 10)),
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
  category text not null default 'wash' check (category in ('wash', 'interior', 'polish', 'ceramic', 'combo')),
  is_active boolean not null default true,
  sort_order integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.users (
  uid text primary key,
  role text not null default 'client' check (role in ('client', 'staff', 'admin')),
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
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'in_progress', 'done', 'cancelled')),
  payment_status text not null default 'unpaid' check (payment_status in ('unpaid', 'paid', 'partial')),
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
  category text not null default 'other' check (category in ('supplies', 'rent', 'salary', 'maintenance', 'marketing', 'other')),
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
  type text not null check (type in ('earned', 'redeemed', 'adjustment')),
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

create index if not exists appointments_status_scheduled_idx on public.appointments(status, scheduled_at);
create index if not exists appointments_client_scheduled_idx on public.appointments(client_uid, scheduled_at desc);
create index if not exists appointments_completed_idx on public.appointments(status, completed_at desc);
create index if not exists expenses_date_idx on public.expenses(expense_date desc);
create index if not exists services_active_sort_idx on public.services(is_active, sort_order);
create index if not exists loyalty_events_user_created_idx on public.loyalty_events(user_uid, created_at desc);

insert into public.settings (id)
values ('business')
on conflict (id) do nothing;

alter table public.settings enable row level security;
alter table public.services enable row level security;
alter table public.users enable row level security;
alter table public.appointments enable row level security;
alter table public.expenses enable row level security;
alter table public.loyalty_events enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "mvp_public_settings_all" on public.settings;
drop policy if exists "mvp_public_services_all" on public.services;
drop policy if exists "mvp_public_users_all" on public.users;
drop policy if exists "mvp_public_appointments_all" on public.appointments;
drop policy if exists "mvp_public_expenses_all" on public.expenses;
drop policy if exists "mvp_public_loyalty_events_all" on public.loyalty_events;
drop policy if exists "mvp_public_notifications_all" on public.notifications;

create policy "mvp_public_settings_all" on public.settings for all using (true) with check (true);
create policy "mvp_public_services_all" on public.services for all using (true) with check (true);
create policy "mvp_public_users_all" on public.users for all using (true) with check (true);
create policy "mvp_public_appointments_all" on public.appointments for all using (true) with check (true);
create policy "mvp_public_expenses_all" on public.expenses for all using (true) with check (true);
create policy "mvp_public_loyalty_events_all" on public.loyalty_events for all using (true) with check (true);
create policy "mvp_public_notifications_all" on public.notifications for all using (true) with check (true);

grant usage on schema public to anon, authenticated;
grant all on public.settings to anon, authenticated;
grant all on public.services to anon, authenticated;
grant all on public.users to anon, authenticated;
grant all on public.appointments to anon, authenticated;
grant all on public.expenses to anon, authenticated;
grant all on public.loyalty_events to anon, authenticated;
grant all on public.notifications to anon, authenticated;
