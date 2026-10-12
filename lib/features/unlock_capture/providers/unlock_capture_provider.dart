import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/native_bridge_service.dart';
import '../models/unlock_capture_settings.dart';
import '../models/unlock_record.dart';

final nativeBridgeProvider = Provider<NativeBridgeService>((ref) => NativeBridgeService());

/// Provider for Unlock Capture Settings (enabled / disabled toggle)
class UnlockCaptureSettingsNotifier extends Notifier<UnlockCaptureSettings> {
  static const String keyEnabled = 'unlock_capture_enabled';

  @override
  UnlockCaptureSettings build() {
    _loadSettings();
    return const UnlockCaptureSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(keyEnabled) ?? false;
      state = state.copyWith(enabled: enabled);
    } catch (e) {
      debugPrint('Error loading unlock capture settings: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyEnabled, enabled);
    } catch (e) {
      debugPrint('Error saving unlock capture setting: $e');
    }
  }
}

final unlockCaptureSettingsProvider =
    NotifierProvider<UnlockCaptureSettingsNotifier, UnlockCaptureSettings>(
  UnlockCaptureSettingsNotifier.new,
);

/// Provider to check and request Camera Permission
class CameraPermissionNotifier extends Notifier<bool> {
  @override
  bool build() {
    checkPermission();
    return false;
  }

  Future<void> checkPermission() async {
    try {
      final granted = await Permission.camera.isGranted;
      state = granted;
    } catch (_) {
      state = false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.camera.request();
      final bridge = ref.read(nativeBridgeProvider);
      await bridge.requestCameraPermission();
      state = status.isGranted;
      return state;
    } catch (_) {
      state = false;
      return false;
    }
  }
}

final cameraPermissionProvider =
    NotifierProvider<CameraPermissionNotifier, bool>(
  CameraPermissionNotifier.new,
);

/// Provider managing Unlock Events and Photos History
class UnlockHistoryNotifier extends Notifier<List<UnlockRecord>> {
  StreamSubscription<String>? _eventSubscription;

  @override
  List<UnlockRecord> build() {
    _listenToEvents();
    refresh();
    ref.onDispose(() {
      _eventSubscription?.cancel();
    });
    return [];
  }

  void _listenToEvents() {
    final bridge = ref.read(nativeBridgeProvider);
    _eventSubscription?.cancel();
    _eventSubscription = bridge.unlockEventsStream.listen((eventJson) {
      try {
        final map = jsonDecode(eventJson);
        if (map is Map<String, dynamic>) {
          final newRecord = UnlockRecord.fromMap(map);
          state = [newRecord, ...state.where((r) => r.id != newRecord.id)];
        }
      } catch (e) {
        debugPrint('Error parsing real-time unlock event: $e');
      }
    });
  }

  Future<void> refresh() async {
    try {
      final bridge = ref.read(nativeBridgeProvider);
      final jsonString = await bridge.getUnlockHistory();
      final List<dynamic> decoded = jsonDecode(jsonString);
      final records = decoded
          .map((item) => UnlockRecord.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
      state = records;
    } catch (e) {
      debugPrint('Error loading unlock history: $e');
    }
  }

  Future<bool> deleteRecord(UnlockRecord record) async {
    try {
      final bridge = ref.read(nativeBridgeProvider);
      final success = await bridge.deleteUnlockPhoto(record.id, record.photoPath);
      if (success) {
        state = state.where((r) => r.id != record.id).toList();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting unlock record: $e');
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      final bridge = ref.read(nativeBridgeProvider);
      final success = await bridge.clearUnlockHistory();
      if (success) {
        state = [];
      }
      return success;
    } catch (e) {
      debugPrint('Error clearing unlock history: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> testCaptureNow() async {
    final bridge = ref.read(nativeBridgeProvider);
    final result = await bridge.captureFrontPhoto();
    await refresh();
    return result;
  }

  Future<bool> simulateUnlock() async {
    final bridge = ref.read(nativeBridgeProvider);
    final success = await bridge.simulateUnlockEvent();
    await Future.delayed(const Duration(milliseconds: 1000));
    await refresh();
    return success;
  }
}

final unlockHistoryProvider =
    NotifierProvider<UnlockHistoryNotifier, List<UnlockRecord>>(
  UnlockHistoryNotifier.new,
);
