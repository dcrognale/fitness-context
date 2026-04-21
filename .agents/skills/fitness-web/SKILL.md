---
name: fitness-web
description: >
  Contexto completo del proyecto fitness-web: panel de administración web
  construido con React + Vite + MUI + Supabase. Leer antes de cualquier
  tarea relacionada con el panel web de administración.
---

# fitness-web — Panel Web de Administración (GymAdmin)

## Ubicación
```
/Users/diego.crognale/Documents/IA-Projects/fitness-web/
```

## Stack Técnico

| Tecnología | Versión | Uso |
|---|---|---|
| React | ^18.2.0 | UI library |
| Vite | ^5.0.0 | Bundler y dev server |
| Material UI (MUI) | ^5.14.20 | Componentes visuales |
| @emotion/react + styled | ^11.11 | CSS-in-JS para MUI |
| React Router DOM | ^6.20.1 | Enrutamiento |
| @supabase/supabase-js | ^2.100.0 | Backend / Auth |
| @hello-pangea/dnd | ^16.3.0 | Drag & drop en editor de rutinas |
| @mui/x-date-pickers | ^6.20.2 | Date picker |
| date-fns | ^2.30.0 | Formateo de fechas |
| dayjs | ^1.11.20 | Manejo de fechas (x-date-pickers) |

## Comandos

```bash
cd /Users/diego.crognale/Documents/IA-Projects/fitness-web

npm run dev      # Dev server → http://localhost:5173
npm run build    # Build producción → dist/
npm run preview  # Preview del build
npm run lint     # Lint
```

## Estructura de Carpetas

```
fitness-web/
├── index.html
├── vite.config.js
├── src/
│   ├── main.jsx                # Entry point
│   ├── App.jsx                 # Router + providers raíz
│   ├── context/
│   │   ├── AuthContext.jsx     # Auth Supabase + perfil (custom_users)
│   │   └── ThemeContext.jsx    # Tema oscuro MUI (Bebas Neue + Barlow)
│   ├── pages/
│   │   ├── LoginPage.jsx
│   │   ├── DashboardPage.jsx
│   │   ├── ExercisesPage.jsx
│   │   ├── UsersPage.jsx
│   │   ├── RoutinesPage.jsx
│   │   ├── RoutinePlannerPage.jsx
│   │   ├── TrainersPage.jsx
│   │   ├── TrainerClientsPage.jsx
│   │   └── ClientRoutinesPage.jsx
│   ├── components/
│   │   ├── layout/
│   │   │   ├── MainLayout.jsx      # Layout con sidebar
│   │   │   ├── Header.jsx          # Barra superior (email + logout)
│   │   │   ├── Sidebar.jsx         # Menú lateral con items por rol
│   │   │   ├── PrivateRoute.jsx    # Redirige a /login si no autenticado
│   │   │   └── RoleGuard.jsx       # Bloquea rutas por rol
│   │   ├── exercises/
│   │   │   └── ExerciseFormModal.jsx
│   │   └── routines/
│   │       └── RoutineEditor.jsx   # Drawer con DnD para editar rutinas
│   ├── services/
│   │   ├── supabaseClient.js       # Cliente Supabase singleton (anon key)
│   │   ├── exercisesService.js     # CRUD exercises
│   │   ├── routinesService.js      # CRUD train + train_exercises + planner
│   │   ├── trainersService.js      # Trainers + trainer_clients (RPCs admin)
│   │   └── usersService.js         # Gestión de usuarios (custom_users)
│   ├── hooks/
│   │   ├── useAuth.js              # Re-export de useAuth desde AuthContext
│   │   └── useRole.js              # Expone role, isAdmin, isTrainer, isClient, can(roles[])
│   └── theme/                      # Tokens de tema MUI
└── supabase/
    ├── functions/                  # Edge Functions (si aplica)
    └── migrations/
        ├── 001_trainer_system.sql
        ├── 002_admin_rpc_functions.sql
        ├── 003_roles_system.sql
        ├── 004_fix_admin_rpcs_types.sql
        ├── 005_exercise_measure_type.sql
        ├── 006_trainer_edit_exercises.sql
        ├── 007_update_rpcs_for_renamed_tables.sql
        └── 008_client_update_train_rls.sql
```

