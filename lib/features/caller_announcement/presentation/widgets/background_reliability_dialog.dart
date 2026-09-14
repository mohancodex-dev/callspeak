import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';

/// Production-grade prominent in-app disclosure dialog for
/// Battery Saver Exemption (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
/// in full compliance with Google Play Store User Data & Sensitive Permissions policy.
class BackgroundReliabilityDialog extends StatelessWidget {
  final AppStrings strings;

  const BackgroundReliabilityDialog({
    super.key,
    required this.strings,
  });

  static Future<bool?> show(BuildContext context, AppStrings strings) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BackgroundReliabilityDialog(strings: strings),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.amber.shade700.withAlpha(25),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.battery_charging_full_rounded,
          color: Colors.amber.shade800,
          size: 30,
        ),
      ),
      title: Column(
        children: [
          Text(
            strings.batteryDisclosureTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            strings.batteryDisclosureSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Core Purpose Message
            Text(
              strings.batteryDisclosureMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // 2. OEM Device Caution Card (Xiaomi, Samsung, Vivo, Oppo)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade700.withAlpha(60)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.batteryDisclosureOemWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? Colors.amber.shade200
                            : Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Guarantees (Zero idle drain & 100% Privacy)
            _buildFeatureBadge(
              context: context,
              icon: Icons.bolt_rounded,
              iconColor: Colors.amber.shade800,
              text: strings.batteryDisclosureBullet1,
            ),
            const SizedBox(height: 10),
            _buildFeatureBadge(
              context: context,
              icon: Icons.shield_rounded,
              iconColor: Colors.teal,
              text: strings.batteryDisclosureBullet2,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            strings.batteryDisclosureLater,
            style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            strings.batteryDisclosureAllow,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBadge({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
