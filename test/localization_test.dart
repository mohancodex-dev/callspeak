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
    test('All 11 supported announcement languages have valid AppStrings translations', () {
      final supported = AnnouncementLanguages.languageNames.keys;
      expect(supported.length, equals(11));

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

    test('RTL identification behavior', () {
      expect(AppLocalizations.isRtl('ur-IN'), isTrue);
      expect(AppLocalizations.isRtl('sd-IN'), isTrue);
      expect(AppLocalizations.isRtl('ar'), isTrue);

      // Supported LTR languages
      for (final langCode in AnnouncementLanguages.languageNames.keys) {
        expect(AppLocalizations.isRtl(langCode), isFalse, reason: '$langCode is LTR');
      }
    });

    test('Fallback to English for unknown language code', () {
      final fallback = AppLocalizations.of('fr-FR');
      expect(fallback, isNotNull);
      expect(fallback.navHome, equals('Home'));
      expect(fallback.navContacts, equals('Contacts'));
      expect(fallback.announcerActive, equals('Announcer ON'));
    });

    test('Specific regional script verifications', () {
      // Hindi
      final hi = AppLocalizations.of('hi-IN');
      expect(hi.navHome, equals('होम'));
      expect(hi.navContacts, equals('कॉन्टैक्ट्स'));
      expect(hi.repeatLabel3, equals('3 बार'));

      // Gujarati
      final gu = AppLocalizations.of('gu-IN');
      expect(gu.navHome, equals('હોમ'));
      expect(gu.repeatLabel3, equals('3 વાર'));

      // Marathi
      final mr = AppLocalizations.of('mr-IN');
      expect(mr.navHome, equals('मुख्यपृष्ठ'));

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

      // Nepali
      final ne = AppLocalizations.of('ne-IN');
      expect(ne.navHome, equals('गृह (होम)'));

      // Rathawi
      final rathawi = AppLocalizations.of('rathawi-IN');
      expect(rathawi.navHome, equals('ઘર (હોમ)'));
    });

    test('Rathawi announcement phrases match expected format', () {
      expect(
        AnnouncementLanguages.getContactAnnouncement(
          language: 'rathawi-IN',
          name: 'Rahul',
        ),
        equals('Rahul ne phon aayrayo'),
      );
      expect(
        AnnouncementLanguages.getUnknownAnnouncement(
          language: 'rathawi-IN',
          phoneNumber: '+919876543210',
        ),
        equals('+919876543210 ne phon aayrayo'),
      );
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

      // Change UI language to Gujarati
      await container.read(appLanguageProvider.notifier).setLanguage('gu-IN');
      expect(container.read(appLanguageProvider), equals('gu-IN'));
      expect(container.read(appStringsProvider).navHome, equals('હોમ'));
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
