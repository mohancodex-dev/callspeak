import 'dart:convert';

class ContactRule {
  final String id; // unique key (phone number or UUID)
  final String name;
  final String phoneNumber;
  final int avatarColorIndex;
  final bool isEnabled;
  final String customText; // e.g., "{name} is calling you"
  final String language;
  final double volume; // 0.1 to 1.0
  final double speechRate; // 0.5 to 2.0
  final String repeatMode; // 'once', 'two_times', 'three_times', 'until_answered'
  final bool bluetoothOnly;
  final bool isVip;
  final String relationshipTag; // 'general', 'family', 'work', 'friend', 'emergency'

  const ContactRule({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.avatarColorIndex = 0,
    this.isEnabled = true,
    this.customText = '{name} is calling',
    this.language = 'en-US',
    this.volume = 1.0,
    this.speechRate = 1.0,
    this.repeatMode = 'three_times',
    this.bluetoothOnly = false,
    this.isVip = false,
    this.relationshipTag = 'general',
  });

  ContactRule copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    int? avatarColorIndex,
    bool? isEnabled,
    String? customText,
    String? language,
    double? volume,
    double? speechRate,
    String? repeatMode,
    bool? bluetoothOnly,
    bool? isVip,
    String? relationshipTag,
  }) {
    return ContactRule(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
      isEnabled: isEnabled ?? this.isEnabled,
      customText: customText ?? this.customText,
      language: language ?? this.language,
      volume: volume ?? this.volume,
      speechRate: speechRate ?? this.speechRate,
      repeatMode: repeatMode ?? this.repeatMode,
      bluetoothOnly: bluetoothOnly ?? this.bluetoothOnly,
      isVip: isVip ?? this.isVip,
      relationshipTag: relationshipTag ?? this.relationshipTag,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'avatarColorIndex': avatarColorIndex,
      'isEnabled': isEnabled,
      'customText': customText,
      'language': language,
      'volume': volume,
      'speechRate': speechRate,
      'repeatMode': repeatMode,
      'bluetoothOnly': bluetoothOnly,
      'isVip': isVip,
      'relationshipTag': relationshipTag,
    };
  }

  factory ContactRule.fromMap(Map<String, dynamic> map) {
    return ContactRule(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      avatarColorIndex: (map['avatarColorIndex'] as num?)?.toInt() ?? 0,
      isEnabled: map['isEnabled'] as bool? ?? true,
      customText: map['customText']?.toString() ?? '{name} is calling',
      language: map['language']?.toString() ?? 'en-US',
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 1.0,
      repeatMode: (map['repeatMode']?.toString() == 'twice')
          ? 'three_times'
          : (map['repeatMode']?.toString() ?? 'three_times'),
      bluetoothOnly: map['bluetoothOnly'] as bool? ?? false,
      isVip: map['isVip'] as bool? ?? false,
      relationshipTag: map['relationshipTag']?.toString() ?? 'general',
    );
  }

  String toJson() => json.encode(toMap());

  factory ContactRule.fromJson(String source) => ContactRule.fromMap(json.decode(source) as Map<String, dynamic>);
}

class CategoryRule {
  final String key;
  final String title;
  final String subtitle;
  final bool isEnabled;
  final String announcementTemplate;
  final String repeatMode; // 'once', 'two_times', 'three_times', 'until_answered'
  final bool bluetoothOnly;
  final String silentModeBehavior; // 'respect_silent', 'bypass_silent', 'vibrate'

  const CategoryRule({
    required this.key,
    required this.title,
    required this.subtitle,
    this.isEnabled = true,
    required this.announcementTemplate,
    this.repeatMode = 'three_times',
    this.bluetoothOnly = false,
    this.silentModeBehavior = 'respect_silent',
  });

  CategoryRule copyWith({
    String? key,
    String? title,
    String? subtitle,
    bool? isEnabled,
    String? announcementTemplate,
    String? repeatMode,
    bool? bluetoothOnly,
    String? silentModeBehavior,
  }) {
    return CategoryRule(
      key: key ?? this.key,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isEnabled: isEnabled ?? this.isEnabled,
      announcementTemplate: announcementTemplate ?? this.announcementTemplate,
      repeatMode: repeatMode ?? this.repeatMode,
      bluetoothOnly: bluetoothOnly ?? this.bluetoothOnly,
      silentModeBehavior: silentModeBehavior ?? this.silentModeBehavior,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'title': title,
      'subtitle': subtitle,
      'isEnabled': isEnabled,
      'announcementTemplate': announcementTemplate,
      'repeatMode': repeatMode,
      'bluetoothOnly': bluetoothOnly,
      'silentModeBehavior': silentModeBehavior,
    };
  }

