import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:callspeak/features/smart_silent/models/smart_silent_schedule.dart';
import 'package:callspeak/features/smart_silent/providers/smart_silent_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartSilentSchedule Model Tests', () {
    test('Serializes to and from Map correctly including optional location', () {
      const schedule = SmartSilentSchedule(
        id: 'test_meeting',
        title: 'Important Meeting',
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5],
        isEnabled: true,
        silenceScope: 'both',
        isLocationEnabled: true,
        locationName: 'Headquarters Conf Room',
        latitude: 19.0760,
        longitude: 72.8777,
        radiusMeters: 300.0,
      );

      final map = schedule.toMap();
      final fromMap = SmartSilentSchedule.fromMap(map);

      expect(fromMap.id, equals('test_meeting'));
      expect(fromMap.title, equals('Important Meeting'));
      expect(fromMap.startHour, equals(10));
      expect(fromMap.startMinute, equals(0));
      expect(fromMap.endHour, equals(11));
      expect(fromMap.endMinute, equals(0));
      expect(fromMap.isLocationEnabled, isTrue);
      expect(fromMap.locationName, equals('Headquarters Conf Room'));
      expect(fromMap.latitude, equals(19.0760));
      expect(fromMap.longitude, equals(72.8777));
      expect(fromMap.radiusMeters, equals(300.0));
      expect(fromMap.daysOfWeek, equals([1, 2, 3, 4, 5]));
    });

    test('isTimeActive correctly evaluates daytime range (10:00 AM -> 11:00 AM)', () {
      const schedule = SmartSilentSchedule(
        id: 'meeting_10_11',
        title: 'Meeting',
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5], // Mon to Fri
        isEnabled: true,
      );

      // Monday at 10:30 AM -> Active
      final mondayDuring = DateTime(2026, 9, 14, 10, 30); // 2026-09-14 is Monday (weekday 1)
      expect(schedule.isTimeActive(mondayDuring), isTrue);

      // Monday at 11:05 AM -> Inactive (End time passed)
      final mondayAfter = DateTime(2026, 9, 14, 11, 5);
      expect(schedule.isTimeActive(mondayAfter), isFalse);

      // Monday at 09:55 AM -> Inactive (Before start time)
      final mondayBefore = DateTime(2026, 9, 14, 9, 55);
      expect(schedule.isTimeActive(mondayBefore), isFalse);

      // Sunday at 10:30 AM -> Inactive (Sunday is weekday 7, not in daysOfWeek)
      final sundayDuring = DateTime(2026, 9, 20, 10, 30);
      expect(schedule.isTimeActive(sundayDuring), isFalse);
    });

    test('isTimeActive correctly evaluates overnight range (23:00 -> 07:00)', () {
      const schedule = SmartSilentSchedule(
        id: 'sleep_schedule',
        title: 'Night Sleep',
        startHour: 23,
        startMinute: 0,
        endHour: 7,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        isEnabled: true,
      );

      // 23:30 -> Active
      expect(schedule.isTimeActive(DateTime(2026, 9, 14, 23, 30)), isTrue);

      // 03:15 -> Active
      expect(schedule.isTimeActive(DateTime(2026, 9, 14, 3, 15)), isTrue);

      // 06:59 -> Active
      expect(schedule.isTimeActive(DateTime(2026, 9, 14, 6, 59)), isTrue);

      // 07:05 -> Inactive
      expect(schedule.isTimeActive(DateTime(2026, 9, 14, 7, 5)), isFalse);

      // 14:00 -> Inactive
      expect(schedule.isTimeActive(DateTime(2026, 9, 14, 14, 0)), isFalse);
    });
  });

  group('SmartSilentNotifier Tests', () {
    test('Loads initial default presets when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(smartSilentProvider.future);

      expect(state.isMasterEnabled, isTrue);
      expect(state.schedules.length, equals(3));
      expect(state.schedules.any((s) => s.title == 'Meeting'), isTrue);
      expect(state.schedules.any((s) => s.title == 'Office Work'), isTrue);
    });

    test('Can add, toggle, and delete schedules', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(smartSilentProvider.future);
      final notifier = container.read(smartSilentProvider.notifier);

      // Add new schedule
      const newSchedule = SmartSilentSchedule(
        id: 'custom_study',
        title: 'Library Study',
        startHour: 14,
        startMinute: 0,
        endHour: 16,
        endMinute: 0,
        isLocationEnabled: true,
        locationName: 'Central Library',
      );
      await notifier.addSchedule(newSchedule);

      var currentState = container.read(smartSilentProvider).value!;
      expect(currentState.schedules.any((s) => s.id == 'custom_study'), isTrue);

      // Toggle schedule off
      await notifier.toggleSchedule('custom_study', false);
      currentState = container.read(smartSilentProvider).value!;
      final found = currentState.schedules.firstWhere((s) => s.id == 'custom_study');
      expect(found.isEnabled, isFalse);

      // Delete schedule
      await notifier.deleteSchedule('custom_study');
      currentState = container.read(smartSilentProvider).value!;
      expect(currentState.schedules.any((s) => s.id == 'custom_study'), isFalse);
    });

    test('Master toggle disables automation', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(smartSilentProvider.future);
      final notifier = container.read(smartSilentProvider.notifier);

      await notifier.toggleMaster(false);
      final currentState = container.read(smartSilentProvider).value!;
      expect(currentState.isMasterEnabled, isFalse);
      expect(currentState.isCurrentlySilenced, isFalse);
    });
  });
}
