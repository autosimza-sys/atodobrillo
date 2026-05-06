# Como hacer que funcione con GitHub, StackBlitz, Vercel y Supabase

Esta guia esta pensada para hacerlo sin saber programar.

## 1. Probar primero sin base de datos

Abri este archivo:

```text
index.html
```

La app puede abrirse desde el navegador para revisar la interfaz. Para usarla en serio, tiene que estar conectada a Supabase. Eso permite:

- Podes crear reservas.
- Podes cambiar rol entre cliente, staff y admin.
- Podes marcar trabajos como terminados.
- Podes probar Club de Brillo.
- Podes cargar servicios y egresos.

En produccion, los datos deben quedar guardados en Supabase.

## 2. Crear la base en Supabase

1. Entra a Supabase.
2. Crea un proyecto nuevo.
3. En el menu izquierdo, entra a `SQL Editor`.
4. Crea una consulta nueva.
5. Copia todo el contenido de este archivo:

```text
supabase-schema-demo.sql
```

6. Pegalo en Supabase.
7. Toca `Run`.

Eso crea estas tablas:

- `settings`
- `services`
- `users`
- `appointments`
- `expenses`
- `loyalty_events`
- `notifications`

Importante: este SQL inicial crea la estructura. Antes de usarlo con clientes reales hay que aplicar tambien la guia de seguridad y cerrar permisos con RLS.

## 3. Conectar la app con Supabase

En Supabase:

1. Entra a `Project Settings`.
2. Entra a `API`.
3. Copia el `Project URL`.
4. Copia la key `anon` o `publishable`.
5. No copies nunca la key `service_role`.

Despues abri este archivo del proyecto:

```text
src/supabase-config.js
```

Vas a ver esto:

```js
window.ATB_SUPABASE_CONFIG = {
  url: "",
  anonKey: "",
};
```

Pegalo asi:

```js
window.ATB_SUPABASE_CONFIG = {
  url: "https://TU-PROYECTO.supabase.co",
  anonKey: "TU-ANON-KEY",
};
```

Guarda el archivo. Cuando abras la app, si las claves estan bien, arriba va a aparecer un aviso diciendo que conecto con Supabase.

## 4. Subir a GitHub

1. Entra a GitHub.
2. Crea un repositorio nuevo.
3. Sube estos archivos y carpetas:

```text
index.html
README.md
COMO-PUBLICAR.md
modelo-datos-firestore.md
backlog-funcional.md
preview.html
supabase-schema-demo.sql
src/
```

La carpeta `src/` debe incluir:

```text
src/app.js
src/styles.css
src/supabase-config.js
```

## 5. Abrir en StackBlitz

Cuando el repositorio sea publico, podes abrirlo asi:

```text
https://stackblitz.com/github/TU-USUARIO/TU-REPO
```

Ejemplo:

```text
https://stackblitz.com/github/miusuario/a-todo-brillo
```

StackBlitz te sirve para ver y editar rapido desde el navegador.

## 6. Publicar en Vercel

1. Entra a Vercel.
2. Toca `Add New Project`.
3. Elegi tu repositorio de GitHub.
4. Si pregunta framework, elegi `Other`.
5. Si pregunta build command, dejalo vacio.
6. Si pregunta output directory, dejalo vacio o usa `.`
7. Toca `Deploy`.

Vercel te va a dar una URL publica.

Cada vez que cambies algo en GitHub, Vercel vuelve a publicar automaticamente.

## 7. Prueba basica

1. Abri la URL de Vercel.
2. Crea una reserva.
3. Cambia el rol a `Staff`.
4. En el panel, cambia el trabajo a `Terminado`.
5. Toca el boton de WhatsApp.
6. Cambia el rol a `Admin`.
7. Proba cambiar el premio del Club de Brillo a 5, 6, 7, 8, 9 o 10 lavados.
8. Revisa en Supabase que aparezcan datos en `appointments`, `users`, `services` y `settings`.

## 8. Antes de usar con clientes reales

Todavia faltan estas mejoras:

- Login real para admin y staff.
- Cerrar permisos de Supabase con RLS segura.
- Sacar el selector publico de roles.
- Separar pantalla cliente y pantalla interna del negocio.
- Configurar dominio propio.

El MVP actual sirve para probar el negocio, mostrar la app y validar el flujo.