  factory CategoryRule.fromMap(Map<String, dynamic> map) {
    return CategoryRule(
      key: map['key']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      isEnabled: map['isEnabled'] as bool? ?? true,
      announcementTemplate: map['announcementTemplate']?.toString() ?? '{name} is calling',
      repeatMode: (map['repeatMode']?.toString() == 'twice')
          ? 'three_times'
          : (map['repeatMode']?.toString() ?? 'three_times'),
      bluetoothOnly: map['bluetoothOnly'] as bool? ?? false,
      silentModeBehavior: map['silentModeBehavior']?.toString() ?? 'respect_silent',
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoryRule.fromJson(String source) => CategoryRule.fromMap(json.decode(source) as Map<String, dynamic>);
}

class CategoryRulesConfig {
  final CategoryRule savedContacts;
  final CategoryRule unknownNumbers;
  final CategoryRule spamCallers;
  final CategoryRule vipContacts;

  const CategoryRulesConfig({
    required this.savedContacts,
    required this.unknownNumbers,
    required this.spamCallers,
    required this.vipContacts,
  });

  factory CategoryRulesConfig.defaultConfig() {
    return const CategoryRulesConfig(
      savedContacts: CategoryRule(
        key: 'saved_contacts',
        title: 'Saved Contacts',
        subtitle: 'Default behavior for known address book contacts',
        isEnabled: true,
        announcementTemplate: 'Incoming call from {name}',
        repeatMode: 'three_times',
        bluetoothOnly: false,
        silentModeBehavior: 'respect_silent',
      ),
      unknownNumbers: CategoryRule(
        key: 'unknown_numbers',
        title: 'Unknown Numbers',
        subtitle: 'Announce calls from numbers not saved in contacts',
        isEnabled: true,
        announcementTemplate: 'Call from unknown number: {number}',
        repeatMode: 'three_times',
        bluetoothOnly: false,
        silentModeBehavior: 'respect_silent',
      ),
      spamCallers: CategoryRule(
        key: 'spam_callers',
        title: 'Spam Callers',
        subtitle: 'Warnings for suspected telemarketers & spam numbers',
        isEnabled: true,
        announcementTemplate: 'Warning! Potential spam call detected',
        repeatMode: 'once',
        bluetoothOnly: false,
        silentModeBehavior: 'respect_silent',
      ),
      vipContacts: CategoryRule(
        key: 'vip_contacts',
        title: 'VIP Contacts',
        subtitle: 'Priority announcements that can bypass silent mode',
        isEnabled: true,
        announcementTemplate: 'Important! VIP call from {name}',
        repeatMode: 'until_answered',
        bluetoothOnly: false,
        silentModeBehavior: 'bypass_silent',
      ),
    );
  }

  CategoryRulesConfig copyWith({
    CategoryRule? savedContacts,
    CategoryRule? unknownNumbers,
    CategoryRule? spamCallers,
    CategoryRule? vipContacts,
  }) {
    return CategoryRulesConfig(
      savedContacts: savedContacts ?? this.savedContacts,
      unknownNumbers: unknownNumbers ?? this.unknownNumbers,
      spamCallers: spamCallers ?? this.spamCallers,
      vipContacts: vipContacts ?? this.vipContacts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'savedContacts': savedContacts.toMap(),
      'unknownNumbers': unknownNumbers.toMap(),
      'spamCallers': spamCallers.toMap(),
      'vipContacts': vipContacts.toMap(),
    };
  }

  factory CategoryRulesConfig.fromMap(Map<String, dynamic> map) {
    return CategoryRulesConfig(
      savedContacts: map['savedContacts'] != null
          ? CategoryRule.fromMap(map['savedContacts'] as Map<String, dynamic>)
          : CategoryRulesConfig.defaultConfig().savedContacts,
      unknownNumbers: map['unknownNumbers'] != null
          ? CategoryRule.fromMap(map['unknownNumbers'] as Map<String, dynamic>)
          : CategoryRulesConfig.defaultConfig().unknownNumbers,
      spamCallers: map['spamCallers'] != null
          ? CategoryRule.fromMap(map['spamCallers'] as Map<String, dynamic>)
          : CategoryRulesConfig.defaultConfig().spamCallers,
      vipContacts: map['vipContacts'] != null
          ? CategoryRule.fromMap(map['vipContacts'] as Map<String, dynamic>)
          : CategoryRulesConfig.defaultConfig().vipContacts,
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoryRulesConfig.fromJson(String source) => CategoryRulesConfig.fromMap(json.decode(source) as Map<String, dynamic>);
}

class SmartFeatureConfig {
  final bool aiSuggestionsEnabled;
  final bool phoneticNameRecognition;
  final bool vipBypassSilent;
  final bool spamWarningAlert;
  final bool earbudContextAware;

  const SmartFeatureConfig({
    this.aiSuggestionsEnabled = true,
    this.phoneticNameRecognition = true,
    this.vipBypassSilent = true,
    this.spamWarningAlert = true,
    this.earbudContextAware = false,
  });

  SmartFeatureConfig copyWith({
    bool? aiSuggestionsEnabled,
    bool? phoneticNameRecognition,
    bool? vipBypassSilent,
    bool? spamWarningAlert,
    bool? earbudContextAware,
  }) {
    return SmartFeatureConfig(
      aiSuggestionsEnabled: aiSuggestionsEnabled ?? this.aiSuggestionsEnabled,
      phoneticNameRecognition: phoneticNameRecognition ?? this.phoneticNameRecognition,
      vipBypassSilent: vipBypassSilent ?? this.vipBypassSilent,
      spamWarningAlert: spamWarningAlert ?? this.spamWarningAlert,
      earbudContextAware: earbudContextAware ?? this.earbudContextAware,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'aiSuggestionsEnabled': aiSuggestionsEnabled,
      'phoneticNameRecognition': phoneticNameRecognition,
      'vipBypassSilent': vipBypassSilent,
      'spamWarningAlert': spamWarningAlert,
      'earbudContextAware': earbudContextAware,
    };
  }

  factory SmartFeatureConfig.fromMap(Map<String, dynamic> map) {
    return SmartFeatureConfig(
      aiSuggestionsEnabled: map['aiSuggestionsEnabled'] as bool? ?? true,
      phoneticNameRecognition: map['phoneticNameRecognition'] as bool? ?? true,
      vipBypassSilent: map['vipBypassSilent'] as bool? ?? true,
      spamWarningAlert: map['spamWarningAlert'] as bool? ?? true,
      earbudContextAware: map['earbudContextAware'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory SmartFeatureConfig.fromJson(String source) => SmartFeatureConfig.fromMap(json.decode(source) as Map<String, dynamic>);
}
