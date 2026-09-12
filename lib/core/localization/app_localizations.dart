import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';
import 'app_strings.dart';
import 'translations/hi_strings.dart';
import 'translations/rathawi_strings.dart';
import 'translations/gu_strings.dart';
import 'translations/mr_strings.dart';
import 'translations/bn_strings.dart';
import 'translations/te_strings.dart';
import 'translations/ta_strings.dart';
import 'translations/kn_strings.dart';
import 'translations/ml_strings.dart';
import 'translations/pa_strings.dart';
import 'translations/or_strings.dart';
import 'translations/as_strings.dart';
import 'translations/ur_strings.dart';
import 'translations/kok_strings.dart';
import 'translations/ne_strings.dart';
import 'translations/sd_strings.dart';

class AppLocalizations {
  static const Map<String, AppStrings> _translations = {
    'en-US': AppStrings(),
    'hi-IN': HiStrings(),
    'rathawi-IN': RathawiStrings(),
    'gu-IN': GuStrings(),
    'mr-IN': MrStrings(),
    'bn-IN': BnStrings(),
    'te-IN': TeStrings(),
    'ta-IN': TaStrings(),
    'kn-IN': KnStrings(),
    'ml-IN': MlStrings(),
    'pa-IN': PaStrings(),
    'or-IN': OrStrings(),
    'as-IN': AsStrings(),
    'ur-IN': UrStrings(),
    'kok-IN': KokStrings(),
    'ne-IN': NeStrings(),
    'ne-NP': NeStrings(),
    'sd-IN': SdStrings(),
  };

  static AppStrings of(String languageCode) {
    return _translations[languageCode] ?? _translations['en-US']!;
  }

  static bool isRtl(String languageCode) {
    return languageCode == 'ur-IN' || languageCode == 'sd-IN';
  }
}

/// Manages App UI Display Language (localization of screens, buttons, menus).
/// Decoupled from Caller Announcement Voice Language.
class AppLanguageNotifier extends Notifier<String> {
  static const String keyAppLanguage = 'app_ui_language';

  @override
  String build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      return prefs.getString(keyAppLanguage) ?? 'en-US';
    } catch (_) {
      return 'en-US';
    }
  }

  Future<void> setLanguage(String languageCode) async {
    state = languageCode;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(keyAppLanguage, languageCode);
    } catch (e) {
      debugPrint('Error saving app language: $e');
    }
  }
}

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, String>(
  AppLanguageNotifier.new,
);

final appStringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return AppLocalizations.of(lang);
});

final isRtlLanguageProvider = Provider<bool>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return AppLocalizations.isRtl(lang);
});
