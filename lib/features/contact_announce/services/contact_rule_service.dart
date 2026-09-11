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
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
      final originalList = decoded.map((e) => ContactRule.fromMap(e as Map<String, dynamic>)).toList();
      // Filter out any legacy dummy sample contacts (e.g. contact_1 .. contact_5)
      final cleanedList = originalList.where((r) => !_isDummyContact(r)).toList();
      if (cleanedList.length != originalList.length) {
        await saveContactRules(cleanedList);
      }
      return cleanedList;
    } catch (e) {
      return [];
    }
  }

  static bool _isDummyContact(ContactRule rule) {
    const dummyIds = {'contact_1', 'contact_2', 'contact_3', 'contact_4', 'contact_5'};
    const dummyNumbers = {
      '+91 98765 43210',
      '+91 91234 56789',
      '+91 94567 89012',
      '+91 99887 76655',
      '+91 14098 76543',
      '9876543210',
      '9123456789',
      '9456789012',
      '9988776655',
      '1409876543',
    };
    final normalized = rule.phoneNumber.replaceAll(RegExp(r'\D'), '');
    return dummyIds.contains(rule.id) || dummyNumbers.contains(rule.phoneNumber) || dummyNumbers.contains(normalized);
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


}
