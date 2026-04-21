---
name: shared-supabase
description: >
  Conocimiento compartido del esquema de base de datos Supabase y patrones
  comunes usados en ambos proyectos (fitness-app y fitness-web). Debe leerse
  antes de hacer cualquier cambio que afecte la base de datos o la autenticación.
---

# Supabase — Esquema y Patrones Compartidos

## Proyecto Supabase

Ambas apps (`fitness-app` y `fitness-web`) se conectan al **mismo proyecto Supabase**.

- Variables de entorno:
  - `VITE_SUPABASE_URL` / `EXPO_PUBLIC_SUPABASE_URL`
  - `VITE_SUPABASE_ANON_KEY` / `EXPO_PUBLIC_SUPABASE_ANON_KEY`
- La `service_role` key **NUNCA se usa desde el cliente**; para operaciones admin se usan funciones RPC con `SECURITY DEFINER`.

---

## Esquema de Base de Datos

### `public.exercises`
| Columna | Tipo | Notas |
|---|---|---|
| `id` | UUID PK | `uuid_generate_v4()` |
| `name` | VARCHAR(255) | NOT NULL |
| `muscle` | VARCHAR(100) | NOT NULL |
| `equipment` | VARCHAR(100) | NOT NULL |
| `description` | TEXT | |
| `secondary_muscles` | TEXT[] | |
| `benefits` | TEXT[] | |
| `level` | TEXT | |
| `video_id` | TEXT | ID de YouTube |
| `measure_type` | VARCHAR | `'Reps'` \| `'Mts'` \| `'Cal'` (default `'Reps'`) |
| `createdAt` | TIMESTAMPTZ | DEFAULT NOW() |

### `public.train` (Rutinas)
| Columna | Tipo | Notas |
|---|---|---|
| `id` | UUID PK | |
| `userId` | UUID | NULL permitido, FK a auth.users |
| `name` | VARCHAR | Nombre de la rutina |
| `date` | TIMESTAMPTZ | DEFAULT NOW() |
| `status` | VARCHAR(50) | `'active'` \| `'Inactive'` |
| `days` | INTEGER | Número de días de la rutina |
| `createdAt` | TIMESTAMPTZ | DEFAULT NOW() |

### `public.train_exercises`
| Columna | Tipo | Notas |
|---|---|---|
| `id` | UUID PK | |
| `trainId` | UUID | FK → train(id) ON DELETE CASCADE |
| `exerciseId` | UUID | FK → exercises(id) ON DELETE CASCADE |
| `sets` | INTEGER | |
| `reps` | INTEGER | |
| `weight` | VARCHAR(50) | |
| `superset_group` | INTEGER | Agrupa supersets |
| `position` | INTEGER | Orden dentro del día |
| `day` | VARCHAR | `"Día 1"`, `"Día 2"`, etc. |
| `indication` | TEXT | Indicación del trainer |
| `observation` | TEXT | |

### `public.train_exercise_detail` (Progreso semanal del alumno)
| Columna | Tipo | Notas |
|---|---|---|
| `id` | UUID PK | |
| `trainId` | UUID | FK → train(id) ON DELETE CASCADE |
| `trainExerciseId` | UUID | FK → train_exercises(id) ON DELETE CASCADE |
| `week` | VARCHAR(20) | `"Semana 1"`, `"Semana 2"`, etc. |
| `setNumber` | INTEGER | NOT NULL DEFAULT 1 |
| `kg` | NUMERIC(6,2) | |
| `reps` | INTEGER | |
| `indication` | TEXT | Indicación del trainer para esa semana |
| `observation` | TEXT | Nota del alumno para ese ejercicio+semana |
| `status` | VARCHAR | `'TO_DO'` \| `'DONE'` |
| `created_at` | TIMESTAMPTZ | |

> **UNIQUE CONSTRAINT:** `(trainExerciseId, week, setNumber)`

### `public.custom_users` (Perfil extendido de usuario)
| Columna | Tipo | Notas |
|---|---|---|
| `id` | UUID PK | = auth.users.id |
| `displayName` | TEXT | |
| `email` | TEXT | |
| `phone` | TEXT | |
| `instagram` | TEXT | |
| `isTrainer` | BOOLEAN | |
| `isEnabled` | BOOLEAN | |
| `role` | TEXT | `'admin'` \| `'trainer'` \| `'client'` |

### `public.trainer_clients` (Relación trainer → cliente)
| Columna | Tipo | Notas |
|---|---|---|
| `id` | UUID PK | |
| `trainerId` | UUID | FK → custom_users(id) |
| `clientId` | UUID | FK → custom_users(id) |
| `createdAt` | TIMESTAMPTZ | |

---

## RLS (Row Level Security)

- **Regla de oro:** NUNCA usar `service_role` en el cliente browser o en la app mobile.
- Las operaciones admin se exponen vía funciones RPC con `SECURITY DEFINER`: `admin_get_clients_by_trainer`, `admin_add_client`, `admin_remove_client`, `admin_list_trainers`, `admin_set_trainer_status`.
- La tabla `trainer_clients` usa RLS que filtra por `auth.uid() = trainerId` automáticamente — nunca pasar `trainerId` como query param.

---

## Roles del sistema

| Rol | Acceso |
|---|---|
| `admin` | Todo: usuarios, trainers, rutinas de todos |
| `trainer` | Sus propios clientes y las rutinas de esos clientes |
| `client` | Solo sus propias rutinas |

El rol se almacena en `custom_users.role` y se carga en el `AuthContext` de cada app como `profile.role`.

---

## Patrones Clave

### Upsert de detalle semanal
Siempre hacer `maybeSingle()` + update si existe o insert si no. Ver `routinesService.js → upsertExerciseIndication()`.

### Naming conventions
- Tablas: `snake_case` para nuevos nombres de tablas (`train_exercises`, `train_exercise_detail`, `trainer_clients`, `custom_users`, `history_exercises`)
- Columnas FK: `camelCase` por retrocompatibilidad (`userId`, `trainId`, `exerciseId`)
- El campo `status` de `train_exercise_detail` SIEMPRE debe ser `'TO_DO'` al crear desde el panel web.

### Supabase client singleton
Ambos proyectos crean un único cliente con `createClient(url, anonKey)`. No crear múltiples instancias.
