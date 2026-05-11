# Load Readiness Review — fitness-app

> **Fecha de análisis:** 2026-05-08  
> **Arquitecto revisor:** Antigravity  
> **Stack:** React Native (Expo 54) + Supabase (PostgreSQL) + supabase-js v2.97  
> **Tipo de app:** Cliente móvil → BaaS (Supabase) sin backend intermedio propio

---

## Resumen ejecutivo

La aplicación se encuentra en un estado de **preparación baja-media para escenarios de alta carga**. Al ser una app móvil de fitness personal que delega toda la lógica de datos a Supabase BaaS, muchos problemas tradicionales de concurrencia de servidor no aplican directamente; sin embargo, el cliente presenta carencias críticas en caché, estrategias de recuperación ante fallos y diseño de queries que se vuelven costosas bajo un volumen creciente de usuarios. La capa de base de datos, observable a través del schema y de las queries generadas por el service layer, muestra ausencia casi total de índices explícitos, queries sin paginación y un patrón de guardado destructivo que genera operaciones innecesarias. El proyecto requiere intervención antes de escalar a más de unos pocos cientos de usuarios concurrentes.

---

## Análisis — Capa de Aplicación

### 1. Manejo de concurrencia y thread pools

**Contexto:** App React Native. No existe backend propio; el "thread pool" relevante es el del cliente HTTP de supabase-js y el event loop de JavaScript.

| Hallazgo | Detalle |
|---|---|
| ✅ `Promise.all` en carga paralela | `routine/[id].tsx` línea 436 y `exercises.tsx` línea 38 usan `Promise.all` para cargas paralelas. Correcto. |
| ⚠️ Sin control de concurrencia en saves | `handleSave` en `train.tsx` no tiene debounce ni guard contra doble submit. Si el usuario presiona "Guardar" rápido dos veces, se disparan dos operaciones `delete + insert`. |
| ⚠️ Re-fetch completo por cambio de semana/día | En `train.tsx` línea 337: `useEffect(() => { loadRoutine(true); }, [loadRoutine, activeWeek, activeDay])`. Cada cambio de pestaña dispara un fetch completo de la rutina activa + todos sus detalles. No hay diferenciación entre "recarga requerida" vs "filtro local". |

---

### 2. Estrategias de caché (local, distribuido)

| Hallazgo | Detalle |
|---|---|
| ❌ Sin caché local de ningún tipo | No hay uso de `AsyncStorage`, React Query, SWR, Zustand, ni ningún mecanismo de caché. Cada mount/focus de pantalla hace un round-trip a Supabase. |
| ❌ `getExercises()` sin caché | El catálogo de ejercicios (tabla estática/semi-estática) se refetch completo en cada apertura de `ExercisesScreen` y en cada apertura del Routine Editor. Con 50+ ejercicios y N usuarios, esto genera carga innecesaria. |
| ❌ `getMuscles()` sin caché | Mismo problema; la tabla `muscles` es prácticamente inmutable pero se consulta en cada render de `ExercisesScreen`. |
| ❌ `getActiveRoutine()` llamado en dos pantallas distintas | `index.tsx` (Home) y `train.tsx` llaman independientemente a `getActiveRoutine()` sin compartir el resultado, duplicando requests. |

---

### 3. Circuit breakers y retry logic

| Hallazgo | Detalle |
|---|---|
| ❌ Sin retry logic | Ninguna función en `databaseService.ts` implementa reintentos. Un error transitorio de red o de Supabase resulta inmediatamente en un error mostrado al usuario. |
| ❌ Sin circuit breaker | No existe ningún mecanismo para cortar llamadas cuando Supabase está degradado. |
| ⚠️ Error handling inconsistente | `train.tsx` hace `console.warn` en el catch del save (línea 101), no propagando el error al usuario. `history.tsx` también suprime errores con `console.warn`. |

---

### 4. Rate limiting y throttling

