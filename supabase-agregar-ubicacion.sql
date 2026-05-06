-- Agrega direccion, link de mapa y WhatsApp del negocio a la configuracion.
-- Pegar una sola vez en Supabase > SQL Editor > Run.

alter table public.settings
  add column if not exists business_address text not null default 'Direccion a confirmar, Mendoza',
  add column if not exists map_url text not null default '',
  add column if not exists contact_phone text not null default '';

insert into public.settings (id)
values ('business')
on conflict (id) do nothing;

update public.settings
set business_address = coalesce(nullif(business_address, ''), 'Direccion a confirmar, Mendoza'),
    map_url = coalesce(map_url, ''),
    contact_phone = coalesce(contact_phone, ''),
    updated_at = now()
where id = 'business';
