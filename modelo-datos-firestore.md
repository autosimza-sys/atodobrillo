# Modelo de Datos Firestore

## Vision General

La arquitectura propuesta mantiene las colecciones actuales del sistema y agrega estructura suficiente para que reservas, finanzas, fidelizacion y automatizaciones funcionen de forma consistente.

Colecciones principales:

- `appointments`: turnos y trabajos operativos.
- `services`: catalogo editable de servicios y precios.
- `expenses`: egresos operativos cargados manualmente.
- `users`: clientes, staff y administradores.
- `settings`: configuracion del negocio, moneda, zona horaria y premio del Club de Brillo.

Colecciones opcionales recomendadas:

- `loyaltyEvents`: historial auditable de puntos otorgados o canjeados.
- `notifications`: registro de mensajes disparados por WhatsApp u otros canales.

## settings

Configuracion editable por administrador. Centraliza decisiones del negocio para evitar valores fijos en codigo.

Ruta recomendada:

```text
settings/business
```

Campos:

```js
{
  businessName: "A Todo Brillo",
  country: "AR",
  province: "Mendoza",
  currency: "ARS",
  locale: "es-AR",
  timezone: "America/Argentina/Mendoza",
  loyaltyTargetServices: 10,
  loyaltyAllowedTargets: [5, 6, 7, 8, 9, 10],
  whatsappMode: "manual_staff_click",
  updatedBy: string,
  updatedAt: Timestamp
}
```

Reglas de negocio:

- Solo `admin` puede cambiar `settings/business`.
- `loyaltyTargetServices` define cuantos lavados completados generan el premio.
- El valor permitido para el premio es `5`, `6`, `7`, `8`, `9` o `10`.
- Los precios se guardan como numeros en pesos argentinos y se muestran con formato `ARS`, locale `es-AR`.
- La agenda, reportes y filtros diarios usan zona horaria `America/Argentina/Mendoza`.
- `whatsappMode: "manual_staff_click"` significa que WhatsApp no se abre solo: el staff toca un boton desde el panel.

## users

Representa clientes, staff y administradores. Para clientes, el documento funciona como ficha comercial y acumulador del Club de Brillo.

Ruta:

```text
users/{uid}
```

Campos:

```js
{
  uid: string,
  role: "client" | "staff" | "admin",
  displayName: string,
  phone: string,
  normalizedPhone: string,
  email: string | null,
  vehicleName: string | null,
  vehiclePlate: string | null,
  loyaltyPoints: number,
  lifetimeServices: number,
  courtesyWashAvailable: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastAppointmentAt: Timestamp | null
}
```

Reglas de negocio:

- `loyaltyPoints` sube de a 1 por cada servicio completado.
- Al llegar a `settings/business.loyaltyTargetServices`, `courtesyWashAvailable` pasa a `true`.
- Al canjear el premio, se crea un evento de canje y `loyaltyPoints` vuelve a `0`.
- `normalizedPhone` debe usarse para deduplicar clientes que reserven mas de una vez.

## services

Catalogo administrable de servicios. Alimenta el formulario de reserva y el calculo automatico de ingresos.

Ruta:

```text
services/{serviceId}
```

Campos:

