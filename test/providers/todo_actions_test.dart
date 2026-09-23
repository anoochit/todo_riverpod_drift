import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_riverpod/database/app_database.dart';
import 'package:todo_riverpod/providers/database_provider.dart';
import 'package:todo_riverpod/providers/todo_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late TodoActions actions;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    actions = container.read(todoActionsProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('addTodo', () {
    test('inserts with isCompleted=false and timestamps', () async {
      final before = DateTime.now();

      await actions.addTodo(title: 'Buy milk', description: '2% only');

      final todos = await db.allTodos();
      expect(todos, hasLength(1));

      final todo = todos.first;
      expect(todo.title, 'Buy milk');
      expect(todo.description, '2% only');
      expect(todo.isCompleted, isFalse);
      expect(
        todo.createdAt.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );
      expect(
        todo.createdAt.isAfter(DateTime.now().add(const Duration(seconds: 1))),
        isFalse,
      );
    });

    test('inserts with null description when omitted', () async {
      await actions.addTodo(title: 'No desc');

      final todo = (await db.allTodos()).first;
      expect(todo.description, isNull);
    });
  });

  group('updateTodo', () {
    test('preserves isCompleted and createdAt, bumps updatedAt', () async {
      final originalCreatedAt = DateTime(2020, 1, 1);
      final originalUpdatedAt = DateTime(2020, 1, 1);
      final id = await db.insertTodo(
        TodosCompanion.insert(
          title: 'Original',
          isCompleted: const Value(true),
          createdAt: Value(originalCreatedAt),
          updatedAt: Value(originalUpdatedAt),
        ),
      );

      await actions.updateTodo(
        id: id,
        title: 'Renamed',
        description: 'now has desc',
      );

      final todo = await db.getTodoById(id);
      expect(todo.title, 'Renamed');
      expect(todo.description, 'now has desc');
      expect(todo.isCompleted, isTrue, reason: 'isCompleted must be preserved');
      expect(
        todo.createdAt,
        originalCreatedAt,
        reason: 'createdAt must be preserved',
      );
      expect(
        todo.updatedAt.isAfter(originalUpdatedAt),
        isTrue,
        reason: 'updatedAt must be bumped',
      );
    });

    test('clears description when null is passed', () async {
      final id = await db.insertTodo(
        TodosCompanion.insert(
          title: 'Has desc',
          description: const Value('temp'),
        ),
      );

      await actions.updateTodo(id: id, title: 'Has desc', description: null);

      final todo = await db.getTodoById(id);
      expect(todo.description, isNull);
    });
  });

  group('toggleCompleted', () {
    test('inverts false → true → false', () async {
      final id = await db.insertTodo(TodosCompanion.insert(title: 'Toggle'));
      expect((await db.getTodoById(id)).isCompleted, isFalse);

      await actions.toggleCompleted(id);
      expect((await db.getTodoById(id)).isCompleted, isTrue);

      await actions.toggleCompleted(id);
      expect((await db.getTodoById(id)).isCompleted, isFalse);
    });

    test('bumps updatedAt', () async {
      final originalUpdatedAt = DateTime(2020, 1, 1);
      final id = await db.insertTodo(
        TodosCompanion.insert(
          title: 'Stamp',
          updatedAt: Value(originalUpdatedAt),
        ),
      );

      await actions.toggleCompleted(id);

      final todo = await db.getTodoById(id);
      expect(todo.updatedAt.isAfter(originalUpdatedAt), isTrue);
    });

    test('throws for missing id', () async {
      expect(() => actions.toggleCompleted(9999), throwsStateError);
    });
  });

  group('deleteTodo', () {
    test('removes the row', () async {
      final id = await db.insertTodo(TodosCompanion.insert(title: 'Bye'));

      await actions.deleteTodo(id);

      expect(await db.allTodos(), isEmpty);
    });

    test('is idempotent for missing id', () async {
      await actions.deleteTodo(9999);
      expect(await db.allTodos(), isEmpty);
    });
  });

  group('todoById', () {
    test('returns the row', () async {
      final id = await db.insertTodo(TodosCompanion.insert(title: 'Look up'));

      final todo = await actions.todoById(id);
      expect(todo.id, id);
      expect(todo.title, 'Look up');
    });

    test('throws for missing id', () async {
      expect(() => actions.todoById(9999), throwsStateError);
    });
  });
}
