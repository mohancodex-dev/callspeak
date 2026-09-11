import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:callspeak/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeProvider Tests', () {
    test('Defaults to ThemeMode.system when no preference is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, equals(ThemeMode.system));
    });

    test('Loads saved Dark theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeNotifier.keyThemeMode: 'dark',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, equals(ThemeMode.dark));
    });

    test('Loads saved Light theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeNotifier.keyThemeMode: 'light',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, equals(ThemeMode.light));
    });

    test('Updates and persists theme mode when changed', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Default
      expect(container.read(themeModeProvider), equals(ThemeMode.system));

      // Switch to Dark
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(prefs.getString(ThemeModeNotifier.keyThemeMode), equals('dark'));

      // Switch to Light
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(prefs.getString(ThemeModeNotifier.keyThemeMode), equals('light'));

      // Switch back to System
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
      expect(container.read(themeModeProvider), equals(ThemeMode.system));
      expect(prefs.getString(ThemeModeNotifier.keyThemeMode), equals('system'));
    });
  });
}
