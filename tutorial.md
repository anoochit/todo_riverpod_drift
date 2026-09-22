# Building a Todo App with Flutter, Riverpod, GoRouter, and Drift

A complete step-by-step tutorial to build a production-quality todo app with local
SQLite persistence, declarative routing, and theme switching.

---

## What You Will Build

A todo application with:

- **CRUD operations** — Create, read, update, and delete todos
- **Persistent storage** — SQLite database via Drift (survives app restarts)
- **Declarative routing** — GoRouter with named routes and path parameters
- **State management** — Riverpod with code generation
- **Theme switching** — Light / dark / system theme, persisted with SharedPreferences
- **Material 3** — Modern Material Design with dynamic color

---

## Prerequisites

- Flutter SDK >= 3.13.3
- Dart SDK >= 3.13.3
- An editor (VS Code with Flutter extension, or Android Studio)

---

## Project Structure

```
lib/
├── main.dart
├── database/
│   ├── app_database.dart
│   └── app_database.g.dart          (generated)
├── providers/
│   ├── database_provider.dart
│   ├── database_provider.g.dart     (generated)
│   ├── settings_provider.dart
│   ├── settings_provider.g.dart     (generated)
│   └── todo_provider.dart
├── router/
│   └── app_router.dart
├── screens/
│   ├── add_edit_todo_screen.dart
│   ├── settings_screen.dart
│   └── todo_list_screen.dart
└── widgets/
    └── todo_tile.dart
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
| `flutter_riverpod` | Reactive state management |
| `riverpod_annotation` | Annotations for Riverpod code generation |
| `go_router` | Declarative URL-based routing |
| `drift` | Type-safe SQLite ORM for Dart |
| `drift_flutter` | Flutter integration for Drift |
| `shared_preferences` | Key-value storage for persisting settings |
| `build_runner` | Runs code generators |
| `drift_dev` | Drift code generator |
| `riverpod_generator` | Riverpod code generator |

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

This enables strict type checking, recommended lint rules, and auto-trailing-commas.

---

## Step 4 — Define the Database (Drift)

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
    return driftDatabase(name: 'todo_database');
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

### How this works

- **`Todos`** defines the table schema — columns, types, defaults, and constraints.
- **`_$AppDatabase`** is generated by `drift_dev` into `app_database.g.dart`.
- **CRUD methods** use Drift's type-safe query builder:
  - `select(todos).watch()` returns a `Stream<List<Todo>>` that auto-updates on data changes.
  - `into(todos).insert(todo)` inserts a row.
  - `update(todos).replace(todo)` updates a row by primary key.
  - `delete(todos)..where(...)` deletes matching rows.

---

## Step 5 — Create the Database Provider

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

### Key points

- `@Riverpod(keepAlive: true)` — The database is a singleton that lives for the app's lifetime.
- `ref.onDispose(database.close)` — Automatically closes the database connection when the provider is disposed.

---

## Step 6 — Create the Todo Provider

Create `lib/providers/todo_provider.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

