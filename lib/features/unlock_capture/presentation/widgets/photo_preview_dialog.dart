import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/unlock_record.dart';

class PhotoPreviewDialog extends StatelessWidget {
  final UnlockRecord record;
  final VoidCallback onDelete;

  const PhotoPreviewDialog({
    super.key,
    required this.record,
    required this.onDelete,
  });

  static void show(BuildContext context, UnlockRecord record, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => PhotoPreviewDialog(record: record, onDelete: onDelete),
    );
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  String _getFileSize(String? path) {
    if (path == null) return 'Unknown';
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }
    } catch (_) {}
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final photoPath = record.photoPath;
    final file = photoPath != null ? File(photoPath) : null;
    final fileExists = file != null && file.existsSync();

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_open_rounded, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unlock Capture Photo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _formatDateTime(record.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Photo Display
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 380),
              color: Colors.black,
              child: fileExists
                  ? InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'Unable to load captured image file.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Photo file no longer exists or was moved.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
            ),
          ),
          const Divider(height: 1),

          // Details & Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fileExists) ...[
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Size: ${_getFileSize(photoPath)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      const Icon(Icons.camera_front_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Front Camera',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete Photo'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (confirmCtx) => AlertDialog(
                            backgroundColor: colorScheme.surfaceContainerHigh,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Delete Capture Photo?'),
                            content: const Text('This will permanently delete this photo file from your device.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(confirmCtx),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                onPressed: () {
                                  Navigator.pop(confirmCtx);
                                  Navigator.pop(context);
                                  onDelete();
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    FilledButton.tonal(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
