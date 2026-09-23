# Test Cases Plan — todo_riverpod

## Prerequisites

1. Add `AppDatabase.forTesting(QueryExecutor e)` constructor in `lib/database/app_database.dart` (enables in-memory DB tests)
2. `flutter pub add dev:integration_test`

## 1. Unit Tests (`test/`)

### `test/database/app_database_test.dart` — DB CRUD with in-memory `NativeDatabase.memory()`

- `insertTodo` returns id; `allTodos` returns it
- `getTodoById` returns row; throws for missing id
- `updateTodo` (replace) updates all columns
- `deleteTodo` removes row; returns 0 for missing id
- `watchAllTodos` emits on insert/update/delete
- Title length constraint: rejects empty (>0) and >200-char titles

### `test/providers/todo_actions_test.dart` — `TodoActions` over `ProviderContainer` with overridden `appDatabaseProvider`

- `addTodo` inserts with `isCompleted=false`, timestamps ≈ now
- `updateTodo` preserves `isCompleted`/`createdAt`, bumps `updatedAt`
- `toggleCompleted` inverts false→true→false; bumps `updatedAt`; throws for missing id
- `deleteTodo` removes row; idempotent for missing id
- `todoById` returns row / throws for missing id

### `test/providers/settings_provider_test.dart` — `ThemeModeState` with mocked `SharedPreferences`

- Defaults to `ThemeMode.system` when unset
- `setThemeMode` persists index under `theme_mode` and updates state
- Round-trips each `ThemeMode` value across provider rebuild

### `test/providers/todo_list_provider_test.dart`

- Emits `[]` initially; reflects insert/toggle/delete via stream

### `test/router/app_router_test.dart`

- `/edit/5` → `AddEditTodoScreen(todoId: 5)`
- `/edit/abc` and `/edit/` → falls back to `TodoListScreen`

## 2. E2E Tests with Flutter Drive (`integration_test/` + `test_driver/`)

### `test_driver/integration_test.dart` — standard `integrationDriver()` entrypoint

### `integration_test/todo_app_test.dart`

Run via:
`flutter drive --driver=test_driver/integration_test.dart --target=integration_test/todo_app_test.dart`

| # | Scenario | Steps |
| --- | --- | --- |
| 1 | Add todo | Tap FAB → Add screen → enter title → tap Add → back on list → todo visible |
| 2 | Validation | On Add screen, tap Add with empty title → "Please enter a title" shown, stays on screen |
| 3 | Toggle complete | Tap checkbox → title gets strikethrough; tap again → reverts |
| 4 | Edit pre-fill | Popup menu → Edit → title/description pre-filled → modify → Update → list shows change |
| 5 | Delete flow | Popup menu → Delete → dialog shows title → Cancel keeps it → repeat → Delete removes it |
| 6 | Empty state | With no todos → "No todos yet" message shown |
| 7 | Settings navigation | Tap settings icon → Settings screen with 3 theme radios |
| 8 | Theme change | Select Dark → app rebuilds with dark theme |
| 9 | Persistence | Add todo + set Dark → restart app (re-run scenario) → todo and theme persist |

## Verification

- `dart analyze lib/ test/ integration_test/ test_driver/`
- `dart format lib/ test/ integration_test/ test_driver/`
- `flutter test`
- `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/todo_app_test.dart`
