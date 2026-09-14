import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:callspeak/core/theme/theme_provider.dart';
import 'package:callspeak/features/onboarding/providers/onboarding_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingProvider Tests', () {
    test('Defaults to false when onboarding has not been completed', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final completed = container.read(onboardingCompletedProvider);
      expect(completed, isFalse);
    });

    test('Loads completed state if previously saved in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingNotifier.keyOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final completed = container.read(onboardingCompletedProvider);
      expect(completed, isTrue);
    });

    test('completeOnboarding sets state to true and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingCompletedProvider), isFalse);

      await container.read(onboardingCompletedProvider.notifier).completeOnboarding();

      expect(container.read(onboardingCompletedProvider), isTrue);
      expect(prefs.getBool(OnboardingNotifier.keyOnboardingCompleted), isTrue);
    });
  });
}
