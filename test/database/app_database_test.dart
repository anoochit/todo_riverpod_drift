import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_riverpod/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase CRUD', () {
    test('insertTodo returns id and allTodos returns it', () async {
      final id = await db.insertTodo(
        TodosCompanion.insert(
          title: 'Test todo',
          description: const Value('desc'),
        ),
      );

      expect(id, greaterThan(0));

      final todos = await db.allTodos();
      expect(todos, hasLength(1));
      expect(todos.first.id, id);
      expect(todos.first.title, 'Test todo');
      expect(todos.first.description, 'desc');
      expect(todos.first.isCompleted, isFalse);
    });

    test(
      'insertTodo applies defaults for isCompleted and timestamps',
      () async {
        final before = DateTime.now();
        final id = await db.insertTodo(
          TodosCompanion.insert(title: 'Defaults'),
        );
        final after = DateTime.now();

        final todo = await db.getTodoById(id);
        expect(todo.isCompleted, isFalse);
        expect(
          todo.createdAt.isBefore(before.subtract(const Duration(seconds: 1))),
          isFalse,
        );
        expect(
          todo.createdAt.isAfter(after.add(const Duration(seconds: 1))),
          isFalse,
        );
        expect(
          todo.updatedAt.isBefore(before.subtract(const Duration(seconds: 1))),
          isFalse,
        );
        expect(
          todo.updatedAt.isAfter(after.add(const Duration(seconds: 1))),
          isFalse,
        );
      },
    );

    test('getTodoById returns the row', () async {
      final id = await db.insertTodo(TodosCompanion.insert(title: 'Find me'));

      final todo = await db.getTodoById(id);
      expect(todo.id, id);
      expect(todo.title, 'Find me');
    });

    test('getTodoById throws for missing id', () async {
      expect(() => db.getTodoById(9999), throwsStateError);
    });

    test('updateTodo (replace) updates all columns', () async {
      final id = await db.insertTodo(
        TodosCompanion.insert(
          title: 'Old',
          description: const Value('old desc'),
        ),
      );
      final original = await db.getTodoById(id);

      final updated = original.copyWith(
        title: 'New',
        description: const Value('new desc'),
        isCompleted: true,
      );
      final result = await db.updateTodo(updated.toCompanion(false));
      expect(result, isTrue);

      final todo = await db.getTodoById(id);
      expect(todo.title, 'New');
      expect(todo.description, 'new desc');
      expect(todo.isCompleted, isTrue);
      expect(todo.id, original.id);
      expect(todo.createdAt, original.createdAt);
    });

    test('deleteTodo removes the row', () async {
      final id = await db.insertTodo(TodosCompanion.insert(title: 'Delete me'));
      expect(await db.allTodos(), hasLength(1));

      final deleted = await db.deleteTodo(id);
      expect(deleted, 1);
      expect(await db.allTodos(), isEmpty);
    });

    test('deleteTodo returns 0 for missing id', () async {
      final deleted = await db.deleteTodo(9999);
      expect(deleted, 0);
    });
  });

  group('AppDatabase streams', () {
    test('watchAllTodos emits on insert, update, and delete', () async {
      final events = <List<Todo>>[];
      final sub = db.watchAllTodos().listen(events.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      expect(events, hasLength(1));
      expect(events.first, isEmpty);

      final id = await db.insertTodo(TodosCompanion.insert(title: 'Streamed'));
      await pumpEventQueue();
      expect(events, hasLength(2));
      expect(events.last, hasLength(1));
      expect(events.last.first.title, 'Streamed');

      final current = await db.getTodoById(id);
      await db.updateTodo(
        current.copyWith(title: 'Updated').toCompanion(false),
      );
      await pumpEventQueue();
      expect(events, hasLength(3));
      expect(events.last.first.title, 'Updated');

      await db.deleteTodo(id);
      await pumpEventQueue();
      expect(events, hasLength(4));
      expect(events.last, isEmpty);
    });

    test('watchTodoById emits the matching row', () async {
      final id = await db.insertTodo(TodosCompanion.insert(title: 'Watch one'));

      final events = <Todo>[];
      final sub = db.watchTodoById(id).listen(events.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      expect(events, hasLength(1));
      expect(events.first.title, 'Watch one');
    });
  });

  group('title length constraints', () {
    test('rejects empty title', () async {
      await expectLater(
        db.insertTodo(TodosCompanion.insert(title: '')),
        throwsA(isA<InvalidDataException>()),
      );
    });

    test('rejects title longer than 200 characters', () async {
      final longTitle = 'a' * 201;
      await expectLater(
        db.insertTodo(TodosCompanion.insert(title: longTitle)),
        throwsA(isA<InvalidDataException>()),
      );
    });

    test('accepts title of exactly 200 characters', () async {
      final title = 'a' * 200;
      final id = await db.insertTodo(TodosCompanion.insert(title: title));
      final todo = await db.getTodoById(id);
      expect(todo.title.length, 200);
    });
  });
}
