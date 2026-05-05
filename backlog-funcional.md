# Backlog Funcional

## Roadmap MVP

Prioridad P0:

- Landing premium con CTA de reserva.
- Formulario de reserva de 5 pasos.
- Persistencia de turnos en Firestore.
- Panel operativo con agenda en tiempo real.
- Cambio de estado a terminado con boton manual de WhatsApp para staff.
- Catalogo CRUD de servicios.

Prioridad P1:

- Modulo financiero con ingresos, egresos y ganancia neta.
- Club de Brillo configurable entre 5 y 10 lavados con sellos visuales.
- Historial de puntos.
- Indicadores de urgencia en agenda.

Prioridad P2:

- Fotos antes/despues con Firebase Storage.
- Recordatorios automaticos por WhatsApp/SMS.
- Reportes PDF mensuales.
- OAuth o login por roles mas robusto.

## Epica 1 - Landing Page de Conversion

Objetivo:

Convertir visitantes en reservas con una experiencia premium, clara y rapida.

Historias:

- Como visitante quiero ver una propuesta de valor clara apenas entro para entender que ofrece A Todo Brillo.
- Como visitante quiero ver metricas de confianza para sentir seguridad antes de reservar.
- Como visitante quiero conocer beneficios tecnicos del cuidado del vehiculo para justificar el valor del servicio.
- Como visitante quiero iniciar una reserva desde un CTA visible para no perder tiempo.

Criterios de aceptacion:

- El hero muestra marca, propuesta de valor y CTA principal.
- La estetica usa fondo oscuro, acento electric blue y jerarquia tipografica fuerte.
- Las metricas incluyen lavados realizados, calificacion y garantia.
- La seccion educativa explica pH neutro, proteccion UV y terminacion premium sin exceso de texto.
- El CTA lleva directo al formulario de reserva.

## Epica 2 - Reserva Intuitiva

Objetivo:

Permitir que un cliente complete una reserva en menos de 30 segundos.

Historias:

- Como cliente quiero ingresar mi nombre y WhatsApp para que puedan contactarme.
- Como cliente quiero cargar mi vehiculo para que el staff sepa que trabajo recibira.
- Como cliente quiero elegir servicio, fecha y hora para confirmar mi turno.
- Como cliente quiero ver un resumen antes de confirmar para evitar errores.

Criterios de aceptacion:

- El formulario tiene 5 pasos: nombre, WhatsApp, vehiculo, fecha/hora y servicio.
- El formulario valida campos obligatorios antes de avanzar.
- El WhatsApp se normaliza para usarlo luego en `wa.me`.
- Al confirmar, se crea un documento en `appointments`.
- Si el cliente ya existe por telefono, se reutiliza o actualiza su ficha en `users`.
- El servicio copia `serviceName` y `servicePrice` dentro del appointment.

## Epica 3 - Panel Operativo

Objetivo:

Dar al staff una vista clara de trabajos pendientes y acciones diarias.

Historias:

- Como staff quiero ver la agenda ordenada por fecha para priorizar el trabajo.
- Como staff quiero identificar trabajos de hoy para actuar rapido.
- Como staff quiero cambiar el estado de un turno para reflejar el avance operativo.
- Como staff quiero agregar notas internas para registrar detalles del trabajo.

Criterios de aceptacion:

- La agenda usa `onSnapshot` para actualizarse en tiempo real.
- Los turnos se ordenan por `scheduledAt` ascendente.
- Los trabajos del dia actual se resaltan visualmente.
- Los estados disponibles son `pending`, `confirmed`, `in_progress`, `done` y `cancelled`.
- El cambio a `done` dispara la logica de finalizacion.

## Epica 4 - WhatsApp Automation

Objetivo:

Reducir friccion operativa al avisar cuando un trabajo esta listo, manteniendo el control manual en manos del staff.

Historias:

- Como staff quiero hacer clic en un boton de WhatsApp cuando el trabajo este terminado para avisar al cliente con un mensaje precargado.
- Como cliente quiero recibir un mensaje profesional con mi vehiculo mencionado.

Criterios de aceptacion:

- Al marcar un appointment como `done`, aparece una accion de WhatsApp visible para `staff` y `admin`.
- El staff debe hacer clic para abrir la URL `wa.me`.
- El mensaje incluye `clientName` y `vehicleName`.
- La apertura usa `window.open`.
- El appointment registra `whatsappOpenedAt` y `whatsappOpenedBy`.
- Si el telefono no es valido, el sistema muestra una accion manual alternativa.

## Epica 5 - Club de Brillo

Objetivo:

Fidelizar clientes con una mecanica configurable de servicios completados mas 1 lavado de cortesia.

Historias:

