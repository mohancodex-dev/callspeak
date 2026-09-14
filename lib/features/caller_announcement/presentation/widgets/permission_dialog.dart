import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';

class PermissionRequiredDialog extends StatelessWidget {
  final AppStrings strings;

  const PermissionRequiredDialog({
    super.key,
    required this.strings,
  });

  static Future<bool?> show(BuildContext context, AppStrings strings) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => PermissionRequiredDialog(strings: strings),
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
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.security_rounded,
          color: colorScheme.primary,
          size: 28,
        ),
      ),
      title: Text(
        strings.permissionsRequiredTitle,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.permissionsRequiredDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildItem(
              context: context,
              icon: Icons.phone_in_talk_rounded,
              iconColor: Colors.blueAccent,
              title: strings.phoneCallsState,
              subtitle: strings.phoneCallsStateDesc,
            ),
            const SizedBox(height: 12),
            _buildItem(
              context: context,
              icon: Icons.contacts_rounded,
              iconColor: Colors.teal,
              title: strings.contactsAccess,
              subtitle: strings.contactsAccessDesc,
            ),
            const SizedBox(height: 12),
            _buildItem(
              context: context,
              icon: Icons.notifications_active_rounded,
              iconColor: Colors.orange,
              title: strings.notificationsAudio,
              subtitle: strings.notificationsAudioDesc,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.withAlpha(50)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.privacy_tip_rounded, color: Colors.teal, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.permissionsPrivacyBadge,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? Colors.teal.shade200
                            : Colors.teal.shade900,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(strings.grantAllPermissions, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30),
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
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