| Hallazgo | Detalle |
|---|---|
| ❌ Sin debounce en búsqueda/filtros | `ExercisesScreen` filtra en memoria (correcto), pero si el filtrado fuera server-side, el `onChangeText` sin debounce dispararía un request por keystroke. |
| ❌ Sin debounce en "Guardar" | El botón "Guardar" en el Routine Editor y el botón "Guardar" por ejercicio en `train.tsx` no tienen protección contra doble-tap. |
| ✅ Rate limiting delegado a Supabase | El rate limiting de la API REST de Supabase está activo por defecto (configurable por plan). No hay nada a nivel cliente que lo complemente. |

---

### 5. Gestión de conexiones (connection pooling)

| Hallazgo | Detalle |
|---|---|
| ✅ Singleton de supabase client | `utils/supabase.ts` crea una única instancia compartida en toda la app. Correcto para evitar múltiples conexiones WebSocket/auth. |
| ✅ Auto-refresh de token | `autoRefreshToken: true` y el listener de `AppState` gestionan correctamente el ciclo de vida del token. |
| ⚠️ Sin pool propio (inherente al BaaS) | supabase-js usa un pool HTTP interno no configurable por el cliente. En escenarios de alta concurrencia, el límite viene del plan de Supabase (Supavisor connection pooling del lado servidor). No hay evidencia de que esté configurado. |

---

### 6. Timeouts configurados correctamente

| Hallazgo | Detalle |
|---|---|
| ❌ Sin timeouts explícitos | Ninguna llamada a Supabase tiene un `AbortController` ni timeout configurado. Si Supabase demora, el usuario ve spinner indefinido. |
| ❌ Sin timeout en `saveTrainExerciseDetails` | Esta función hace `delete` + `insert` secuencialmente. Si el `insert` cuelga, no hay timeout de rescate. |

---

### 7. Comportamiento bajo backpressure

| Hallazgo | Detalle |
|---|---|
| ❌ Sin cancelación de requests en-flight | Al cambiar de semana (`setActiveWeek`) o de día (`setActiveDay`), el `useEffect` en `train.tsx` dispara un nuevo `loadRoutine` sin cancelar el anterior. Pueden llegar respuestas out-of-order y sobrescribir estado correcto. |
| ❌ Sin `AbortController` | Ningún fetch usa `AbortController`. Al desmontar el componente, operaciones en-flight siguen ejecutándose y pueden intentar actualizar estado desmontado (warning de React). `AuthContext` sí usa la bandera `mounted` como mitigación parcial, pero los DB calls no. |
| ⚠️ `deleteRoutine` con doble round-trip | `deleteRoutine` primero hace un SELECT para validar ownership y luego un DELETE. En alta carga, esto es una TOCTOU (time-of-check-time-of-use) potencial, y duplica el trabajo que RLS debería hacer. |

---

### 8. Stateless vs stateful — cuellos de botella de estado

| Hallazgo | Detalle |
|---|---|
| ✅ App mayormente stateless hacia el backend | No hay sesiones de servidor ni estado compartido entre usuarios en el cliente. |
| ⚠️ Estado de workout en memoria (WorkoutContext) | `WorkoutContext` guarda el workout activo en memoria. Si la app se cierra/crashea durante un entrenamiento, el progreso se pierde. No hay persistencia local. |
| ⚠️ `weekLogs` en estado local de `train.tsx` | El objeto `weekLogs` crece con O(ejercicios × semanas × sets). Con rutinas grandes, este objeto puede volverse pesado para el reconciliador de React. |
| ❌ IDs generados con `Math.random()` | `WorkoutContext` y `routine/[id].tsx` usan `Math.random().toString(36)` para generar IDs locales. No es criptográficamente seguro ni garantiza unicidad real bajo colisión de timestamp. |

---

## Análisis — Capa de Base de Datos

