-- Consulta publica segura para Club de Brillo.
-- Permite que un cliente consulte sus puntos poniendo su WhatsApp,
-- sin abrir lectura completa sobre la tabla users.
--
-- Pegar en Supabase > SQL Editor > Run.

create or replace function public.lookup_loyalty_by_phone(phone_digits text)
returns table (
  display_name text,
  vehicle_name text,
  loyalty_points integer,
  lifetime_services integer,
  courtesy_wash_available boolean
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
    u.courtesy_wash_available
  from public.users u
  where u.role = 'client'
    and u.normalized_phone = phone_digits
  limit 1
$$;

grant execute on function public.lookup_loyalty_by_phone(text) to anon, authenticated;
