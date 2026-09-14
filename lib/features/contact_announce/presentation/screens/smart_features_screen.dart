import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contact_rule_provider.dart';
import '../../../../core/localization/app_localizations.dart';

class SmartFeaturesScreen extends ConsumerWidget {
  const SmartFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final smartConfigAsync = ref.watch(smartFeaturesProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.smartFeaturesTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: smartConfigAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (config) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              // Google Assistant / Gemini Banner
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.smartFeaturesBannerTitle,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.smartFeaturesBannerDesc,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(strings.smartFeaturesTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 8),

              // Grouped Pixel Container for Smart Features
              _buildPixelGroupContainer(
                colorScheme: colorScheme,
                children: [
                  // 1. AI Announcement Assistant
                  _buildFeatureTile(
                    icon: Icons.psychology_rounded,
                    iconColor: Colors.deepPurple,
                    title: strings.smartAiAnnounceTitle,
                    subtitle: strings.smartAiAnnounceDesc,
                    value: config.aiSuggestionsEnabled,
                    onChanged: (val) {
                      ref.read(smartFeaturesProvider.notifier).updateConfig(
                            config.copyWith(aiSuggestionsEnabled: val),
                          );
                    },
                  ),
                  const Divider(height: 1, indent: 64),

                  // 2. Phonetic Name Assistant
                  _buildFeatureTile(
                    icon: Icons.spellcheck_rounded,
                    iconColor: Colors.teal,
                    title: strings.smartPhoneticTitle,
                    subtitle: strings.smartPhoneticDesc,
                    value: config.phoneticNameRecognition,
                    onChanged: (val) {
                      ref.read(smartFeaturesProvider.notifier).updateConfig(
                            config.copyWith(phoneticNameRecognition: val),
                          );
                    },
                  ),
                  const Divider(height: 1, indent: 64),

                  // 3. VIP Caller Priority
                  _buildFeatureTile(
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber.shade800,
                    title: strings.smartVipTitle,
                    subtitle: strings.smartVipDesc,
                    value: config.vipBypassSilent,
                    onChanged: (val) {
                      ref.read(smartFeaturesProvider.notifier).updateConfig(
                            config.copyWith(vipBypassSilent: val),
                          );
                    },
                  ),
                  const Divider(height: 1, indent: 64),

                  // 4. Spam Caller Warning
                  _buildFeatureTile(
                    icon: Icons.shield_rounded,
                    iconColor: Colors.redAccent,
                    title: strings.smartSpamTitle,
                    subtitle: strings.smartSpamDesc,
                    value: config.spamWarningAlert,
                    onChanged: (val) {
                      ref.read(smartFeaturesProvider.notifier).updateConfig(
                            config.copyWith(spamWarningAlert: val),
                          );
                    },
                  ),
                  const Divider(height: 1, indent: 64),

                  // 5. Earbud Private Mode
                  _buildFeatureTile(
                    icon: Icons.headphones_rounded,
                    iconColor: Colors.blueAccent,
                    title: strings.smartEarbudTitle,
                    subtitle: strings.smartEarbudDesc,
                    value: config.earbudContextAware,
                    onChanged: (val) {
                      ref.read(smartFeaturesProvider.notifier).updateConfig(
                            config.copyWith(earbudContextAware: val),
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildPixelGroupContainer({required ColorScheme colorScheme, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
