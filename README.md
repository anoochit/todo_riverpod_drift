# Todo App — Riverpod, GoRouter, Drift

A Flutter todo application with local SQLite persistence, declarative routing, and theme switching.

## Features

- **CRUD operations** — Create, read, update, and delete todos
- **Persistent storage** — SQLite database via Drift (survives app restarts)
- **Declarative routing** — GoRouter with named routes and path parameters
- **State management** — Riverpod with code generation
- **Theme switching** — Light / dark / system theme, persisted with SharedPreferences
- **Material 3** — Modern Material Design with dynamic color
- **Cross-platform** — Android, iOS, Web, Windows, macOS, Linux

## Tech Stack

| Layer | Package | Version |
|-------|---------|---------|
| State | `flutter_riverpod` | ^3.4.3 |
| State (codegen) | `riverpod_annotation` | ^4.0.7 |
| Routing | `go_router` | ^18.0.1 |
| Database | `drift` | ^2.35.0 |
| DB (Flutter) | `drift_flutter` | ^0.3.1 |
| Persistence | `shared_preferences` | ^2.5.3 |

## Getting Started

### Prerequisites

- Flutter SDK >= 3.13.3
- Dart SDK >= 3.13.3

### Setup

```bash
# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Copy WASM files for web support
copy "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\drift-2.35.0\extension\devtools\build\sqlite3.wasm" web\sqlite3.wasm
copy "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\drift-2.35.0\drift_worker.js" web\drift_worker.js

# Run the app
flutter run
```

### Available Commands

| Command | Description |
|---------|-------------|
| `flutter run` | Run on connected device |
| `flutter run -d chrome` | Run on web |
| `dart run build_runner build --delete-conflicting-outputs` | Regenerate code |
| `dart analyze lib/` | Static analysis |
| `dart format lib/` | Format code |
| `flutter test` | Run tests |

## Project Structure

```
lib/
├── main.dart                          # Entry point
├── database/
│   └── app_database.dart              # Drift schema + queries
├── providers/
│   ├── database_provider.dart         # Database singleton provider
│   ├── settings_provider.dart         # Theme persistence
│   └── todo_provider.dart             # Todo CRUD operations
├── router/
│   └── app_router.dart                # GoRouter route table
├── screens/
│   ├── add_edit_todo_screen.dart      # Add/edit form
│   ├── settings_screen.dart           # Theme settings
│   └── todo_list_screen.dart          # Main list view
└── widgets/
    └── todo_tile.dart                 # Todo list item
```

## Architecture

```
UI Layer (ConsumerWidget / ConsumerStatefulWidget)
    │ watches / reads
Providers Layer (StreamProvider, Provider, Notifier)
    │ delegates to
Data Layer (AppDatabase via Drift, SharedPreferences)
```

- **Reading**: UI watches `todoListProvider` → streams from `AppDatabase.watchAllTodos()` → rebuilds on DB changes
- **Writing**: UI calls `ref.read(todoActionsProvider).addTodo(...)` → Drift inserts row → stream emits new list → UI rebuilds
- **Theme**: UI calls `setThemeMode()` → writes to SharedPreferences → updates Riverpod state → MaterialApp rebuilds

## Documentation

- [tutorial.md](tutorial.md) — Full step-by-step build tutorial
