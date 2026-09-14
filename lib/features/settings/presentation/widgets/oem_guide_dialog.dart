import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../services/native_bridge_service.dart';

/// Guide dialog helping users on Xiaomi, Samsung, Vivo, Oppo, and OnePlus
/// configure OS-level Auto-Start and Unrestricted Battery settings.
class OemOptimizationGuideDialog extends StatelessWidget {
  final AppStrings strings;

  const OemOptimizationGuideDialog({
    super.key,
    required this.strings,
  });

  static void show(BuildContext context, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => OemOptimizationGuideDialog(strings: strings),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bridge = NativeBridgeService();

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.app_settings_alt_rounded,
          color: colorScheme.primary,
          size: 28,
        ),
      ),
      title: Text(
        strings.oemGuideTitle,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.oemGuideDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            // Step 1: Unrestricted Battery
            _buildStepCard(
              context: context,
              stepNumber: '1',
              icon: Icons.battery_saver_rounded,
              iconColor: Colors.amber.shade800,
              title: strings.oemStep1Title,
              desc: strings.oemStep1Desc,
            ),
            const SizedBox(height: 12),

            // Step 2: Auto-Start / Background Activity
            _buildStepCard(
              context: context,
              stepNumber: '2',
              icon: Icons.autorenew_rounded,
              iconColor: Colors.blueAccent,
              title: strings.oemStep2Title,
              desc: strings.oemStep2Desc,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            bridge.openBatterySettings();
          },
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text(strings.oemOpenSettings, style: const TextStyle(fontWeight: FontWeight.bold)),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required String stepNumber,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
