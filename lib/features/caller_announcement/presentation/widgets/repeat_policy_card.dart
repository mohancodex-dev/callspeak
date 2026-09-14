import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/call_settings.dart';

class RepeatPolicyCard extends StatelessWidget {
  final CallSettings settings;
  final String effectiveRepeat;
  final AppStrings strings;
  final ValueChanged<String> onSelectRepeatMode;

  const RepeatPolicyCard({
    super.key,
    required this.settings,
    required this.effectiveRepeat,
    required this.strings,
    required this.onSelectRepeatMode,
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
                  color: Colors.blue.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.repeat_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.repeatMode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(
                      strings.repeatModeDesc,
                      style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                avatar: effectiveRepeat == 'three_times'
                    ? const Icon(Icons.check, size: 16)
                    : null,
                label: Text('${strings.repeatLabel3} (Default)'),
                selected: effectiveRepeat == 'three_times',
                onSelected: (val) {
                  if (val) onSelectRepeatMode('three_times');
                },
              ),
              ChoiceChip(
                avatar: effectiveRepeat == 'until_answered'
                    ? const Icon(Icons.check, size: 16)
                    : null,
                label: Text(strings.repeatUntilAnswered),
                selected: effectiveRepeat == 'until_answered',
                onSelected: (val) {
                  if (val) onSelectRepeatMode('until_answered');
                },
              ),
              ChoiceChip(
                avatar: effectiveRepeat == 'two_times'
                    ? const Icon(Icons.check, size: 16)
                    : null,
                label: Text(strings.repeatLabel2),
                selected: effectiveRepeat == 'two_times',
                onSelected: (val) {
                  if (val) onSelectRepeatMode('two_times');
                },
              ),
              ChoiceChip(
                avatar: effectiveRepeat == 'once'
                    ? const Icon(Icons.check, size: 16)
                    : null,
                label: Text(strings.repeatLabel1),
                selected: effectiveRepeat == 'once',
                onSelected: (val) {
                  if (val) onSelectRepeatMode('once');
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    effectiveRepeat == 'three_times'
                        ? 'Announces 3 times with a 3-second natural gap between repetitions.'
                        : (effectiveRepeat == 'until_answered'
                            ? 'Repeats continuously until you answer or decline the call.'
                            : 'Announces ${_getRepeatLabel(effectiveRepeat)} during ringing.'),
                    style: TextStyle(fontSize: 11.5, color: theme.hintColor),
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
