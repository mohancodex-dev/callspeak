import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:callspeak/core/constants/announcement_languages.dart';
import 'package:callspeak/core/localization/app_localizations.dart';
import 'package:callspeak/core/theme/theme_provider.dart';
import 'package:callspeak/features/caller_announcement/models/call_settings.dart';
import 'package:callspeak/features/caller_announcement/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AppLocalizations & Multi-Language Tests', () {
    test('All 17 supported announcement languages have valid AppStrings translations', () {
      final supported = AnnouncementLanguages.languageNames.keys;
      expect(supported.length, equals(17));

      for (final langCode in supported) {
        final strings = AppLocalizations.of(langCode);
        expect(strings, isNotNull, reason: 'Language $langCode should have AppStrings');
        expect(strings.navHome.isNotEmpty, isTrue, reason: '$langCode navHome should not be empty');
        expect(strings.navContacts.isNotEmpty, isTrue, reason: '$langCode navContacts should not be empty');
        expect(strings.navRules.isNotEmpty, isTrue, reason: '$langCode navRules should not be empty');
        expect(strings.navSmartAi.isNotEmpty, isTrue, reason: '$langCode navSmartAi should not be empty');

        expect(strings.announcerActive.isNotEmpty, isTrue);
        expect(strings.announcerPaused.isNotEmpty, isTrue);
        expect(strings.systemReady.isNotEmpty, isTrue);
        expect(strings.permissionNeeded.isNotEmpty, isTrue);
        expect(strings.repeatLabel3.isNotEmpty, isTrue);

        expect(strings.permissionsRequiredTitle.isNotEmpty, isTrue);
        expect(strings.grantAllPermissions.isNotEmpty, isTrue);

        expect(strings.searchContactsHint.isNotEmpty, isTrue);
        expect(strings.filterAll.isNotEmpty, isTrue);
        expect(strings.filterVip.isNotEmpty, isTrue);
        expect(strings.addRule.isNotEmpty, isTrue);

        expect(strings.categoryRulesTitle.isNotEmpty, isTrue);
        expect(strings.savedContactsTitle.isNotEmpty, isTrue);
        expect(strings.unknownNumbersTitle.isNotEmpty, isTrue);
      }
    });

    test('RTL languages (Urdu and Sindhi) are correctly identified', () {
      expect(AppLocalizations.isRtl('ur-IN'), isTrue);
      expect(AppLocalizations.isRtl('sd-IN'), isTrue);

      // LTR languages
      expect(AppLocalizations.isRtl('en-US'), isFalse);
      expect(AppLocalizations.isRtl('hi-IN'), isFalse);
      expect(AppLocalizations.isRtl('rathawi-IN'), isFalse);
      expect(AppLocalizations.isRtl('gu-IN'), isFalse);
      expect(AppLocalizations.isRtl('mr-IN'), isFalse);
      expect(AppLocalizations.isRtl('bn-IN'), isFalse);
      expect(AppLocalizations.isRtl('te-IN'), isFalse);
      expect(AppLocalizations.isRtl('ta-IN'), isFalse);
      expect(AppLocalizations.isRtl('kn-IN'), isFalse);
      expect(AppLocalizations.isRtl('ml-IN'), isFalse);
      expect(AppLocalizations.isRtl('pa-IN'), isFalse);
      expect(AppLocalizations.isRtl('or-IN'), isFalse);
      expect(AppLocalizations.isRtl('as-IN'), isFalse);
      expect(AppLocalizations.isRtl('kok-IN'), isFalse);
      expect(AppLocalizations.isRtl('ne-IN'), isFalse);
    });

    test('Fallback to English for unknown language code', () {
      final fallback = AppLocalizations.of('fr-FR');
      expect(fallback, isNotNull);
      expect(fallback.navHome, equals('Home'));
      expect(fallback.navContacts, equals('Contacts'));
      expect(fallback.announcerActive, equals('Announcer Active'));
    });

    test('Specific regional script verifications', () {
      // Hindi
      final hi = AppLocalizations.of('hi-IN');
      expect(hi.navHome, equals('होम'));
      expect(hi.navContacts, equals('संपर्क'));
      expect(hi.repeatLabel3, equals('3 बार'));

      // Gujarati
      final gu = AppLocalizations.of('gu-IN');
      expect(gu.navHome, equals('હોમ'));
      expect(gu.repeatLabel3, equals('3 વાર'));

      // Marathi
      final mr = AppLocalizations.of('mr-IN');
      expect(mr.navHome, equals('मुख्यपृष्ठ'));

      // Bengali
      final bn = AppLocalizations.of('bn-IN');
      expect(bn.navHome, equals('হোম'));

      // Tamil
      final ta = AppLocalizations.of('ta-IN');
      expect(ta.navHome, equals('முகப்பு'));

      // Telugu
      final te = AppLocalizations.of('te-IN');
      expect(te.navHome, equals('హోమ్'));

      // Kannada
      final kn = AppLocalizations.of('kn-IN');
      expect(kn.navHome, equals('ಮುಖಪುಟ'));

      // Malayalam
      final ml = AppLocalizations.of('ml-IN');
      expect(ml.navHome, equals('ഹോം'));

      // Punjabi
      final pa = AppLocalizations.of('pa-IN');
      expect(pa.navHome, equals('ਹੋਮ'));

      // Urdu
      final ur = AppLocalizations.of('ur-IN');
      expect(ur.navHome, equals('ہوم'));

      // Sindhi
      final sd = AppLocalizations.of('sd-IN');
      expect(sd.navHome, equals('هوم'));

      // Rathawi
      final rathawi = AppLocalizations.of('rathawi-IN');
      expect(rathawi.navHome, equals('ઘર (હોમ)'));
    });
  });

  group('AppLanguageProvider & Decoupling Tests', () {
    test('Defaults to en-US and persists custom language selection', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Default should be en-US
      expect(container.read(appLanguageProvider), equals('en-US'));
      expect(container.read(appStringsProvider).navHome, equals('Home'));
      expect(container.read(isRtlLanguageProvider), isFalse);

      // Change UI language to Hindi
      await container.read(appLanguageProvider.notifier).setLanguage('hi-IN');
      expect(container.read(appLanguageProvider), equals('hi-IN'));
      expect(container.read(appStringsProvider).navHome, equals('होम'));
      expect(prefs.getString(AppLanguageNotifier.keyAppLanguage), equals('hi-IN'));

      // Change UI language to Urdu (RTL)
      await container.read(appLanguageProvider.notifier).setLanguage('ur-IN');
      expect(container.read(appLanguageProvider), equals('ur-IN'));
      expect(container.read(appStringsProvider).navHome, equals('ہوم'));
      expect(container.read(isRtlLanguageProvider), isTrue);
    });

    test('Changing CallSettings announcement language does NOT change App UI language', () async {
      SharedPreferences.setMockInitialValues({
        AppLanguageNotifier.keyAppLanguage: 'en-US',
      });
      final prefs = await SharedPreferences.getInstance();

      final initialSettings = CallSettings(
        announcementEnabled: true,
        announceOnlyWithBluetooth: false,
        language: 'gu-IN', // Gujarati announcement voice
        speechRate: 1.0,
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsProvider.overrideWith(() => _MockSettingsNotifier(initialSettings)),
        ],
      );
      addTearDown(container.dispose);

      // App UI is English, announcement voice is Gujarati
      expect(container.read(appLanguageProvider), equals('en-US'));
      expect(container.read(appStringsProvider).navHome, equals('Home'));

      // Update announcement voice to Hindi
      await container.read(settingsProvider.notifier).updateSettings(
        initialSettings.copyWith(language: 'hi-IN'),
      );

      // App UI must REMAIN English!
      expect(container.read(appLanguageProvider), equals('en-US'));
      expect(container.read(appStringsProvider).navHome, equals('Home'));
    });
  });
}

class _MockSettingsNotifier extends SettingsNotifier {
  final CallSettings _initial;
  _MockSettingsNotifier(this._initial);

  @override
  Future<CallSettings> build() async => _initial;

  @override
  Future<void> updateSettings(CallSettings newSettings) async {
    state = AsyncValue.data(newSettings);
  }
}
