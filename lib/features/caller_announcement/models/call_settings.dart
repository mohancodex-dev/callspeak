class CallSettings {
  final bool announcementEnabled;
  final bool announceOnlyWithBluetooth;
  final String language;
  final double speechRate;

  CallSettings({
    required this.announcementEnabled,
    required this.announceOnlyWithBluetooth,
    required this.language,
    required this.speechRate,
  });

  CallSettings copyWith({
    bool? announcementEnabled,
    bool? announceOnlyWithBluetooth,
    String? language,
    double? speechRate,
  }) {
    return CallSettings(
      announcementEnabled: announcementEnabled ?? this.announcementEnabled,
      announceOnlyWithBluetooth: announceOnlyWithBluetooth ?? this.announceOnlyWithBluetooth,
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
    );
  }
}
