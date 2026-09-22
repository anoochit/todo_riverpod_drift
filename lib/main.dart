import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/settings_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Defer plugin initialization until after the first frame
  // to avoid the "lifecycle channel discarded" warning.
  await Future<void>.delayed(Duration.zero);
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TodoApp(),
    ),
  );
}

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeStateProvider);

    return MaterialApp.router(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: router,
    );
  }
}
