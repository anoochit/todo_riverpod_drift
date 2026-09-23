import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todo_riverpod/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ThemeModeState.build', () {
    test('defaults to ThemeMode.system when unset', () {
      final container = createContainer();
      final sub = container.listen(themeModeStateProvider, (_, _) {});
      addTearDown(sub.close);

      expect(sub.read(), ThemeMode.system);
    });

    test('reads persisted value from SharedPreferences', () async {
      await prefs.setInt('theme_mode', ThemeMode.dark.index);

      final container = createContainer();
      final sub = container.listen(themeModeStateProvider, (_, _) {});
      addTearDown(sub.close);

      expect(sub.read(), ThemeMode.dark);
    });
  });

  group('setThemeMode', () {
    test('persists index under theme_mode and updates state', () async {
      final container = createContainer();
      final sub = container.listen(themeModeStateProvider, (_, _) {});
      addTearDown(sub.close);

      expect(sub.read(), ThemeMode.system);

      await container
          .read(themeModeStateProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(sub.read(), ThemeMode.dark);
      expect(prefs.getInt('theme_mode'), ThemeMode.dark.index);
    });

    test('round-trips each ThemeMode value across provider rebuild', () async {
      for (final mode in ThemeMode.values) {
        SharedPreferences.setMockInitialValues({});
        final freshPrefs = await SharedPreferences.getInstance();

        final writeContainer = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(freshPrefs)],
        );
        final writeSub = writeContainer.listen(
          themeModeStateProvider,
          (_, _) {},
        );

        await writeContainer
            .read(themeModeStateProvider.notifier)
            .setThemeMode(mode);
        expect(writeSub.read(), mode);
        expect(freshPrefs.getInt('theme_mode'), mode.index);

        writeSub.close();
        writeContainer.dispose();

        final readContainer = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(freshPrefs)],
        );
        addTearDown(readContainer.dispose);
        final readSub = readContainer.listen(themeModeStateProvider, (_, _) {});
        addTearDown(readSub.close);

        expect(readSub.read(), mode, reason: '$mode should survive rebuild');
      }
    });
  });
}
