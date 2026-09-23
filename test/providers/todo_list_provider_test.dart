import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_riverpod/database/app_database.dart';
import 'package:todo_riverpod/providers/database_provider.dart';
import 'package:todo_riverpod/providers/todo_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<List<Todo>>> sub;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    sub = container.listen(todoListProvider, (_, _) {});
  });

  tearDown(() async {
    sub.close();
    container.dispose();
    await db.close();
  });

  test('emits [] initially', () async {
    final initial = await container.read(todoListProvider.future);
    expect(initial, isEmpty);
    expect(sub.read().requireValue, isEmpty);
  });

  test('reflects inserts via the stream', () async {
    await container.read(todoListProvider.future);

    await container
        .read(todoActionsProvider)
        .addTodo(title: 'First', description: 'desc');
    await pumpEventQueue();

    final todos = sub.read().requireValue;
    expect(todos, hasLength(1));
    expect(todos.single.title, 'First');
    expect(todos.single.description, 'desc');
  });

  test('reflects toggleCompleted via the stream', () async {
    final actions = container.read(todoActionsProvider);
    await actions.addTodo(title: 'Toggle me');
    await container.read(todoListProvider.future);
    await pumpEventQueue();

    final id = sub.read().requireValue.single.id;
    await actions.toggleCompleted(id);
    await pumpEventQueue();

    expect(sub.read().requireValue.single.isCompleted, isTrue);
  });

  test('reflects deleteTodo via the stream', () async {
    final actions = container.read(todoActionsProvider);
    await actions.addTodo(title: 'Doomed');
    await container.read(todoListProvider.future);
    await pumpEventQueue();
    expect(sub.read().requireValue, hasLength(1));

    final id = sub.read().requireValue.single.id;
    await actions.deleteTodo(id);
    await pumpEventQueue();

    expect(sub.read().requireValue, isEmpty);
  });

  test('reflects multiple adds in order of emission', () async {
    final actions = container.read(todoActionsProvider);
    await container.read(todoListProvider.future);

    await actions.addTodo(title: 'A');
    await pumpEventQueue();
    await actions.addTodo(title: 'B');
    await pumpEventQueue();

    final titles = sub.read().requireValue.map((t) => t.title).toList();
    expect(titles, ['A', 'B']);
  });
}
