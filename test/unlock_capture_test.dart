import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:callspeak/features/unlock_capture/models/unlock_record.dart';
import 'package:callspeak/features/unlock_capture/models/unlock_capture_settings.dart';
import 'package:callspeak/features/unlock_capture/providers/unlock_capture_provider.dart';

void main() {
  group('UnlockRecord Model Tests', () {
    test('Correctly serializes and deserializes captured record', () {
      final now = DateTime(2026, 10, 12, 14, 30, 0);
      final record = UnlockRecord(
        id: 'rec_101',
        timestamp: now,
        status: 'captured',
        photoPath: '/data/user/0/com.inurum.smartcallannounce/files/unlock_photos/unlock_101.jpg',
        errorMessage: null,
      );

      expect(record.isCaptured, isTrue);
      expect(record.isRestricted, isFalse);
      expect(record.isPermissionDenied, isFalse);
      expect(record.isError, isFalse);

      final map = record.toMap();
      expect(map['id'], 'rec_101');
      expect(map['status'], 'captured');
      expect(map['photoPath'], contains('unlock_101.jpg'));

      final fromMap = UnlockRecord.fromMap(map);
      expect(fromMap.id, 'rec_101');
      expect(fromMap.status, 'captured');
      expect(fromMap.photoPath, contains('unlock_101.jpg'));
      expect(fromMap.isCaptured, isTrue);
    });

    test('Correctly handles restricted and permission_denied status', () {
      final restrictedRecord = UnlockRecord.fromMap({
        'id': 'rec_102',
        'timestamp': 1728723456000,
        'status': 'camera_restricted',
        'photoPath': '',
        'errorMessage': 'Android OS restricted background camera access for privacy',
      });

      expect(restrictedRecord.isCaptured, isFalse);
      expect(restrictedRecord.isRestricted, isTrue);
      expect(restrictedRecord.photoPath, isNull);
      expect(restrictedRecord.errorMessage, contains('Android OS restricted'));

      final deniedRecord = UnlockRecord.fromMap({
        'id': 'rec_103',
        'timestamp': 1728723456000,
        'status': 'permission_denied',
        'photoPath': null,
        'errorMessage': 'Camera permission not granted',
      });

      expect(deniedRecord.isCaptured, isFalse);
      expect(deniedRecord.isPermissionDenied, isTrue);
    });
  });

  group('UnlockCaptureSettings Tests', () {
    test('Defaults and copyWith behavior', () {
      const settings = UnlockCaptureSettings();
      expect(settings.enabled, isFalse);
      expect(settings.showNotification, isTrue);

      final updated = settings.copyWith(enabled: true);
      expect(updated.enabled, isTrue);
      expect(updated.showNotification, isTrue);
    });
  });

  group('UnlockCaptureSettingsNotifier Tests', () {
    test('Persists enabled state to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(unlockCaptureSettingsProvider.notifier);
      await notifier.setEnabled(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('unlock_capture_enabled'), isTrue);
      expect(container.read(unlockCaptureSettingsProvider).enabled, isTrue);
    });
  });
}
