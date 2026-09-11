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
}
