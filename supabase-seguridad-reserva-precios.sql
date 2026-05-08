-- A Todo Brillo - seguridad de reservas publicas
-- Pegar en Supabase > SQL Editor > Run.
-- Objetivo: el turno publico solo acepta servicios activos existentes.

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
  v_service_id text;
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

  if v_service.id is null or coalesce(v_service.price, 0) <= 0 then
    raise exception 'Servicio no disponible';
  end if;

  v_service_id := v_service.id;
  v_service_name := v_service.name;
  v_service_price := v_service.price;

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

grant execute on function public.create_public_booking(text, text, text, text, text, text, text, numeric, timestamptz) to anon, authenticated;
