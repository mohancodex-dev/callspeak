class UnlockCaptureSettings {
  final bool enabled;
  final bool showNotification;

  const UnlockCaptureSettings({
    this.enabled = false,
    this.showNotification = true,
  });

  UnlockCaptureSettings copyWith({
    bool? enabled,
    bool? showNotification,
  }) {
    return UnlockCaptureSettings(
      enabled: enabled ?? this.enabled,
      showNotification: showNotification ?? this.showNotification,
    );
  }
}
