# PLAN — Desarrollo por hitos

Cada hito termina con verificación y un commit descriptivo (Conventional Commits).

## Hito 0 — Especificación y repositorio
- [x] Inicializar Git y enlazar `origin` (GitHub) sobre el `main` existente.
- [x] Redactar `SPECIFICATION.md` y `PLAN.md`.
- [x] `.gitignore` raíz.
- Commit: `docs: especificación SDD y plan de desarrollo`

## Hito 1 — Backend: base de datos
- [x] `backend/package.json` (ESM, scripts `start`, `dev`, `seed`, `test`).
- [x] `src/config/env.js` — lectura de `.env` con valores por defecto.
- [x] `src/db/database.js` — conexión SQLite + creación de esquema con `CHECK`/`UNIQUE`.
- [x] `src/db/seed-data.js` + `src/db/seed.js` — 12 productos de prueba.
- Commit: `feat(db): esquema SQLite de productos y seeder con 12 registros`

## Hito 2 — Backend: API REST
- [x] `src/repositories/producto.repository.js` — consultas preparadas.
- [x] `src/validators/producto.validator.js` — reglas §5.4.
- [x] `src/controllers/producto.controller.js` — lógica HTTP y códigos.
- [x] `src/routes/producto.routes.js` — 5 endpoints.
- [x] `src/middlewares/` — 404, JSON mal formado, errores 500.
- [x] `src/utils/response.js` — formato estándar de respuesta.
- [x] `src/app.js` (fábrica de app inyectable) + `src/server.js`.
- [x] `test/productos.test.js` — pruebas de integración con BD en memoria.
- [x] Prueba de integración Flutter ↔ API real (`frontend/test/integration`).
- Verificación: `npm test` en verde + prueba manual con `curl`.
- Commit: `feat(api): CRUD REST de productos con validaciones y pruebas`

## Hito 3 — Frontend: proyecto y capa de datos
- [x] `flutter create` (android, ios, web, windows).
- [x] Dependencias `dio`, `go_router`, `flutter_dotenv`.
- [x] `.env` / `.env.example` registrados como asset.
- [x] `config/`, `models/`, `services/` (Dio + manejo de errores).
- Commit: `feat(frontend): proyecto Flutter, configuración y capa de servicios`

## Hito 4 — Frontend: UI
- [x] `themes/app_theme.dart`.
- [x] `widgets/` reutilizables (métricas, estados, diálogo, snackbar, tile).
- [x] `routes/app_router.dart` con `StatefulShellRoute`.
- [x] Vistas: Dashboard, Listado, Detalle, Formulario.
- Verificación: `flutter analyze` + `flutter test`.
- Commit: `feat(frontend): dashboard, CRUD de productos y navegación`

## Hito 5 — Integración y documentación
- [x] README completo (instalación, BD, endpoints, ejemplos JSON).
- [x] Revisión de `.gitignore` (sin `.env`, `node_modules`, `build`, `*.db`).
- [x] Push a `origin/main`.
- Commit: `docs: README con guía de instalación, BD y catálogo de endpoints`

## Riesgos y decisiones
| Decisión | Motivo |
|----------|--------|
| `node:sqlite` en lugar de `better-sqlite3` | Evita compilación nativa en Windows; requiere Node ≥ 22.13. |
| `codigo` duplicado → 422 | La spec agrupa validaciones en 422; se devuelve `errors.codigo`. |
| Métricas calculadas en cliente | Se derivan del listado de la API; `InventarioResumen` las encapsula fuera de los widgets. |
| `ProductoService.cambios` (`ValueNotifier`) | Dashboard y listado se refrescan tras cualquier mutación sin gestor de estado externo. |
| URL de la API en `.env` | Android emulador usa `10.0.2.2`; dispositivo físico usa la IP LAN del PC. |
