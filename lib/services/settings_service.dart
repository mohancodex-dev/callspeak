import 'package:shared_preferences/shared_preferences.dart';
import '../features/caller_announcement/models/call_settings.dart';

class SettingsService {
  static const String keyAnnouncementEnabled = 'announcementEnabled';
  static const String keyAnnounceOnlyWithBluetooth = 'announceOnlyWithBluetooth';
  static const String keyAlsoAnnounceOnSpeaker = 'alsoAnnounceOnSpeaker';
  static const String keySilenceInSilentMode = 'silenceInSilentMode';
  static const String keySilenceInDndMode = 'silenceInDndMode';
  static const String keyLanguage = 'language';
  static const String keySpeechRate = 'speechRateStr';
  static const String keyRepeatMode = 'repeatMode';

  Future<CallSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRepeat = prefs.getString(keyRepeatMode);
    final repeatMode = (savedRepeat == null || savedRepeat.isEmpty || savedRepeat == 'twice')
        ? 'three_times'
        : savedRepeat;

    return CallSettings(
      announcementEnabled: prefs.getBool(keyAnnouncementEnabled) ?? false,
      announceOnlyWithBluetooth: prefs.getBool(keyAnnounceOnlyWithBluetooth) ?? false,
      alsoAnnounceOnSpeaker: prefs.getBool(keyAlsoAnnounceOnSpeaker) ?? false,
      silenceInSilentMode: prefs.getBool(keySilenceInSilentMode) ?? true,
      silenceInDndMode: prefs.getBool(keySilenceInDndMode) ?? true,
      language: prefs.getString(keyLanguage) ?? 'en-US',
      speechRate: double.tryParse(prefs.getString(keySpeechRate) ?? '1.0') ?? 1.0,
      repeatMode: repeatMode,
    );
  }

  Future<void> saveSettings(CallSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAnnouncementEnabled, settings.announcementEnabled);
    await prefs.setBool(keyAnnounceOnlyWithBluetooth, settings.announceOnlyWithBluetooth);
    await prefs.setBool(keyAlsoAnnounceOnSpeaker, settings.alsoAnnounceOnSpeaker);
    await prefs.setBool(keySilenceInSilentMode, settings.silenceInSilentMode);
    await prefs.setBool(keySilenceInDndMode, settings.silenceInDndMode);
    await prefs.setString(keyLanguage, settings.language);
    await prefs.setString(keySpeechRate, settings.speechRate.toString());
    await prefs.setString(keyRepeatMode, settings.repeatMode);
  }
}
