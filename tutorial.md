# Building a Todo App with Flutter, Riverpod, GoRouter, and Drift

A complete step-by-step tutorial to build a production-quality todo app with local SQLite persistence, declarative routing, state management, and theme switching.

---

## What You Will Build

A todo application with:

- **CRUD operations** — Create, read, update, and delete todos
- **Persistent storage** — SQLite database via Drift (survives app restarts)
- **Declarative routing** — GoRouter with named routes and path parameters
- **State management** — Riverpod with code generation
- **Theme switching** — Light / dark / system theme, persisted with SharedPreferences
- **Material 3** — Modern Material Design with dynamic color
- **Cross-platform** — Works on Android, iOS, Web, Windows, macOS, Linux

---

## Prerequisites

- Flutter SDK >= 3.13.3
- Dart SDK >= 3.13.3
- An editor (VS Code with Flutter extension, or Android Studio)

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── database/
│   ├── app_database.dart              # Drift table definitions & DB class
│   └── app_database.g.dart            # Generated Drift code
├── providers/
│   ├── database_provider.dart         # Riverpod provider for database
│   ├── database_provider.g.dart       # Generated code
│   ├── settings_provider.dart         # Theme mode persistence
│   ├── settings_provider.g.dart       # Generated code
│   └── todo_provider.dart             # Todo CRUD operations
├── router/
│   └── app_router.dart                # GoRouter configuration
├── screens/
│   ├── add_edit_todo_screen.dart      # Add/edit todo form
│   ├── settings_screen.dart           # Theme settings
│   └── todo_list_screen.dart          # Main todo list
└── widgets/
    └── todo_tile.dart                 # Individual todo item widget

web/
├── sqlite3.wasm                       # SQLite WebAssembly for web support
└── drift_worker.js                    # Drift web worker

analysis_options.yaml                  # Linter and analyzer config
build.yaml                             # Code generation config
```

---

## Step 1 — Create the Flutter Project

```bash
flutter create todo_riverpod
cd todo_riverpod
```

---

## Step 2 — Add Dependencies

Replace the contents of `pubspec.yaml` with:

```yaml
name: todo_riverpod
description: "A todo app with Riverpod, GoRouter, and Drift."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.13.3

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8

  # State management
  flutter_riverpod: ^3.4.3
  riverpod_annotation: ^4.0.7

  # Routing
  go_router: ^18.0.1

  # Local database
  drift: ^2.35.0
  drift_flutter: ^0.3.1

  # Theme persistence
  shared_preferences: ^2.5.3

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0

  # Code generation
  build_runner: ^2.15.1
  drift_dev: ^2.34.0
  riverpod_generator: ^4.0.4

flutter:
  uses-material-design: true
```

Then run:

```bash
flutter pub get
```

### What each package does

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | Reactive state management — providers replace setState, InheritedWidget, BLoC |
| `riverpod_annotation` | Annotations (`@riverpod`) for automatic code generation |
| `go_router` | Declarative URL-based routing — route table, path params, deep links |
| `drift` | Type-safe SQLite ORM — compile-time checked queries, reactive streams |
| `drift_flutter` | Flutter integration for Drift — handles platform-specific database connections |
| `shared_preferences` | Key-value storage — used to persist theme preference |
| `build_runner` | Runs code generators — produces `*.g.dart` files |
| `drift_dev` | Drift code generator — generates table classes, query builders, data classes |
| `riverpod_generator` | Riverpod code generator — generates provider classes from annotations |

---

## Step 3 — Configure Analysis Options

Create `analysis_options.yaml` at the project root:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**
    - "**/*.g.dart"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_assignment: warning
    missing_return: error
    dead_code: warning

linter:
  rules:
    always_declare_return_types: true
    avoid_dynamic_calls: true
    avoid_print: true
    avoid_unnecessary_containers: true
    collect_whitespace: false
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_locals: true
    prefer_is_empty: true
    require_trailing_commas: true
    use_super_parameters: true
    unnecessary_const: true
    unnecessary_lambdas: true
    sized_box_for_whitespace: true
    sort_child_properties_last: true

formatter:
  page_width: 80
  trailing_commas: automate
```

### Why strict mode?

- **`strict-casts: true`** — Prevents implicit downcasts from `dynamic` to specific types
- **`strict-inference: true`** — Forces explicit type annotations where inference is ambiguous
- **`strict-raw-types: true`** — Ensures generic types are always specified

---

## Step 4 — Configure Code Generation

