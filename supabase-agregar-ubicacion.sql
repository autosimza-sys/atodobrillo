-- Agrega direccion, link de mapa y WhatsApp del negocio a la configuracion.
-- Pegar una sola vez en Supabase > SQL Editor > Run.

alter table public.settings
  add column if not exists business_address text not null default '8085 Rodríguez, Luján de Cuyo, Mendoza',
  add column if not exists map_url text not null default 'https://www.google.com/maps/search/?api=1&query=8085%20Rodriguez%2C%20Lujan%20de%20Cuyo%2C%20Mendoza',
  add column if not exists contact_phone text not null default '';

insert into public.settings (id)
values ('business')
on conflict (id) do nothing;

update public.settings
set business_address = '8085 Rodríguez, Luján de Cuyo, Mendoza',
    map_url = coalesce(nullif(map_url, ''), 'https://www.google.com/maps/search/?api=1&query=8085%20Rodriguez%2C%20Lujan%20de%20Cuyo%2C%20Mendoza'),
    contact_phone = coalesce(contact_phone, ''),
    updated_at = now()
where id = 'business';
