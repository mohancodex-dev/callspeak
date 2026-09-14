import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';

class OnboardingNotifier extends Notifier<bool> {
  static const String keyOnboardingCompleted = 'is_onboarding_completed';

  @override
  bool build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      return prefs.getBool(keyOnboardingCompleted) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> completeOnboarding() async {
    state = true;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(keyOnboardingCompleted, true);
    } catch (e) {
      // Ignored
    }
  }
}

final onboardingCompletedProvider = NotifierProvider<OnboardingNotifier, bool>(() {
  return OnboardingNotifier();
});
