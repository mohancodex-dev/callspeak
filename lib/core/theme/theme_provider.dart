import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences instance injected at app startup in main().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main() via overrideWithValue');
});

/// Manages App ThemeMode: System (Default), Light, or Dark.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String keyThemeMode = 'app_theme_mode';

  @override
  ThemeMode build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final saved = prefs.getString(keyThemeMode);
      return switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system, // Default is always System Setting
      };
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(keyThemeMode, mode.name);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
