import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.contacts,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.notification,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });
    return allGranted;
  }

  Future<bool> arePermissionsGranted() async {
    bool phone = await Permission.phone.isGranted;
    bool contacts = await Permission.contacts.isGranted;
    bool btConnect = await Permission.bluetoothConnect.isGranted;
    bool btScan = await Permission.bluetoothScan.isGranted;
    
    return phone && contacts && btConnect && btScan;
  }
}
