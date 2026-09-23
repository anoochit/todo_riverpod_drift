import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

final todoListProvider = StreamProvider<List<Todo>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchAllTodos();
});

class TodoActions {
  TodoActions(this._ref);

  final Ref _ref;

  AppDatabase get _database => _ref.read(appDatabaseProvider);

  Future<void> addTodo({required String title, String? description}) async {
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
    await (_database.update(
      _database.todos,
    )..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        title: Value(title),
        description: Value(description),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> toggleCompleted(int id) async {
    final todo = await _database.getTodoById(id);
    await (_database.update(
      _database.todos,
    )..where((t) => t.id.equals(id))).write(
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

final todoActionsProvider = Provider<TodoActions>((ref) {
  return TodoActions(ref);
});