Create `build.yaml` at the project root:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        enabled: true
      riverpod_generator:
        enabled: true
```

This tells `build_runner` to run both Drift and Riverpod generators.

---

## Step 5 — Define the Database Schema (Drift)

Create `lib/database/app_database.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Todos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'todo_database',
      native: const DriftNativeOptions(),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  Future<List<Todo>> allTodos() => select(todos).get();

  Stream<List<Todo>> watchAllTodos() => select(todos).watch();

  Future<Todo> getTodoById(int id) =>
      (select(todos)..where((t) => t.id.equals(id))).getSingle();

  Stream<Todo> watchTodoById(int id) =>
      (select(todos)..where((t) => t.id.equals(id))).watchSingle();

  Future<int> insertTodo(TodosCompanion todo) =>
      into(todos).insert(todo);

  Future<bool> updateTodo(TodosCompanion todo) =>
      update(todos).replace(todo);

  Future<int> deleteTodo(int id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();
}
```

### How Drift works

- **`Todos extends Table`** — Defines the table schema. Each column is declared with a type and constraints.
- **`part 'app_database.g.dart'`** — Links to the generated file. Never edit `.g.dart` files manually.
- **`_$AppDatabase`** — Generated base class containing table definitions, query builders, and data classes.
- **`_openConnection()`** — Returns a `QueryExecutor` — the database connection. Configured for both native (SQLite) and web (WASM + IndexedDB).

### Column types used

| Column | Dart Type | SQL Type | Notes |
|--------|-----------|----------|-------|
| `id` | `int` | INTEGER | Auto-increment primary key |
| `title` | `String` | TEXT | Required, 1–200 chars |
| `description` | `String?` | TEXT | Nullable |
| `isCompleted` | `bool` | BOOLEAN | Default: `false` |
| `createdAt` | `DateTime` | DATETIME | Default: server time |
| `updatedAt` | `DateTime` | DATETIME | Default: server time |

### Query patterns

- **`select(todos).get()`** — One-shot fetch, returns `Future<List<Todo>>`
- **`select(todos).watch()`** — Reactive stream, returns `Stream<List<Todo>>` that emits on any table change
- **`into(todos).insert(companion)`** — Insert a row
- **`update(todos).replace(companion)`** — Update a row by primary key
- **`update(todos)..where(...).write(companion)`** — Partial update (only specified columns)
- **`delete(todos)..where(...)`** — Delete matching rows

---

## Step 6 — Create the Database Provider

Create `lib/providers/database_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
}
```

### Key decisions

- **`@Riverpod(keepAlive: true)`** — The database is a singleton. Without `keepAlive`, Riverpod would dispose it when no widgets are watching it, which is wrong for a database connection.
- **`ref.onDispose(database.close)`** — Automatically closes the database when the provider is disposed (e.g., when the app shuts down).
- **Code generation** — `riverpod_generator` produces `appDatabaseProvider` in `database_provider.g.dart` with proper type safety and disposal tracking.

---

## Step 7 — Create the Todo Provider

Create `lib/providers/todo_provider.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

/// Streams the full list of todos.
/// UI watches this for real-time updates.
final todoListProvider = StreamProvider<List<Todo>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchAllTodos();
});

/// Encapsulates all todo CRUD operations.
class TodoActions {
  TodoActions(this._ref);

  final Ref _ref;

  AppDatabase get _database => _ref.read(appDatabaseProvider);

