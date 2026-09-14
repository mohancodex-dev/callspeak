import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/smart_silent_schedule.dart';
import '../../providers/smart_silent_provider.dart';
import '../widgets/smart_silent_editor_sheet.dart';

class SmartSilentScreen extends ConsumerStatefulWidget {
  const SmartSilentScreen({super.key});

  @override
  ConsumerState<SmartSilentScreen> createState() => _SmartSilentScreenState();
}

class _SmartSilentScreenState extends ConsumerState<SmartSilentScreen> {
  bool _isDndGranted = true;

  @override
  void initState() {
    super.initState();
    _checkDndPermission();
  }

  Future<void> _checkDndPermission() async {
    final bridge = ref.read(nativeBridgeProvider);
    final granted = await bridge.isDndAccessGranted();
    if (mounted) {
      setState(() => _isDndGranted = granted);
    }
  }

  Future<void> _showDndDisclosureDialog() async {
    final strings = ref.read(appStringsProvider);
    final theme = Theme.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.amber.shade900.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.do_not_disturb_on_rounded, color: Colors.amber.shade800, size: 28),
        ),
        title: Text(
          strings.dndDisclosureTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
          textAlign: TextAlign.center,
        ),
        content: Text(
          strings.dndDisclosureDesc,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.dndDisclosureOpen, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      final bridge = ref.read(nativeBridgeProvider);
      await bridge.openDndSettings();
      await Future.delayed(const Duration(seconds: 1));
      _checkDndPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = ref.watch(appStringsProvider);
    final stateAsync = ref.watch(smartSilentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.smartSilentTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          SmartSilentEditorSheet.show(
            context,
            strings: strings,
            onSave: (newSchedule) {
              ref.read(smartSilentProvider.notifier).addSchedule(newSchedule);
            },
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.addSchedule, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. DND Access Permission Banner (if not granted)
              if (!_isDndGranted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade700.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.do_not_disturb_on_rounded, color: Colors.amber.shade800, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.dndAccessNeeded,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            FilledButton.tonal(
                              onPressed: _showDndDisclosureDialog,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(strings.grantDndAccess),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Status Banner (Active Silent vs Normal)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: state.isCurrentlySilenced
                        ? [Colors.deepOrange.shade800, Colors.orange.shade700]
                        : [colorScheme.primaryContainer, colorScheme.surfaceContainerHigh],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: state.isCurrentlySilenced ? Colors.white24 : colorScheme.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.isCurrentlySilenced ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
                        color: state.isCurrentlySilenced ? Colors.white : colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isCurrentlySilenced
                                ? '🔕 ${strings.currentlySilenced}'
                                : '🔔 ${strings.normalActive}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: state.isCurrentlySilenced ? Colors.white : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.isCurrentlySilenced && state.activeScheduleTitle != null
                                ? '${strings.activeNow}: ${state.activeScheduleTitle}'
                                : strings.smartSilentSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: state.isCurrentlySilenced ? Colors.white70 : theme.hintColor,
                            ),
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
              ),
              const SizedBox(height: 20),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Schedules & Automations',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${state.schedules.length} Active',
                    style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Schedules List
              ...state.schedules.map((schedule) {
                return _buildScheduleCard(
                  context: context,
                  schedule: schedule,
                  strings: strings,
                  colorScheme: colorScheme,
                  theme: theme,
                );
              }),
              const SizedBox(height: 80), // Space for FAB
            ],
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard({
    required BuildContext context,
    required SmartSilentSchedule schedule,
    required AppStrings strings,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    final now = DateTime.now();
    final isActive = schedule.isTimeActive(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? Colors.orange.shade700 : colorScheme.outlineVariant.withAlpha(40),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Switch Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(schedule.title).withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getCategoryIcon(schedule.title),
                    color: _getCategoryColor(schedule.title),
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
                            schedule.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                strings.activeNow.toUpperCase(),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDays(schedule.daysOfWeek),
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: schedule.isEnabled,
                  onChanged: (val) {
                    ref.read(smartSilentProvider.notifier).toggleSchedule(schedule.id, val);
                  },
                ),
              ],
            ),
            const Divider(height: 20),

            // Time & Flow Row (Start -> 🔕 Silent, End -> 🔔 Normal)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_off_rounded, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.formatTime(context, schedule.startHour, schedule.startMinute),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(strings.autoSilentIndicator, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.formatTime(context, schedule.endHour, schedule.endMinute),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(strings.autoNormalIndicator, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Optional Location badge if enabled
            if (schedule.isLocationEnabled) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Colors.teal),
                    const SizedBox(width: 6),
                    Text(
                      'Location: ${schedule.locationName ?? "Office"} (${schedule.radiusMeters.toInt()}m)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            // Actions (Edit & Delete)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    SmartSilentEditorSheet.show(
                      context,
                      schedule: schedule,
                      strings: strings,
                      onSave: (updated) {
                        ref.read(smartSilentProvider.notifier).updateSchedule(updated);
                      },
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: strings.editSchedule,
                ),
                IconButton(
                  onPressed: () {
                    ref.read(smartSilentProvider.notifier).deleteSchedule(schedule.id);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  tooltip: strings.delete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('meeting')) return Colors.deepPurple;
    if (lower.contains('office') || lower.contains('work')) return Colors.blue;
    if (lower.contains('sleep') || lower.contains('rest')) return Colors.indigo;
    if (lower.contains('class') || lower.contains('school')) return Colors.teal;
    if (lower.contains('prayer')) return Colors.amber.shade800;
    return Colors.blueGrey;
  }

  IconData _getCategoryIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('meeting')) return Icons.business_center_rounded;
    if (lower.contains('office') || lower.contains('work')) return Icons.apartment_rounded;
    if (lower.contains('sleep') || lower.contains('rest')) return Icons.nightlight_round;
    if (lower.contains('class') || lower.contains('school')) return Icons.school_rounded;
    if (lower.contains('prayer')) return Icons.self_improvement_rounded;
    return Icons.schedule_rounded;
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Everyday (Daily)';
    if (days.length == 5 && days.contains(1) && days.contains(5)) return 'Mon - Fri (Weekdays)';
    if (days.length == 2 && days.contains(6) && days.contains(7)) return 'Sat - Sun (Weekends)';
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }
}
