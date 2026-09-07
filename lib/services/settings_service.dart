import 'package:shared_preferences/shared_preferences.dart';
import '../features/caller_announcement/models/call_settings.dart';

class SettingsService {
  static const String keyAnnouncementEnabled = 'announcementEnabled';
  static const String keyAnnounceOnlyWithBluetooth = 'announceOnlyWithBluetooth';
  static const String keyLanguage = 'language';
  static const String keySpeechRate = 'speechRateStr';

  Future<CallSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return CallSettings(
      announcementEnabled: prefs.getBool(keyAnnouncementEnabled) ?? false,
      announceOnlyWithBluetooth: prefs.getBool(keyAnnounceOnlyWithBluetooth) ?? true,
      language: prefs.getString(keyLanguage) ?? 'en-US',
      speechRate: double.tryParse(prefs.getString(keySpeechRate) ?? '1.0') ?? 1.0,
    );
  }

  Future<void> saveSettings(CallSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAnnouncementEnabled, settings.announcementEnabled);
    await prefs.setBool(keyAnnounceOnlyWithBluetooth, settings.announceOnlyWithBluetooth);
    await prefs.setString(keyLanguage, settings.language);
    await prefs.setString(keySpeechRate, settings.speechRate.toString());
  }
}
