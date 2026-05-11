# Plan de Implementación — Load Readiness

> Cada tarea está diseñada para ejecutarse de forma independiente y en orden.  
> **Convención:** `[DB]` = cambio en Supabase SQL Editor · `[APP]` = cambio en el código

---

## Sprint 1 — Crítico

### Tarea 1.1 `[DB]` — Índices en tablas principales
**Mejoras:** #1, #2, #3, #15  
**Archivo:** nuevo `database/migrations/001_add_indexes.sql`

**Pasos:**
1. Verificar índices existentes ejecutando en Supabase SQL Editor:
   ```sql
   SELECT indexname, tablename, indexdef
   FROM pg_indexes
   WHERE schemaname = 'public'
   ORDER BY tablename;
   ```
2. Crear el archivo de migración local `database/migrations/001_add_indexes.sql`.
3. Pegar y ejecutar el siguiente SQL en el Supabase SQL Editor:
   ```sql
   -- train: filtros por usuario y estado (getRoutines, getActiveRoutine, getFinishedRoutines)
   CREATE INDEX IF NOT EXISTS idx_train_user_status
       ON public.train ("userId", status);

   -- train_exercises: filtro por rutina (getRoutineExercises, getActiveRoutine)
   CREATE INDEX IF NOT EXISTS idx_train_exercises_train_id
       ON public.train_exercises ("trainId");

   -- train_exercise_detail: filtro por ejercicio (getTrainExerciseDetails)
   CREATE INDEX IF NOT EXISTS idx_ted_train_exercise_id
       ON public.train_exercise_detail ("trainExerciseId");

   -- history: filtro por usuario (getHistory)
   CREATE INDEX IF NOT EXISTS idx_history_user_id
       ON public.history ("userId");
   ```
4. Verificar que los 4 índices aparecen en el resultado del SELECT del paso 1.
5. Opcional: ejecutar `EXPLAIN ANALYZE` sobre una query representativa para confirmar que usa el índice (Index Scan en lugar de Seq Scan).

**Validación:** Ningún cambio en el código de la app. Los índices son transparentes.

---

### Tarea 1.2 `[DB]` — Corregir unique index de rutina activa
**Mejora:** #9  
**Archivo:** nuevo `database/migrations/002_fix_active_routine_index.sql`

**Contexto del bug:** El índice actual (`WHERE status = 'active'`) nunca se activa porque la app guarda `'Activa'`. Además, no tiene scope por usuario, por lo que solo permitiría una rutina activa en toda la plataforma.

**Pasos:**
1. Ejecutar en Supabase SQL Editor:
   ```sql
   -- 1. Eliminar el índice incorrecto
   DROP INDEX IF EXISTS public.uq_one_active_routine;

   -- 2. Crear índice único parcial con el valor correcto y scope por usuario
   CREATE UNIQUE INDEX IF NOT EXISTS uq_one_active_routine_per_user
       ON public.train ("userId", status)
       WHERE status = 'Activa';
   ```
2. Guardar el SQL en `database/migrations/002_fix_active_routine_index.sql`.
3. Verificar que no hay usuarios con más de una rutina `'Activa'` antes de crear el índice:
   ```sql
   SELECT "userId", COUNT(*) 
   FROM public.train 
   WHERE status = 'Activa' 
   GROUP BY "userId" 
   HAVING COUNT(*) > 1;
   ```
   Si hay duplicados, resolverlos manualmente antes de continuar.

**Validación:** Intentar crear dos rutinas con `status = 'Activa'` para el mismo `userId` debe fallar con error de constraint.

---

### Tarea 1.3 `[DB]` — Atomizar `saveRoutineExercises` con RPC
**Mejora:** #4 (parte 1)  
**Archivos:** `database/migrations/003_rpc_save_routine_exercises.sql` + `services/databaseService.ts`

**Pasos:**

**A. Crear la función RPC en Supabase:**
```sql
CREATE OR REPLACE FUNCTION save_routine_exercises(
    p_train_id UUID,
    p_exercises JSONB
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete existing exercises for this routine
    DELETE FROM public.train_exercises WHERE "trainId" = p_train_id;

    -- Insert new exercises if any
    IF jsonb_array_length(p_exercises) > 0 THEN
        INSERT INTO public.train_exercises (
            "trainId", "exerciseId", sets, reps, weight,
            superset_group, position, day
        )
        SELECT
            p_train_id,
            (ex->>'exerciseId')::UUID,
            (ex->>'sets')::INTEGER,
            (ex->>'reps')::INTEGER,
            ex->>'weight',
            (ex->>'superset_group')::INTEGER,
            (ex->>'position')::INTEGER,
            ex->>'day'
        FROM jsonb_array_elements(p_exercises) AS ex;
    END IF;
END;
$$;
```

