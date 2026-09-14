import 'package:flutter/material.dart';
import '../../../../core/constants/announcement_languages.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/call_settings.dart';

class VoiceEngineCard extends StatelessWidget {
  final CallSettings settings;
  final String currentAppLang;
  final AppStrings strings;
  final VoidCallback onSelectAppLanguage;
  final VoidCallback onSelectAnnouncementLanguage;
  final ValueChanged<double> onSpeechRateChanged;

  const VoiceEngineCard({
    super.key,
    required this.settings,
    required this.currentAppLang,
    required this.strings,
    required this.onSelectAppLanguage,
    required this.onSelectAnnouncementLanguage,
    required this.onSpeechRateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final langNames = AnnouncementLanguages.languageNames;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        children: [
          // 1. App UI Display Language
          InkWell(
            onTap: onSelectAppLanguage,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.translate_rounded, color: Colors.teal),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.appLanguage, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${langNames[currentAppLang] ?? currentAppLang} • ${strings.appLanguageDesc}',
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          langNames[currentAppLang]?.split('(').first.trim() ?? currentAppLang,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 64),

          // 2. Announcement Voice Language (Caller TTS)
          InkWell(
            onTap: onSelectAnnouncementLanguage,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.record_voice_over_rounded, color: Colors.purple),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.announcementVoiceLanguage,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${langNames[settings.language] ?? settings.language} • ${strings.announcementVoiceDesc}',
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          langNames[settings.language]?.split('(').first.trim() ?? settings.language,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.purple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 64),

          // 3. Speech Rate Slider
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.speed_rounded, size: 18, color: Colors.deepOrange),
                        ),
                        const SizedBox(width: 10),
                        Text(strings.speechRate, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${settings.speechRate.toStringAsFixed(1)}x Speed',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: settings.speechRate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: onSpeechRateChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
