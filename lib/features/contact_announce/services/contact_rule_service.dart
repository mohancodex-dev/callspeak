import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_rule.dart';

class ContactRuleService {
  static const String keyContactRules = 'contact_rules_json';
  static const String keyCategoryRules = 'category_rules_json';
  static const String keySmartFeatures = 'smart_features_json';

  Future<List<ContactRule>> loadContactRules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(keyContactRules);
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      // First time initialization: populate default curated sample contact rules
      final initialRules = _getDefaultSampleRules();
      await saveContactRules(initialRules);
      return initialRules;
    }

    try {
      final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded.map((e) => ContactRule.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getDefaultSampleRules();
    }
  }

  Future<void> saveContactRules(List<ContactRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(rules.map((r) => r.toMap()).toList());
    await prefs.setString(keyContactRules, jsonStr);
  }

  Future<void> saveSingleRule(ContactRule rule) async {
    final rules = await loadContactRules();
    final index = rules.indexWhere((r) => r.id == rule.id || r.phoneNumber == rule.phoneNumber);
    if (index >= 0) {
      rules[index] = rule;
    } else {
      rules.add(rule);
    }
    await saveContactRules(rules);
  }

  Future<void> deleteRule(String ruleId) async {
    final rules = await loadContactRules();
    rules.removeWhere((r) => r.id == ruleId);
    await saveContactRules(rules);
  }

  Future<CategoryRulesConfig> loadCategoryRules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(keyCategoryRules);
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      final defaultConfig = CategoryRulesConfig.defaultConfig();
      await saveCategoryRules(defaultConfig);
      return defaultConfig;
    }

    try {
      return CategoryRulesConfig.fromJson(jsonStr);
    } catch (e) {
      return CategoryRulesConfig.defaultConfig();
    }
  }

  Future<void> saveCategoryRules(CategoryRulesConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCategoryRules, config.toJson());
  }

  Future<SmartFeatureConfig> loadSmartFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(keySmartFeatures);
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      return const SmartFeatureConfig();
    }

    try {
      return SmartFeatureConfig.fromJson(jsonStr);
    } catch (e) {
      return const SmartFeatureConfig();
    }
  }

  Future<void> saveSmartFeatures(SmartFeatureConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySmartFeatures, config.toJson());
  }

  static List<ContactRule> _getDefaultSampleRules() {
    return [
      const ContactRule(
        id: 'contact_1',
        name: 'Mom',
        phoneNumber: '+91 98765 43210',
        avatarColorIndex: 0,
        isEnabled: true,
        customText: 'Mom is calling! Please pick up the call.',
        language: 'en-US',
        volume: 1.0,
        speechRate: 1.0,
        repeatMode: 'until_answered',
        bluetoothOnly: false,
        isVip: true,
        relationshipTag: 'family',
      ),
      const ContactRule(
        id: 'contact_2',
        name: 'Project Manager',
        phoneNumber: '+91 91234 56789',
        avatarColorIndex: 1,
        isEnabled: true,
        customText: 'Incoming office call from Project Manager.',
        language: 'en-US',
        volume: 0.9,
        speechRate: 1.1,
        repeatMode: 'twice',
        bluetoothOnly: false,
        isVip: false,
        relationshipTag: 'work',
      ),
      const ContactRule(
        id: 'contact_3',
        name: 'Dr. Sameer (Clinic)',
        phoneNumber: '+91 94567 89012',
        avatarColorIndex: 2,
        isEnabled: true,
        customText: 'Urgent medical call from Doctor Sameer.',
        language: 'en-US',
        volume: 1.0,
        speechRate: 0.9,
        repeatMode: 'until_answered',
        bluetoothOnly: false,
        isVip: true,
        relationshipTag: 'emergency',
      ),
      const ContactRule(
        id: 'contact_4',
        name: 'Rahul Sharma',
        phoneNumber: '+91 99887 76655',
        avatarColorIndex: 3,
        isEnabled: true,
        customText: 'Rahul is calling you buddy!',
        language: 'hi-IN',
        volume: 0.8,
        speechRate: 1.0,
        repeatMode: 'twice',
        bluetoothOnly: false,
        isVip: false,
        relationshipTag: 'friend',
      ),
      const ContactRule(
        id: 'contact_5',
        name: 'Telemarketing / Spam',
        phoneNumber: '+91 14098 76543',
        avatarColorIndex: 4,
        isEnabled: false,
        customText: 'Muted Spam Caller',
        language: 'en-US',
        volume: 0.0,
        speechRate: 1.0,
        repeatMode: 'once',
        bluetoothOnly: false,
        isVip: false,
        relationshipTag: 'general',
      ),
    ];
  }
}