```js
{
  name: string,
  description: string,
  price: number,
  estimatedMinutes: number,
  category: "wash" | "interior" | "polish" | "ceramic" | "combo",
  isActive: boolean,
  sortOrder: number,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Reglas de negocio:

- Solo los servicios con `isActive: true` aparecen en la landing y en nuevas reservas.
- El precio guardado en una reserva debe copiarse desde el servicio al momento de reservar para preservar historicos.
- El admin puede crear, editar, desactivar o eliminar servicios. Para evitar romper historiales, se recomienda desactivar antes que borrar.

## appointments

Turnos de clientes y trabajos operativos para el panel de staff.

Ruta:

```text
appointments/{appointmentId}
```

Campos:

```js
{
  clientUid: string,
  clientName: string,
  clientPhone: string,
  normalizedPhone: string,
  vehicleName: string,
  vehiclePlate: string | null,
  serviceId: string,
  serviceName: string,
  servicePrice: number,
  scheduledAt: Timestamp,
  status: "pending" | "confirmed" | "in_progress" | "done" | "cancelled",
  paymentStatus: "unpaid" | "paid" | "partial",
  paidAmount: number,
  staffNotes: string | null,
  whatsappOpenedAt: Timestamp | null,
  whatsappOpenedBy: string | null,
  loyaltyPointAwarded: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  completedAt: Timestamp | null
}
```

Flujo de estados:

```text
pending -> confirmed -> in_progress -> done
pending -> cancelled
confirmed -> cancelled
```

Reglas de negocio:

- La agenda operativa se ordena por `scheduledAt` ascendente.
- Los trabajos con fecha del dia actual se resaltan como urgentes.
- Al marcar `status: "done"`:
  - Se registra `completedAt`.
  - Se suma el ingreso si corresponde.
  - Se suma 1 punto de fidelizacion si `loyaltyPointAwarded` era `false`.
  - Se habilita el boton de WhatsApp para usuarios con rol `staff` o `admin`.
- WhatsApp se abre manualmente cuando el staff hace clic en el boton del appointment terminado.
- Se marca `whatsappOpenedAt` y `whatsappOpenedBy` cuando la accion manual se ejecuta.

Mensaje sugerido para WhatsApp:

```text
Hola {clientName}, tu {vehicleName} ya esta listo. Gracias por confiar en A Todo Brillo. Te esperamos para retirarlo cuando gustes.
```

URL sugerida:

```js
const message = `Hola ${clientName}, tu ${vehicleName} ya esta listo. Gracias por confiar en A Todo Brillo. Te esperamos para retirarlo cuando gustes.`;
const url = `https://wa.me/${normalizedPhone}?text=${encodeURIComponent(message)}`;
window.open(url, "_blank", "noopener,noreferrer");
```

Permiso de accion:

```js
const canOpenWhatsApp = ["staff", "admin"].includes(currentUser.role) && appointment.status === "done";
```

## expenses

Registro manual de egresos para calcular ganancia neta.

Ruta:

```text
expenses/{expenseId}
```

Campos:

```js
{
  title: string,
  amount: number,
  category: "supplies" | "rent" | "salary" | "maintenance" | "marketing" | "other",
  expenseDate: Timestamp,
  notes: string | null,
  createdBy: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Reglas de negocio:

- Los egresos se suman por rango de fechas.
- Los importes se expresan en pesos argentinos (`ARS`) y se formatean con `Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS" })`.
- La ganancia neta se calcula como:

```text
ingresos de appointments done - expenses del periodo
```

## loyaltyEvents

Coleccion recomendada para auditoria del Club de Brillo. Evita depender solo de un contador mutable.

Ruta:

```text
loyaltyEvents/{eventId}
```

Campos:

```js
{
  userUid: string,
  appointmentId: string | null,
  type: "earned" | "redeemed" | "adjustment",
  points: number,
  reason: string,
  createdBy: string | "system",
  createdAt: Timestamp
}
```

Reglas de negocio:

- Cada appointment terminado genera un evento `earned` de `1` punto.
- Cada canje genera un evento `redeemed` equivalente a `-settings/business.loyaltyTargetServices` puntos o resetea el contador del usuario.
- El panel debe mostrar tantos sellos visuales como indique `loyaltyTargetServices`, con sellos activos segun `users.loyaltyPoints`.

## notifications

Coleccion opcional para trazabilidad de automatizaciones.

Ruta:

```text
notifications/{notificationId}
```

Campos:

```js
{
  appointmentId: string,
  userUid: string,
  channel: "whatsapp",
  type: "job_done" | "reminder" | "loyalty_reward",
  status: "opened" | "sent" | "failed",
  messagePreview: string,
  createdAt: Timestamp,
  openedAt: Timestamp | null
}
```

## Indices Sugeridos

Para `appointments`:

- `status ASC, scheduledAt ASC`
- `clientUid ASC, scheduledAt DESC`
- `scheduledAt ASC`
- `status ASC, completedAt DESC`

Para `expenses`:

- `expenseDate DESC`
- `category ASC, expenseDate DESC`

Para `services`:

- `isActive ASC, sortOrder ASC`

Para `loyaltyEvents`:

- `userUid ASC, createdAt DESC`
- `appointmentId ASC`

## Consultas Principales

Agenda operativa:

```js
query(
  collection(db, "appointments"),
  where("status", "in", ["pending", "confirmed", "in_progress"]),
  orderBy("scheduledAt", "asc")
)
```

Ingresos del periodo:

```js
query(
  collection(db, "appointments"),
  where("status", "==", "done"),
  where("completedAt", ">=", startDate),
  where("completedAt", "<=", endDate)
)
```

Egresos del periodo:

```js
query(
  collection(db, "expenses"),
  where("expenseDate", ">=", startDate),
  where("expenseDate", "<=", endDate)
)
```

## Reglas de Seguridad Base

Politica recomendada:

- Clientes anonimos pueden crear reservas.
- Clientes pueden leer solo su propia ficha y reservas si se implementa login real.
- Staff puede leer appointments, actualizar estados operativos, cargar notas y abrir WhatsApp con clic manual.
- Admin puede gestionar services, expenses, settings y roles.
- Nadie desde cliente debe poder modificar manualmente `loyaltyPoints`, `servicePrice` historico o `completedAt`.

Pseudoreglas:

```js
allow create: if request.auth != null;
allow read, update: if isStaffOrAdmin();
allow delete: if isAdmin();
```

## Invariantes Criticos

- Un appointment solo puede otorgar fidelizacion una vez.
- El precio historico de un appointment no debe cambiar si luego cambia el servicio.
- WhatsApp no debe abrirse automaticamente al pasar a `done`; debe habilitarse para clic manual de staff/admin.
- Los ingresos deben tomar appointments `done`, no reservas pendientes.
- Los gastos deben ser manuales y auditables.
