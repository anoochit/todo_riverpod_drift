import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Todos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

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

  Future<int> insertTodo(TodosCompanion todo) => into(todos).insert(todo);

  Future<bool> updateTodo(TodosCompanion todo) => update(todos).replace(todo);

  Future<int> deleteTodo(int id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();
}
