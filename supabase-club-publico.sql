-- Consulta publica segura para Club de Brillo y estado del vehiculo.
-- Permite que un cliente consulte sus puntos y el ultimo estado poniendo su WhatsApp,
-- sin abrir lectura completa sobre las tablas users y appointments.
--
-- Pegar en Supabase > SQL Editor > Run.

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
