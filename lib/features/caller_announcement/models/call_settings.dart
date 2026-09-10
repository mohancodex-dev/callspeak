class CallSettings {
  final bool announcementEnabled;
  final bool announceOnlyWithBluetooth;
  final bool alsoAnnounceOnSpeaker;
  final bool silenceInSilentMode;
  final bool silenceInDndMode;
  final String language;
  final double speechRate;
  final String repeatMode;

  CallSettings({
    required this.announcementEnabled,
    required this.announceOnlyWithBluetooth,
    this.alsoAnnounceOnSpeaker = false,
    this.silenceInSilentMode = true,
    this.silenceInDndMode = true,
    required this.language,
    required this.speechRate,
    this.repeatMode = 'three_times',
  });

  CallSettings copyWith({
    bool? announcementEnabled,
    bool? announceOnlyWithBluetooth,
    bool? alsoAnnounceOnSpeaker,
    bool? silenceInSilentMode,
    bool? silenceInDndMode,
    String? language,
    double? speechRate,
    String? repeatMode,
  }) {
    return CallSettings(
      announcementEnabled: announcementEnabled ?? this.announcementEnabled,
      announceOnlyWithBluetooth: announceOnlyWithBluetooth ?? this.announceOnlyWithBluetooth,
      alsoAnnounceOnSpeaker: alsoAnnounceOnSpeaker ?? this.alsoAnnounceOnSpeaker,
      silenceInSilentMode: silenceInSilentMode ?? this.silenceInSilentMode,
      silenceInDndMode: silenceInDndMode ?? this.silenceInDndMode,
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}