> **Nota:** El schema analizado corresponde a `database/schema.sql` (schema inicial) + migraciones parciales en `trainExerciseDetail.sql` y `train_active_unique.sql`. El schema real en producción incluye columnas adicionales (muscles, muscle_id, trainer_id, etc.) que se infieren de las queries del service layer. Los índices y RLS policies en producción **no son visibles** en los archivos locales; este análisis se basa exclusivamente en lo verificable.

---

### 1. Uso y cobertura de índices

| Hallazgo | Detalle |
|---|---|
| ❌ Sin índices explícitos en `train` | Las queries `WHERE userId = ? AND status = ?` en `getActiveRoutine`, `getRoutines`, `getFinishedRoutines` no tienen índice visible. Con N usuarios, la tabla `train` crece linealmente y cada query hace un seq scan filtrado por `userId`. |
| ❌ Sin índice en `train_exercises.trainId` | `getRoutineExercises` y `getActiveRoutine` hacen `WHERE trainId = ?` en esta tabla. La FK existe en el schema, pero PostgreSQL no crea índices automáticamente en FKs (a diferencia de MySQL). Sin índice, es seq scan. |
| ❌ Sin índice en `train_exercise_detail.trainExerciseId` | `getTrainExerciseDetails` usa `IN (trainExerciseId[])`. Sin índice, cada elemento del IN hace un seq scan o bitmap heap scan ineficiente. |
| ❌ Sin índice en `history.userId` | `getHistory` filtra `WHERE userId = ?`. Mismo problema que `train`. |
| ✅ Unique index parcial en `train.status` | `train_active_unique.sql` crea `uq_one_active_routine` — pero solo aplica para `status = 'active'` (minúscula). La app usa `'Activa'` (con mayúscula y acento). El índice parcial **probablemente no aplica** a los valores reales. |

---

### 2. Queries N+1 o sin límite de resultados

| Hallazgo | Detalle |
|---|---|
| ❌ `getExercises()` sin límite | `SELECT *, muscles(id, name) FROM exercises ORDER BY name` — sin `.limit()`. Con 1000+ ejercicios, esto retorna todo el catálogo. |
| ❌ `getFinishedRoutines()` sin límite | `SELECT * FROM train WHERE status='Inactiva' AND userId=?` — sin `.limit()`. Un usuario activo con años de uso puede tener cientos de rutinas finalizadas. |
| ❌ `getHistory()` sin límite | `SELECT *, history_exercises(sets, reps, weight, exercises(name)) FROM history WHERE userId=?` — sin `.limit()`. Con historial largo, este payload crece indefinidamente. |
| ⚠️ `getRoutineProgress()` hace dos queries separadas | Primero carga todos los `train_exercises` (N filas), luego todos los `train_exercise_detail` para esos IDs (M filas). Correcto en términos de N+1 (usa `IN`), pero sin límite en el segundo query. |
| ⚠️ `saveRoutineExercises` es "full replace" | Hace un `DELETE WHERE trainId = ?` y luego re-inserta todos los ejercicios. Para rutinas grandes (50+ ejercicios), esto genera una transacción con N deletes + N inserts en cada guardado, aunque solo cambió 1 ejercicio. |

---

### 3. Gestión del connection pool

| Hallazgo | Detalle |
|---|---|
| ⚠️ No configurable desde el cliente | supabase-js usa PostgREST (HTTP/REST), no conexiones directas a PostgreSQL. El pooling real está en Supavisor (Supabase). No hay evidencia de configuración de pool size en el proyecto. |
| ❌ Sin pgBouncer/Supavisor confirmado | No hay configuración visible de `?pgbouncer=true` en la URL de Supabase ni en el `.env`. En plans gratuitos, el pool es limitado (aprox. 60 conexiones directas). |

---

### 4. Transacciones largas o locks problemáticos