## Autenticación y Perfil

- **Archivo:** `src/context/AuthContext.jsx`
- Expone: `{ user, session, profile, loading, login, logout, refreshProfile }`
- `profile` = fila de `custom_users` (`id, displayName, isTrainer, role, phone, instagram, isEnabled`)
- Usar `profile.role` para determinar permisos (`'admin'` | `'trainer'` | `'client'`)

## Hook useRole

- **Archivo:** `src/hooks/useRole.js`
- Hook de conveniencia que consume `AuthContext` internamente y expone helpers de rol.
- **Siempre usar `useRole` en lugar de leer `profile.role` directamente en los componentes.**

```js
const { role, loading, isAdmin, isTrainer, isClient, can } = useRole()

// Ejemplos
if (isAdmin) { ... }
if (can(['admin', 'trainer'])) { ... }
```

| Propiedad | Tipo | Descripción |
|---|---|---|
| `role` | `string \| null` | Rol actual (`'admin'`, `'trainer'`, `'client'`) o `null` si carga |
| `loading` | `boolean` | `true` mientras el perfil carga |
| `isAdmin` | `boolean` | `role === 'admin'` |
| `isTrainer` | `boolean` | `role === 'trainer'` |
| `isClient` | `boolean` | `role === 'client'` |
| `can(roles[])` | `boolean` | `true` si el rol actual está en el array |

## Rutas y Control de Acceso

| Ruta | Protección | Descripción |
|---|---|---|
| `/login` | Pública | Login con email + password |
| `/dashboard` | Todos los roles | Estadísticas generales |
| `/exercises` | Todos los roles | Catálogo de ejercicios (CRUD) |
| `/routines` | Todos los roles | Rutinas (vista filtrada por rol) |
| `/routines/plan/:id` | Todos los roles | Editor de planificación semanal |
| `/users` | `admin` | CRUD de usuarios |
| `/trainers` | `admin` | Gestión de trainers y asignación de clientes |
| `/trainer/clients` | `trainer` | Lista de clientes del trainer |
| `/trainer/clients/:clientId/routines` | `trainer` | Rutinas de un cliente específico |

### RoleGuard

- **Archivo:** `src/components/layout/RoleGuard.jsx`
- Usa `useRole()` internamente (no recibe `profile` como prop).
- Muestra `CircularProgress` mientras `loading === true` para evitar flashes de redirección.
- Prop `redirectTo` (default: `'/dashboard'`) para controlar el destino si el rol no es permitido.

```jsx
<RoleGuard roles={['admin']}>
  <AdminOnlyPage />
</RoleGuard>

<RoleGuard roles={['admin', 'trainer']} redirectTo="/dashboard">
  <SharedPage />
</RoleGuard>
```

### Sidebar — Navegación por rol

El `Sidebar` usa `useRole()` para mostrar ítems diferenciados:

| Rol | Ítems del menú |
|---|---|
| `admin` | Dashboard, Ejercicios, Usuarios, Trainers, Rutinas |
| `trainer` | Dashboard, Mis Clientes, Ejercicios, Rutinas |
| `client` | Dashboard, Ejercicios, Mis Rutinas |

El footer del sidebar muestra un `Chip` con el rol del usuario (color: `error`=admin, `primary`=trainer, `success`=cliente).

## Tema Visual

- **Modo:** Oscuro (dark theme MUI)
- **Paleta:** Negro, gris oscuro, naranja (estilo gym)
- **Tipografía:** `Bebas Neue` (títulos) + `Barlow` (cuerpo) de Google Fonts
- El tema está en `ThemeContext.jsx` — siempre usar el theme MUI, no hardcodear colores