**B. Actualizar `services/databaseService.ts`:**

Reemplazar la función `saveRoutineExercises` existente:
```typescript
export const saveRoutineExercises = async (
    trainId: string,
    exercises: Array<{
        exerciseId: string;
        sets: number | null;
        reps: number | null;
        weight: string | null;
        superset_group: number | null;
        position: number;
        day: string;
    }>
): Promise<void> => {
    const { error } = await supabase.rpc('save_routine_exercises', {
        p_train_id: trainId,
        p_exercises: exercises,
    });
    if (error) throw handleSupabaseError(error);
};
```

**Validación:** Guardar una rutina con el Routine Editor y luego matar la app. Los datos deben estar completos o ausentes, nunca a medias.

---

### Tarea 1.4 `[DB]` — Atomizar `saveWorkout` con RPC
**Mejora:** #4 (parte 2)  
**Archivos:** `database/migrations/004_rpc_save_workout.sql` + `services/databaseService.ts`

**Pasos:**

**A. Crear la función RPC en Supabase:**
```sql
CREATE OR REPLACE FUNCTION save_workout(
    p_user_id UUID,
    p_duration VARCHAR,
    p_exercises JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_history_id UUID;
BEGIN
    -- 1. Insert history record
    INSERT INTO public.history ("userId", date, duration)
    VALUES (p_user_id, NOW(), p_duration)
    RETURNING id INTO v_history_id;

    -- 2. Insert history_exercises if any
    IF jsonb_array_length(p_exercises) > 0 THEN
        INSERT INTO public.history_exercises (
            "historyId", "exerciseId", sets, reps, weight
        )
        SELECT
            v_history_id,
            (ex->>'exerciseId')::UUID,
            (ex->>'sets')::INTEGER,
            (ex->>'reps')::INTEGER,
            ex->>'weight'
        FROM jsonb_array_elements(p_exercises) AS ex;
    END IF;

    RETURN v_history_id;
END;
$$;
```

**B. Actualizar `services/databaseService.ts`:**

Reemplazar la función `saveWorkout`:
```typescript
export const saveWorkout = async (
    userId: string,
    duration: string,
    workoutExercises: any[]
): Promise<HistorySession> => {
    if (!userId) throw new DatabaseError('Valid userId is required', 'VALIDATION');

    const exercises = workoutExercises.map(ex => ({
        exerciseId: ex.exerciseId,
        sets: ex.sets ? ex.sets.length : 0,
        reps: ex.sets && ex.sets.length > 0 ? parseInt(ex.sets[0].reps) || 0 : 0,
        weight: ex.sets && ex.sets.length > 0 ? ex.sets[0].weight : '',
    }));

    const { data, error } = await supabase.rpc('save_workout', {
        p_user_id: userId,
        p_duration: duration,
        p_exercises: exercises,
    });
    if (error) throw handleSupabaseError(error);

    // Fetch the full history session to return
    const { data: session, error: fetchError } = await supabase
        .from('history')
        .select('*')
        .eq('id', data)
        .single();
    if (fetchError) throw handleSupabaseError(fetchError);
    return session as HistorySession;
};
```

**Validación:** Finalizar un workout y verificar que `history` e `history_exercises` se crean juntos.

---

## Sprint 2 — Alto Impacto

### Tarea 2.1 `[APP]` — Caché en memoria para catálogo de ejercicios y músculos
**Mejora:** #5  
**Archivos:** nuevo `services/catalogCache.ts` + `services/databaseService.ts`

**Pasos:**

**A. Crear `services/catalogCache.ts`:**
```typescript
// Simple in-memory cache with TTL for static/semi-static catalogs
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

interface CacheEntry<T> {
    data: T;
    expiresAt: number;
}

const store = new Map<string, CacheEntry<any>>();

export function cacheGet<T>(key: string): T | null {
    const entry = store.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
        store.delete(key);
        return null;
    }
    return entry.data as T;
}

export function cacheSet<T>(key: string, data: T): void {
    store.set(key, { data, expiresAt: Date.now() + CACHE_TTL_MS });
}

export function cacheInvalidate(key: string): void {
    store.delete(key);
}
```

