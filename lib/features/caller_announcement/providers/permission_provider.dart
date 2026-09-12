import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/permissions/permission_service.dart';

import '../../contact_announce/providers/contact_rule_provider.dart';

final permissionServiceProvider = Provider((ref) => PermissionService());

final permissionStatusProvider = NotifierProvider<PermissionNotifier, bool>(() {
  return PermissionNotifier();
});

final contactsPermissionProvider = NotifierProvider<ContactsPermissionNotifier, bool>(() {
  return ContactsPermissionNotifier();
});

class ContactsPermissionNotifier extends Notifier<bool> {
  @override
  bool build() {
    checkPermission();
    return false;
  }

  Future<void> checkPermission() async {
    final service = ref.read(permissionServiceProvider);
    final granted = await service.isContactsPermissionGranted();
    state = granted;
  }

  Future<bool> requestPermission() async {
    final service = ref.read(permissionServiceProvider);
    final granted = await service.requestContactsPermission();
    state = granted;
    if (granted) {
      await ref.read(contactRulesProvider.notifier).refreshFromDevice();
      ref.read(permissionStatusProvider.notifier).checkPermissions();
    }
    return granted;
  }
}

class PermissionNotifier extends Notifier<bool> {
  @override
  bool build() {
    checkPermissions();
    return false;
  }

  Future<void> checkPermissions() async {
    final service = ref.read(permissionServiceProvider);
    final granted = await service.arePermissionsGranted();
    final contactsGranted = await service.isContactsPermissionGranted();
    ref.read(contactsPermissionProvider.notifier).state = contactsGranted;
    state = granted;
  }

  Future<void> requestPermissions() async {
    final service = ref.read(permissionServiceProvider);
    final granted = await service.checkAndRequestPermissions();
    final contactsGranted = await service.isContactsPermissionGranted();
    ref.read(contactsPermissionProvider.notifier).state = contactsGranted;
    state = granted;
    if (contactsGranted) {
      await ref.read(contactRulesProvider.notifier).refreshFromDevice();
    }
  }
}