/// Streams the full list of todos. UI watches this for real-time updates.
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
    await _database.updateTodo(
      TodosCompanion(
        id: Value(id),
        title: Value(title),
        description: Value(description),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> toggleCompleted(int id) async {
    final todo = await _database.getTodoById(id);
    await _database.updateTodo(
      TodosCompanion(
        id: Value(id),
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

- **`todoListProvider`** is a `StreamProvider` — the UI gets real-time updates whenever the database changes.
- **`TodoActions`** is a plain class, not a Notifier — it performs side effects (writes) that don't need to be stored as state. The stream (`todoListProvider`) is the source of truth for the list.
- **`ref.read()`** (not `ref.watch()`) is used inside `TodoActions` — we only need the database instance once per operation, not a reactive dependency.

---

## Step 7 — Create the Settings Provider (with Persistence)

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

- `sharedPreferencesProvider` is a placeholder provider — it gets **overridden** in `main.dart` with a real `SharedPreferences` instance after async initialization.
- `ThemeModeState.build()` reads the saved theme index from `SharedPreferences` on startup.
- `setThemeMode()` writes the new value to `SharedPreferences` **and** updates Riverpod state, so the UI rebuilds immediately.

---

## Step 8 — Set Up Routing (GoRouter)

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

| Path | Name | Screen | Notes |
|------|------|--------|-------|
| `/` | `todoList` | `TodoListScreen` | Home — list of all todos |
| `/add` | `addTodo` | `AddEditTodoScreen` | Create a new todo |
| `/edit/:id` | `editTodo` | `AddEditTodoScreen` | Edit existing todo (by ID) |
| `/settings` | `settings` | `SettingsScreen` | Theme preferences |

### Safety

`int.tryParse` is used instead of `int.parse` to prevent crashes if a user navigates to `/edit/abc` with a non-numeric ID — it gracefully redirects to the home screen.

---

## Step 9 — Create the Todo List Screen

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

### How it works

- `ref.watch(todoListProvider)` subscribes to the stream — the list rebuilds automatically when any todo is added, updated, or deleted.
- `todoAsync.when(...)` handles the three async states: loading, error, and data.
- Each `TodoTile` receives callbacks — the screen owns the business logic, the tile is purely visual.

---

## Step 10 — Create the Add/Edit Screen

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

- **`ConsumerStatefulWidget`** — needed because we use `ref` in `initState` (to load the todo) and in `_saveTodo`.
- **`mounted` checks** — before calling `context.pop()` or `ScaffoldMessenger`, we verify the widget is still in the tree to avoid runtime errors.
- **Form validation** — `TextFormField.validator` ensures the title is not empty.
- **Loading state** — `_isLoading` disables the button and shows a spinner while saving.

---

## Step 11 — Create the Settings Screen

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

### How it works

- `RadioGroup<ThemeMode>` is a Material 3 widget that manages radio button state.
- When the user selects a theme, `ref.read(themeModeStateProvider.notifier).setThemeMode(mode)` persists it to `SharedPreferences` and updates the Riverpod state.
- `main.dart` watches `themeModeStateProvider` and passes the value to `MaterialApp.router(themeMode: ...)`.

---

## Step 12 — Create the Todo Tile Widget

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

- **StatelessWidget** — `TodoTile` has no internal state. All data comes from the `todo` parameter, and all actions go through callbacks. This makes it easy to test and reuse.
- **Strikethrough style** — completed todos get `TextDecoration.lineThrough` and grey color.
- **Delete confirmation** — a dialog prevents accidental deletions.

---

## Step 13 — Wire Everything Together (main.dart)

Replace `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/settings_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

### What happens at startup

1. `WidgetsFlutterBinding.ensureInitialized()` — required before calling async code in `main()`.
2. `SharedPreferences.getInstance()` — initializes the local storage.
3. `ProviderScope(overrides: [...])` — injects the real `SharedPreferences` instance into the Riverpod tree, replacing the placeholder.
4. `TodoApp` watches `routerProvider` and `themeModeStateProvider` — the app rebuilds when the theme changes.

---

## Step 14 — Run Code Generation

Both Drift and Riverpod require generated code. Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates the `*.g.dart` files:

- `app_database.g.dart` — Drift table classes, query builders, and data classes
- `database_provider.g.dart` — Riverpod provider for the database
- `settings_provider.g.dart` — Riverpod notifier for theme mode

Run this command again whenever you modify a file that uses `part '*.g.dart'` or `@riverpod` / `@Riverpod` annotations.

---

## Step 15 — Run the App

```bash
flutter run
```

### Features to test

1. **Add a todo** — tap the FAB, enter a title, tap "Add"
2. **Toggle completion** — tap the checkbox on any todo
3. **Edit a todo** — tap the three-dot menu, select "Edit"
4. **Delete a todo** — tap the three-dot menu, select "Delete", confirm
5. **Theme switching** — tap the settings icon, choose System/Light/Dark
6. **Persistence** — kill and restart the app — todos and theme preference survive

---

## Architecture Summary

```
┌─────────────────────────────────────────────┐
│                   UI Layer                   │
│  TodoListScreen, AddEditTodoScreen,         │
│  SettingsScreen, TodoTile                   │
│  (ConsumerWidget / ConsumerStatefulWidget)  │
└──────────────────┬──────────────────────────┘
                   │ watches / reads
┌──────────────────▼──────────────────────────┐
│              Providers Layer                 │
│  todoListProvider (StreamProvider)           │
│  todoActionsProvider (Provider<TodoActions>) │
│  themeModeStateProvider (Notifier)           │
│  appDatabaseProvider (keepAlive)             │
└──────────────────┬──────────────────────────┘
                   │ delegates to
┌──────────────────▼──────────────────────────┐
│               Data Layer                     │
│  AppDatabase (Drift)                         │
│  SharedPreferences (theme persistence)      │
└─────────────────────────────────────────────┘
```

### Data flow

- **Reading**: UI watches `todoListProvider` → streams from `AppDatabase.watchAllTodos()` → rebuilds on any DB change.
- **Writing**: UI calls `ref.read(todoActionsProvider).addTodo(...)` → `AppDatabase.insertTodo(...)` → Drift emits new value on the stream → UI rebuilds.
- **Theme**: UI calls `ref.read(themeModeStateProvider.notifier).setThemeMode(...)` → writes to `SharedPreferences` → updates Riverpod state → `MaterialApp.router` rebuilds with new theme.

---

## Troubleshooting

### "Could not find generated file"

Run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### "The method 'int.parse' threw an exception"

This was fixed with `int.tryParse`. If you see this in your own routes, always use `int.tryParse` and handle the `null` case.

### Database not resetting after schema change

Bump `schemaVersion` in `AppDatabase` and add a migration strategy:

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    // Write migration logic here
  },
);
```

### Theme not persisting

Ensure `SharedPreferences` is initialized **before** `runApp`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const TodoApp(),
  ));
}
```

---

## Next Steps

- **Add categories/tags** — extend the `Todos` table with a `category` column
- **Add search/filter** — use Drift's `where` clauses with a search query provider
- **Add due dates** — add a `DateTimeColumn` and sort by deadline
- **Add drag-to-reorder** — use `ReorderableListView` with an `order` column
- **Write tests** — test `TodoActions`, the database CRUD, and widget rendering
- **Add animations** — use `AnimatedList` for smooth add/remove transitions
