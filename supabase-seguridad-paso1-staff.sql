-- PASO 1 - Crear perfiles internos para staff/admin.
-- Ejecutar en Supabase > SQL Editor.
-- Este paso NO cierra permisos todavia, asi no rompe la app actual.

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

drop policy if exists "staff_profiles_select_self_or_admin" on public.staff_profiles;
drop policy if exists "staff_profiles_admin_all" on public.staff_profiles;

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
grant select on public.staff_profiles to authenticated;
grant execute on function public.current_staff_role() to anon, authenticated;
grant execute on function public.is_internal_staff() to anon, authenticated;
grant execute on function public.is_internal_admin() to anon, authenticated;

-- DESPUES de crear un usuario en Authentication > Users,
-- reemplazar el email y ejecutar SOLO este bloque para hacerlo admin:
--
-- insert into public.staff_profiles (user_id, email, display_name, role)
-- select id, email, 'Administrador', 'admin'
-- from auth.users
-- where email = 'TU_EMAIL_ADMIN'
-- on conflict (user_id) do update
-- set role = excluded.role,
--     display_name = excluded.display_name,
--     is_active = true,
--     updated_at = now();

