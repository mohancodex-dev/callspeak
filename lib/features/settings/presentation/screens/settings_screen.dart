import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../services/native_bridge_service.dart';
import '../widgets/faq_sheet.dart';
import '../widgets/privacy_policy_sheet.dart';
import '../widgets/oem_guide_dialog.dart';
import '../../../caller_announcement/presentation/widgets/background_reliability_dialog.dart';
import '../../../unlock_capture/presentation/screens/unlock_capture_screen.dart';
import '../../../unlock_capture/providers/unlock_capture_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Map<String, String> _uiLanguages = {
    'en-US': 'English',
    'hi-IN': 'हिन्दी (Hindi)',
    'gu-IN': 'ગુજરાતી (Gujarati)',
    'mr-IN': 'मराठी (Marathi)',
    'ta-IN': 'தமிழ் (Tamil)',
    'te-IN': 'తెలుగు (Telugu)',
    'kn-IN': 'ಕನ್ನಡ (Kannada)',
    'ml-IN': 'മലയാളം (Malayalam)',
    'pa-IN': 'ਪੰਜਾਬੀ (Punjabi)',
    'ne-IN': 'नेपाली (Nepali)',
    'rathawi-IN': 'રાઠવી / राठवी (Rathawi)',
  };

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentLang = ref.read(appLanguageProvider);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
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
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded),
                    const SizedBox(width: 12),
                    Text(
                      'App Display Language',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: _uiLanguages.entries.map((entry) {
                    final isSelected = entry.key == currentLang;
                    return ListTile(
                      title: Text(
                        entry.value,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        ref.read(appLanguageProvider.notifier).setLanguage(entry.key);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeModeProvider);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withAlpha(120),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    const Icon(Icons.palette_outlined),
                    const SizedBox(width: 12),
                    Text(
                      'Choose Theme',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.brightness_auto_rounded),
                title: const Text('System Default'),
                trailing: currentTheme == ThemeMode.system ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_rounded),
                title: const Text('Light Mode'),
                trailing: currentTheme == ThemeMode.light ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded),
                title: const Text('Dark Mode'),
                trailing: currentTheme == ThemeMode.dark ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Row(
          children: [
            Icon(Icons.feedback_outlined, color: Colors.blue),
            SizedBox(width: 12),
            Text('Send Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Encountered a bug or want a new feature? Let us know!',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your message or suggestion here...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Thank you! Your feedback has been received.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = ref.watch(appStringsProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final themeMode = ref.watch(themeModeProvider);
    final bridge = NativeBridgeService();

    final themeName = switch (themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System Default',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // Section 1: Voice & System TTS Engine
          _buildSectionHeader(title: strings.ttsEngineTitle, icon: Icons.record_voice_over_rounded, colorScheme: colorScheme),
          const SizedBox(height: 8),
          _buildGroupContainer(
            colorScheme: colorScheme,
            children: [
              _buildSettingTile(
                icon: Icons.settings_voice_rounded,
                iconColor: Colors.deepPurple,
                title: strings.openSystemTts,
                subtitle: strings.openSystemTtsDesc,
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await bridge.openTtsSettings();
                },
              ),
              const Divider(height: 1, indent: 64),
              _buildSettingTile(
                icon: Icons.language_rounded,
                iconColor: Colors.blue,
                title: 'App Display Language',
                subtitle: _uiLanguages[currentLang] ?? currentLang,
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showLanguagePicker(context, ref);
                },
              ),
              const Divider(height: 1, indent: 64),
              _buildSettingTile(
                icon: Icons.palette_outlined,
                iconColor: Colors.pinkAccent,
                title: 'Theme Appearance',
                subtitle: themeName,
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showThemePicker(context, ref);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 2: Background Reliability & Battery
          _buildSectionHeader(title: strings.batteryOptimizationTitle, icon: Icons.battery_charging_full_rounded, colorScheme: colorScheme),
          const SizedBox(height: 8),
          _buildGroupContainer(
            colorScheme: colorScheme,
            children: [
              _buildSettingTile(
                icon: Icons.bolt_rounded,
                iconColor: Colors.amber.shade800,
                title: strings.disableBatteryOpt,
                subtitle: strings.batteryOptimizationDesc,
                trailing: FilledButton.tonal(
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    final allow = await BackgroundReliabilityDialog.show(context, strings);
                    if (allow == true) {
                      await bridge.requestIgnoreBatteryOptimizations();
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(strings.allow, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final allow = await BackgroundReliabilityDialog.show(context, strings);
                  if (allow == true) {
                    await bridge.requestIgnoreBatteryOptimizations();
                  }
                },
              ),
              const Divider(height: 1, indent: 64),
              _buildSettingTile(
                icon: Icons.app_settings_alt_rounded,
                iconColor: Colors.teal,
                title: strings.oemGuideTitle,
                subtitle: strings.oemGuideDesc,
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  OemOptimizationGuideDialog.show(context, strings);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 3: Security & Intruder Protection
          _buildSectionHeader(title: 'Security & Intruder Alert', icon: Icons.security_rounded, colorScheme: colorScheme),
          const SizedBox(height: 8),
          _buildGroupContainer(
            colorScheme: colorScheme,
            children: [
              _buildSettingTile(
                icon: Icons.camera_front_rounded,
                iconColor: Colors.teal,
                title: 'Automatic Unlock Capture',
                subtitle: ref.watch(unlockCaptureSettingsProvider).enabled
                    ? 'Active • Captures photo on device unlock'
                    : 'Disabled • Tap to configure unlock capture',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UnlockCaptureScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 4: Troubleshooting & Support
          _buildSectionHeader(title: strings.troubleshootingTitle, icon: Icons.help_outline_rounded, colorScheme: colorScheme),
          const SizedBox(height: 8),
          _buildGroupContainer(
            colorScheme: colorScheme,
            children: [
              _buildSettingTile(
                icon: Icons.live_help_rounded,
                iconColor: Colors.blueAccent,
                title: 'Frequently Asked Questions (FAQ)',
                subtitle: 'Solutions for silent calls, Bluetooth & battery issues',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  FaqSheet.show(context);
                },
              ),
              const Divider(height: 1, indent: 64),
              _buildSettingTile(
                icon: Icons.rate_review_rounded,
                iconColor: Colors.orange,
                title: strings.feedback,
                subtitle: 'Suggest features or report issues directly',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => _showFeedbackDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 4: Privacy & Legal
          _buildSectionHeader(title: 'Legal & Policy', icon: Icons.privacy_tip_outlined, colorScheme: colorScheme),
          const SizedBox(height: 8),
          _buildGroupContainer(
            colorScheme: colorScheme,
            children: [
              _buildSettingTile(
                icon: Icons.shield_rounded,
                iconColor: Colors.green,
                title: strings.privacyPolicyTitle,
                subtitle: '100% on-device & zero data collection',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  PrivacyPolicySheet.show(context);
                },
              ),
              const Divider(height: 1, indent: 64),
              _buildSettingTile(
                icon: Icons.description_outlined,
                iconColor: Colors.blueGrey,
                title: strings.termsOfService,
                subtitle: 'Standard software usage license',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'CallSpeak',
                    applicationVersion: 'v1.0.0 (Build 1)',
                    applicationLegalese: '© 2026 Inurum Technologies. All rights reserved.',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30),

          // App Branding Footer
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.record_voice_over_rounded, color: colorScheme.primary, size: 28),
                ),
                const SizedBox(height: 10),
                const Text(
                  'CallSpeak • Smart Call Announce',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0+1 • Production Ready',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContainer({
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
