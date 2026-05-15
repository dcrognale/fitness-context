# Training Blocks — Routine Editor Refactor

Refactor the routine editor to support ordered training blocks per day (WARMUP, REST, POWER, AMRAP, EMOM, TABATA). Each day contains an ordered list of blocks; each block contains an ordered list of exercises. This replaces the current flat `exercises[]` + `warmUp` text structure.

---

## User Review Required

> [!IMPORTANT]
> **RoutinePlannerPage impact**: The current planner reads `routine.train_exercises[]` (flat, with `day`, `position`, `exerciseId`, `sets`, `reps`, `train_exercise_detail`). After this migration, `train_exercises` rows will lose the `day` column and gain `block_id`. The planner will need a structural query update to continue working. The task says *"update the data fetching in the service layer so it doesn't break"* — meaning `getRoutinePlannerData` must be updated to produce the **same shape** the planner currently consumes (or a shape that doesn't break any existing planner UI code).
>
> My plan: `getRoutinePlannerData` will JOIN `training_blocks` and re-attach `day` / `day_name` from the block onto each exercise row in the returned object — preserving backward compatibility for the planner's rendering logic with zero changes to `RoutinePlannerPage.jsx`.

> [!IMPORTANT]
> **getActiveRoutine / getRoutineProgress**: Both functions in `routinesService.js` read `train_exercises` with the `day`, `warm_up` fields. These must be updated to join `training_blocks` and derive `day` from the block. This is in scope of the service layer changes.

> [!WARNING]
> **Data loss**: All existing `train_exercises` and `train_exercise_detail` rows **will be dropped** and recreated. The constraint from migration 009 (`chk_exercise_or_warmup`) will be dropped as part of recreating the table.

---

## Open Questions

> [!NOTE]
> None — all block types, colors, and rules are fully specified. Proceeding with plan.

---

## Proposed Changes

### 1. Database Migration

#### [NEW] `supabase/migrations/021_training_blocks.sql`

Full migration that:
1. Drops `train_exercise_detail` (CASCADE), `train_exercises`, and all their policies
2. Creates `training_blocks` with RLS mirroring `train_exercises` existing policy pattern (access via `train` ownership, admin full)
3. Recreates `train_exercises` with new schema (`block_id` FK, drops `day`, `day_name`, `warm_up`, keeps `sets`, `reps`, `superset_group`, `position`)
4. Recreates `train_exercise_detail` with FK to new `train_exercises`

**Schema summary:**

```sql
-- NEW table
training_blocks (
  id UUID PK,
  train_id UUID → train.id CASCADE,
  day INTEGER,
  day_name TEXT,
  position INTEGER DEFAULT 0,
  type TEXT CHECK IN ('WARMUP','REST','POWER','AMRAP','EMOM','TABATA'),
  duration_seconds INTEGER,   -- REST only
  duration_minutes INTEGER,   -- AMRAP, EMOM only
  cycles INTEGER,             -- TABATA only
  created_at TIMESTAMPTZ
)

-- MODIFIED train_exercises
train_exercises (
  id UUID PK,
  trainId UUID → train.id,
  block_id UUID → training_blocks.id CASCADE,  -- NEW
  exerciseId UUID → exercises.id,
  sets INTEGER,                    -- NULL for non-POWER blocks
  reps VARCHAR(50),                -- "12" / "15-12-10-8" (POWER) or "X" (others)
  superset_group INTEGER,
  position INTEGER
  -- REMOVED: day, day_name, warm_up
)

-- train_exercise_detail — unchanged structure, recreated with FKs
```

---

### 2. Service Layer

#### [MODIFY] `src/services/routinesService.js`

| Function | Change |
|---|---|
| `getRoutineById` | Select `training_blocks(... train_exercises(...))` nested |
| `insertTrainExercises` → `insertRoutineBlocks` | New function: inserts blocks then exercises per block |
| `deleteTrainExercises` → `deleteRoutineBlocks` | Delete from `training_blocks` (cascades to `train_exercises`) |
| `getRoutinePlannerData` | Join blocks to preserve backward-compatible shape for planner |
| `getActiveRoutine` | Join blocks to get `day` from block, filter out REST blocks |
| `getRoutineProgress` | Derive `day` from block join |
| `getRoutines` | Update count select: `training_blocks(train_exercises(id))` for exercise count, or keep simpler |

---

### 3. RoutinesPage.jsx

#### [MODIFY] `src/pages/RoutinesPage.jsx`

- Update imports: `deleteTrainExercises` → `deleteRoutineBlocks`, `insertTrainExercises` → `insertRoutineBlocks`
- Update `handleEdit`: parse `training_blocks` (nested) instead of flat `train_exercises`
- Update `handleSave`: call `deleteRoutineBlocks` + `insertRoutineBlocks`
- The rest of the page (table, filters, pagination, delete dialog) is unchanged

**New `handleEdit` shape** (deserialization from DB → editor state):
```js
// For each training_block: build block object with exercises[]
// For POWER blocks: deserializeReps() as before
// For WARMUP/AMRAP/EMOM/TABATA blocks: simple reps integer
// For REST blocks: exercises = []
```

---

### 4. RoutineEditor.jsx — Full Refactor

This is the largest change. The file will be fully rewritten preserving:
- `useEditorColors()` hook
- `getStatusConfig()`, `getInputSx()` helpers
- `serializeReps` / `deserializeReps` (exported)
- `SUPERSET_COLORS` constant
- `generateId()` helper

**New constants at top of file:**
```js
const BLOCK_TYPE_COLORS = {
  WARMUP: '#ef4444',  // red
  REST:   '#22c55e',  // green
  POWER:  '#6b7280',  // grey
  AMRAP:  '#eab308',  // yellow
  EMOM:   '#3b82f6',  // blue
  TABATA: '#a855f7',  // violet
};
const BLOCK_TYPES = ['WARMUP', 'REST', 'POWER', 'AMRAP', 'EMOM', 'TABATA'];
```

**New/modified sub-components:**

| Component | Description |
|---|---|
| `ExerciseCard` | Unchanged for POWER blocks. Receives `blockType` prop; shows compact (name + reps only) for WARMUP/AMRAP/EMOM/TABATA |
| `BlockCard` | **NEW** — colored header with type label + config inputs + droppable exercises list |
| `RestBlock` | **NEW** — duration input only, no exercise drop zone |
| `DayColumn` | Refactored — renders `blocks[]` instead of `exercises[]`; droppable for blocks |
| `ExerciseLibraryItem` | More compact (reduced padding/font) |
| `BlockPaletteItem` | **NEW** — draggable colored chip for each block type |
| `RoutineEditor` (main) | Updated state shape, `onDragEnd` handles 4 drag scenarios |

**Drag-and-drop IDs (new scheme):**
```
Droppable IDs:
  "library"                    → exercise library (isDropDisabled)
  "block-palette"              → block palette (isDropDisabled)
  "day-{dayIdx}"               → day column (drops: block chips from palette)
  "block-{dayIdx}-{blockIdx}"  → block exercise list (drops: exercises)

Draggable IDs:
  "lib-{exerciseId}"           → library exercise
  "blktype-{TYPE}"             → block type chip
  "block-{dayIdx}-{blockIdx}"  → block itself within a day
  "{dayId}__{blockIdx}__{ex._id}" → exercise within a block
```

**`onDragEnd` logic (4 scenarios):**
1. `block-palette` → `day-N`: insert new empty block of dragged type at destination index (enforce WARMUP at 0 if applicable)
2. `lib-*` → `block-N-M`: add exercise to block M of day N
3. `block-N-*` → `block-N-*`: reorder blocks within same day (clamp WARMUP to index 0)
4. `{day}__{block}__{ex}` → `block-*`: move/reorder exercise between blocks

**New state shape:**
```js
days = [
  {
    id: string,
    label: string,
    blocks: [
      {
        _id: string,
        type: 'WARMUP'|'REST'|'POWER'|'AMRAP'|'EMOM'|'TABATA',
        position: number,
        durationSeconds?: number,
        durationMinutes?: number,
        cycles?: number,
        exercises: ExerciseItem[]
      }
    ]
  }
]
```

**Left panel changes:**
- Width: 300px → 380px
- Add **Blocks palette** section above exercise library (6 colored draggable chips)
- Exercise library items: more compact (padding, font sizes reduced)

---

### 5. Summary of File Changes

| File | Status |
|---|---|
| `supabase/migrations/021_training_blocks.sql` | NEW |
| `src/services/routinesService.js` | MODIFY |
| `src/pages/RoutinesPage.jsx` | MODIFY (import/handler updates) |
| `src/components/routines/RoutineEditor.jsx` | MODIFY (full refactor) |
| `src/pages/RoutinePlannerPage.jsx` | NO CHANGE (service layer preserves shape) |

---

## Verification Plan

### Automated Checks
- `npm run build` — TypeScript/JSX compile check (no type errors)

### Manual Verification (browser)
1. Open Routine Editor → create a new routine with all 6 block types
2. Drag a WARMUP chip → verify it appears at position 0; drag another → verify it goes to 0 and pushes others down
3. Drag exercises from library into POWER, AMRAP, EMOM, TABATA blocks — verify correct input UIs
4. Drag a REST block — verify only duration input shows
5. Save routine → inspect `training_blocks` table in Supabase to verify data
6. Edit saved routine → verify correct deserialization (all blocks and exercises reload correctly)
7. Open RoutinePlannerPage for a saved routine → verify it still displays exercises correctly