| Hallazgo | Detalle |
|---|---|
| ❌ `saveRoutineExercises` no es transaccional | El `DELETE` y el `INSERT` posterior son dos operaciones separadas sin transacción explícita. Si el `INSERT` falla, la rutina queda sin ejercicios (estado inválido). No hay rollback posible desde el cliente con supabase-js REST. |
| ❌ `saveWorkout` igual problema | `INSERT into history` + `INSERT into history_exercises` son dos llamadas separadas. Fallo en la segunda deja un registro de historial huérfano. |
| ⚠️ `deleteRoutine` con doble round-trip sin transacción | `SELECT (check ownership)` → `DELETE train_exercises` → `DELETE train`. Tres operaciones separadas. Una falla intermedia deja datos inconsistentes. |

---

### 5. Estrategia de paginación

| Hallazgo | Detalle |
|---|---|
| ❌ Sin paginación en ningún listado | Ninguna query usa `.range()` o `.limit()`. `getExercises`, `getFinishedRoutines`, `getHistory` retornan todos los registros. |
| ❌ Sin cursor-based pagination | No hay implementación de infinite scroll ni paginación por cursor. |

---

### 6. Read replicas o separación de cargas

| Hallazgo | Detalle |
|---|---|
| ❌ Sin configuración de read replicas | No hay evidencia de uso de read replicas en supabase-js (requeriría configurar un segundo cliente con la URL de la réplica). |
| ℹ️ No aplica aún | Para el estadio actual de la app, read replicas son prematuras pero deben tenerse en cuenta al escalar. |

---

### 7. Vacuuming / mantenimiento automático

| Hallazgo | Detalle |
|---|---|
| ✅ Gestionado por Supabase | Al usar Supabase como BaaS, autovacuum y mantenimiento de PostgreSQL son responsabilidad de Supabase. No hay configuración visible a nivel proyecto. |
| ⚠️ `saveRoutineExercises` genera bloat | El patrón DELETE+INSERT en cada guardado genera mucho dead tuple turnover en `train_exercises`, lo que puede requerir autovacuum más agresivo en tablas con alta frecuencia de actualización. |

---

### 8. Capacidad de escalar horizontalmente vs verticalmente

| Hallazgo | Detalle |
|---|---|
| ℹ️ Escalabilidad vertical vía Supabase plan upgrade | El camino inmediato de escala es upgradear el plan de Supabase (más conexiones, más compute). No hay nada en el código que lo bloquee. |
| ❌ No hay separación CQRS ni read/write paths | Todas las operaciones van por el mismo cliente. Una query analítica pesada (`getRoutineProgress`) compite con writes de usuarios. |
| ✅ Arquitectura stateless en el cliente | Al ser una app móvil sin backend propio, escala horizontalmente de forma natural (cada instancia es independiente). |

---

## Mejoras identificadas

