import 'package:flutter/services.dart';
import '../core/constants/channel_constants.dart';

class NativeBridgeService {
  final MethodChannel _methodChannel = const MethodChannel(ChannelConstants.methodChannel);
  final EventChannel _eventChannel = const EventChannel(ChannelConstants.eventChannel);

  Future<bool> testAnnouncement() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('testAnnouncement');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to test announcement: '${e.message}'.");
      return false;
    }
  }

  Future<bool> getBluetoothStatus() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('getBluetoothStatus');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to get bluetooth status: '${e.message}'.");
      return false;
    }
  }
}
