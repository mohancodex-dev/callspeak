import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';

class MetricGrid extends StatelessWidget {
  final int totalContacts;
  final int vipCount;
  final bool permissionsGranted;
  final ColorScheme colorScheme;
  final AppStrings strings;
  final VoidCallback onNavigateContacts;
  final VoidCallback onNavigateRules;
  final VoidCallback onNavigateSettings;
  final VoidCallback onFixPermissions;

  const MetricGrid({
    super.key,
    required this.totalContacts,
    required this.vipCount,
    required this.permissionsGranted,
    required this.colorScheme,
    required this.strings,
    required this.onNavigateContacts,
    required this.onNavigateRules,
    required this.onNavigateSettings,
    required this.onFixPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTile(
                title: '$totalContacts ${strings.navContacts}',
                subtitle: '$vipCount ${strings.filterVip}',
                badgeText: strings.navContacts,
                icon: Icons.contacts_rounded,
                iconColor: const Color(0xFF0B57D0),
                containerBg: colorScheme.surfaceContainerLowest,
                onTap: onNavigateContacts,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTile(
                title: strings.navRules,
                subtitle: '4 Category profiles',
                badgeText: strings.navRules,
                icon: Icons.tune_rounded,
                iconColor: Colors.deepPurple,
                containerBg: colorScheme.surfaceContainerLowest,
                onTap: onNavigateRules,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTile(
                title: strings.navSettings,
                subtitle: 'TTS & background setup',
                badgeText: strings.navSettings,
                icon: Icons.settings_suggest_rounded,
                iconColor: Colors.deepOrange,
                containerBg: colorScheme.surfaceContainerLowest,
                onTap: onNavigateSettings,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTile(
                title: permissionsGranted ? strings.fullGuard : strings.needsAction,
                subtitle: strings.dndSilentActive,
                badgeText: permissionsGranted ? strings.secure : strings.fix,
                icon: Icons.security_rounded,
                iconColor: permissionsGranted ? Colors.teal : Colors.orange,
                containerBg: colorScheme.surfaceContainerLowest,
                onTap: permissionsGranted ? null : onFixPermissions,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTile({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color iconColor,
    required Color containerBg,
    VoidCallback? onTap,
  }) {
    return Material(
      color: containerBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: iconColor,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 16, color: iconColor),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
