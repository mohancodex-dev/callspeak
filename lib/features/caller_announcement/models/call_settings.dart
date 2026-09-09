class CallSettings {
  final bool announcementEnabled;
  final bool announceOnlyWithBluetooth;
  final bool alsoAnnounceOnSpeaker;
  final bool silenceInSilentMode;
  final bool silenceInDndMode;
  final String language;
  final double speechRate;

  CallSettings({
    required this.announcementEnabled,
    required this.announceOnlyWithBluetooth,
    this.alsoAnnounceOnSpeaker = false,
    this.silenceInSilentMode = true,
    this.silenceInDndMode = true,
    required this.language,
    required this.speechRate,
  });

  CallSettings copyWith({
    bool? announcementEnabled,
    bool? announceOnlyWithBluetooth,
    bool? alsoAnnounceOnSpeaker,
    bool? silenceInSilentMode,
    bool? silenceInDndMode,
    String? language,
    double? speechRate,
  }) {
    return CallSettings(
      announcementEnabled: announcementEnabled ?? this.announcementEnabled,
      announceOnlyWithBluetooth: announceOnlyWithBluetooth ?? this.announceOnlyWithBluetooth,
      alsoAnnounceOnSpeaker: alsoAnnounceOnSpeaker ?? this.alsoAnnounceOnSpeaker,
      silenceInSilentMode: silenceInSilentMode ?? this.silenceInSilentMode,
      silenceInDndMode: silenceInDndMode ?? this.silenceInDndMode,
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
    );
  }
}
