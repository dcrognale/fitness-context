---
description: Cómo usar el contexto de agentes del proyecto fitness para tareas en fitness-app o fitness-web
---

# Cómo usar el fitness-context

Este contexto provee skills y agentes especializados para los dos proyectos fitness.

## 1. Leer el skill del proyecto correcto

Antes de trabajar en cualquier tarea, leer el SKILL.md correspondiente:

```
# Para la app mobile:
/Users/diego.crognale/Documents/IA-Projects/fitness-context/.agents/skills/fitness-app/SKILL.md

# Para el panel web:
/Users/diego.crognale/Documents/IA-Projects/fitness-context/.agents/skills/fitness-web/SKILL.md

# Para cambios de base de datos (siempre leer):
/Users/diego.crognale/Documents/IA-Projects/fitness-context/.agents/skills/shared-supabase/SKILL.md
```

## 2. Verificar estructura antes de crear archivos

Siempre usar `list_dir` para verificar la estructura existente antes de crear nuevos archivos o carpetas.

## 3. Respetar convenciones

- **fitness-app**: TypeScript, `services/databaseService.ts` como único archivo de queries, expo-router file-based routing.
- **fitness-web**: JSX, servicios en `src/services/`, tema MUI oscuro, RPCs para operaciones admin.

## 4. Nunca usar service_role en el cliente

Para operaciones admin en la web, siempre usar las RPCs de Supabase definidas con `SECURITY DEFINER`.
Ver `fitness-web/supabase/migrations/002_admin_rpc_functions.sql` para las funciones disponibles.

## 5. Workflow de tarea típica

1. Leer skill relevante
2. Verificar archivos existentes relacionados a la tarea
3. Implementar cambios respetando los patrones del proyecto
4. Si hay cambios de BD → actualizar el skill `shared-supabase`
5. Luego de agregar, modificar o eliminar codigo actualizar siempre el contexto y los readme.MD