- Como cliente quiero ver mi progreso en sellos para saber cuan cerca estoy del premio.
- Como admin quiero elegir si el premio se obtiene a los 5, 6, 7, 8, 9 o 10 lavados.
- Como admin quiero que cada trabajo terminado sume un punto automaticamente.
- Como admin quiero saber cuando un cliente llego al objetivo configurado para otorgar el beneficio.
- Como admin quiero registrar un canje para reiniciar el progreso.

Criterios de aceptacion:

- Cada appointment `done` suma 1 punto si `loyaltyPointAwarded` es `false`.
- Al llegar a `settings/business.loyaltyTargetServices`, `courtesyWashAvailable` pasa a `true`.
- La UI muestra sellos o estrellas segun el objetivo configurado.
- El admin puede configurar el objetivo en `5`, `6`, `7`, `8`, `9` o `10` lavados.
- El canje crea un evento en `loyaltyEvents`.
- El sistema evita sumar dos veces por el mismo appointment.

## Epica 6 - Gestion Financiera

Objetivo:

Mostrar salud financiera basica del negocio en tiempo real.

Historias:

- Como admin quiero ver ingresos por servicios realizados para medir facturacion.
- Como admin quiero cargar egresos para tener control operativo.
- Como admin quiero ver ganancia neta para entender el resultado real.
- Como admin quiero filtrar por periodo para revisar dias, semanas o meses.

Criterios de aceptacion:

- Los ingresos se calculan desde appointments `done`.
- Los egresos se cargan manualmente en `expenses`.
- La ganancia neta se calcula como ingresos menos egresos.
- Todos los montos se muestran en pesos argentinos (`ARS`) con formato `es-AR`.
- Los filtros diarios y mensuales usan zona horaria Mendoza (`America/Argentina/Mendoza`).
- El panel se actualiza en tiempo real con `onSnapshot`.
- Cada egreso incluye monto, categoria, fecha y descripcion.

## Epica 7 - CRUD de Servicios

Objetivo:

Permitir que el negocio ajuste su oferta sin tocar codigo.

Historias:

- Como admin quiero crear servicios con nombre, descripcion, precio y duracion.
- Como admin quiero editar precios y descripciones para mantener la oferta actualizada.
- Como admin quiero desactivar servicios sin perder historicos.
- Como cliente quiero ver solo servicios disponibles.

Criterios de aceptacion:

- El admin puede crear, editar y desactivar servicios.
- El listado publico solo muestra `isActive: true`.
- El orden se controla con `sortOrder`.
- Los appointments guardan copia del nombre y precio del servicio elegido.

## Epica 8 - Roles y Accesos

Objetivo:

Proteger acciones sensibles sin bloquear el flujo simple de reservas.

Historias:

- Como visitante quiero reservar con baja friccion.
- Como cliente quiero consultar mi reserva y mi progreso del Club de Brillo sin acceder a funciones internas.
- Como staff quiero acceder al panel operativo.
- Como admin quiero gestionar servicios, finanzas y roles.

Criterios de aceptacion:

- Las reservas pueden crearse con autenticacion anonima.
- El rol `client` puede crear reservas y ver informacion propia.
- El panel operativo requiere rol `staff` o `admin`.
- El rol `staff` puede ver agenda, cambiar estados, cargar notas y abrir WhatsApp manualmente con clic.
- Finanzas, CRUD de servicios, configuracion del premio y gestion de roles requieren rol `admin`.
- Las reglas de Firestore impiden modificar campos sensibles desde cliente.

## Configuracion del Negocio

Objetivo:

Permitir que el administrador ajuste parametros comerciales sin modificar codigo.

Criterios definidos:

- Roles activos: `client`, `staff` y `admin`.
- Premio Club de Brillo configurable en `5`, `6`, `7`, `8`, `9` o `10` lavados.
- Moneda: pesos argentinos (`ARS`).
- Ubicacion operativa: Mendoza, Argentina.
- Zona horaria: `America/Argentina/Mendoza`.
- WhatsApp: modo manual con clic desde rol `staff` o `admin`.

## Definicion de Done Tecnica

Una historia se considera terminada cuando:

- Tiene UI funcional en desktop y mobile.
- Persiste correctamente en Firestore.
- Maneja estados vacios y errores basicos.
- No rompe el flujo de reserva principal.
- Incluye validaciones de datos criticos.
- Fue probada manualmente con al menos un caso feliz y un caso de error.

## Riesgos Pendientes

- Confirmar si el login de staff/admin sera por email/password, Google OAuth o Custom Tokens.
- Definir si el premio resetea a cero o permite acumulacion con saldo excedente.
- Definir si los reportes PDF se generan del lado cliente o mediante Cloud Functions.
