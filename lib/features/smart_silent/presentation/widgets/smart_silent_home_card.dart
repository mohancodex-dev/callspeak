import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../screens/smart_silent_screen.dart';
import '../../providers/smart_silent_provider.dart';

class SmartSilentHomeCard extends ConsumerWidget {
  final AppStrings strings;

  const SmartSilentHomeCard({
    super.key,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stateAsync = ref.watch(smartSilentProvider);

    return stateAsync.maybeWhen(
      data: (state) {
        final isSilenced = state.isCurrentlySilenced;
        final activeTitle = state.activeScheduleTitle;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSilenced ? Colors.orange.shade700 : colorScheme.outlineVariant.withAlpha(40),
              width: isSilenced ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmartSilentScreen()),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSilenced ? Colors.orange.shade700.withAlpha(25) : Colors.indigo.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSilenced ? Icons.notifications_off_rounded : Icons.auto_mode_rounded,
                          color: isSilenced ? Colors.orange.shade800 : Colors.indigo,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  strings.smartSilentTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                if (isSilenced) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade800,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      strings.activeNow.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSilenced && activeTitle != null
                                  ? '🔕 $activeTitle (Auto Silent Active)'
                                  : strings.smartSilentSubtitle,
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: state.isMasterEnabled,
                        onChanged: (val) {
                          ref.read(smartSilentProvider.notifier).toggleMaster(val);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: theme.hintColor),
                          const SizedBox(width: 6),
                          Text(
                            '${state.schedules.where((s) => s.isEnabled).length} active schedules',
                            style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Configure',
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
