import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/bluetooth_status_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsyncValue = ref.watch(settingsProvider);
    final permissionsGranted = ref.watch(permissionStatusProvider);
    final bluetoothConnected = ref.watch(bluetoothStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CallSpeak'),
        centerTitle: true,
      ),
      body: settingsAsyncValue.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildStatusSection(
                permissionsGranted,
                bluetoothConnected,
                settings.announcementEnabled,
                ref,
                context,
              ),
              const SizedBox(height: 24),
              _buildSettingsSection(settings, ref, context),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading settings: $e')),
      ),
    );
  }

  Widget _buildStatusSection(
    bool permissionsGranted,
    bool bluetoothConnected,
    bool announcementEnabled,
    WidgetRef ref,
    BuildContext context,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _StatusRow(
              icon: permissionsGranted ? Icons.check_circle : Icons.error,
              color: permissionsGranted ? Colors.green : Colors.red,
              text: 'Permissions: ${permissionsGranted ? "Ready" : "Missing"}',
              action: permissionsGranted
                  ? null
                  : TextButton(
                      onPressed: () => ref.read(permissionStatusProvider.notifier).requestPermissions(),
                      child: const Text('Grant'),
                    ),
            ),
            const SizedBox(height: 8),
            _StatusRow(
              icon: bluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: bluetoothConnected ? Colors.blue : Colors.grey,
              text: 'Bluetooth: ${bluetoothConnected ? "Connected" : "Not Connected"}',
            ),
            const SizedBox(height: 8),
            _StatusRow(
              icon: announcementEnabled ? Icons.volume_up : Icons.volume_off,
              color: announcementEnabled ? Colors.green : Colors.grey,
              text: 'CallSpeak: ${announcementEnabled ? "Enabled" : "Disabled"}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: If you Force Stop this app via Android Settings, the background announcement will not work until you open the app again.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(settings, WidgetRef ref, BuildContext context) {
    final notifier = ref.read(settingsProvider.notifier);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('CallSpeak'),
              subtitle: const Text('Enable or disable caller announcement'),
              value: settings.announcementEnabled,
              onChanged: (val) {
                notifier.updateSettings(settings.copyWith(announcementEnabled: val));
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Announce only with Bluetooth'),
              value: settings.announceOnlyWithBluetooth,
              onChanged: (val) {
                notifier.updateSettings(settings.copyWith(announceOnlyWithBluetooth: val));
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Language'),
              trailing: DropdownButton<String>(
                value: settings.language,
                items: const [
                  DropdownMenuItem(value: 'en-US', child: Text('English (US)')),
                  DropdownMenuItem(value: 'en-GB', child: Text('English (UK)')),
                  DropdownMenuItem(value: 'hi-IN', child: Text('Hindi')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    notifier.updateSettings(settings.copyWith(language: val));
                  }
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Speech Rate', style: TextStyle(fontSize: 16)),
                  Slider(
                    value: settings.speechRate,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: settings.speechRate.toStringAsFixed(1),
                    onChanged: (val) {
                      notifier.updateSettings(settings.copyWith(speechRate: val));
                    },
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Slow'),
                      Text('Fast'),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(nativeBridgeProvider).testAnnouncement();
                },
                icon: const Icon(Icons.record_voice_over),
                label: const Text('Test Announcement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;

  const _StatusRow({
    required this.icon,
    required this.color,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        if (action != null) action!,
      ],
    );
  }
}
