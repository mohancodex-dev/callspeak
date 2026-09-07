class CallSettings {
  final bool announcementEnabled;
  final bool announceOnlyWithBluetooth;
  final bool alsoAnnounceOnSpeaker;
  final String language;
  final double speechRate;

  CallSettings({
    required this.announcementEnabled,
    required this.announceOnlyWithBluetooth,
    this.alsoAnnounceOnSpeaker = false,
    required this.language,
    required this.speechRate,
  });

  CallSettings copyWith({
    bool? announcementEnabled,
    bool? announceOnlyWithBluetooth,
    bool? alsoAnnounceOnSpeaker,
    String? language,
    double? speechRate,
  }) {
    return CallSettings(
      announcementEnabled: announcementEnabled ?? this.announcementEnabled,
      announceOnlyWithBluetooth: announceOnlyWithBluetooth ?? this.announceOnlyWithBluetooth,
      alsoAnnounceOnSpeaker: alsoAnnounceOnSpeaker ?? this.alsoAnnounceOnSpeaker,
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
    );
  }
}
