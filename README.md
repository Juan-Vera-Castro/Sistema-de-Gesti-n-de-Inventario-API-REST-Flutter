# Sistema de Gestión de Inventario — API REST + Flutter

Repositorio creado para añadir todas las evidencias del parcial #2 de la materia, de forma que quede en evidencia todo lo realizado.

Sistema para administrar el inventario de productos compuesto por una **API REST** en Node.js con persistencia real en **SQLite** y una **aplicación móvil Flutter** que muestra métricas en tiempo real y permite el CRUD completo de productos.

> Proyecto desarrollado con **SDD (Specification-Driven Development)**: la especificación está en [SPECIFICATION.md](SPECIFICATION.md) y el plan por hitos en [PLAN.md](PLAN.md).

---

## Tabla de contenido

1. [Tecnologías](#tecnologías)
2. [Estructura del proyecto](#estructura-del-proyecto)
3. [Instalación y ejecución](#instalación-y-ejecución)
4. [Base de datos](#base-de-datos)
5. [Catálogo de endpoints](#catálogo-de-endpoints)
6. [Aplicación Flutter](#aplicación-flutter)
7. [Pruebas](#pruebas)
8. [Seguridad del repositorio](#seguridad-del-repositorio)

---

## Tecnologías

### Backend
| Tecnología | Uso |
|---|---|
| **Node.js ≥ 22.13** | Runtime. Usa el módulo nativo `node:sqlite` (no requiere compilar dependencias). |
| **Express 5** | Framework HTTP y enrutamiento. |
| **SQLite** | Base de datos en archivo (`backend/data/inventario.db`). |
| **dotenv** | Variables de entorno (`PORT`, `HOST`, `DB_PATH`). |
| **cors** | Permite peticiones desde Flutter Web y emuladores. |
| **node:test** | Pruebas de integración (17 casos) sobre BD en memoria. |

### Frontend
| Tecnología | Uso |
|---|---|
| **Flutter 3.x / Dart 3.x** | Aplicación multiplataforma (Android, iOS, Web, Windows). |
| **dio** | Cliente HTTP y manejo de errores de red. |
| **go_router** | Enrutamiento declarativo con barra de navegación inferior. |
| **flutter_dotenv** | URL base de la API desde `.env`. |
| **intl** | Formato de moneda colombiana y números. |

---

## Estructura del proyecto

```
Parcial2_API REST + Flutter/
├── SPECIFICATION.md          Especificación (fuente de verdad)
├── PLAN.md                   Plan de desarrollo por hitos
├── README.md
├── backend/
│   ├── .env.example
│   ├── package.json
│   ├── src/
│   │   ├── app.js                         Fábrica de la app Express
│   │   ├── server.js                      Punto de entrada
│   │   ├── config/env.js                  Variables de entorno
│   │   ├── db/database.js                 Conexión y esquema SQLite
│   │   ├── db/seed.js · seed-data.js      Seeder (12 productos)
│   │   ├── repositories/                  Consultas SQL preparadas
│   │   ├── validators/                    Reglas de validación
│   │   ├── controllers/                   Lógica HTTP y códigos de estado
│   │   ├── routes/                        Definición de endpoints
│   │   ├── middlewares/                   404 y manejador global de errores
│   │   └── utils/response.js              Formato estándar de respuesta
│   └── test/productos.test.js
└── frontend/
    ├── .env.example
    ├── pubspec.yaml
    ├── lib/
    │   ├── config/      app_config.dart (.env), formatters.dart
    │   ├── models/      producto.dart, inventario_resumen.dart
    │   ├── routes/      app_router.dart, app_routes.dart
    │   ├── services/    api_client.dart, api_exception.dart, producto_service.dart
    │   ├── themes/      app_theme.dart
    │   ├── views/       dashboard, listado, detalle, formulario, home_shell
    │   ├── widgets/     metric_card, producto_tile, state_views, confirm_dialog, app_snackbar
    │   └── main.dart
    └── test/            modelos, servicio, vistas e integración
```

---

## Instalación y ejecución

### Requisitos previos
- [Node.js](https://nodejs.org/) **22.13 o superior** (`node -v`)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x (`flutter doctor`)
- Git
- Un emulador Android, un dispositivo físico, Chrome o Windows para ejecutar la app

### 1. Clonar el repositorio
```bash
git clone https://github.com/Juan-Vera-Castro/Sistema-de-Gesti-n-de-Inventario-API-REST-Flutter.git
cd Sistema-de-Gesti-n-de-Inventario-API-REST-Flutter
```

### 2. Backend
```bash
cd backend
npm install
cp .env.example .env        # En Windows (PowerShell): Copy-Item .env.example .env
npm run seed                # Crea la BD y carga los 12 productos de prueba
npm start                   # http://localhost:3000/api
```

| Script | Descripción |
|---|---|
| `npm start` | Inicia la API. Si la tabla está vacía ejecuta el seeder automáticamente. |
| `npm run dev` | Inicia con recarga automática (`node --watch`). |
| `npm run seed` | Reinicia la tabla `productos` y carga los datos de prueba. |
| `npm test` | Ejecuta las pruebas de integración. |

Comprobación rápida: abre <http://localhost:3000/api/health> o <http://localhost:3000/api/productos>.

### 3. Frontend (Flutter)
En otra terminal, con el backend en ejecución:
```bash
cd frontend
cp .env.example .env        # Obligatorio: el archivo se empaqueta como asset
flutter pub get
flutter run                 # Elige el dispositivo (emulador, Chrome, Windows...)
```

Ajusta `API_BASE_URL` en `frontend/.env` según dónde se ejecute la app:

| Dispositivo | `API_BASE_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:3000/api` (valor por defecto) |
| Chrome / Windows / simulador iOS | `http://localhost:3000/api` |
| Dispositivo físico (misma red Wi-Fi) | `http://<IP_LAN_DEL_PC>:3000/api` (ej. `http://192.168.1.20:3000/api`) |

> Tras cambiar `.env` hay que **detener y volver a ejecutar** `flutter run` (el hot reload no recarga assets).
> Para un dispositivo físico, permite el puerto 3000 en el firewall de Windows.

---

## Base de datos

Motor: **SQLite**, archivo `backend/data/inventario.db` (configurable con `DB_PATH`). El esquema se crea automáticamente al iniciar.

### Tabla `productos`

| Campo | Tipo | Restricciones |
|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `nombre` | TEXT | NOT NULL, 1–100 caracteres |
| `codigo` | TEXT | NOT NULL, **UNIQUE** (no distingue mayúsculas), 1–50 caracteres |
| `descripcion` | TEXT | Opcional (NULL), máx. 500 caracteres |
| `precio` | REAL | NOT NULL, `CHECK (precio > 0)` |
| `cantidad` | INTEGER | NOT NULL, `CHECK (cantidad >= 0)` |
| `categoria` | TEXT | NOT NULL, 1–50 caracteres |
| `creado_en` | TEXT | Fecha ISO-8601 de creación (automática) |
| `actualizado_en` | TEXT | Fecha ISO-8601 de la última actualización |

```sql
CREATE TABLE IF NOT EXISTS productos (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre         TEXT    NOT NULL CHECK (length(trim(nombre)) BETWEEN 1 AND 100),
  codigo         TEXT    NOT NULL UNIQUE COLLATE NOCASE CHECK (length(trim(codigo)) BETWEEN 1 AND 50),
  descripcion    TEXT    CHECK (descripcion IS NULL OR length(descripcion) <= 500),
  precio         REAL    NOT NULL CHECK (precio > 0),
  cantidad       INTEGER NOT NULL CHECK (cantidad >= 0),
  categoria      TEXT    NOT NULL CHECK (length(trim(categoria)) BETWEEN 1 AND 50),
  creado_en      TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  actualizado_en TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
```

### Datos de prueba (seeder)
12 productos en las categorías **Tecnología, Oficina, Alimentos y Aseo** (definidos en [backend/src/db/seed-data.js](backend/src/db/seed-data.js)), entre ellos uno agotado (`ASE-002`, cantidad 0) para probar ese estado en la app.

---

## Catálogo de endpoints

URL base: `http://localhost:3000/api`

### Formato estándar de respuesta

```jsonc
// Éxito
{ "success": true, "message": "Texto descriptivo", "data": { /* ... */ } }

// Error
{ "success": false, "message": "Texto descriptivo", "errors": { "campo": "detalle" } }
```

### Códigos de estado

| Código | Cuándo |
|---|---|
| `200 OK` | Consulta, actualización o eliminación correcta |
| `201 Created` | Producto creado (incluye cabecera `Location`) |
| `400 Bad Request` | JSON mal formado o `id` no numérico |
| `404 Not Found` | Producto o ruta inexistente |
| `422 Unprocessable Entity` | Validación fallida o código duplicado |
| `500 Internal Server Error` | Error inesperado (sin exponer detalles internos) |

### Reglas de validación (POST y PUT)
- `nombre`, `codigo`, `precio`, `cantidad` y `categoria` son **obligatorios**; `descripcion` es opcional.
- `codigo` debe ser **único** (en PUT puede conservar su propio código).
- `precio` debe ser numérico y **mayor que 0** (se redondea a 2 decimales).
- `cantidad` debe ser **entera y mayor o igual a 0**.
- Los textos se recortan; los números pueden enviarse como texto (`"12.5"`).

---

### `GET /api/productos` — Listar productos
**Respuesta `200`**
```json
{
  "success": true,
  "message": "Productos obtenidos correctamente",
  "total": 12,
  "data": [
    {
      "id": 1,
      "nombre": "Laptop Lenovo IdeaPad 3",
      "codigo": "TEC-001",
      "descripcion": "Portátil 15.6\", Ryzen 5, 16 GB RAM, 512 GB SSD",
      "precio": 2899000,
      "cantidad": 8,
      "categoria": "Tecnología",
      "creado_en": "2026-10-26T20:28:09.271Z",
      "actualizado_en": "2026-10-26T20:28:09.271Z"
    }
  ]
}
```

### `GET /api/productos/{id}` — Consultar detalle
**Respuesta `200`**
```json
{
  "success": true,
  "message": "Producto obtenido correctamente",
  "data": { "id": 2, "nombre": "Mouse inalámbrico Logitech M170", "codigo": "TEC-002", "descripcion": "Mouse óptico inalámbrico 2.4 GHz", "precio": 45900, "cantidad": 35, "categoria": "Tecnología", "creado_en": "...", "actualizado_en": "..." }
}
```
**Respuesta `404`**
```json
{ "success": false, "message": "No existe un producto con id 99" }
```

### `POST /api/productos` — Registrar producto
**Petición**
```json
{
  "nombre": "Memoria USB 64 GB",
  "codigo": "TEC-100",
  "descripcion": "USB 3.2",
  "precio": 39900,
  "cantidad": 20,
  "categoria": "Tecnología"
}
```
**Respuesta `201`** (cabecera `Location: /api/productos/13`)
```json
{
  "success": true,
  "message": "Producto creado correctamente",
  "data": { "id": 13, "nombre": "Memoria USB 64 GB", "codigo": "TEC-100", "descripcion": "USB 3.2", "precio": 39900, "cantidad": 20, "categoria": "Tecnología", "creado_en": "...", "actualizado_en": "..." }
}
```
**Respuesta `422`** (validación)
```json
{
  "success": false,
  "message": "Los datos del producto no son válidos",
  "errors": {
    "categoria": "El campo categoría es obligatorio",
    "precio": "El precio debe ser mayor que 0",
    "cantidad": "La cantidad no puede ser negativa"
  }
}
```
**Respuesta `422`** (código duplicado)
```json
{
  "success": false,
  "message": "Los datos del producto no son válidos",
  "errors": { "codigo": "Ya existe un producto con este código" }
}
```

### `PUT /api/productos/{id}` — Actualizar producto
Requiere el objeto completo (mismos campos y reglas que POST).

**Petición**
```json
{
  "nombre": "Mouse inalámbrico Logitech M170",
  "codigo": "TEC-002",
  "descripcion": "Mouse óptico inalámbrico 2.4 GHz",
  "precio": 42900,
  "cantidad": 50,
  "categoria": "Tecnología"
}
```
**Respuesta `200`**
```json
{
  "success": true,
  "message": "Producto actualizado correctamente",
  "data": { "id": 2, "nombre": "Mouse inalámbrico Logitech M170", "codigo": "TEC-002", "precio": 42900, "cantidad": 50, "...": "..." }
}
```
Errores: `400` id inválido · `404` no existe · `422` validación.

### `DELETE /api/productos/{id}` — Eliminar producto
**Respuesta `200`** (devuelve el producto eliminado)
```json
{
  "success": true,
  "message": "Producto eliminado correctamente",
  "data": { "id": 3, "nombre": "Teclado mecánico Redragon Kumara", "codigo": "TEC-003", "...": "..." }
}
```
Errores: `400` id inválido · `404` no existe.

### `GET /api/health` — Estado del servicio
```json
{ "success": true, "message": "API de inventario operativa", "data": { "status": "ok" } }
```

### Ejemplos con `curl`
```bash
curl http://localhost:3000/api/productos
curl http://localhost:3000/api/productos/1
curl -X POST http://localhost:3000/api/productos -H "Content-Type: application/json" \
     -d '{"nombre":"Memoria USB 64 GB","codigo":"TEC-100","precio":39900,"cantidad":20,"categoria":"Tecnología"}'
curl -X PUT http://localhost:3000/api/productos/13 -H "Content-Type: application/json" \
     -d '{"nombre":"Memoria USB 128 GB","codigo":"TEC-100","precio":59900,"cantidad":15,"categoria":"Tecnología"}'
curl -X DELETE http://localhost:3000/api/productos/13
```

---

## Aplicación Flutter

### Pantallas y navegación (`go_router`)

| Ruta | Pantalla | Descripción |
|---|---|---|
| `/` | **Dashboard** | Identidad de la app, 3 métricas y accesos directos |
| `/productos` | **Listado** | Nombre, precio y cantidad de cada producto |
| `/productos/nuevo` | **Registrar** | Formulario con validación (POST) |
| `/productos/:id` | **Detalle** | Todos los campos + acciones Editar / Eliminar |
| `/productos/:id/editar` | **Editar** | Formulario precargado (PUT) |

La barra de navegación inferior alterna entre **Dashboard** y **Productos**.

### Métricas del Dashboard
1. **Productos registrados** — cantidad de productos.
2. **Unidades disponibles** — Σ `cantidad`.
3. **Valor total del inventario** — Σ (`precio` × `cantidad`).

Se recalculan al abrir la app, al deslizar hacia abajo (pull-to-refresh), con el botón de actualizar y **automáticamente después de cada registro, edición o eliminación**.

### Arquitectura y buenas prácticas
- **Separación de responsabilidades**: las vistas nunca usan Dio; todo pasa por `ProductoService`, que recibe la instancia de Dio creada en `api_client.dart`.
- **Manejo de errores**: `ApiException` traduce errores de Dio (sin conexión, timeout, 404, 422, 5xx) a mensajes claros; los errores 422 se muestran en el campo correspondiente del formulario.
- **Estados visuales**: spinner de carga, vista de error con *Reintentar*, vista de lista vacía y `SnackBar` de éxito/fallo.
- **Eliminación segura**: diálogo de confirmación antes de enviar el `DELETE`.
- `Future` + `async/await` en toda la capa de red.

---

## Pruebas

```bash
# Backend: 17 pruebas de integración (BD SQLite en memoria)
cd backend && npm test

# Frontend: análisis estático + pruebas de modelos, servicio y vistas
cd frontend && flutter analyze && flutter test

# Integración Flutter ↔ API real (con el backend en ejecución)
# Bash:        API_BASE_URL=http://localhost:3000/api flutter test test/integration
# PowerShell:  $env:API_BASE_URL="http://localhost:3000/api"; flutter test test/integration
```

---

## Seguridad del repositorio

El archivo [.gitignore](.gitignore) de la raíz (y el de `frontend/`) excluye:

- `.env` y `.env.*` (solo se versionan los `.env.example`, sin secretos)
- `node_modules/`
- `build/`, `.dart_tool/` y demás artefactos de Flutter
- Bases de datos locales (`*.db`, `*.sqlite`), ya que se regeneran con el seeder
- Configuración de IDE y archivos del sistema operativo

Además, la API no expone trazas de error internas en sus respuestas (solo `"Error interno del servidor"`).
