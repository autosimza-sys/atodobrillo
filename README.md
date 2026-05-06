# A Todo Brillo - Pro Detailing Ecosystem

Documentacion funcional y tecnica inicial para convertir la vision del producto en una base clara de implementacion.

## Entregables

- [Modelo de datos Firestore](./modelo-datos-firestore.md): colecciones, campos, reglas de negocio, estados, indices sugeridos y automatizaciones clave.
- [Backlog funcional](./backlog-funcional.md): epicas, historias de usuario, criterios de aceptacion y roadmap MVP.
- [SPA funcional](./index.html): landing, reserva, panel operativo, finanzas, servicios, configuracion y Club de Brillo.
- [Preview de documentacion](./preview.html): vista visual resumida de la documentacion tecnica.
- [Como publicar](./COMO-PUBLICAR.md): guia paso a paso para GitHub, StackBlitz, Vercel y Supabase.
- [SQL Supabase inicial](./supabase-schema-demo.sql): tablas iniciales para usar Supabase como base de datos.
- [Seguridad](./SEGURIDAD.md): pasos para activar login staff/admin y cerrar permisos.
- [SQL Seguridad Paso 1](./supabase-seguridad-paso1-staff.sql): crea perfiles internos.
- [SQL Seguridad Paso 2](./supabase-seguridad-paso2-rls-produccion.sql): cierra RLS para produccion.
- [SQL Club Publico](./supabase-club-publico.sql): consulta segura de puntos por WhatsApp.

## Codigo

La app principal esta implementada con HTML, CSS y JavaScript vanilla:

- `index.html`: estructura de la SPA.
- `src/styles.css`: estilo Dark Premium Detailing.
- `src/app.js`: logica de reservas, roles, servicios, agenda, finanzas, WhatsApp manual y fidelizacion.

La app de produccion usa Supabase como base de datos. El navegador conserva una copia tecnica para mejorar la carga, pero las reservas y el panel interno dependen de la conexion real a Supabase.

URLs principales:

- Cliente: `https://atodobrillo.vercel.app`
- Staff/Admin: `https://atodobrillo.vercel.app/admin.html`

## Objetivo del sistema

"A Todo Brillo" es una plataforma integral para centros de estetica automotriz. Combina una landing page de conversion, un flujo de reservas simple, un panel operativo para staff/admin, gestion financiera, WhatsApp manual por staff/admin y un programa de fidelizacion configurable.

## Principios de producto

- El cliente debe poder completar una reserva en menos de 30 segundos.
- El staff debe ver turnos y cambios en tiempo real sin recargar.
- Cada trabajo terminado debe alimentar ingresos, fidelizacion y comunicacion con el cliente.
- La interfaz debe transmitir una estetica premium, oscura, rapida y confiable.
- Roles definidos: cliente, staff y admin.
- Moneda operativa: pesos argentinos (`ARS`) para Mendoza, Argentina.
- Club de Brillo configurable: premio a los 5, 6, 7, 8, 9 o 10 lavados.
- WhatsApp operativo: apertura manual por clic desde staff/admin.
