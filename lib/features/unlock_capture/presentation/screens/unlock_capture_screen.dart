import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/unlock_record.dart';
import '../../providers/unlock_capture_provider.dart';
import '../widgets/photo_preview_dialog.dart';

class UnlockCaptureScreen extends ConsumerStatefulWidget {
  const UnlockCaptureScreen({super.key});

  @override
  ConsumerState<UnlockCaptureScreen> createState() => _UnlockCaptureScreenState();
}

class _UnlockCaptureScreenState extends ConsumerState<UnlockCaptureScreen> {
  String _selectedFilter = 'all'; // 'all', 'photos', 'restricted'
  bool _isTestingCapture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraPermissionProvider.notifier).checkPermission();
      ref.read(unlockHistoryProvider.notifier).refresh();
    });
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');

    if (isToday) {
      return 'Today at $hour:$minute:$second';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hour:$minute:$second';
  }

  Future<void> _handleToggle(bool enabled) async {
    HapticFeedback.lightImpact();
    if (enabled) {
      final hasPermission = ref.read(cameraPermissionProvider);
      if (!hasPermission) {
        final proceed = await _showPermissionExplanationDialog();
        if (proceed != true) return;
        final granted = await ref.read(cameraPermissionProvider.notifier).requestPermission();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Camera permission is required to enable Unlock Photo Capture.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }
    await ref.read(unlockCaptureSettingsProvider.notifier).setEnabled(enabled);
  }

  Future<bool?> _showPermissionExplanationDialog() {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.camera_alt_rounded, color: Colors.blue),
            SizedBox(width: 12),
            Text('Camera Access Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To capture a photo using the front camera when your phone is unlocked, CallSpeak requires Camera permission.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              '• 100% On-Device Privacy: Captured photos are stored exclusively on your device internal memory.\n• Zero Data Sharing: Photos are never uploaded, shared, or accessible by third parties.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _testFrontCamera() async {
    HapticFeedback.mediumImpact();
    setState(() => _isTestingCapture = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(unlockHistoryProvider.notifier).testCaptureNow();
      final success = result['success'] == true;
      final photoPath = result['photoPath'] as String?;
      final error = result['error'] as String?;

      if (!mounted) return;

      if (success && photoPath != null) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Front camera capture succeeded! Photo saved.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Capture failed: ${error ?? "Unknown error"}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingCapture = false);
      }
    }
  }

  Future<void> _simulateUnlock() async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Simulating device unlock event...'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await ref.read(unlockHistoryProvider.notifier).simulateUnlock();
  }

  void _showClearConfirmDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear All Unlock Records?'),
        content: const Text('This will delete all saved unlock logs and permanently erase any captured photos from device storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(unlockHistoryProvider.notifier).clearAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All unlock records and photos deleted.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showRestrictedExplanationDialog(UnlockRecord record) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.amber),
            SizedBox(width: 12),
            Expanded(child: Text('Android Privacy Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unlock detected at ${_formatDateTime(record.timestamp)}.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              record.errorMessage ?? 'Android OS restricted background camera access for privacy.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Starting in Android 9 and enforced through Android 14, 15 & 16, background apps cannot silently access the camera. When an unlock event happens, the app notifies you so you can capture with a single tap in the foreground.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.camera_front_rounded, size: 16),
            label: const Text('Capture Now'),
            onPressed: () {
              Navigator.pop(ctx);
              _testFrontCamera();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(unlockCaptureSettingsProvider);
    final hasCameraPermission = ref.watch(cameraPermissionProvider);
    final history = ref.watch(unlockHistoryProvider);

    final filteredHistory = switch (_selectedFilter) {
      'photos' => history.where((r) => r.isCaptured).toList(),
      'restricted' => history.where((r) => r.isRestricted || r.isPermissionDenied || r.isError).toList(),
      _ => history,
    };

    final totalCaptures = history.where((r) => r.isCaptured).length;
    final totalRestricted = history.where((r) => r.isRestricted || r.isPermissionDenied).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Photo Capture', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh History',
            onPressed: () => ref.read(unlockHistoryProvider.notifier).refresh(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'clear') _showClearConfirmDialog();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear History', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // Master Switch Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            color: colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: settings.enabled
                              ? Colors.green.withAlpha(35)
                              : colorScheme.surfaceContainerLowest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          settings.enabled ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          color: settings.enabled ? Colors.green : Colors.grey,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Capture on Unlock',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              settings.enabled
                                  ? 'Active - detects device unlocks'
                                  : 'Disabled - no capture on unlock',
                              style: TextStyle(
                                fontSize: 13,
                                color: settings.enabled ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.enabled,
                        onChanged: _handleToggle,
                      ),
                    ],
                  ),
                  if (!hasCameraPermission && settings.enabled) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Camera permission required for capture',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.read(cameraPermissionProvider.notifier).requestPermission(),
                            child: const Text('Grant', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Android OS Background Camera Notice Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Android Security & Privacy Notice',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Modern Android (9 through 16) restricts background camera access for privacy. When your phone unlocks, a photo is captured automatically if permitted by your OS; if restricted in the background, CallSpeak logs the unlock event and provides an instant tap-to-capture notification.',
                        style: TextStyle(fontSize: 12, color: theme.hintColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Test Camera & Simulate Unlock
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isTestingCapture ? null : _testFrontCamera,
                  icon: _isTestingCapture
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.camera_front_rounded, size: 18),
                  label: const Text('Test Front Camera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _simulateUnlock,
                  icon: const Icon(Icons.phonelink_lock_rounded, size: 18),
                  label: const Text('Simulate Unlock', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Statistics Row
          Row(
            children: [
              _buildStatCard('Total Events', '${history.length}', Icons.history_rounded, Colors.blue),
              const SizedBox(width: 8),
              _buildStatCard('Photos Captured', '$totalCaptures', Icons.photo_camera_rounded, Colors.green),
              const SizedBox(width: 8),
              _buildStatCard('OS Restricted', '$totalRestricted', Icons.security_rounded, Colors.amber),
            ],
          ),
          const SizedBox(height: 20),

          // Section Header & Filters
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 20),
              const SizedBox(width: 8),
              const Text('Unlock History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              if (history.isNotEmpty)
                Text('${history.length} records', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ],
          ),
          const SizedBox(height: 10),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Events', 'all', history.length),
                const SizedBox(width: 8),
                _buildFilterChip('Photos Only', 'photos', totalCaptures),
                const SizedBox(width: 8),
                _buildFilterChip('Restricted / Alerts', 'restricted', totalRestricted),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // History List
          if (filteredHistory.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.lock_open_rounded, size: 54, color: theme.dividerColor),
                  const SizedBox(height: 12),
                  Text(
                    history.isEmpty ? 'No unlock events detected yet' : 'No records match filter',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.hintColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    history.isEmpty
                      ? 'Lock and unlock your device to see events and captured photos here.'
                      : 'Try switching the filter above to view all unlock events.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: theme.hintColor.withAlpha(160)),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...filteredHistory.map((record) => _buildHistoryTile(record, colorScheme, theme)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.hintColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    final theme = Theme.of(context);
    return FilterChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = value);
      },
      shape: const StadiumBorder(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
    );
  }

  Widget _buildHistoryTile(UnlockRecord record, ColorScheme colorScheme, ThemeData theme) {
    final hasPhoto = record.isCaptured && record.photoPath != null;
    final photoFile = hasPhoto ? File(record.photoPath!) : null;
    final fileExists = photoFile != null && photoFile.existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: colorScheme.surfaceContainerHigh,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.lightImpact();
            if (hasPhoto && fileExists) {
              PhotoPreviewDialog.show(context, record, () {
                ref.read(unlockHistoryProvider.notifier).deleteRecord(record);
              });
            } else if (record.isRestricted) {
              _showRestrictedExplanationDialog(record);
            } else if (record.isPermissionDenied) {
              ref.read(cameraPermissionProvider.notifier).requestPermission();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Thumbnail or Status Icon
                if (hasPhoto && fileExists)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Image.file(
                        photoFile,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(record.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getStatusIcon(record.status), color: _getStatusColor(record.status), size: 24),
                  ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusBgColor(record.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusLabel(record.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(record.status),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDateTime(record.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.hintColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getStatusDescription(record),
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Trailing Action
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: Colors.grey,
                  tooltip: 'Delete Record',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(unlockHistoryProvider.notifier).deleteRecord(record);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'captured' => Colors.green,
      'camera_restricted' => Colors.amber.shade800,
      'permission_denied' => Colors.red,
      _ => Colors.grey,
    };
  }

  Color _getStatusBgColor(String status) {
    return _getStatusColor(status).withAlpha(30);
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'captured' => Icons.camera_alt_rounded,
      'camera_restricted' => Icons.shield_outlined,
      'permission_denied' => Icons.lock_person_rounded,
      _ => Icons.error_outline_rounded,
    };
  }

  String _getStatusLabel(String status) {
    return switch (status) {
      'captured' => 'Photo Captured',
      'camera_restricted' => 'OS Restricted',
      'permission_denied' => 'Permission Denied',
      _ => 'Error',
    };
  }

  String _getStatusDescription(UnlockRecord record) {
    if (record.isCaptured) {
      return 'Front photo saved locally';
    }
    if (record.isRestricted) {
      return record.errorMessage ?? 'Android OS background policy restriction';
    }
    if (record.isPermissionDenied) {
      return 'Camera permission required';
    }
    return record.errorMessage ?? 'Failed to capture photo';
  }
}