**B. Actualizar `getMuscles` y `getExercises` en `databaseService.ts`:**
```typescript
import { cacheGet, cacheSet } from './catalogCache';

export const getMuscles = async (): Promise<Muscle[]> => {
    const cached = cacheGet<Muscle[]>('muscles');
    if (cached) return cached;

    const { data, error } = await supabase
        .from('muscles')
        .select('id, name')
        .order('name', { ascending: true });
    if (error) throw handleSupabaseError(error);
    const result = (data || []) as Muscle[];
    cacheSet('muscles', result);
    return result;
};

export const getExercises = async (): Promise<Exercise[]> => {
    const cached = cacheGet<Exercise[]>('exercises');
    if (cached) return cached;

    const { data, error } = await supabase
        .from('exercises')
        .select('*, muscles(id, name)')
        .order('name', { ascending: true });
    if (error) throw handleSupabaseError(error);
    const result = (data || []) as Exercise[];
    cacheSet('exercises', result);
    return result;
};
```

**Validación:** Abrir `ExercisesScreen`, cerrarla y volverla a abrir. La segunda vez debe ser instantánea (sin spinner de carga).

---

### Tarea 2.2 `[APP]` — Eliminar re-fetches en `train.tsx` por cambio de semana/día
**Mejora:** #7  
**Archivo:** `app/(tabs)/train.tsx`

**Contexto:** El `useEffect` actual tiene `activeWeek` y `activeDay` como dependencias, causando un fetch completo a la DB cada vez que el usuario cambia de pestaña. Toda la data de la rutina + detalles se puede cargar una sola vez.

**Pasos:**

1. **Cambiar el `useEffect` de carga** — quitar `activeWeek` y `activeDay` de las dependencias y usar `useFocusEffect`:

```typescript
// ANTES (línea 337):
useEffect(() => { loadRoutine(true); }, [loadRoutine, activeWeek, activeDay]);

// DESPUÉS:
useFocusEffect(useCallback(() => { loadRoutine(); }, [loadRoutine]));
```

2. **Agregar import** de `useFocusEffect`:
```typescript
import { useFocusEffect } from 'expo-router';
```

3. **Eliminar el parámetro `isRefresh`** del `useEffect` de carga inicial (queda solo para el pull-to-refresh manual). El `loadRoutine` ya tiene `setRefreshing` para ese path.

4. **Verificar que `weekLogs` y `weekIndications`** ya contienen datos de todas las semanas en el primer fetch (actualmente sí, línea 300 itera sobre `WEEKS`). No requiere cambios adicionales.

**Validación:** Cambiar entre Semana 1 / Semana 2 / Día 1 / Día 2 no debe mostrar spinner ni hacer llamadas a Supabase visibles en el log de red.

---

### Tarea 2.3 `[APP]` — Paginación en Historial y Rutinas finalizadas
**Mejora:** #6  
**Archivos:** `services/databaseService.ts` + `app/(tabs)/history.tsx` + `app/history/[id].tsx` (si existe)

**Pasos:**

**A. Actualizar `getFinishedRoutines` en `databaseService.ts`:**
```typescript
const PAGE_SIZE = 20;

export const getFinishedRoutines = async (
    userId: string,
    page = 0
): Promise<{ data: TrainSession[]; hasMore: boolean }> => {
    if (!userId) throw new DatabaseError('Valid userId is required', 'VALIDATION');
    const from = page * PAGE_SIZE;
    const to = from + PAGE_SIZE - 1;

    const { data, error } = await supabase
        .from('train')
        .select('*')
        .eq('status', 'Inactiva')
        .eq('userId', userId)
        .order('createdAt', { ascending: false })
        .range(from, to);

    if (error) throw handleSupabaseError(error);
    const rows = (data || []) as TrainSession[];
    return { data: rows, hasMore: rows.length === PAGE_SIZE };
};
```

