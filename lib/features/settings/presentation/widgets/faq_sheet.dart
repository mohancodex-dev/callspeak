import 'package:flutter/material.dart';
import '../../../../services/native_bridge_service.dart';

class FaqSheet extends StatelessWidget {
  const FaqSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FaqSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bridge = NativeBridgeService();

    final List<Map<String, String>> faqs = [
      {
        'q': 'Why does CallSpeak stop announcing when the screen is locked?',
        'a':
            'Modern Android devices (especially Xiaomi, Samsung, Oppo, Vivo) aggressively put background apps to sleep to save battery. To fix this:\n1. Tap "Disable Battery Optimization" below.\n2. In phone settings, set CallSpeak battery usage to "Unrestricted".\n3. For Xiaomi/MIUI, enable "Autostart" for CallSpeak.',
      },
      {
        'q': 'Why did my phone not announce a call while on silent?',
        'a':
            'By default, CallSpeak respects your phone’s Silent and Do Not Disturb (DND) modes to prevent embarrassment during meetings or while sleeping. You can change this anytime from the "Silent & DND Settings" card on the Home screen or mark specific contacts as VIP.',
      },
      {
        'q': 'How can I download or improve Indian regional voices (Hindi, Tamil, Marathi, etc.)?',
        'a':
            'CallSpeak uses your device\'s built-in Google Speech Services (TTS Engine). Tap "Open System TTS Settings" in the Settings tab to download high-quality offline voice packs for your preferred language.',
      },
      {
        'q': 'Does CallSpeak announce WhatsApp, Telegram, or Truecaller calls?',
        'a':
            'Currently, CallSpeak announces standard cellular / SIM phone calls. Support for VoIP apps like WhatsApp is being actively developed for future updates.',
      },
      {
        'q': 'How do I stop announcement during an incoming call?',
        'a':
            'Simply press the Volume Up or Volume Down button on your phone once, or turn the phone face-down to immediately silence the voice announcement.',
      },
    ];

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
                  child: Icon(Icons.help_outline_rounded, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Troubleshooting & FAQ',
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
          // Quick Action Banner: Battery Optimization
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.battery_alert_rounded, color: Colors.orange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Background Battery Fix',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Prevent system from killing announcer',
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => bridge.requestIgnoreBatteryOptimizations(),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Fix Now', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: faqs.length,
              itemBuilder: (ctx, i) {
                final item = faqs[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      leading: Icon(Icons.question_answer_outlined, color: colorScheme.primary, size: 20),
                      title: Text(
                        item['q']!,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      children: [
                        Text(
                          item['a']!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
