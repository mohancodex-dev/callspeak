import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/call_settings.dart';

class SilenceProtectionCard extends StatelessWidget {
  final CallSettings settings;
  final AppStrings strings;
  final ValueChanged<bool> onToggleSilentMode;
  final ValueChanged<bool> onToggleDndMode;

  const SilenceProtectionCard({
    super.key,
    required this.settings,
    required this.strings,
    required this.onToggleSilentMode,
    required this.onToggleDndMode,
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
                color: Colors.amber.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_off_rounded, color: Colors.amber),
            ),
            title: Text(strings.silenceInSilent, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              strings.silenceInSilentDesc,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            value: settings.silenceInSilentMode,
            onChanged: onToggleSilentMode,
          ),
          const Divider(height: 1, indent: 64),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.do_not_disturb_on_rounded, color: Colors.redAccent),
            ),
            title: Text(strings.silenceInDnd, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              strings.silenceInDndDesc,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            value: settings.silenceInDndMode,
            onChanged: onToggleDndMode,
          ),
        ],
      ),
    );
  }
}