**B. Actualizar `history.tsx` para infinite scroll:**
```typescript
const [page, setPage] = useState(0);
const [hasMore, setHasMore] = useState(true);
const [loadingMore, setLoadingMore] = useState(false);

const load = useCallback(async (isRefresh = false) => {
    if (!userId) return;
    const currentPage = isRefresh ? 0 : page;
    if (isRefresh) { setPage(0); setRoutines([]); }
    isRefresh ? setRefreshing(true) : setLoading(true);
    try {
        const result = await getFinishedRoutines(userId, currentPage);
        setRoutines(prev => isRefresh ? result.data : [...prev, ...result.data]);
        setHasMore(result.hasMore);
        if (!isRefresh) setPage(p => p + 1);
    } catch (e: any) {
        console.warn('Error fetching finished routines:', e?.message);
    } finally {
        setLoading(false);
        setRefreshing(false);
    }
}, [userId, page]);

const loadMore = useCallback(async () => {
    if (!hasMore || loadingMore) return;
    setLoadingMore(true);
    try {
        const result = await getFinishedRoutines(userId!, page);
        setRoutines(prev => [...prev, ...result.data]);
        setHasMore(result.hasMore);
        setPage(p => p + 1);
    } finally {
        setLoadingMore(false);
    }
}, [hasMore, loadingMore, userId, page]);
```

Agregar al `FlatList`:
```typescript
onEndReached={loadMore}
onEndReachedThreshold={0.3}
ListFooterComponent={loadingMore ? <ActivityIndicator /> : null}
```

**Validación:** Con más de 20 rutinas finalizadas, el scroll al fondo debe cargar la siguiente página.

---

### Tarea 2.4 `[APP]` — Timeouts en operaciones críticas de DB
**Mejora:** #8  
**Archivos:** nuevo `utils/withTimeout.ts` + `services/databaseService.ts`

**Pasos:**

**A. Crear `utils/withTimeout.ts`:**
```typescript
export class TimeoutError extends Error {
    constructor(ms: number) {
        super(`La operación tardó más de ${ms / 1000}s. Verificá tu conexión.`);
        this.name = 'TimeoutError';
    }
}

export function withTimeout<T>(promise: Promise<T>, ms = 10000): Promise<T> {
    const timeout = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new TimeoutError(ms)), ms)
    );
    return Promise.race([promise, timeout]);
}
```

**B. Aplicar a las operaciones críticas de lectura en `databaseService.ts`:**
```typescript
import { withTimeout } from '../utils/withTimeout';

// Envolver las funciones de lectura más usadas:
export const getActiveRoutine = async (userId: string) => {
    // ... query existente ...
    return withTimeout(queryPromise, 10000);
};
```

> **Nota práctica:** en lugar de refactorizar función por función, podés aplicar el wrapper al nivel de los callers en `train.tsx` e `index.tsx`:
> ```typescript
> const data = await withTimeout(getActiveRoutine(userId), 10000);
> ```

**C. Mostrar error claro al usuario cuando ocurre timeout:**

En los catch de `train.tsx` e `index.tsx`:
```typescript
} catch (e: any) {
    if (e?.name === 'TimeoutError') {
        setError(e.message);
    } else {
        setError(e?.message ?? 'Error al cargar la rutina.');
    }
}
```

**Validación:** Activar modo avión después de iniciar la carga. Debe mostrarse error a los 10 segundos en lugar de spinner infinito.

---

## Sprint 3 — Resiliencia

### Tarea 3.1 `[APP]` — Persistencia local de WorkoutContext
**Mejora:** #13  
**Archivo:** `context/WorkoutContext.tsx`

**Pasos:**

1. Importar `AsyncStorage`:
```typescript
import AsyncStorage from '@react-native-async-storage/async-storage';
```

2. Agregar constante de clave:
```typescript
const WORKOUT_STORAGE_KEY = '@fitness_app/active_workout';
```

3. **Al inicializar el contexto**, recuperar workout guardado:
```typescript
useEffect(() => {
    AsyncStorage.getItem(WORKOUT_STORAGE_KEY).then(raw => {
        if (raw) {
            try { setActiveWorkout(JSON.parse(raw)); } catch { /* ignore */ }
        }
    });
}, []);
```

4. **Persistir en cada cambio** de `activeWorkout`:
```typescript
useEffect(() => {
    if (activeWorkout === null) {
        AsyncStorage.removeItem(WORKOUT_STORAGE_KEY);
    } else {
        AsyncStorage.setItem(WORKOUT_STORAGE_KEY, JSON.stringify(activeWorkout));
    }
}, [activeWorkout]);
```

