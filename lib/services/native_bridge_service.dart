import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants/channel_constants.dart';

class NativeBridgeService {
  final MethodChannel _methodChannel = const MethodChannel(ChannelConstants.methodChannel);

  Future<bool> testAnnouncement() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('testAnnouncement');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to test announcement: '${e.message}'.");
      return false;
    }
  }

  Future<bool> getBluetoothStatus() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('getBluetoothStatus');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to get bluetooth status: '${e.message}'.");
      return false;
    }
  }

  Future<bool> startService() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('startService');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to start service: '${e.message}'.");
      return false;
    }
  }

  Future<bool> stopService() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('stopService');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to stop service: '${e.message}'.");
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to request permissions: '${e.message}'.");
      return false;
    }
  }

  Future<bool> arePermissionsGranted() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('arePermissionsGranted');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to check permissions: '${e.message}'.");
      return false;
    }
  }

  Future<List<Map<String, String>>> getDeviceContacts() async {
    try {
      final result = await _methodChannel.invokeListMethod<Map<dynamic, dynamic>>('getContacts');
      if (result == null) return [];
      return result.map((item) {
        return {
          'name': item['name']?.toString() ?? 'Unknown',
          'number': item['number']?.toString() ?? '',
          'id': item['id']?.toString() ?? '',
        };
      }).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get contacts: '${e.message}'.");
      return [];
    }
  }

  Future<bool> previewAnnouncement({
    required String text,
    required String language,
    required double speechRate,
    required double volume,
    String repeatMode = 'three_times',
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('previewAnnouncement', {
        'text': text,
        'language': language,
        'speechRate': speechRate,
        'volume': volume,
        'repeatMode': repeatMode,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to preview announcement: '${e.message}'.");
      return false;
    }
  }

    Future<bool> stopAnnouncement() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('stopAnnouncement');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to stop announcement: '${e.message}'.");
      return false;
    }
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return result ?? true;
    } on PlatformException catch (e) {
      debugPrint("Failed to check battery optimization: '${e.message}'.");
      return true;
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to request battery optimization exemption: '${e.message}'.");
      return false;
    }
  }

  Future<bool> openTtsSettings() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('openTtsSettings');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to open TTS settings: '${e.message}'.");
      return false;
    }
  }

  Future<bool> openBatterySettings() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('openBatterySettings');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to open battery settings: '${e.message}'.");
      return false;
    }
  }

  Future<bool> setRingerMode(String mode) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('setRingerMode', {'mode': mode});
      return result ?? false;
    } catch (e) {
      debugPrint("Failed to set ringer mode: '$e'.");
      return false;
    }
  }

  Future<String> getRingerMode() async {
    try {
      final result = await _methodChannel.invokeMethod<String>('getRingerMode');
      return result ?? 'normal';
    } catch (e) {
      debugPrint("Failed to get ringer mode: '$e'.");
      return 'normal';
    }
  }

  Future<bool> isDndAccessGranted() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isDndAccessGranted');
      return result ?? false;
    } catch (e) {
      debugPrint("Failed to check DND access: '$e'.");
      return false;
    }
  }

  Future<bool> openDndSettings() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('openDndSettings');
      return result ?? false;
    } catch (e) {
      debugPrint("Failed to open DND settings: '$e'.");
      return false;
    }
  }

  // --- Automatic Unlock Capture Bridge Methods ---

  Future<bool> isCameraPermissionGranted() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isCameraPermissionGranted');
      return result ?? false;
    } catch (e) {
      debugPrint("Failed to check camera permission: '$e'.");
      return false;
    }
  }

  Future<bool> requestCameraPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('requestCameraPermission');
      return result ?? false;
    } catch (e) {
      debugPrint("Failed to request camera permission: '$e'.");
      return false;
    }
  }

  Future<Map<String, dynamic>> captureFrontPhoto() async {
    try {
      final result = await _methodChannel.invokeMapMethod<dynamic, dynamic>('captureFrontPhoto');
      if (result == null) return {'success': false, 'error': 'Null result from native camera'};
      return {
        'success': result['success'] == true,
        'photoPath': result['photoPath']?.toString(),
        'error': result['error']?.toString(),
      };
    } catch (e) {
      debugPrint("Failed to capture front photo: '$e'.");
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<String> getUnlockHistory() async {
    try {
      final result = await _methodChannel.invokeMethod<String>('getUnlockHistory');
      return result ?? '[]';
    } catch (e) {
      debugPrint("Failed to fetch unlock history: '$e'.");
      return '[]';
    }
  }

  Future<bool> clearUnlockHistory() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('clearUnlockHistory');
      return result ?? false;
    } catch (e) {
      debugPrint("Failed to clear unlock history: '$e'.");
      return false;
    }
  }

  Future<bool> deleteUnlockPhoto(String id, String? photoPath) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('deleteUnlockPhoto', {
        'id': id,
        'photoPath': photoPath ?? '',
      });
      return result ?? false;
    } catch (e) {
      debugPrint("Failed to delete unlock photo: '$e'.");
      return false;
    }
  }

  Future<bool> simulateUnlockEvent() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('simulateUnlockEvent');
      return result ?? false;
    } catch (e) {
      debugPrint("Failed to simulate unlock event: '$e'.");
      return false;
    }
  }

  Stream<String> get unlockEventsStream {
    const eventChannel = EventChannel(ChannelConstants.eventChannel);
    return eventChannel.receiveBroadcastStream().map((event) => event.toString());
  }
}

