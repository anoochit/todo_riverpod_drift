import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_riverpod/database/app_database.dart';
import 'package:todo_riverpod/main.dart';
import 'package:todo_riverpod/providers/settings_provider.dart';
import 'package:todo_riverpod/screens/add_edit_todo_screen.dart';
import 'package:todo_riverpod/screens/settings_screen.dart';
import 'package:todo_riverpod/screens/todo_list_screen.dart';
import 'package:todo_riverpod/widgets/todo_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> resetState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final db = AppDatabase();
    await db.delete(db.todos).go();
    await db.close();
  }

  Future<void> launchApp(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TodoApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addTodoViaUi(
    WidgetTester tester, {
    required String title,
    String? description,
  }) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AddEditTodoScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, title);
    if (description != null) {
      await tester.enterText(find.byType(TextFormField).at(1), description);
    }

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.byType(TodoListScreen), findsOneWidget);
  }

  Future<void> openTileMenu(WidgetTester tester, String title) async {
    final tile = find.ancestor(
      of: find.text(title),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: tile, matching: find.byIcon(Icons.more_vert)),
    );
    await tester.pumpAndSettle();
  }

  group('Todo app E2E', () {
    setUp(() async {
      await resetState();
    });

    testWidgets('empty state shows placeholder message', (tester) async {
      await launchApp(tester);

      expect(find.byType(TodoListScreen), findsOneWidget);
      expect(find.textContaining('No todos yet'), findsOneWidget);
      expect(find.byType(TodoTile), findsNothing);
    });

    testWidgets('add todo via FAB appears in list', (tester) async {
      await launchApp(tester);
      expect(find.textContaining('No todos yet'), findsOneWidget);

      await addTodoViaUi(
        tester,
        title: 'Buy groceries',
        description: 'Milk, eggs',
      );

      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Milk, eggs'), findsOneWidget);
      expect(find.textContaining('No todos yet'), findsNothing);
    });

    testWidgets('validation blocks empty title', (tester) async {
      await launchApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
      expect(find.byType(AddEditTodoScreen), findsOneWidget);
    });

    testWidgets('checkbox toggles strikethrough on and off', (tester) async {
      await launchApp(tester);
      await addTodoViaUi(tester, title: 'Walk the dog');

      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final completed = tester.widget<Text>(find.text('Walk the dog'));
      expect(completed.style?.decoration, TextDecoration.lineThrough);
      expect(completed.style?.color, Colors.grey);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final active = tester.widget<Text>(find.text('Walk the dog'));
      expect(active.style?.decoration, isNot(TextDecoration.lineThrough));
      expect(active.style?.color, isNot(Colors.grey));
    });

    testWidgets('edit via popup menu pre-fills and saves changes', (
      tester,
    ) async {
      await launchApp(tester);
      await addTodoViaUi(
        tester,
        title: 'Original title',
        description: 'Original desc',
      );

      await openTileMenu(tester, 'Original title');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditTodoScreen), findsOneWidget);
      expect(find.text('Edit Todo'), findsOneWidget);

      final titleField = find.byType(TextFormField).first;
      final descriptionField = find.byType(TextFormField).at(1);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: titleField,
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'Original title',
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: descriptionField,
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'Original desc',
      );

      await tester.enterText(titleField, 'Updated title');
      await tester.enterText(descriptionField, 'Updated desc');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Update'));
      await tester.pumpAndSettle();

      expect(find.byType(TodoListScreen), findsOneWidget);
      expect(find.text('Updated title'), findsOneWidget);
      expect(find.text('Updated desc'), findsOneWidget);
      expect(find.text('Original title'), findsNothing);
    });

    testWidgets('delete: cancel keeps todo, confirm removes it', (
      tester,
    ) async {
      await launchApp(tester);
      await addTodoViaUi(tester, title: 'Disposable task');

      await openTileMenu(tester, 'Disposable task');
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Todo'), findsOneWidget);
      expect(
        find.textContaining(
          'Are you sure you want to delete "Disposable task"?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Disposable task'), findsOneWidget);
      expect(find.text('Delete Todo'), findsNothing);

      await openTileMenu(tester, 'Disposable task');
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Disposable task'), findsNothing);
      expect(find.textContaining('No todos yet'), findsOneWidget);
    });

    testWidgets('settings icon navigates to Settings with three theme radios', (
      tester,
    ) async {
      await launchApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.byType(RadioListTile<ThemeMode>), findsNWidgets(3));
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
    });

    testWidgets('selecting Dark radio applies dark theme', (tester) async {
      await launchApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('todos and theme persist across app restart', (tester) async {
      await launchApp(tester);
      await addTodoViaUi(tester, title: 'Persistent todo');

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      final beforeRestart = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );
      expect(beforeRestart.themeMode, ThemeMode.dark);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      await launchApp(tester);

      expect(find.text('Persistent todo'), findsOneWidget);

      final afterRestart = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(afterRestart.themeMode, ThemeMode.dark);
    });
  });
}
