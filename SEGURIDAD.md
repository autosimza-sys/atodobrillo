# Seguridad - A Todo Brillo

Objetivo: proteger el panel interno sin romper las reservas publicas.

## Que cambio en la app

- Ya no hay selector publico `Cliente / Staff / Admin`.
- El visitante solo puede reservar y consultar su progreso local.
- El panel interno queda oculto si no hay login.
- Staff/Admin ingresan con Supabase Auth.
- `staff` puede ver agenda, cambiar estados y abrir WhatsApp.
- `admin` puede ver finanzas, servicios, gastos y configuracion.

## Orden correcto

No cierres permisos antes de subir el codigo con login.

### Paso 1 - Subir estos archivos a GitHub

Subi/actualiza:

```text
index.html
src/app.js
src/styles.css
src/supabase-config.js
supabase-seguridad-paso1-staff.sql
supabase-seguridad-paso2-rls-produccion.sql
SEGURIDAD.md
```

Vercel va a publicar solo cuando detecte el cambio.

### Paso 2 - Crear tu usuario admin en Supabase

1. Supabase > `Authentication`.
2. `Users`.
3. `Add user`.
4. Email: tu email.
5. Password: una contrasena fuerte.
6. Activar/confirmar el usuario si Supabase lo pide.

### Paso 3 - Ejecutar SQL paso 1

1. Supabase > `SQL Editor`.
2. Pega todo el archivo:

```text
supabase-seguridad-paso1-staff.sql
```

3. Ejecuta `Run`.

### Paso 4 - Hacer tu usuario admin

En el mismo SQL Editor, pega esto cambiando el email:

```sql
insert into public.staff_profiles (user_id, email, display_name, role)
select id, email, 'Administrador', 'admin'
from auth.users
where email = 'TU_EMAIL_ADMIN'
on conflict (user_id) do update
set role = excluded.role,
    display_name = excluded.display_name,
    is_active = true,
    updated_at = now();
```

Ejemplo:

```sql
where email = 'miemail@gmail.com'
```

### Paso 5 - Probar login

1. Abri la web de Vercel.
2. Anda a `Ingreso staff`.
3. Entra con el email y contrasena que creaste.
4. Si entras y ves el panel, esta bien.

### Paso 6 - Cerrar permisos

Solo si el login ya funciona:

1. Supabase > `SQL Editor`.
2. Pega todo el archivo:

```text
supabase-seguridad-paso2-rls-produccion.sql
```

3. Ejecuta `Run`.

### Paso 7 - Probar otra vez

Proba:

- Crear reserva sin login.
- Entrar como admin.
- Ver agenda.
- Marcar trabajo terminado.
- Abrir WhatsApp.
- Ver finanzas.

Si todo anda, el panel interno ya queda protegido con login y RLS.

## Como crear un staff despues

1. Supabase > `Authentication` > `Users` > `Add user`.
2. Crea el email del empleado.
3. En SQL Editor ejecuta:

```sql
insert into public.staff_profiles (user_id, email, display_name, role)
select id, email, 'Nombre del empleado', 'staff'
from auth.users
where email = 'EMAIL_DEL_EMPLEADO'
on conflict (user_id) do update
set role = excluded.role,
    display_name = excluded.display_name,
    is_active = true,
    updated_at = now();
```

## Importante

La publishable key puede estar en el navegador. La seguridad real queda en:

- Supabase Auth.
- RLS activado.
- Politicas por rol.
- No mostrar panel interno sin login.
