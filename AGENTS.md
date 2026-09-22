# AGENTS.md

Instructions for AI agents working on this codebase.

## Commands

```bash
# Static analysis (run after every change)
dart analyze lib/

# Format code (run after every change)
dart format lib/

# Regenerate code (run after modifying any file with part '*.g.dart' or @riverpod)
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Run the app
flutter run
```

## Code Generation

This project uses code generation for Drift and Riverpod. After editing any file with `part '*.g.dart'` or `@riverpod`/`@Riverpod` annotations, you must regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files (never edit manually):

- `lib/database/app_database.g.dart`
- `lib/providers/database_provider.g.dart`
- `lib/providers/settings_provider.g.dart`

## Architecture

### Layers

| Layer | Location | Responsibility |
| ------- | ---------- | ---------------- |
| UI | `lib/screens/`, `lib/widgets/` | Widgets, layout, user interaction |
| Providers | `lib/providers/` | State management, business logic |
| Data | `lib/database/`, `lib/providers/database_provider.dart` | Database, persistence |

### Provider Conventions

- **Stream-based reading**: Use `StreamProvider` for reactive data (e.g., `todoListProvider`)
- **Class-based operations**: Use a plain class with `Provider` for side effects (e.g., `TodoActions` via `todoActionsProvider`)
- **Notifier for state**: Use `@riverpod` class-based notifier for persistent state (e.g., `ThemeModeState`)
- **Singleton database**: Use `@Riverpod(keepAlive: true)` for the database provider

### Database Conventions

- Use `write()` for partial updates (only specified columns)
- Use `replace()` only when updating ALL non-nullable columns
- Always use `int.tryParse` instead of `int.parse` for path parameters
- Schema changes require bumping `schemaVersion` in `AppDatabase`

### UI Conventions

- Use `ConsumerWidget` for stateless screens that read providers
- Use `ConsumerStatefulWidget` for screens that need `ref` in `initState` or async methods
- Check `mounted` before using `context` after any `await`
- Use `showDialog<void>` with explicit type argument (strict analysis)

## Dependencies

| Package | Purpose |
| --------- | --------- |
| `flutter_riverpod` | State management |
| `riverpod_annotation` | Riverpod code generation |
| `go_router` | Declarative routing |
| `drift` | Type-safe SQLite ORM |
| `drift_flutter` | Flutter integration for Drift |
| `shared_preferences` | Key-value persistence (theme) |

## Testing

- Run `flutter test` to execute all tests
- Tests are in `test/` directory
- Test database operations with in-memory Drift databases
- Test widgets using `WidgetTester` with mocked providers

## Known Patterns

- `Duration.zero` delay in `main()` prevents "lifecycle channel discarded" warning
- `sharedPreferencesProvider` is overridden in `main.dart` with real instance
- `DriftWebOptions` and `DriftNativeOptions` are both required for cross-platform Drift
- WASM files (`sqlite3.wasm`, `drift_worker.js`) must be in `web/` for web support