## Servicios — Patrones de Uso

### routinesService.js
```js
// Listar rutinas paginadas (filtrar por userId, userIds, status)
getRoutines({ search, userId, userIds, status, page, pageSize })

// Obtener rutina con ejercicios
getRoutineById(id)

// CRUD
createRoutine({ userId, name, status, days })
updateRoutine(id, { userId, name, status, days })
deleteRoutine(id)  // elimina train_exercises en cascada primero

// Planner semanal
getRoutinePlannerData(id)  // join con train_exercise_detail
upsertExerciseIndication({ trainId, trainExerciseId, week, indication, status })
```

### trainersService.js — Reglas de seguridad
```js
// Trainer: sus propios clientes (RLS automática, sin pasar trainerId)
getMyClients()

// Admin: operaciones solo vía RPC (SECURITY DEFINER)
getClientsByTrainer(trainerId)   // rpc: admin_get_clients_by_trainer
addClient(trainerId, clientId)   // rpc: admin_add_client
removeClient(trainerId, clientId) // rpc: admin_remove_client
getAllTrainers()                  // rpc: admin_list_trainers
setTrainerStatus(userId, isTrainer) // rpc: admin_set_trainer_status
```

## Variables de Entorno

```env
# .env en la raíz de fitness-web
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
# VITE_SUPABASE_SERVICE_KEY → DEPRECADA, usar RPCs SECURITY DEFINER en su lugar
```

## Funcionalidades Detalladas

### ExercisesPage
- CRUD completo con filtros por nombre/músculo
- Paginación server-side
- Chips para músculo, equipment, level, beneficios
- Tipo de medición (measure_type: Mts, Cal, Reps)
- Preview video YouTube inline

### RoutinesPage
- Vista diferenciada por rol:
  - `admin`: ve todas las rutinas de todos los usuarios
  - `trainer`: ve solo rutinas de sus clientes asignados
  - `client`: ve solo sus propias rutinas
- Filtros por estado, búsqueda por nombre
- Editor de rutinas (`RoutineEditor.jsx`) con drag & drop para reordenar ejercicios
- Soporte multi-día (`day: "Día 1"`, `"Día 2"`, etc.)
- Supersets (`superset_group` integer)

### RoutinePlannerPage
- Vista semanal de una rutina
- Permite al trainer ingresar `indication` por semana/ejercicio
- `status` se fuerza a `'TO_DO'` al crear/actualizar indicaciones
- Lee datos de `train_exercise_detail` (progreso real del alumno)

### UsersPage
- CRUD de usuarios usando tabla `custom_users`
- Edición inline de `displayName` e `isEnabled`
- Filtros y búsqueda

### TrainersPage (Admin)
- Lista todos los usuarios con `isTrainer = true`
- Permite asignar/desasignar clientes a trainers
- Usa RPCs admin para todas las operaciones

## Convenciones de Código

- **JSX** (no TypeScript) en toda la web app
- Componentes funcionales con hooks
- Manejo de estado local con `useState`, datos remotos con `useEffect` + service
- Siempre mostrar feedback visual al usuario (snackbar/alert de MUI) al guardar/eliminar
- Usar `CircularProgress` de MUI mientras se cargan datos
- Los servicios lanzan `throw error` — manejar con `try/catch` en los componentes

## Advertencias Importantes

> ⚠️ **No usar** `VITE_SUPABASE_SERVICE_KEY` en el cliente. Está deprecada. Usar RPCs con `SECURITY DEFINER`.
>
> ⚠️ **RoutinesPage:** Puede haber race conditions si se refresca después de crear/editar. Asegurarse de await completo antes de refetch.
>
> ⚠️ **RoleGuard** usa `profile.role` del AuthContext. Si el perfil aún está cargando, no bloquear la navegación prematuramente.
>
> ⚠️ La tabla `trainer_clients` tiene RLS: `trainerId = auth.uid()`. Si la query la hace un admin, debe ir por RPC.
