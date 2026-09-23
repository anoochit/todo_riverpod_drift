import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        centerTitle: true,
        actions: [
          IconButton(
            key: const ValueKey('settings_icon_button'),
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: todoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (todos) {
          if (todos.isEmpty) {
            return const Center(
              child: Text(
                'No todos yet.\nTap + to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            key: const ValueKey('todo_list_view'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: todos.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final todo = todos[index];
              final actions = ref.read(todoActionsProvider);
              return TodoTile(
                todo: todo,
                onToggle: () => actions.toggleCompleted(todo.id),
                onDelete: () => actions.deleteTodo(todo.id),
                onEdit: () => context.push('/edit/${todo.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('add_todo_fab'),
        onPressed: () => context.push('/add'),
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