| # | Área | Problema | Impacto bajo alta carga | Solución propuesta | Prioridad |
|---|---|---|---|---|---|
| 1 | DB — Índices | Ausencia de índice en `train.userId`, `train.status` | Seq scans en la tabla principal con cada usuario que abre la app. Con 10k rows y 100 usuarios concurrentes, tiempo de query se dispara a O(N). | `CREATE INDEX idx_train_user_status ON train ("userId", status);` | **CRÍTICA** |
| 2 | DB — Índices | Ausencia de índice en `train_exercises.trainId` | Cada carga de rutina hace seq scan de toda la tabla `train_exercises`. | `CREATE INDEX idx_train_exercises_train_id ON train_exercises ("trainId");` | **CRÍTICA** |
| 3 | DB — Índices | Ausencia de índice en `train_exercise_detail.trainExerciseId` | El `IN (ids[])` sin índice escala mal. Con 20+ ejercicios por rutina y 100 usuarios, genera bitmap scans costosos. | `CREATE INDEX idx_ted_exercise_id ON train_exercise_detail ("trainExerciseId");` | **CRÍTICA** |
| 4 | DB — Transacciones | `saveRoutineExercises` y `saveWorkout` no son atómicos | Corrupción de datos en fallos parciales de red. Invisible para el usuario hasta que note datos faltantes. | Mover la lógica a una Supabase Edge Function o RPC que ejecute todo en una transacción PostgreSQL. | **CRÍTICA** |
| 5 | App — Caché | Sin caché del catálogo de ejercicios y músculos | Cada apertura de ExerciseScreen o RoutineEditor descarga el catálogo completo. Con 200 usuarios activos simultáneos = 200 queries idénticas por minuto. | Implementar caché en memoria con TTL (ej: `useState` + timestamp, o React Query `staleTime: 5 * 60 * 1000`). | **ALTA** |
| 6 | DB — Paginación | `getHistory` y `getFinishedRoutines` sin límite | Un usuario con 2 años de uso puede tener 100+ rutinas. El payload crece indefinidamente, degradando UI y cargando la red. | Agregar `.limit(20).range()` e implementar infinite scroll con `FlatList onEndReached`. | **ALTA** |
| 7 | App — Backpressure | `useEffect` en `train.tsx` re-fetcha en cada cambio de semana/día | Cambiar rapidamente entre días/semanas dispara múltiples fetches concurrentes. Las respuestas out-of-order pueden corromper el estado visible. | Separar la carga inicial de la rutina (solo al mount) del filtrado local por día/semana. Los datos de todas las semanas se cargan una vez y se filtran en memoria. | **ALTA** |
| 8 | App — Timeouts | Sin timeout en ninguna operación de DB | Una red lenta deja al usuario en spinner indefinido sin posibilidad de recuperación. | Envolver llamadas críticas con `Promise.race([fetch, timeout(8000)])` o usar `AbortController` + `signal` option en el cliente. | **ALTA** |
| 9 | DB — Unique Index | `uq_one_active_routine` usa `status = 'active'` pero la app usa `'Activa'` | El índice parcial no protege contra múltiples rutinas activas porque los valores no coinciden. Un bug en el cliente puede crear estado inválido silenciosamente. | Corregir el índice a `WHERE status = 'Activa'` y agregar índice `userId` para aplicar la constraint por usuario: `UNIQUE ("userId", status) WHERE status = 'Activa'`. | **ALTA** |
| 10 | DB — Query design | `getExercises()` sin límite retorna catálogo completo | Con 500+ ejercicios (escalando el negocio), el payload serializado puede superar 100KB. Impacta latencia percibida y uso de datos móviles. | Implementar búsqueda server-side con `.ilike('name', '%query%')` para el caso de filtrado, y paginación para el listado base. | **MEDIA** |
| 11 | App — Saves | Sin debounce/guard en botones de guardado | Doble-tap en "Guardar" genera dos DELETE+INSERT paralelos. El segundo puede ganar la carrera y dejar los ejercicios duplicados. | Deshabilitar el botón durante `saving === true` (ya parcialmente implementado en Routine Editor) y agregar guard en `saveTrainExerciseDetails`. | **MEDIA** |
| 12 | DB — Write amplification | `saveRoutineExercises` hace full-replace (DELETE+INSERT) en cada save | Con rutinas de 30+ ejercicios, cada guardado genera 60+ operaciones DB. En sesiones de edición activas, esto multiplica el load de writes. | Implementar diff: comparar items actuales vs guardados y hacer solo UPSERTs/DELETEs de lo que cambió. O usar una RPC con `ON CONFLICT DO UPDATE`. | **MEDIA** |
| 13 | App — Estado | `WorkoutContext` sin persistencia local | Si el usuario pierde conexión o la app crashea durante un entrenamiento, todo el progreso se pierde. | Serializar `activeWorkout` a `AsyncStorage` en cada cambio con `useEffect`. Recuperar al inicializar el contexto. | **MEDIA** |
| 14 | App — Circuit breaker | Sin retry ni circuit breaker | Un error transitorio de Supabase (503, timeout) resulta en error inmediato al usuario, sin oportunidad de recuperación automática. | Implementar retry con backoff exponencial (max 3 intentos) para operaciones de lectura. Para writes, preferir error inmediato + feedback claro. | **MEDIA** |
| 15 | DB — Índices | Ausencia de índice en `history.userId` | `getHistory` filtera por `userId` sin índice. Mismo problema que `train`. | `CREATE INDEX idx_history_user ON history ("userId");` | **MEDIA** |
| 16 | App — IDs locales | `Math.random()` para IDs de items locales | No es UUID ni garantiza unicidad en edge cases. Bajo estrés, dos ejercicios podrían obtener el mismo `localId`, causando comportamiento inesperado en React keys. | Usar `crypto.randomUUID()` (disponible en React Native 0.71+) o la función `uuid` de expo-crypto. | **BAJA** |
| 17 | App — Ownership check | `deleteRoutine` hace SELECT + DELETE (TOCTOU) | Entre el check de ownership y el delete, otro cliente podría modificar el registro. Además, duplica el round-trip. | Eliminar el SELECT manual y confiar en RLS policy (`userId = auth.uid()`). Si RLS está bien configurado, el DELETE fallará con 0 rows si no hay permisos. | **BAJA** |

