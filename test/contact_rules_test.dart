import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:callspeak/features/contact_announce/services/contact_rule_service.dart';
import 'package:callspeak/features/contact_announce/presentation/widgets/protected_template_field.dart';

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

  group('MandatoryPlaceholderFormatter Tests', () {
    const formatter = MandatoryPlaceholderFormatter('{name}');

    test('Allows typing text before {name}', () {
      const oldValue = TextEditingValue(
        text: '{name}',
        selection: TextSelection.collapsed(offset: 0),
      );
      const newValue = TextEditingValue(
        text: 'Call from {name}',
        selection: TextSelection.collapsed(offset: 10),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('Call from {name}'));
    });

    test('Allows typing text after {name}', () {
      const oldValue = TextEditingValue(
        text: '{name}',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newValue = TextEditingValue(
        text: '{name} is calling',
        selection: TextSelection.collapsed(offset: 17),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('{name} is calling'));
    });

    test('Rejects deletion of {name} when backspacing', () {
      const oldValue = TextEditingValue(
        text: '{name}',
        selection: TextSelection.collapsed(offset: 6),
      );
      // User pressed backspace, deleting '}'
      const newValue = TextEditingValue(
        text: '{name',
        selection: TextSelection.collapsed(offset: 5),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      // Must reject and retain old value
      expect(result.text, equals('{name}'));
    });

    test('Rejects clearing all text or cutting {name}', () {
      const oldValue = TextEditingValue(
        text: '{name} is calling',
        selection: TextSelection(baseOffset: 0, extentOffset: 17),
      );
      // User selected all and deleted
      const newValue = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('{name} is calling'));
    });
  });
}
