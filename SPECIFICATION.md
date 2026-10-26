# SPECIFICATION — Sistema de Gestión de Inventario (API REST + Flutter)

> Documento fuente de verdad del proyecto (metodología SDD). Todo el código debe
> cumplir lo aquí descrito; cualquier cambio de alcance se registra primero aquí.

## 1. Objetivo

Construir un sistema para administrar el inventario de productos compuesto por:

1. **Backend**: API REST con persistencia real en base de datos.
2. **Frontend**: aplicación móvil Flutter que consume la API, muestra métricas
   del inventario y permite el CRUD completo de productos.

## 2. Arquitectura general

```
┌──────────────────────────┐   HTTP/JSON (Dio)   ┌───────────────────────────┐
│  Flutter (frontend/)     │ ──────────────────▶ │  Express API (backend/)   │
│  views → services → Dio  │ ◀────────────────── │  routes → controllers     │
└──────────────────────────┘                     │  → validators → repository│
                                                 │  → SQLite (node:sqlite)   │
                                                 └───────────────────────────┘
```

```
Parcial2_API REST + Flutter/
├── SPECIFICATION.md   ← este documento
├── PLAN.md            ← plan de desarrollo por hitos
├── README.md          ← guía de instalación, BD y endpoints
├── backend/           ← API REST (Node.js + Express + SQLite)
└── frontend/          ← App móvil Flutter
```

## 3. Stack técnico

| Capa       | Tecnología                                                        |
|------------|-------------------------------------------------------------------|
| Runtime    | Node.js ≥ 22.13 (módulo nativo `node:sqlite`, sin compilación)     |
| Framework  | Express 5 (manejo nativo de errores async)                        |
| BD         | SQLite (archivo `backend/data/inventario.db`)                     |
| Config     | `dotenv` (`backend/.env`)                                         |
| CORS       | `cors` (permite Flutter Web / emuladores)                         |
| Pruebas    | `node:test` + `fetch` nativo contra BD en memoria                 |
| Móvil      | Flutter 3.x / Dart 3.x                                            |
| HTTP       | `dio`                                                             |
| Navegación | `go_router` (`StatefulShellRoute` con barra inferior)             |
| Entorno    | `flutter_dotenv` (`frontend/.env` → `API_BASE_URL`)               |

## 4. Modelo de datos

### Tabla `productos`

| Campo            | Tipo SQLite | Restricciones                                  |
|------------------|-------------|------------------------------------------------|
| `id`             | INTEGER     | PRIMARY KEY AUTOINCREMENT                      |
| `nombre`         | TEXT        | NOT NULL, 1–100 caracteres                     |
| `codigo`         | TEXT        | NOT NULL, UNIQUE (sin distinguir mayúsculas), 1–50 |
| `descripcion`    | TEXT        | NULL permitido, máx. 500 caracteres            |
| `precio`         | REAL        | NOT NULL, `precio > 0` (redondeado a 2 decimales) |
| `cantidad`       | INTEGER     | NOT NULL, `cantidad >= 0`                      |
| `categoria`      | TEXT        | NOT NULL, 1–50 caracteres                      |
| `creado_en`      | TEXT        | ISO-8601, asignado por la BD                   |
| `actualizado_en` | TEXT        | ISO-8601, se actualiza en cada PUT             |

Las restricciones se aplican **en dos niveles**: validador de la API (mensajes
claros por campo) y `CHECK`/`UNIQUE` en SQLite (integridad garantizada).

### Seeder

Script `npm run seed` que reinicia la tabla y carga **12 productos** de prueba
de varias categorías. Al arrancar el servidor, si la tabla está vacía se
ejecuta el seeder automáticamente.

## 5. Contrato de la API

Base: `http://<host>:3000/api`

### 5.1 Formato estándar de respuesta

Éxito:
```json
{ "success": true, "message": "Texto descriptivo", "data": { } }
```
Listado (añade `total`):
```json
{ "success": true, "message": "...", "total": 12, "data": [ ] }
```
Error:
```json
{ "success": false, "message": "Texto descriptivo", "errors": { "campo": "detalle" } }
```
`errors` solo aparece cuando hay errores por campo.

### 5.2 Endpoints

| Método | Ruta                   | Descripción          | Éxito | Errores          |
|--------|------------------------|----------------------|-------|------------------|
| GET    | `/api/productos`       | Listar todos         | 200   | —                |
| GET    | `/api/productos/{id}`  | Detalle              | 200   | 400, 404         |
| POST   | `/api/productos`       | Crear                | 201   | 400, 422         |
| PUT    | `/api/productos/{id}`  | Actualizar (completo)| 200   | 400, 404, 422    |
| DELETE | `/api/productos/{id}`  | Eliminar             | 200   | 400, 404         |
| GET    | `/api/health`          | Estado del servicio  | 200   | —                |

