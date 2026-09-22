import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/todo_provider.dart';

class AddEditTodoScreen extends ConsumerStatefulWidget {
  final int? todoId;

  const AddEditTodoScreen({super.key, this.todoId});

  bool get isEditing => todoId != null;

  @override
  ConsumerState<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends ConsumerState<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadTodo();
    }
  }

  Future<void> _loadTodo() async {
    try {
      final todo = await ref.read(todoActionsProvider).todoById(widget.todoId!);
      _titleController.text = todo.title;
      _descriptionController.text = todo.description ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading todo: $e')));
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final actions = ref.read(todoActionsProvider);

      if (widget.isEditing) {
        await actions.updateTodo(
          id: widget.todoId!,
          title: title,
          description: description.isEmpty ? null : description,
        );
      } else {
        await actions.addTodo(
          title: title,
          description: description.isEmpty ? null : description,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving todo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Todo' : 'Add Todo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter todo title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveTodo(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTodo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
