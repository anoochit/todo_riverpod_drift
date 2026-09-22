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