### 5.3 Códigos de estado

- **200 OK** — lectura, actualización o eliminación correcta.
- **201 Created** — producto creado (incluye cabecera `Location`).
- **400 Bad Request** — JSON mal formado o `id` no numérico/positivo.
- **404 Not Found** — producto o ruta inexistente.
- **422 Unprocessable Entity** — validación de campos fallida o `codigo` duplicado.
- **500 Internal Server Error** — error inesperado (sin exponer detalles internos).

### 5.4 Reglas de validación (POST y PUT)

| Campo         | Regla                                                         |
|---------------|---------------------------------------------------------------|
| `nombre`      | Obligatorio, texto no vacío, ≤ 100                             |
| `codigo`      | Obligatorio, texto no vacío, ≤ 50, único (en PUT se excluye el propio producto) |
| `descripcion` | Opcional; texto ≤ 500; cadena vacía se guarda como `null`      |
| `precio`      | Obligatorio, numérico, `> 0`                                   |
| `cantidad`    | Obligatorio, entero, `>= 0`                                    |
| `categoria`   | Obligatorio, texto no vacío, ≤ 50                              |

Se aceptan números enviados como texto numérico (`"12.5"`). Los textos se
recortan (`trim`). Campos desconocidos se ignoran. `PUT` exige el objeto completo.

## 6. Aplicación Flutter

### 6.1 Estructura de `lib/`

```
lib/
├── config/     app_config.dart          (carga .env, URL base, timeouts)
├── models/     producto.dart            (fromJson / toJson)
│               inventario_resumen.dart  (métricas calculadas)
├── routes/     app_router.dart          (go_router)
├── services/   api_client.dart          (instancia Dio + interceptores)
│               api_exception.dart       (errores de red/API tipados)
│               producto_service.dart    (CRUD centralizado)
├── themes/     app_theme.dart
├── views/      dashboard_view.dart, productos_list_view.dart,
│               producto_detail_view.dart, producto_form_view.dart,
│               home_shell.dart
├── widgets/    metric_card.dart, producto_tile.dart, state_views.dart,
│               confirm_dialog.dart, app_snackbar.dart
└── main.dart
```

### 6.2 Rutas

| Ruta                       | Pantalla                     |
|----------------------------|------------------------------|
| `/`                        | Dashboard (pestaña 1)        |
| `/productos`               | Listado (pestaña 2)          |
| `/productos/nuevo`         | Formulario de registro       |
| `/productos/:id`           | Detalle                      |
| `/productos/:id/editar`    | Formulario de edición        |

Navegación principal mediante `NavigationBar` inferior (Dashboard / Productos).

### 6.3 Funcionalidades

- **Dashboard**: identidad visual (nombre + ícono), acceso directo a productos y
  a registrar, y 3 tarjetas de métricas:
  1. Total de productos registrados.
  2. Total de unidades disponibles (Σ cantidad).
  3. Valor total del inventario (Σ precio × cantidad).
  Las métricas se recalculan al abrir la app, al deslizar para refrescar y
  automáticamente tras cualquier creación/edición/eliminación.
- **Listado**: nombre, precio y cantidad; toque → detalle; botón flotante → nuevo.
- **Detalle**: todos los campos; acciones Editar y Eliminar.
- **Formulario**: mismo widget para crear (POST) y editar (PUT, precarga datos);
  validación local equivalente a la del backend y muestra de errores del
  servidor (422) en el campo correspondiente.
- **Eliminar**: diálogo de confirmación previo al DELETE.

### 6.4 Reglas de calidad

- Cero llamadas HTTP en widgets: las vistas solo invocan `ProductoService`.
- `async/await` + `Future` en toda la capa de red.
- Estados visuales: cargando (spinner), error (con reintentar), lista vacía y
  `SnackBar` para éxito/fallo de operaciones.
- Errores de Dio traducidos a mensajes comprensibles (sin conexión, timeout,
  404, 422, 5xx).

## 7. Seguridad y repositorio

- `.gitignore` excluye `.env`, `node_modules/`, `build/`, `.dart_tool/`,
  bases de datos `*.db` y archivos de IDE.
- Se versionan `backend/.env.example` y `frontend/.env.example` (sin secretos).
- El backend no expone trazas de error en las respuestas.

## 8. Criterios de aceptación

1. `npm install && npm start` levanta la API con 12 productos precargados.
2. Los 5 endpoints responden según §5 (verificado por `npm test`).
3. `flutter analyze` sin errores; la app lista, crea, edita y elimina
   productos contra la API real y el dashboard refleja los cambios.
4. README documenta instalación, BD y endpoints con ejemplos JSON.
