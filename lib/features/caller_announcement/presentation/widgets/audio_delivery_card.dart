import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/call_settings.dart';

class AudioDeliveryCard extends StatelessWidget {
  final CallSettings settings;
  final bool bluetoothConnected;
  final AppStrings strings;
  final ValueChanged<bool> onToggleBluetoothOnly;
  final ValueChanged<bool> onToggleSpeaker;

  const AudioDeliveryCard({
    super.key,
    required this.settings,
    required this.bluetoothConnected,
    required this.strings,
    required this.onToggleBluetoothOnly,
    required this.onToggleSpeaker,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.headphones_rounded, color: Colors.blue),
            ),
            title: Text(strings.bluetoothOnly, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              bluetoothConnected
                  ? (strings.languageCode.startsWith('hi')
                      ? 'ईयरफोन कनेक्टेड है — नाम बोलेगा'
                      : 'Earphones connected — will speak name')
                  : strings.bluetoothOnlyDesc,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            value: settings.announceOnlyWithBluetooth,
            onChanged: onToggleBluetoothOnly,
          ),
          const Divider(height: 1, indent: 64),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.speaker_phone_rounded, color: Colors.teal),
            ),
            title: Text(strings.speakerOutput, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              strings.speakerOutputDesc,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            value: settings.alsoAnnounceOnSpeaker,
            onChanged: onToggleSpeaker,
          ),
        ],
      ),
    );
  }
}
