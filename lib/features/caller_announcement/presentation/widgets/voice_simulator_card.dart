import 'package:flutter/material.dart';
import '../../../../core/constants/announcement_languages.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/call_settings.dart';

class VoiceSimulatorCard extends StatelessWidget {
  final CallSettings settings;
  final bool isPlayingPreview;
  final AppStrings strings;
  final VoidCallback onTogglePlay;

  const VoiceSimulatorCard({
    super.key,
    required this.settings,
    required this.isPlayingPreview,
    required this.strings,
    required this.onTogglePlay,
  });

  String _getSimulatedMessage(String language) {
    return AnnouncementLanguages.getContactAnnouncement(
      language: language,
      name: 'Rahul',
    );
  }

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
    final previewSpeech = _getSimulatedMessage(settings.language);
    final repeatLabel = _getRepeatLabel(settings.repeatMode);
    final languageName = AnnouncementLanguages.languageNames[settings.language] ?? settings.language;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.indigo, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.simulateIncomingCall,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${strings.sectionSimulatorDesc} ($languageName)',
                      style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Speech Bubble Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withAlpha(120),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hearing_rounded, size: 16, color: Colors.blueAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Speech Synthesizer',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Repeats $repeatLabel',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"$previewSpeech"',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dialect: $languageName • Speed: ${settings.speechRate.toStringAsFixed(1)}x',
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Test Button (Toggles between Play and Stop)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTogglePlay,
              icon: Icon(
                isPlayingPreview ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
              ),
              label: Text(
                isPlayingPreview ? strings.stopVoice : strings.testVoice,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isPlayingPreview ? Colors.red.shade700 : null,
                foregroundColor: isPlayingPreview ? Colors.white : null,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