5. **Al finalizar el workout** (`finishWorkout`), limpiar storage:
```typescript
const finishWorkout = async (...) => {
    // ... lógica existente ...
    setActiveWorkout(null);
    // AsyncStorage se limpia automáticamente por el useEffect del punto 4
};
```

**Validación:** Iniciar un workout, agregar ejercicios, matar la app y relanzarla. El workout debe estar restaurado.

---

### Tarea 3.2 `[APP]` — Retry con backoff exponencial para lecturas
**Mejora:** #14  
**Archivos:** nuevo `utils/withRetry.ts` + aplicar en lecturas críticas

**Pasos:**

**A. Crear `utils/withRetry.ts`:**
```typescript
interface RetryOptions {
    maxAttempts?: number;
    baseDelayMs?: number;
    shouldRetry?: (error: any) => boolean;
}

const isNetworkError = (e: any) =>
    e?.message?.includes('fetch') ||
    e?.message?.includes('network') ||
    e?.code === 'NETWORK_ERROR';

export async function withRetry<T>(
    fn: () => Promise<T>,
    options: RetryOptions = {}
): Promise<T> {
    const { maxAttempts = 3, baseDelayMs = 500, shouldRetry = isNetworkError } = options;

    let lastError: any;
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
        try {
            return await fn();
        } catch (e) {
            lastError = e;
            if (!shouldRetry(e) || attempt === maxAttempts - 1) throw e;
            await new Promise(r => setTimeout(r, baseDelayMs * Math.pow(2, attempt)));
        }
    }
    throw lastError;
}
```

**B. Aplicar en lecturas críticas** (en los callers, no en el service):
```typescript
// En train.tsx - loadRoutine:
const data = await withRetry(() => getActiveRoutine(userId));

// En index.tsx - loadData:
const routine = await withRetry(() => getActiveRoutine(userId));
const prog = await withRetry(() => getRoutineProgress(routine.session.id));
```

> ⚠️ No aplicar retry en **escrituras** (save, delete). Un write que falla y se reintenta puede crear duplicados.

**Validación:** Simular red inestable con throttling. Las lecturas deben reintentarse silenciosamente hasta 3 veces antes de mostrar error.

---

### Tarea 3.3 `[DB+APP]` — Diff-based save en `saveRoutineExercises`
**Mejora:** #12  
**Archivos:** `database/migrations/005_rpc_upsert_routine_exercises.sql` + `services/databaseService.ts`

**Pasos:**

**A. Crear RPC con UPSERT en Supabase:**
```sql
CREATE OR REPLACE FUNCTION upsert_routine_exercises(
    p_train_id UUID,
    p_exercises JSONB,
    p_keep_ids UUID[]  -- IDs de train_exercises a conservar (los demás se borran)
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete only exercises that were removed
    DELETE FROM public.train_exercises
    WHERE "trainId" = p_train_id
      AND id <> ALL(p_keep_ids);

    -- Upsert exercises (insert new, update existing)
    INSERT INTO public.train_exercises (
        id, "trainId", "exerciseId", sets, reps, weight,
        superset_group, position, day
    )
    SELECT
        COALESCE((ex->>'id')::UUID, gen_random_uuid()),
        p_train_id,
        (ex->>'exerciseId')::UUID,
        (ex->>'sets')::INTEGER,
        (ex->>'reps')::INTEGER,
        ex->>'weight',
        (ex->>'superset_group')::INTEGER,
        (ex->>'position')::INTEGER,
        ex->>'day'
    FROM jsonb_array_elements(p_exercises) AS ex
    ON CONFLICT (id) DO UPDATE SET
        sets = EXCLUDED.sets,
        reps = EXCLUDED.reps,
        weight = EXCLUDED.weight,
        superset_group = EXCLUDED.superset_group,
        position = EXCLUDED.position,
        day = EXCLUDED.day;
END;
$$;
```

**B. Actualizar el `RoutineEditorScreen` (`routine/[id].tsx`)** para mantener los IDs originales en el estado local:

