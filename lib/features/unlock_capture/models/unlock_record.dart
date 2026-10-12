class UnlockRecord {
  final String id;
  final DateTime timestamp;
  final String status; // 'captured', 'camera_restricted', 'permission_denied', 'error'
  final String? photoPath;
  final String? errorMessage;

  const UnlockRecord({
    required this.id,
    required this.timestamp,
    required this.status,
    this.photoPath,
    this.errorMessage,
  });

  bool get isCaptured => status == 'captured' && (photoPath != null && photoPath!.isNotEmpty);
  bool get isRestricted => status == 'camera_restricted';
  bool get isPermissionDenied => status == 'permission_denied';
  bool get isError => status == 'error';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'photoPath': photoPath ?? '',
      'errorMessage': errorMessage ?? '',
    };
  }

  factory UnlockRecord.fromMap(Map<String, dynamic> map) {
    DateTime parsedTime;
    final rawTime = map['timestamp'];
    if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else if (rawTime is String) {
      final parsedInt = int.tryParse(rawTime);
      if (parsedInt != null) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(parsedInt);
      } else {
        parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
      }
    } else {
      parsedTime = DateTime.now();
    }

    final path = map['photoPath']?.toString();
    final error = map['errorMessage']?.toString();

    return UnlockRecord(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: parsedTime,
      status: map['status']?.toString() ?? 'unknown',
      photoPath: (path != null && path.isNotEmpty) ? path : null,
      errorMessage: (error != null && error.isNotEmpty) ? error : null,
    );
  }
}
