import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/native_bridge_service.dart';
import 'dart:async';

final nativeBridgeProvider = Provider((ref) => NativeBridgeService());

final bluetoothStatusProvider = NotifierProvider<BluetoothStatusNotifier, bool>(() {
  return BluetoothStatusNotifier();
});

class BluetoothStatusNotifier extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      checkStatus();
    });
    
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    return false;
  }

  Future<void> checkStatus() async {
    final nativeBridge = ref.read(nativeBridgeProvider);
    final status = await nativeBridge.getBluetoothStatus();
    if (state != status) {
      state = status;
    }
  }
}