En el map de `trainExercises → RoutineItem` (línea ~452), agregar campo `dbId`:
```typescript
interface RoutineItem {
    localId: string;
    dbId?: string;  // ID real en train_exercises (si ya existe)
    // ... resto sin cambios
}

// Al mapear:
const mapped: RoutineItem[] = trainExercises.map((te, idx) => ({
    localId: uid(),
    dbId: te.id,  // preservar el ID de DB
    // ...
}));
```

En `handleSave`, usar la nueva RPC:
```typescript
const keepIds = normalized
    .filter(it => it.dbId)
    .map(it => it.dbId!);

await supabase.rpc('upsert_routine_exercises', {
    p_train_id: id,
    p_exercises: toSave,
    p_keep_ids: keepIds,
});
```

**Validación:** En una rutina con 20 ejercicios, editar solo el peso de uno y guardar. Verificar en Supabase que solo se actualizó 1 fila en lugar de 20 deletes + 20 inserts.

---

### Tarea 3.4 `[APP]` — Guards de doble-submit en todos los formularios
**Mejora:** #11  
**Archivos:** `app/(tabs)/train.tsx` + `app/routine/[id].tsx`

**Pasos:**

**En `train.tsx` — `ExerciseCard.handleSave`:**

El estado `saving` ya existe. Solo falta deshabilitar el botón correctamente:
```typescript
// Verificar que el TouchableOpacity tiene disabled={saving}:
<TouchableOpacity
    style={[styles.saveBtn, { backgroundColor: saveSuccess ? '#16a34a' : theme.tint }]}
    onPress={handleSave}
    disabled={saving}  // ← ya existe, verificar que esté
>
```

Agregar también opacity visual cuando está deshabilitado:
```typescript
style={[
    styles.saveBtn,
    { backgroundColor: saveSuccess ? '#16a34a' : theme.tint },
    saving && { opacity: 0.6 },  // ← agregar
]}
```

**En `train.tsx` — `handleFinish`:**

Agregar estado de loading para el botón finalizar:
```typescript
const [finishing, setFinishing] = useState(false);

// En el onPress del Alert:
onPress: async () => {
    if (!session?.id || finishing) return;
    setFinishing(true);
    try {
        await deactivateRoutine(session.id);
        loadRoutine();
    } catch (e: any) {
        Alert.alert('Error', e?.message ?? 'No se pudo finalizar.');
    } finally {
        setFinishing(false);
    }
}

// En el botón:
<TouchableOpacity
    style={[styles.finishBtn, { backgroundColor: '#ef4444', opacity: finishing ? 0.6 : 1 }]}
    onPress={handleFinish}
    disabled={finishing}
>
```

**En `routine/[id].tsx` — `handleSave`:**

El `saving` ya deshabilita el botón (línea 625). Verificar que también aplica a `updateStatus`:
```typescript
const updateStatus = async (status: string) => {
    if (!routine || !userId || saving) return;  // ← agregar `|| saving`
    // ...
};
```

**Validación:** Presionar "Guardar" varias veces rápido. Solo debe ejecutarse una operación. El botón debe verse deshabilitado visualmente mientras procesa.

---

## Resumen de archivos por tarea

| Tarea | Archivos nuevos | Archivos modificados |
|---|---|---|
| 1.1 | `database/migrations/001_add_indexes.sql` | — |
| 1.2 | `database/migrations/002_fix_active_routine_index.sql` | — |
| 1.3 | `database/migrations/003_rpc_save_routine_exercises.sql` | `services/databaseService.ts` |
| 1.4 | `database/migrations/004_rpc_save_workout.sql` | `services/databaseService.ts` |
| 2.1 | `services/catalogCache.ts` | `services/databaseService.ts` |
| 2.2 | — | `app/(tabs)/train.tsx` |
| 2.3 | — | `services/databaseService.ts`, `app/(tabs)/history.tsx` |
| 2.4 | `utils/withTimeout.ts` | `app/(tabs)/train.tsx`, `app/(tabs)/index.tsx` |
| 3.1 | — | `context/WorkoutContext.tsx` |
| 3.2 | `utils/withRetry.ts` | `app/(tabs)/train.tsx`, `app/(tabs)/index.tsx` |
| 3.3 | `database/migrations/005_rpc_upsert_routine_exercises.sql` | `services/databaseService.ts`, `app/routine/[id].tsx` |
| 3.4 | — | `app/(tabs)/train.tsx`, `app/routine/[id].tsx` |
