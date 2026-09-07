import 'package:permission_handler/permission_handler.dart';
import '../../services/native_bridge_service.dart';

class PermissionService {
  final NativeBridgeService _nativeBridge = NativeBridgeService();

  Future<bool> checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.contacts,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.notification,
    ].request();

    // Trigger native permission request for READ_CALL_LOG, READ_PHONE_STATE, READ_CONTACTS
    await _nativeBridge.requestPermissions();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    final nativeGranted = await _nativeBridge.arePermissionsGranted();
    return allGranted && nativeGranted;
  }

  Future<bool> arePermissionsGranted() async {
    bool phone = await Permission.phone.isGranted;
    bool contacts = await Permission.contacts.isGranted;
    bool btConnect = await Permission.bluetoothConnect.isGranted;
    bool btScan = await Permission.bluetoothScan.isGranted;
    bool nativeGranted = await _nativeBridge.arePermissionsGranted();
    
    return phone && contacts && btConnect && btScan && nativeGranted;
  }
}
