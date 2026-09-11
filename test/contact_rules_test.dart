import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:callspeak/features/contact_announce/services/contact_rule_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContactRuleService Dummy Data Tests', () {
    test('loadContactRules returns empty list when no data is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ContactRuleService();
      final rules = await service.loadContactRules();
      expect(rules, isEmpty);
    });

    test('loadContactRules purges legacy dummy sample contacts', () async {
      final dummyJson = json.encode([
        {
          'id': 'contact_1',
          'name': 'Mom',
          'phoneNumber': '+91 98765 43210',
          'avatarColorIndex': 0,
          'isEnabled': true,
          'customText': 'Mom is calling!',
          'language': 'en-US',
          'volume': 1.0,
          'speechRate': 1.0,
          'repeatMode': 'until_answered',
          'bluetoothOnly': false,
          'isVip': true,
          'relationshipTag': 'family',
          'isCustomized': false,
        },
        {
          'id': 'client_user_999',
          'name': 'Actual Client',
          'phoneNumber': '+91 97777 88888',
          'avatarColorIndex': 2,
          'isEnabled': true,
          'customText': 'Actual Client is calling',
          'language': 'en-US',
          'volume': 1.0,
          'speechRate': 1.0,
          'repeatMode': 'three_times',
          'bluetoothOnly': false,
          'isVip': false,
          'relationshipTag': 'work',
          'isCustomized': true,
        },
      ]);

      SharedPreferences.setMockInitialValues({
        ContactRuleService.keyContactRules: dummyJson,
      });

      final service = ContactRuleService();
      final rules = await service.loadContactRules();

      // The dummy contact 'contact_1' must be removed
      expect(rules.length, equals(1));
      expect(rules.first.id, equals('client_user_999'));
      expect(rules.first.name, equals('Actual Client'));

      // Check that SharedPreferences was updated to remove the dummy contact
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(ContactRuleService.keyContactRules);
      expect(savedJson, isNotNull);
      expect(savedJson!.contains('contact_1'), isFalse);
      expect(savedJson.contains('Actual Client'), isTrue);
    });
  });
}