  Future<void> addTodo({
    required String title,
    String? description,
  }) async {
    await _database.insertTodo(
      TodosCompanion(
        title: Value(title),
        description: Value(description),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTodo({
    required int id,
    required String title,
    String? description,
  }) async {
    await (_database.update(_database.todos)
          ..where((t) => t.id.equals(id)))
        .write(
      TodosCompanion(
        title: Value(title),
        description: Value(description),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> toggleCompleted(int id) async {
    final todo = await _database.getTodoById(id);
    await (_database.update(_database.todos)
          ..where((t) => t.id.equals(id)))
        .write(
      TodosCompanion(
        isCompleted: Value(!todo.isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteTodo(int id) async {
    await _database.deleteTodo(id);
  }

  Future<Todo> todoById(int id) async {
    return _database.getTodoById(id);
  }
}

/// Provides access to all todo operations.
final todoActionsProvider = Provider<TodoActions>((ref) {
  return TodoActions(ref);
});
```

### Architecture decisions

**Why `StreamProvider` for reading?**

```dart
final todoListProvider = StreamProvider<List<Todo>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchAllTodos();
});
```

- `ref.watch(appDatabaseProvider)` — If the database changes, this provider rebuilds.
- `database.watchAllTodos()` — Returns a `Stream<List<Todo>>`. Drift automatically emits a new list whenever any row in the `Todos` table changes.
- The UI gets real-time updates without manually calling `setState` or `notifyListeners`.

**Why a plain class for writing?**

```dart
class TodoActions {
  TodoActions(this._ref);
  final Ref _ref;
  // ...
}
```

- `TodoActions` performs side effects (database writes) that don't need to be stored as state.
- The stream (`todoListProvider`) is the source of truth — when a write happens, the stream emits a new value, and the UI rebuilds.
- This avoids the complexity of `AsyncNotifier` or `StateNotifier` for simple CRUD operations.

**Why `write()` instead of `replace()` for updates?**

```dart
await (_database.update(_database.todos)
      ..where((t) => t.id.equals(id)))
    .write(
  TodosCompanion(
    isCompleted: Value(!todo.isCompleted),
    updatedAt: Value(DateTime.now()),
  ),
);
```

- `replace()` requires **all non-nullable columns** to be present in the `TodosCompanion`.
- `write()` only updates the columns you specify — much more efficient and less error-prone.

---

## Step 8 — Create the Settings Provider (with Persistence)

Create `lib/providers/settings_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

const _kThemeModeKey = 'theme_mode';

@riverpod
class ThemeModeState extends _$ThemeModeState {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final index = prefs.getInt(_kThemeModeKey) ?? ThemeMode.system.index;
    return ThemeMode.values[index];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_kThemeModeKey, mode.index);
    state = mode;
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
```

### How persistence works

1. **`sharedPreferencesProvider`** is a placeholder — it throws `UnimplementedError` if used directly. It gets **overridden** in `main.dart` with a real `SharedPreferences` instance after async initialization.
2. **`ThemeModeState.build()`** reads the saved theme index from `SharedPreferences` on startup.
3. **`setThemeMode()`** writes the new value to `SharedPreferences` **and** updates Riverpod state, so the UI rebuilds immediately.

### Why `ref.watch` vs `ref.read`?

- **`ref.watch(sharedPreferencesProvider)`** in `build()` — creates a dependency on the prefs provider. If prefs change, this notifier rebuilds.
- **`ref.read(sharedPreferencesProvider)`** in `setThemeMode()` — one-shot access for writing. We don't want a reactive dependency here.

---

## Step 9 — Set Up Routing (GoRouter)

Create `lib/router/app_router.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/todo_list_screen.dart';
import '../screens/add_edit_todo_screen.dart';
import '../screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'todoList',
        builder: (context, state) => const TodoListScreen(),
      ),
      GoRoute(
        path: '/add',
        name: 'addTodo',
        builder: (context, state) => const AddEditTodoScreen(),
      ),
      GoRoute(
        path: '/edit/:id',
        name: 'editTodo',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const TodoListScreen();
          }
          return AddEditTodoScreen(todoId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
```

### Route table

| Path | Name | Screen | Purpose |
|------|------|--------|---------|
| `/` | `todoList` | `TodoListScreen` | Home — list of all todos |
| `/add` | `addTodo` | `AddEditTodoScreen` | Create a new todo |
| `/edit/:id` | `editTodo` | `AddEditTodoScreen` | Edit existing todo (by ID) |
| `/settings` | `settings` | `SettingsScreen` | Theme preferences |

### Why `int.tryParse` instead of `int.parse`?

```dart
final id = int.tryParse(state.pathParameters['id'] ?? '');
if (id == null) {
  return const TodoListScreen();
}
```

- `int.parse` throws `FormatException` on invalid input (e.g., `/edit/abc`).
- `int.tryParse` returns `null` on invalid input — we redirect to the home screen gracefully.

### How navigation works

```dart
// Push a new route
context.push('/add');

// Push with a path parameter
context.push('/edit/${todo.id}');

// Pop back to previous route
context.pop();
```

---

## Step 10 — Create the Todo List Screen

Create `lib/screens/todo_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: todoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (todos) {
          if (todos.isEmpty) {
            return const Center(
              child: Text(
                'No todos yet.\nTap + to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: todos.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final todo = todos[index];
              final actions = ref.read(todoActionsProvider);
              return TodoTile(
                todo: todo,
                onToggle: () => actions.toggleCompleted(todo.id),
                onDelete: () => actions.deleteTodo(todo.id),
                onEdit: () => context.push('/edit/${todo.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### How async data is handled

```dart
final todoAsync = ref.watch(todoListProvider);

todoAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
  data: (todos) => ListView(...),
);
```

- `ref.watch(todoListProvider)` returns an `AsyncValue<List<Todo>>`.
- `.when()` handles the three possible states: loading, error, or data.
- When the database emits a new list (after any add/edit/delete), `todoAsync` updates and the UI rebuilds automatically.

### Why `ConsumerWidget`?

- `ConsumerWidget` gives access to `WidgetRef` in the `build` method.
- We need `ref.watch(todoListProvider)` to subscribe to the stream.
- We need `ref.read(todoActionsProvider)` to call CRUD operations.

---

## Step 11 — Create the Add/Edit Screen

Create `lib/screens/add_edit_todo_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/todo_provider.dart';

class AddEditTodoScreen extends ConsumerStatefulWidget {
  final int? todoId;

  const AddEditTodoScreen({super.key, this.todoId});

  bool get isEditing => todoId != null;

  @override
  ConsumerState<AddEditTodoScreen> createState() =>
      _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends ConsumerState<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadTodo();
    }
  }

  Future<void> _loadTodo() async {
    try {
      final todo =
          await ref.read(todoActionsProvider).todoById(widget.todoId!);
      _titleController.text = todo.title;
      _descriptionController.text = todo.description ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading todo: $e')),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final actions = ref.read(todoActionsProvider);

      if (widget.isEditing) {
        await actions.updateTodo(
          id: widget.todoId!,
          title: title,
          description: description.isEmpty ? null : description,
        );
      } else {
        await actions.addTodo(
          title: title,
          description: description.isEmpty ? null : description,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving todo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Todo' : 'Add Todo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter todo title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveTodo(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTodo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Key patterns

**`ConsumerStatefulWidget` vs `StatefulWidget`**

```dart
class AddEditTodoScreen extends ConsumerStatefulWidget {
// ...
class _AddEditTodoScreenState extends ConsumerState<AddEditTodoScreen> {
```

- We need `ConsumerStatefulWidget` because we use `ref` in `initState` (to load the todo) and in `_saveTodo`.
- Regular `StatefulWidget` doesn't have access to `ref`.

**`mounted` checks before async operations**

```dart
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
  context.pop();
}
```

- After an `await`, the widget may have been disposed (e.g., user navigated away).
- Calling `context.pop()` or `ScaffoldMessenger.of(context)` on a disposed widget throws.
- Always check `mounted` before using `context` after async gaps.

**Form validation**

```dart
TextFormField(
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title';
    }
    return null;
  },
);
```

- `TextFormField` validates on submit and when `FormState.validate()` is called.
- Return `null` for valid input, or an error message string.

---

## Step 12 — Create the Settings Screen

Create `lib/screens/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (mode) {
              if (mode != null) {
                ref
                    .read(themeModeStateProvider.notifier)
                    .setThemeMode(mode);
              }
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('System Default'),
                  subtitle: Text('Follow system theme'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Light'),
                  subtitle: Text('Always use light theme'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Dark'),
                  subtitle: Text('Always use dark theme'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
```

### How theme switching works

```dart
RadioGroup<ThemeMode>(
  groupValue: themeMode,
  onChanged: (mode) {
    if (mode != null) {
      ref.read(themeModeStateProvider.notifier).setThemeMode(mode);
    }
  },
);
```

1. User taps a radio button.
2. `setThemeMode(mode)` is called on the notifier.
3. The notifier writes the new index to `SharedPreferences`.
4. The notifier updates `state = mode`.
5. `main.dart` watches `themeModeStateProvider` and passes the value to `MaterialApp.router(themeMode: ...)`.
6. The app rebuilds with the new theme.

---

## Step 13 — Create the Todo Tile Widget

Create `lib/widgets/todo_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../database/app_database.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: todo.isCompleted,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration:
              todo.isCompleted ? TextDecoration.lineThrough : null,
          color: todo.isCompleted ? Colors.grey : null,
        ),
      ),
      subtitle: todo.description != null &&
              todo.description!.isNotEmpty
          ? Text(
              todo.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    todo.isCompleted ? Colors.grey : Colors.grey[600],
              ),
            )
          : null,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            onEdit();
          } else if (value == 'delete') {
            _confirmDelete(context);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(
              value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text(
          'Are you sure you want to delete "${todo.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
```

### Design decisions

- **StatelessWidget** — `TodoTile` has no internal state. All data comes from `todo`, all actions go through callbacks. Easy to test, easy to reuse.
- **Strikethrough style** — completed todos get `TextDecoration.lineThrough` and grey color.
- **Delete confirmation** — prevents accidental deletions with an `AlertDialog`.
- **`showDialog<void>`** — explicit type argument satisfies strict analysis.

---

## Step 14 — Wire Everything Together (main.dart)

Replace `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/settings_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Defer plugin initialization until after the first frame
  // to avoid the "lifecycle channel discarded" warning.
  await Future<void>.delayed(Duration.zero);
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TodoApp(),
    ),
  );
}

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeStateProvider);

    return MaterialApp.router(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: router,
    );
  }
}
```

### Startup sequence

```
main() async
  │
  ├─ WidgetsFlutterBinding.ensureInitialized()
  │     Required before calling async code in main()
  │
  ├─ await Future.delayed(Duration.zero)
  │     Defers to next microtask, gives framework time to
  │     register lifecycle listeners (avoids channel warning)
  │
  ├─ SharedPreferences.getInstance()
  │     Initializes local key-value storage
  │
  ├─ ProviderScope(overrides: [...])
  │     Injects real SharedPreferences into the Riverpod tree,
  │     replacing the placeholder that throws UnimplementedError
  │
  └─ TodoApp
       ├─ ref.watch(routerProvider) → GoRouter instance
       └─ ref.watch(themeModeStateProvider) → ThemeMode
            └─ MaterialApp.router(themeMode: ...)
```

---

## Step 15 — Set Up Web Support (WASM Files)

Drift requires WebAssembly files to run on web. Copy them from the drift package cache:

```bash
# From the project root
copy "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\drift-2.35.0\extension\devtools\build\sqlite3.wasm" web\sqlite3.wasm
copy "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\drift-2.35.0\drift_worker.js" web\drift_worker.js
```

Or on macOS/Linux:

```bash
cp ~/.pub-cache/hosted/pub.dev/drift-2.35.0/extension/devtools/build/sqlite3.wasm web/sqlite3.wasm
cp ~/.pub-cache/hosted/pub.dev/drift-2.35.0/drift_worker.js web/drift_worker.js
```

### What these files do

| File | Purpose |
|------|---------|
| `sqlite3.wasm` | Compiled SQLite running in WebAssembly — browser-native SQL engine |
| `drift_worker.js` | Web Worker that runs database operations off the main thread |

---

## Step 16 — Run Code Generation

Both Drift and Riverpod require generated code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates the `*.g.dart` files:

| File | Generator | Contents |
|------|-----------|----------|
| `app_database.g.dart` | `drift_dev` | Table classes, query builders, `Todo` data class, `TodosCompanion` |
| `database_provider.g.dart` | `riverpod_generator` | `appDatabaseProvider` with `keepAlive` |
| `settings_provider.g.dart` | `riverpod_generator` | `themeModeStateProvider` notifier class |

Run this command again whenever you modify a file that uses `part '*.g.dart'` or `@riverpod` annotations.

---

## Step 17 — Run the App

```bash
# Mobile/desktop
flutter run

# Web
flutter run -d chrome
```

### Features to test

| # | Action | Expected Result |
|---|--------|-----------------|
| 1 | Tap the FAB (+) | Navigates to Add Todo screen |
| 2 | Enter title, tap "Add" | Todo appears in the list |
| 3 | Tap checkbox | Todo gets strikethrough, isCompleted toggles |
| 4 | Tap three-dot menu → Edit | Navigates to Edit screen with pre-filled fields |
| 5 | Tap three-dot menu → Delete | Confirmation dialog appears |
| 6 | Confirm delete | Todo is removed from the list |
| 7 | Tap settings icon | Navigates to Settings screen |
| 8 | Select Light/Dark theme | App theme changes immediately |
| 9 | Kill and restart the app | All todos and theme preference survive |

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────┐
│                     UI Layer                         │
│                                                     │
│  TodoListScreen    AddEditTodoScreen    SettingsScreen│
│  (ConsumerWidget)  (ConsumerStatefulW) (ConsumerW)  │
│         │                  │                 │       │
│         └──────────────────┼─────────────────┘       │
│                            │                         │
│                      TodoTile                        │
│                    (StatelessWidget)                  │
└────────────────────┬────────────────────────────────┘
                     │ watches / reads
┌────────────────────▼────────────────────────────────┐
│                  Providers Layer                     │
│                                                     │
│  todoListProvider ──StreamProvider<List<Todo>>       │
│       │                                              │
│  todoActionsProvider ──Provider<TodoActions>         │
│       │                                              │
│  themeModeStateProvider ──Notifier<ThemeMode>        │
│       │                                              │
│  appDatabaseProvider ──Provider<AppDatabase>         │
│       │              (keepAlive: true)               │
└───────┬─────────────────────────────────────────────┘
        │ delegates to
┌───────▼─────────────────────────────────────────────┐
│                   Data Layer                         │
│                                                     │
│  AppDatabase (Drift)                                 │
│    └─ Todos table (SQLite / WASM on web)             │
│                                                     │
│  SharedPreferences                                  │
│    └─ theme_mode key (int index)                     │
└─────────────────────────────────────────────────────┘
```

### Data flow: Adding a todo

```
User taps FAB
  → context.push('/add')
  → AddEditTodoScreen builds
  → User fills form, taps "Add"
  → _saveTodo() called
  → ref.read(todoActionsProvider).addTodo(...)
  → TodoActions.addTodo()
  → _database.insertTodo(TodosCompanion(...))
  → Drift inserts row into SQLite
  → database.watchAllTodos() stream emits new list
  → todoListProvider updates
  → TodoListScreen rebuilds with new todo
```

### Data flow: Toggling completion

```
User taps checkbox
  → onToggle callback fired
  → actions.toggleCompleted(todo.id)
  → TodoActions.toggleCompleted()
  → _database.getTodoById(id)  // fetch current isCompleted
  → _database.update(...).write(TodosCompanion(isCompleted: !todo.isCompleted))
  → Drift updates the row
  → database.watchAllTodos() stream emits new list
  → todoListProvider updates
  → TodoListScreen rebuilds
  → TodoTile shows strikethrough style
```

---

## Troubleshooting

### "Could not find generated file"

Run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### "A message on the flutter/lifecycle channel was discarded"

This happens when `SharedPreferences` initializes before the framework is ready. The fix is already in `main.dart`:

```dart
await Future<void>.delayed(Duration.zero);
final prefs = await SharedPreferences.getInstance();
```

`Duration.zero` defers initialization to the next microtask, giving the framework time to register its lifecycle listener.

### "When compiling to the web, the 'web' parameter needs to be set"

Drift needs WASM files for web support. See [Step 15](#step-15--set-up-web-support-wasm-files).

### "TodosCompanion cannot be used for that because title: This value was required, but isn't present"

This happens when using `replace()` with incomplete data. Use `write()` instead for partial updates:

```dart
// WRONG — replace() requires all non-nullable columns
await _database.updateTodo(
  TodosCompanion(
    id: Value(id),
    isCompleted: Value(!todo.isCompleted),
  ),
);

// CORRECT — write() only updates specified columns
await (_database.update(_database.todos)
      ..where((t) => t.id.equals(id)))
    .write(
  TodosCompanion(
    isCompleted: Value(!todo.isCompleted),
  ),
);
```

### Theme not persisting

Ensure `SharedPreferences` is initialized **before** `runApp` and injected via `ProviderScope`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future<void>.delayed(Duration.zero);
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const TodoApp(),
  ));
}
```

### Database not resetting after schema change

Bump `schemaVersion` in `AppDatabase` and add a migration:

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from == 1 && to == 2) {
      await m.addColumn(todos, todos.priority);
    }
  },
);
```

---

## Next Steps

| Feature | How to implement |
|---------|------------------|
| **Categories/tags** | Add a `TextColumn get category => text()()` to `Todos` table, filter with `where((t) => t.category.equals(...))` |
| **Search** | Add a `StreamProvider` with a query string parameter, use Drift's `like()` for partial matching |
| **Due dates** | Add `DateTimeColumn get dueDate => dateTime().nullable()()`, sort with `orderBy([(t) => OrderingTerm.asc(t.dueDate)])` |
| **Drag-to-reorder** | Add `IntColumn get sortIndex => integer().withDefault(const Constant(0))()`, use `ReorderableListView` |
| **Priority levels** | Create an `IntColumn get priority => integer().withDefault(const Constant(0))()`, filter/sort by priority |
| **Unit tests** | Test `TodoActions` methods with an in-memory database, test widgets with `MockAppDatabase` |
| **Animations** | Use `AnimatedList` for smooth add/remove transitions, `Hero` for shared element transitions |
