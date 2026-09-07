import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/settings_service.dart';
import '../models/call_settings.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, CallSettings>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends AsyncNotifier<CallSettings> {
  @override
  Future<CallSettings> build() async {
    final settingsService = ref.read(settingsServiceProvider);
    return await settingsService.loadSettings();
  }

  Future<void> updateSettings(CallSettings newSettings) async {
    final settingsService = ref.read(settingsServiceProvider);
    try {
      await settingsService.saveSettings(newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
