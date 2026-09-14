import 'package:permission_handler/permission_handler.dart';
import '../../services/native_bridge_service.dart';

class PermissionService {
  final NativeBridgeService _nativeBridge = NativeBridgeService();

  /// Mandatory permissions required for the core caller announcer to function.
  /// Note: bluetoothScan and bluetoothConnect are NOT mandatory for core announcement.
  Future<bool> checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.contacts,
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

  /// Checks if all mandatory core permissions are granted.
  Future<bool> arePermissionsGranted() async {
    bool phone = await Permission.phone.isGranted;
    bool contacts = await Permission.contacts.isGranted;
    bool notification = await Permission.notification.isGranted;
    bool nativeGranted = await _nativeBridge.arePermissionsGranted();

    return phone && contacts && notification && nativeGranted;
  }

  Future<bool> isContactsPermissionGranted() async {
    return await Permission.contacts.isGranted;
  }

  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Optional: Specifically for Bluetooth/Headphones announcement mode
  Future<bool> isBluetoothPermissionGranted() async {
    return await Permission.bluetoothConnect.isGranted;
  }

  /// Optional: Requests BLUETOOTH_CONNECT when user activates Headphone/Bluetooth mode
  Future<bool> requestBluetoothPermission() async {
    final status = await Permission.bluetoothConnect.request();
    return status.isGranted;
  }
}