---

## Próximos pasos recomendados

### Sprint 1 — Crítico (esta semana)
1. **Crear índices faltantes** en `train`, `train_exercises` y `train_exercise_detail` (mejoras #1, #2, #3). Ejecutar en Supabase SQL Editor. Tiempo: 30 min.
2. **Corregir el unique index** de rutina activa para usar `'Activa'` y scope por `userId` (mejora #9). Tiempo: 15 min.
3. **Atomizar `saveRoutineExercises` y `saveWorkout`** mediante una Supabase RPC/PL-pgSQL (mejora #4). Tiempo: 2-3 hs.

### Sprint 2 — Alto impacto (próximas 2 semanas)
4. **Implementar caché de catálogo** (`exercises`, `muscles`) con React Query o una solución simple de módulo singleton (mejora #5). Tiempo: 4 hs.
5. **Separar fetch inicial de filtrado local** en `train.tsx` para eliminar re-fetches por cambio de semana/día (mejora #7). Tiempo: 2 hs.
6. **Agregar paginación** a `getHistory` y `getFinishedRoutines` (mejora #6). Tiempo: 3 hs.
7. **Implementar timeouts** con `AbortController` en las llamadas críticas (mejora #8). Tiempo: 2 hs.

### Sprint 3 — Resiliencia y UX (mes siguiente)
8. **Persistencia local** de `WorkoutContext` con `AsyncStorage` (mejora #13).
9. **Retry con backoff** para operaciones de lectura (mejora #14).
10. **Diff-based save** en `saveRoutineExercises` para reducir write amplification (mejora #12).
11. **Guard de doble-submit** en todos los formularios (mejora #11).

### A futuro (si el producto escala)
12. Evaluar búsqueda server-side de ejercicios (mejora #10).
13. Revisar configuración de Supavisor/pgBouncer según plan contratado.
14. Considerar separación de queries analíticas (`getRoutineProgress`) del path de lectura principal.

---

## Qué NO fue posible analizar

- **RLS policies en producción**: no hay archivos `.sql` de políticas en el repositorio. La seguridad y correctness de las policies deben auditarse directamente en el dashboard de Supabase.
- **Índices existentes en producción**: el schema local está desactualizado (no refleja las migraciones de `muscle_id`, `trainer_id`, etc.). Los índices reales deben verificarse con `SELECT indexname, indexdef FROM pg_indexes WHERE schemaname = 'public';` en Supabase.
- **Configuración de Supavisor/pgBouncer**: requiere acceso al dashboard o `.env` de producción.
- **Métricas de performance reales**: no hay APM, logging estructurado ni métricas de query time en el código analizado.
- **Edge Functions / Realtime**: no se detectó uso de Supabase Realtime ni Edge Functions en el proyecto.
