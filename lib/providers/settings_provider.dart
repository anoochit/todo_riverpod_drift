import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

const _kThemeModeKey = 'theme_mode';

@riverpod
class ThemeModeState extends _$ThemeModeState {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final index = prefs.getInt(_kThemeModeKey) ?? ThemeMode.system.index;
    return ThemeMode.values[index];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_kThemeModeKey, mode.index);
    state = mode;
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
