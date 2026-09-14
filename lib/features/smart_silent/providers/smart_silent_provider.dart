import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/native_bridge_service.dart';
import '../models/smart_silent_schedule.dart';

final nativeBridgeProvider = Provider<NativeBridgeService>((ref) => NativeBridgeService());

class SmartSilentState {
  final bool isMasterEnabled;
  final List<SmartSilentSchedule> schedules;
  final String? activeScheduleTitle;
  final bool isCurrentlySilenced;

  const SmartSilentState({
    this.isMasterEnabled = true,
    this.schedules = const [],
    this.activeScheduleTitle,
    this.isCurrentlySilenced = false,
  });

  SmartSilentState copyWith({
    bool? isMasterEnabled,
    List<SmartSilentSchedule>? schedules,
    String? Function()? activeScheduleTitle,
    bool? isCurrentlySilenced,
  }) {
    return SmartSilentState(
      isMasterEnabled: isMasterEnabled ?? this.isMasterEnabled,
      schedules: schedules ?? this.schedules,
      activeScheduleTitle: activeScheduleTitle != null ? activeScheduleTitle() : this.activeScheduleTitle,
      isCurrentlySilenced: isCurrentlySilenced ?? this.isCurrentlySilenced,
    );
  }
}

class SmartSilentNotifier extends AsyncNotifier<SmartSilentState> {
  static const _keySchedules = 'smart_silent_schedules_v1';
  static const _keyMasterEnabled = 'smart_silent_master_enabled';
  Timer? _ticker;

  @override
  Future<SmartSilentState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final masterEnabled = prefs.getBool(_keyMasterEnabled) ?? true;
    final savedJson = prefs.getString(_keySchedules);

    List<SmartSilentSchedule> schedules;
    if (savedJson != null && savedJson.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(savedJson);
        schedules = list.map((item) => SmartSilentSchedule.fromMap(item as Map<String, dynamic>)).toList();
      } catch (_) {
        schedules = _defaultPresets();
      }
    } else {
      schedules = _defaultPresets();
      await prefs.setString(_keySchedules, json.encode(schedules.map((s) => s.toMap()).toList()));
    }

    // Start periodic evaluation timer (every 30 seconds)
    _startPeriodicChecker();

    final initialState = SmartSilentState(
      isMasterEnabled: masterEnabled,
      schedules: schedules,
    );

    return _evaluateActiveState(initialState);
  }

  static List<SmartSilentSchedule> _defaultPresets() {
    return const [
      SmartSilentSchedule(
        id: 'meeting_preset',
        title: 'Meeting',
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5], // Mon-Fri
        isEnabled: true,
        silenceScope: 'both',
        isLocationEnabled: false,
        locationName: null,
      ),
      SmartSilentSchedule(
        id: 'office_preset',
        title: 'Office Work',
        startHour: 9,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5], // Mon-Fri
        isEnabled: false,
        silenceScope: 'both',
        isLocationEnabled: true,
        locationName: 'Office',
      ),
      SmartSilentSchedule(
        id: 'sleep_preset',
        title: 'Night Rest',
        startHour: 23,
        startMinute: 0,
        endHour: 7,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // All days
        isEnabled: false,
        silenceScope: 'both',
        isLocationEnabled: false,
      ),
    ];
  }

  void _startPeriodicChecker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      checkActiveSchedule();
    });
  }

  SmartSilentState _evaluateActiveState(SmartSilentState current) {
    if (!current.isMasterEnabled) {
      return current.copyWith(
        activeScheduleTitle: () => null,
        isCurrentlySilenced: false,
      );
    }

    final now = DateTime.now();
    for (final schedule in current.schedules) {
      if (schedule.isTimeActive(now)) {
        return current.copyWith(
          activeScheduleTitle: () => schedule.title,
          isCurrentlySilenced: true,
        );
      }
    }

    return current.copyWith(
      activeScheduleTitle: () => null,
      isCurrentlySilenced: false,
    );
  }

  Future<void> checkActiveSchedule() async {
    final current = state.value;
    if (current == null) return;

    final updated = _evaluateActiveState(current);
    if (updated.isCurrentlySilenced != current.isCurrentlySilenced ||
        updated.activeScheduleTitle != current.activeScheduleTitle) {
      state = AsyncData(updated);

      final bridge = ref.read(nativeBridgeProvider);
      if (updated.isCurrentlySilenced) {
        await bridge.setRingerMode('silent');
      } else {
        await bridge.setRingerMode('normal');
      }
    }
  }

  Future<void> toggleMaster(bool isEnabled) async {
    final current = state.value;
    if (current == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMasterEnabled, isEnabled);

    final updated = current.copyWith(isMasterEnabled: isEnabled);
    state = AsyncData(_evaluateActiveState(updated));

    final bridge = ref.read(nativeBridgeProvider);
    if (!isEnabled) {
      await bridge.setRingerMode('normal');
    } else {
      await checkActiveSchedule();
    }
  }

  Future<void> addSchedule(SmartSilentSchedule schedule) async {
    final current = state.value;
    if (current == null) return;

    final newList = [...current.schedules, schedule];
    await _saveSchedules(newList);

    final updated = current.copyWith(schedules: newList);
    state = AsyncData(_evaluateActiveState(updated));
    await checkActiveSchedule();
  }

  Future<void> updateSchedule(SmartSilentSchedule schedule) async {
    final current = state.value;
    if (current == null) return;

    final newList = current.schedules.map((s) => s.id == schedule.id ? schedule : s).toList();
    await _saveSchedules(newList);

    final updated = current.copyWith(schedules: newList);
    state = AsyncData(_evaluateActiveState(updated));
    await checkActiveSchedule();
  }

  Future<void> toggleSchedule(String id, bool isEnabled) async {
    final current = state.value;
    if (current == null) return;

    final newList = current.schedules.map((s) {
      if (s.id == id) {
        return s.copyWith(isEnabled: isEnabled);
      }
      return s;
    }).toList();

    await _saveSchedules(newList);
    final updated = current.copyWith(schedules: newList);
    state = AsyncData(_evaluateActiveState(updated));
    await checkActiveSchedule();
  }

  Future<void> deleteSchedule(String id) async {
    final current = state.value;
    if (current == null) return;

    final newList = current.schedules.where((s) => s.id != id).toList();
    await _saveSchedules(newList);

    final updated = current.copyWith(schedules: newList);
    state = AsyncData(_evaluateActiveState(updated));
    await checkActiveSchedule();
  }

  Future<void> _saveSchedules(List<SmartSilentSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(schedules.map((s) => s.toMap()).toList());
    await prefs.setString(_keySchedules, jsonStr);
  }
}

final smartSilentProvider =
    AsyncNotifierProvider<SmartSilentNotifier, SmartSilentState>(SmartSilentNotifier.new);
