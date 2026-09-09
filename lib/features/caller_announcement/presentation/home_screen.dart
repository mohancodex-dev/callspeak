import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/bluetooth_status_provider.dart';
import '../models/call_settings.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsyncValue = ref.watch(settingsProvider);
    final permissionsGranted = ref.watch(permissionStatusProvider);
    final bluetoothConnected = ref.watch(bluetoothStatusProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CallSpeak Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Test Voice',
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: () {
              ref.read(nativeBridgeProvider).testAnnouncement();
            },
          ),
        ],
      ),
      body: settingsAsyncValue.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              // 1. Google Pixel Hero Status Banner
              _buildPixelHeroBanner(
                context: context,
                settings: settings,
                permissionsGranted: permissionsGranted,
                bluetoothConnected: bluetoothConnected,
                ref: ref,
              ),
              const SizedBox(height: 16),

              // 2. Group: Audio Delivery & Headset
              Text('Audio Delivery', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 8),
              _buildPixelGroupContainer(
                colorScheme: colorScheme,
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    secondary: const Icon(Icons.headphones_rounded),
                    title: const Text('Bluetooth / Headset Only', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Only speak when wireless audio device is connected'),
                    value: settings.announceOnlyWithBluetooth,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(announceOnlyWithBluetooth: val));
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    secondary: const Icon(Icons.speaker_phone_rounded),
                    title: const Text('Also Announce on Speaker', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Play sound on internal phone speaker even when Bluetooth is paired'),
                    value: settings.alsoAnnounceOnSpeaker,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(alsoAnnounceOnSpeaker: val));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Group: Silence & Do Not Disturb (DND)
              Text('Silence & DND Protection', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 8),
              _buildPixelGroupContainer(
                colorScheme: colorScheme,
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    secondary: const Icon(Icons.volume_off_rounded),
                    title: const Text('Silence in Silent/Vibrate Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Do not announce when phone is set to silent or vibrate'),
                    value: settings.silenceInSilentMode,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(silenceInSilentMode: val));
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    secondary: const Icon(Icons.do_not_disturb_on_rounded),
                    title: const Text('Silence in Do Not Disturb (DND)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Stay completely quiet when DND mode is active on phone'),
                    value: settings.silenceInDndMode,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(silenceInDndMode: val));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Group: Voice & Engine Settings
              Text('Default Voice Engine', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 8),
              _buildPixelGroupContainer(
                colorScheme: colorScheme,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('System Language', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: DropdownButton<String>(
                      value: settings.language,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(18),
                      items: const [
                        DropdownMenuItem(value: 'hi-IN', child: Text('Hindi (हिन्दी)')),
                        DropdownMenuItem(value: 'en-US', child: Text('English (US)')),
                        DropdownMenuItem(value: 'bn-IN', child: Text('Bengali (বাংলা)')),
                        DropdownMenuItem(value: 'te-IN', child: Text('Telugu (తెలుగు)')),
                        DropdownMenuItem(value: 'mr-IN', child: Text('Marathi (मराठी)')),
                        DropdownMenuItem(value: 'ta-IN', child: Text('Tamil (தமிழ்)')),
                        DropdownMenuItem(value: 'gu-IN', child: Text('Gujarati (ગુજરાતી)')),
                        DropdownMenuItem(value: 'kn-IN', child: Text('Kannada (ಕನ್ನಡ)')),
                        DropdownMenuItem(value: 'ml-IN', child: Text('Malayalam (മലയാളം)')),
                        DropdownMenuItem(value: 'pa-IN', child: Text('Punjabi (ਪੰਜਾਬੀ)')),
                        DropdownMenuItem(value: 'or-IN', child: Text('Odia (ଓଡ଼ିଆ)')),
                        DropdownMenuItem(value: 'as-IN', child: Text('Assamese (অসমীয়া)')),
                        DropdownMenuItem(value: 'ur-IN', child: Text('Urdu (اردو)')),
                        DropdownMenuItem(value: 'kok-IN', child: Text('Konkani (कोंकणी)')),
                        DropdownMenuItem(value: 'ne-IN', child: Text('Nepali (नेपाली)')),
                        DropdownMenuItem(value: 'sd-IN', child: Text('Sindhi (سنڌي)')),
                        DropdownMenuItem(value: 'rathawi-IN', child: Text('Rathawi')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(language: val));
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Default Speech Speed', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('${settings.speechRate.toStringAsFixed(1)}x', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                          ],
                        ),
                        Slider(
                          value: settings.speechRate,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(speechRate: val));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Test Announcement Button
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    ref.read(nativeBridgeProvider).testAnnouncement();
                  },
                  icon: const Icon(Icons.record_voice_over_rounded),
                  label: const Text('Test Voice Output', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading dashboard: $e')),
      ),
    );
  }

  Widget _buildPixelHeroBanner({
    required BuildContext context,
    required CallSettings settings,
    required bool permissionsGranted,
    required bool bluetoothConnected,
    required WidgetRef ref,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = settings.announcementEnabled;

    final bannerBg = isEnabled ? colorScheme.primaryContainer.withAlpha(120) : colorScheme.surfaceContainerHigh;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
                  color: isEnabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnabled ? 'Announcer Active' : 'Announcer Paused',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isEnabled
                          ? 'Smart Call Announce is monitoring incoming calls'
                          : 'Turn on to speak caller names aloud',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(announcementEnabled: val));
                  if (val) {
                    ref.read(nativeBridgeProvider).startService();
                  } else {
                    ref.read(nativeBridgeProvider).stopService();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sub-pills for Bluetooth & Permissions
          Row(
            children: [
              Expanded(
                child: _buildStatusPill(
                  icon: permissionsGranted ? Icons.check_circle_rounded : Icons.warning_rounded,
                  label: permissionsGranted ? 'Ready' : 'Permissions',
                  color: permissionsGranted ? Colors.green : Colors.orange,
                  colorScheme: colorScheme,
                  onTap: permissionsGranted
                      ? null
                      : () => ref.read(permissionStatusProvider.notifier).requestPermissions(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusPill(
                  icon: bluetoothConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
                  label: bluetoothConnected ? 'Headset' : 'Phone Speaker',
                  color: bluetoothConnected ? Colors.blue : colorScheme.onSurfaceVariant,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required Color color,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPixelGroupContainer({required ColorScheme colorScheme, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
