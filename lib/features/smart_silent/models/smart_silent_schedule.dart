import 'dart:convert';
import 'package:flutter/material.dart';

class SmartSilentSchedule {
  final String id;
  final String title; // e.g. "Meeting", "Office", "Night Rest"
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final List<int> daysOfWeek; // 1 = Mon, 7 = Sun (DateTime weekday format)
  final bool isEnabled;
  final String silenceScope; // 'both' (Phone + Voice Announce), 'announce_only', 'phone_only'
  
  // Optional Location-based trigger
  final bool isLocationEnabled;
  final String? locationName; // e.g. "Office", "Meeting Room", "Conference Hall"
  final double? latitude;
  final double? longitude;
  final double radiusMeters; // default 200m

  const SmartSilentSchedule({
    required this.id,
    required this.title,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.daysOfWeek = const [1, 2, 3, 4, 5], // Monday to Friday by default
    this.isEnabled = true,
    this.silenceScope = 'both',
    this.isLocationEnabled = false,
    this.locationName,
    this.latitude,
    this.longitude,
    this.radiusMeters = 200.0,
  });

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  String formatTime(BuildContext context, int hour, int minute) {
    final tod = TimeOfDay(hour: hour, minute: minute);
    return tod.format(context);
  }

  String formatTimeRange(BuildContext context) {
    return '${formatTime(context, startHour, startMinute)} → ${formatTime(context, endHour, endMinute)}';
  }

  /// Evaluates whether this schedule is currently within active time on the given DateTime
  bool isTimeActive(DateTime now) {
    if (!isEnabled) return false;
    if (!daysOfWeek.contains(now.weekday)) return false;

    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    final currentMinutes = now.hour * 60 + now.minute;

    if (startMinutes <= endMinutes) {
      // Normal range within same day (e.g., 10:00 AM to 11:00 AM)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Overnight range spanning midnight (e.g., 11:00 PM to 07:00 AM)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  SmartSilentSchedule copyWith({
    String? id,
    String? title,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<int>? daysOfWeek,
    bool? isEnabled,
    String? silenceScope,
    bool? isLocationEnabled,
    String? locationName,
    double? latitude,
    double? longitude,
    double? radiusMeters,
  }) {
    return SmartSilentSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      silenceScope: silenceScope ?? this.silenceScope,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
      'silenceScope': silenceScope,
      'isLocationEnabled': isLocationEnabled,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    };
  }

  factory SmartSilentSchedule.fromMap(Map<String, dynamic> map) {
    return SmartSilentSchedule(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Schedule',
      startHour: (map['startHour'] as num?)?.toInt() ?? 10,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 11,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 0,
      daysOfWeek: (map['daysOfWeek'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ??
          const [1, 2, 3, 4, 5],
      isEnabled: map['isEnabled'] as bool? ?? true,
      silenceScope: map['silenceScope']?.toString() ?? 'both',
      isLocationEnabled: map['isLocationEnabled'] as bool? ?? false,
      locationName: map['locationName']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 200.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory SmartSilentSchedule.fromJson(String source) =>
      SmartSilentSchedule.fromMap(json.decode(source) as Map<String, dynamic>);
}
