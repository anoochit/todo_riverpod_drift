import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todo_riverpod/database/app_database.dart';
import 'package:todo_riverpod/main.dart';
import 'package:todo_riverpod/providers/database_provider.dart';
import 'package:todo_riverpod/providers/settings_provider.dart';
import 'package:todo_riverpod/router/app_router.dart';
import 'package:todo_riverpod/screens/add_edit_todo_screen.dart';
import 'package:todo_riverpod/screens/settings_screen.dart';
import 'package:todo_riverpod/screens/todo_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TodoApp()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> navigate(WidgetTester tester, String location) async {
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  group('router routes', () {
    testWidgets('initial location / shows TodoListScreen', (tester) async {
      await pumpApp(tester);

      expect(find.byType(TodoListScreen), findsOneWidget);
      expect(find.byType(AddEditTodoScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('/add shows AddEditTodoScreen in add mode', (tester) async {
      await pumpApp(tester);
      await navigate(tester, '/add');

      expect(find.byType(AddEditTodoScreen), findsOneWidget);
      expect(find.text('Add Todo'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Add'), findsOneWidget);
    });

    testWidgets('/edit/:id with valid id shows Edit Todo with prefilled data', (
      tester,
    ) async {
      final id = await db.insertTodo(
        TodosCompanion.insert(
          title: 'Existing',
          description: const Value('Existing desc'),
        ),
      );

      await pumpApp(tester);
      await navigate(tester, '/edit/$id');

      expect(find.byType(AddEditTodoScreen), findsOneWidget);
      expect(find.text('Edit Todo'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Update'), findsOneWidget);
      expect(find.text('Existing'), findsOneWidget);
      expect(find.text('Existing desc'), findsOneWidget);
      expect(find.byType(TodoListScreen), findsNothing);
    });

    testWidgets('/edit/abc falls back to TodoListScreen', (tester) async {
      await pumpApp(tester);
      await navigate(tester, '/edit/abc');

      expect(find.byType(AddEditTodoScreen), findsNothing);
      expect(find.byType(TodoListScreen), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('/edit/ (empty id) does not open the edit form', (
      tester,
    ) async {
      await pumpApp(tester);
      await navigate(tester, '/edit/');

      expect(find.byType(AddEditTodoScreen), findsNothing);
      expect(find.text('Edit Todo'), findsNothing);
    });

    testWidgets('/settings shows SettingsScreen', (tester) async {
      await pumpApp(tester);
      await navigate(tester, '/settings');

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(TodoListScreen), findsNothing);
    });
  });
}
