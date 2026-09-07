import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/permissions/permission_service.dart';

final permissionServiceProvider = Provider((ref) => PermissionService());

final permissionStatusProvider = NotifierProvider<PermissionNotifier, bool>(() {
  return PermissionNotifier();
});

class PermissionNotifier extends Notifier<bool> {
  @override
  bool build() {
    checkPermissions();
    return false;
  }

  Future<void> checkPermissions() async {
    final service = ref.read(permissionServiceProvider);
    final granted = await service.arePermissionsGranted();
    state = granted;
  }

  Future<void> requestPermissions() async {
    final service = ref.read(permissionServiceProvider);
    final granted = await service.checkAndRequestPermissions();
    state = granted;
  }
}
