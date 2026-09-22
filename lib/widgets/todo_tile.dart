import 'package:flutter/material.dart';

import '../database/app_database.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(value: todo.isCompleted, onChanged: (_) => onToggle()),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
          color: todo.isCompleted ? Colors.grey : null,
        ),
      ),
      subtitle: todo.description != null && todo.description!.isNotEmpty
          ? Text(
              todo.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: todo.isCompleted ? Colors.grey : Colors.grey[600],
              ),
            )
          : null,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            onEdit();
          } else if (value == 'delete') {
            _confirmDelete(context);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
