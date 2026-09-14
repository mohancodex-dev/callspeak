import 'package:flutter/material.dart';
import '../../../../core/constants/announcement_languages.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/call_settings.dart';

class MasterHeroCard extends StatelessWidget {
  final CallSettings settings;
  final bool permissionsGranted;
  final bool bluetoothConnected;
  final String effectiveRepeat;
  final bool isDark;
  final AppStrings strings;
  final ValueChanged<bool> onToggle;
  final VoidCallback onFixPermissions;

  const MasterHeroCard({
    super.key,
    required this.settings,
    required this.permissionsGranted,
    required this.bluetoothConnected,
    required this.effectiveRepeat,
    required this.isDark,
    required this.strings,
    required this.onToggle,
    required this.onFixPermissions,
  });

  String _getRepeatLabel(String repeatMode) {
    return switch (repeatMode) {
      'once' || '1' => strings.repeatLabel1,
      'two_times' || '2' => strings.repeatLabel2,
      'three_times' || '3_times' || '3' || 'twice' => strings.repeatLabel3,
      'until_answered' || 'continuous' => strings.repeatUntilAnswered,
      _ => strings.repeatLabel3,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = settings.announcementEnabled;

    final primaryGradient = isEnabled
        ? (isDark
            ? const LinearGradient(
                colors: [Color(0xFF0F2B5C), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF0B57D0), Color(0xFF19376D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ))
        : LinearGradient(
            colors: isDark
                ? [const Color(0xFF1F242C), const Color(0xFF181B20)]
                : [const Color(0xFFE2E7EE), const Color(0xFFD3DAE4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final textColor = isEnabled || isDark ? Colors.white : const Color(0xFF1B1B1F);
    final subTextColor = isEnabled || isDark ? Colors.white.withAlpha(200) : const Color(0xFF44474E);

    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isEnabled ? colorScheme.primary.withAlpha(70) : Colors.black.withAlpha(15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Colors.white.withAlpha(40)
                      : (isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(20)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isEnabled ? Colors.white.withAlpha(70) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isEnabled ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
                  color: isEnabled ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isEnabled ? strings.announcerActive : strings.announcerPaused,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isEnabled ? const Color(0xFF4ADE80) : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnabled ? strings.announcerActiveDesc : strings.announcerPausedDesc,
                      style: TextStyle(fontSize: 12, color: subTextColor, height: 1.3),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.95,
                child: Switch(
                  value: isEnabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF38BDF8),
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.black26,
                  onChanged: onToggle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Real-time Diagnostic Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroPill(
                icon: permissionsGranted ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                label: permissionsGranted ? strings.systemReady : strings.permissionNeeded,
                bgColor: permissionsGranted
                    ? (isEnabled ? Colors.white.withAlpha(30) : Colors.green.withAlpha(30))
                    : Colors.amber.shade700.withAlpha(60),
                contentColor: permissionsGranted
                    ? (isEnabled || isDark ? Colors.white : Colors.green.shade800)
                    : Colors.amber.shade200,
                onTap: permissionsGranted ? null : onFixPermissions,
              ),
              _buildHeroPill(
                icon: bluetoothConnected ? Icons.headphones_rounded : Icons.speaker_phone_rounded,
                label: bluetoothConnected ? strings.headsetConnected : strings.phoneSpeaker,
                bgColor: isEnabled ? Colors.white.withAlpha(30) : (isDark ? Colors.white12 : Colors.black12),
                contentColor: textColor,
              ),
              _buildHeroPill(
                icon: Icons.repeat_rounded,
                label: _getRepeatLabel(effectiveRepeat),
                bgColor: isEnabled ? Colors.white.withAlpha(30) : (isDark ? Colors.white12 : Colors.black12),
                contentColor: textColor,
              ),
              _buildHeroPill(
                icon: Icons.language_rounded,
                label: AnnouncementLanguages.languageNames[settings.language] ?? settings.language,
                bgColor: isEnabled ? Colors.white.withAlpha(30) : (isDark ? Colors.white12 : Colors.black12),
                contentColor: textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color contentColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: contentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
