import 'package:flutter/material.dart';

class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PrivacyPolicySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withAlpha(120),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_outlined, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Privacy Policy',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildBadge(
                  icon: Icons.verified_user_rounded,
                  color: Colors.green,
                  text: '100% On-Device & Zero Data Collection',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: '1. Overview',
                  content:
                      'CallSpeak ("Smart Call Announce") is developed with strict user privacy as its core principle. The app announces caller names aloud to enhance accessibility and convenience. We do not collect, store, sell, or transmit any personal data, contacts, or phone numbers to any external servers.',
                ),
                _buildSection(
                  title: '2. Permissions We Request and Why',
                  content:
                      '• Phone State (READ_PHONE_STATE): Used exclusively to detect incoming calls in real time so the voice announcer can be triggered.\n\n'
                      '• Contacts (READ_CONTACTS): Used exclusively on your local device to read contact names matching incoming phone numbers so the caller’s name can be spoken.\n\n'
                      '• Post Notifications (POST_NOTIFICATIONS): Used on Android 13+ to display the ongoing foreground service notification required by Android to keep the announcer active.\n\n'
                      '• Bluetooth Connect (BLUETOOTH_CONNECT): Optional. Used only when you enable "Announce only with Bluetooth / Headset" to check whether wireless earphones are connected.',
                ),
                _buildSection(
                  title: '3. Data Security & Storage',
                  content:
                      'All customized contact rules, voice pitch, speed, and language preferences are stored strictly on your device using local encrypted SharedPreferences. No analytics or tracking SDKs record your call logs or contact list.',
                ),
                _buildSection(
                  title: '4. Third-Party Services',
                  content:
                      'The Text-to-Speech audio is generated on-device using the operating system’s default TTS Engine (such as Google Speech Services or Samsung TTS). We do not send your speech text to cloud servers.',
                ),
                _buildSection(
                  title: '5. Contact & Questions',
                  content:
                      'If you have any questions or feedback regarding our privacy practices, please contact us at support@inurum.com.',
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Last updated: September 2026\nInurum Technologies',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
