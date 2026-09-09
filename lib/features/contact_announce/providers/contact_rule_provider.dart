import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_rule.dart';
import '../services/contact_rule_service.dart';
import '../../../services/native_bridge_service.dart';

final contactRuleServiceProvider = Provider<ContactRuleService>((ref) {
  return ContactRuleService();
});

final nativeBridgeProvider = Provider<NativeBridgeService>((ref) {
  return NativeBridgeService();
});

enum ContactFilter { all, customized, vip, muted }

class ContactSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String val) => super.state = val;
}

final contactSearchProvider = NotifierProvider<ContactSearchNotifier, String>(ContactSearchNotifier.new);

class ContactFilterNotifier extends Notifier<ContactFilter> {
  @override
  ContactFilter build() => ContactFilter.all;

  @override
  set state(ContactFilter val) => super.state = val;
}

final contactFilterProvider = NotifierProvider<ContactFilterNotifier, ContactFilter>(ContactFilterNotifier.new);

class ContactRulesNotifier extends AsyncNotifier<List<ContactRule>> {
  @override
  Future<List<ContactRule>> build() async {
    final service = ref.read(contactRuleServiceProvider);
    final savedRules = await service.loadContactRules();

    // Attempt background merge with device contacts if available
    _mergeWithDeviceContacts(savedRules);

    return savedRules;
  }

  Future<void> _mergeWithDeviceContacts(List<ContactRule> currentRules) async {
    try {
      final nativeBridge = ref.read(nativeBridgeProvider);
      final deviceContacts = await nativeBridge.getDeviceContacts();
      if (deviceContacts.isEmpty) return;

      final existingNumbers = currentRules.map((r) => _normalizeNumber(r.phoneNumber)).toSet();
      final List<ContactRule> merged = List.from(currentRules);
      bool changed = false;

      int colorIndex = (currentRules.length) % 6;
      for (final dc in deviceContacts) {
        final number = dc['number'] ?? '';
        final norm = _normalizeNumber(number);
        if (norm.length >= 7 && !existingNumbers.contains(norm)) {
          existingNumbers.add(norm);
          merged.add(ContactRule(
            id: dc['id']?.isNotEmpty == true ? dc['id']! : 'device_${DateTime.now().millisecondsSinceEpoch}_$colorIndex',
            name: dc['name'] ?? 'Unknown',
            phoneNumber: number,
            avatarColorIndex: colorIndex % 6,
            isEnabled: true,
            customText: '${dc['name'] ?? 'Someone'} is calling',
            language: 'en-US',
            volume: 1.0,
            speechRate: 1.0,
            repeatMode: 'twice',
            bluetoothOnly: false,
            isVip: false,
            relationshipTag: 'general',
          ));
          colorIndex++;
          changed = true;
        }
      }

      if (changed) {
        final service = ref.read(contactRuleServiceProvider);
        await service.saveContactRules(merged);
        state = AsyncValue.data(merged);
      }
    } catch (_) {
      // Ignore background merge failure
    }
  }

  String _normalizeNumber(String raw) {
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> saveRule(ContactRule rule) async {
    final service = ref.read(contactRuleServiceProvider);
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((r) => r.id == rule.id || r.phoneNumber == rule.phoneNumber);
    
    final updatedList = List<ContactRule>.from(currentList);
    if (index >= 0) {
      updatedList[index] = rule;
    } else {
      updatedList.insert(0, rule);
    }

    state = AsyncValue.data(updatedList);
    await service.saveContactRules(updatedList);
  }

  Future<void> toggleRule(String ruleId) async {
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((r) => r.id == ruleId);
    if (index >= 0) {
      final oldRule = currentList[index];
      final newRule = oldRule.copyWith(isEnabled: !oldRule.isEnabled);
      final updatedList = List<ContactRule>.from(currentList);
      updatedList[index] = newRule;
      state = AsyncValue.data(updatedList);

      final service = ref.read(contactRuleServiceProvider);
      await service.saveContactRules(updatedList);
    }
  }

  Future<void> deleteRule(String ruleId) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.where((r) => r.id != ruleId).toList();
    state = AsyncValue.data(updatedList);

    final service = ref.read(contactRuleServiceProvider);
    await service.saveContactRules(updatedList);
  }

  Future<void> refreshFromDevice() async {
    final currentList = state.value ?? [];
    await _mergeWithDeviceContacts(currentList);
  }
}

final contactRulesProvider = AsyncNotifierProvider<ContactRulesNotifier, List<ContactRule>>(() {
  return ContactRulesNotifier();
});

final filteredContactRulesProvider = Provider<List<ContactRule>>((ref) {
  final rulesAsync = ref.watch(contactRulesProvider);
  final search = ref.watch(contactSearchProvider).trim().toLowerCase();
  final filter = ref.watch(contactFilterProvider);

  final rules = rulesAsync.value ?? [];

  return rules.where((rule) {
    // Search match
    final matchesSearch = search.isEmpty ||
        rule.name.toLowerCase().contains(search) ||
        rule.phoneNumber.toLowerCase().contains(search) ||
        rule.customText.toLowerCase().contains(search);

    if (!matchesSearch) return false;

    // Filter match
    return switch (filter) {
      ContactFilter.all => true,
      ContactFilter.customized => rule.customText != '{name} is calling' || rule.repeatMode != 'twice' || rule.speechRate != 1.0,
      ContactFilter.vip => rule.isVip,
      ContactFilter.muted => !rule.isEnabled,
    };
  }).toList();
});

class CategoryRulesNotifier extends AsyncNotifier<CategoryRulesConfig> {
  @override
  Future<CategoryRulesConfig> build() async {
    final service = ref.read(contactRuleServiceProvider);
    return await service.loadCategoryRules();
  }

  Future<void> updateConfig(CategoryRulesConfig newConfig) async {
    state = AsyncValue.data(newConfig);
    final service = ref.read(contactRuleServiceProvider);
    await service.saveCategoryRules(newConfig);
  }
}

final categoryRulesProvider = AsyncNotifierProvider<CategoryRulesNotifier, CategoryRulesConfig>(() {
  return CategoryRulesNotifier();
});

class SmartFeaturesNotifier extends AsyncNotifier<SmartFeatureConfig> {
  @override
  Future<SmartFeatureConfig> build() async {
    final service = ref.read(contactRuleServiceProvider);
    return await service.loadSmartFeatures();
  }

  Future<void> updateConfig(SmartFeatureConfig newConfig) async {
    state = AsyncValue.data(newConfig);
    final service = ref.read(contactRuleServiceProvider);
    await service.saveSmartFeatures(newConfig);
  }
}

final smartFeaturesProvider = AsyncNotifierProvider<SmartFeaturesNotifier, SmartFeatureConfig>(() {
  return SmartFeaturesNotifier();
});
