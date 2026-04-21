---
name: fitness-app
description: >
  Contexto completo del proyecto fitness-app: app mobile construida con
  React Native + Expo + expo-router + Supabase. Leer antes de cualquier
  tarea relacionada con la app mobile.
---

# fitness-app — App Mobile

## Ubicación
```
/Users/diego.crognale/Documents/IA-Projects/fitness-app/
```

## Stack Técnico

| Tecnología | Versión | Uso |
|---|---|---|
| React Native | 0.81.5 | Framework base |
| React | 19.1.0 | UI library |
| Expo | ~54.0.33 | Runtime y tooling |
| expo-router | ~6.0.23 | File-based routing |
| @supabase/supabase-js | ^2.97.0 | Backend / Auth |
| react-native-paper | ^5.15.0 | Componentes UI |
| expo-secure-store | ^55.0.9 | Almacenamiento seguro (tokens auth) |
| react-native-reanimated | ~4.1.1 | Animaciones |
| react-native-youtube-iframe | ^2.4.1 | Preview videos ejercicios |

## Comandos

```bash
cd /Users/diego.crognale/Documents/IA-Projects/fitness-app

# Desarrollo
npm start          # Expo DevTools
npm run ios        # Simulador iOS
npm run android    # Emulador Android
npm run web        # Web (Expo)
npm run lint       # Lint
```

## Estructura de Carpetas

```
fitness-app/
├── app/                        # Rutas (expo-router file-based)
│   ├── _layout.tsx             # Root layout: AuthProvider, WorkoutProvider, PaperProvider
│   ├── (auth)/                 # Grupo de rutas de autenticación (sin tabs)
│   │   └── login.tsx
│   ├── (tabs)/                 # Grupo de rutas con tab bar
│   │   ├── _layout.tsx         # Tab bar config
│   │   ├── index.tsx           # Home / Rutinas
│   │   ├── train.tsx           # Pantalla de entrenamiento activo
│   │   ├── exercises.tsx       # Catálogo de ejercicios
│   │   ├── rest.tsx            # Cronómetro de descanso
│   │   ├── history.tsx         # Historial de entrenamientos
│   │   ├── explore.tsx
│   │   └── profile.tsx         # Perfil del usuario
│   ├── routine/                # Pantalla detalle rutina
│   │   └── [id].tsx
│   ├── exercise/               # Pantalla detalle ejercicio
│   ├── history/                # Detalle de historial
│   │   └── [id].tsx
│   └── modal.tsx
├── context/
│   ├── AuthContext.tsx          # Sesión Supabase, user, isLoading, signOut
│   └── WorkoutContext.tsx       # Estado del entrenamiento activo en progreso
├── services/
│   └── databaseService.ts      # TODAS las queries a Supabase (single file)
├── database/
│   ├── schema.sql              # Schema inicial
│   ├── trainExerciseDetail.sql # Migración add setNumber
│   └── train_active_unique.sql # Constraint unique rutina activa
├── components/                  # Componentes reutilizables
├── constants/                   # Colores, temas
├── hooks/                       # Custom hooks
├── utils/
│   └── supabase.ts             # Cliente Supabase singleton
└── assets/                      # Imágenes, fuentes
```

## Autenticación

- **Archivo:** `context/AuthContext.tsx`
- Usa `supabase.auth.getSession()` + `supabase.auth.onAuthStateChange()`
- Expone: `{ session, user, isLoading, signOut }`
- **`expo-secure-store`** se usa como storage adapter para persistir tokens de forma segura (ver `utils/supabase.ts`)

### Flujo de navegación de auth
```
_layout.tsx → RootLayoutNav
  isLoading=true  → SplashScreen visible
  isLoading=false + no session → redirect /(auth)/login
  isLoading=false + session → redirect /(tabs)
```

## Pantallas Principales

| Pantalla | Archivo | Descripción |
|---|---|---|
| Home/Rutinas | `(tabs)/index.tsx` | Lista rutinas activas del usuario, pull-to-refresh |
| Entrenamiento | `(tabs)/train.tsx` | Pantalla de entrenamiento activo con métricas dinámicas (sets/reps/mts/cal) |
| Ejercicios | `(tabs)/exercises.tsx` | Catálogo de ejercicios con filtros |
| Descanso | `(tabs)/rest.tsx` | Temporizador de descanso |
| Historial | `(tabs)/history.tsx` | Rutinas con status=`'Inactive'` ordenadas por fecha |
| Perfil | `(tabs)/profile.tsx` | Info del usuario + logout |
| Detalle Rutina | `routine/[id].tsx` | Vista detallada de rutina (solo lectura o en progreso) |
| Historial Detalle | `history/[id].tsx` | Rutina pasada en modo read-only |

## WorkoutContext

Estado global del entrenamiento activo en progreso:
```typescript
{
  activeWorkout: WorkoutExercise[] | null, // null = sin entrenamiento activo
  isInWorkout: boolean,
  startWorkout: () => void,
  addExercise: (exercise) => void,
  addSet: (workoutExerciseId) => void,
  updateSet: (workoutExerciseId, setId, field, value) => void,
  removeSet: (workoutExerciseId, setId) => void,
  finishWorkout: (userId, duration) => Promise<void>, // llama a saveWorkout()
}
```

## Servicio de Base de Datos

- **Archivo único:** `services/databaseService.ts`
- Contiene TODAS las queries: ejercicios, rutinas, `train_exercise_detail`, historial, etc.
- Siempre importar desde este archivo, no crear nuevos service files en la app mobile.

## Variables de Entorno

```env
# .env en la raíz de fitness-app
EXPO_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJ...
```

## Convenciones de Código

- **TypeScript** en toda la app (`.tsx`, `.ts`)
- Componentes de pantalla en `app/` con expo-router
- Estilos con `StyleSheet.create()` de React Native
- Usar `react-native-paper` para componentes UI (Button, Card, TextInput, etc.)
- Colores y tema definidos en `constants/`
- Siempre manejar estados `loading` y `error` en pantallas que fetchen datos

## Advertencias Importantes

> ⚠️ **expo-router v6** usa file-based routing. No mezclar con React Navigation manual.
> 
> ⚠️ **`expo-secure-store`** es el storage de Supabase. No usar `AsyncStorage` para tokens de auth.
>
> ⚠️ El campo `status` de rutina es `'active'` (activa) o `'Inactive'` (terminada/historial). Historial filtra por `status = 'Inactive'`.
>
> ⚠️ No usar `service_role` key en ningún punto del cliente mobile.
