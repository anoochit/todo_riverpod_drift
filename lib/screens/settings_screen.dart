import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(themeModeStateProvider.notifier).setThemeMode(mode);
              }
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('System Default'),
                  subtitle: Text('Follow system theme'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Light'),
                  subtitle: Text('Always use light theme'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Dark'),
                  subtitle: Text('Always use dark theme'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const ListTile(title: Text('Version'), subtitle: Text('1.0.0')),
        ],
      ),
    );
  }
}
