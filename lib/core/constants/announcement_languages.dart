class AnnouncementLanguages {
  static const String defaultLanguage = 'en-US';

  static const Map<String, String> languageNames = {
    'hi-IN': 'Hindi (हिन्दी)',
    'rathawi-IN': 'Rathawi (राठवी)',
    'en-US': 'English (US)',
    'te-IN': 'Telugu (తెలుగు)',
    'mr-IN': 'Marathi (मराठी)',
    'ta-IN': 'Tamil (தமிழ்)',
    'gu-IN': 'Gujarati (ગુજરાતી)',
    'kn-IN': 'Kannada (ಕನ್ನಡ)',
    'ml-IN': 'Malayalam (മലയാളം)',
    'pa-IN': 'Punjabi (ਪੰਜਾਬੀ)',
    'ne-IN': 'Nepali (नेपाली)',
  };

  /// Template / Phrase when a saved or known contact calls.
  static String getContactAnnouncement({
    required String language,
    required String name,
  }) {
    final contactName = name.trim().isNotEmpty ? name.trim() : 'Someone';

    return switch (language) {
      'hi-IN' => '$contactName का फोन आ रहा है।',
      'rathawi-IN' => '$contactName ne phon aayrayo',
      'te-IN' => '$contactName నుండి కాల్ వస్తోంది.',
      'mr-IN' => '$contactName यांचा फोन येत आहे.',
      'ta-IN' => '$contactName அழைக்கிறார்.',
      'gu-IN' => '$contactName નો ફોન આવી રહ્યો છે.',
      'kn-IN' => '$contactName ಅವರಿಂದ ಕರೆ ಬರುತ್ತಿದೆ.',
      'ml-IN' => '$contactName വിളിക്കുന്നു.',
      'pa-IN' => '$contactName ਦਾ ਫ਼ੋਨ ਆ ਰਿਹਾ ਹੈ।',
      'ne-IN' || 'ne-NP' => '$contactName को फोन आउँदैछ।',
      _ => 'Incoming call from $contactName.',
    };
  }

  /// Template / Phrase when an unknown number or unsaved caller calls.
  static String getUnknownAnnouncement({
    required String language,
    String? phoneNumber,
  }) {
    final hasNumber = phoneNumber != null && phoneNumber.trim().isNotEmpty && phoneNumber.trim() != 'null';
    final target = hasNumber ? phoneNumber.trim() : getUnknownCallerLabel(language);

    return switch (language) {
      'hi-IN' => '$target का फोन आ रहा है।',
      'rathawi-IN' => '$target ne phon aayrayo',
      'te-IN' => '$target నుండి కాల్ వస్తోంది.',
      'mr-IN' => '$target वरून फोन येत आहे.',
      'ta-IN' => '$target இலிருந்து அழைப்பு வருகிறது.',
      'gu-IN' => '$target નો ફોન આવી રહ્યો છે.',
      'kn-IN' => '$target ಇಂದ ಕರೆ ಬರುತ್ತಿದೆ.',
      'ml-IN' => '$target ൽ നിന്ന് കോൾ വരുന്നു.',
      'pa-IN' => '$target ਦਾ ਫ਼ੋਨ ਆ ਰਿਹਾ ਹੈ।',
      'ne-IN' || 'ne-NP' => '$target बाट फोन आउँदैछ।',
      _ => 'Incoming call from $target.',
    };
  }

  /// Localized default text for "Unknown Caller" or "Unknown Number".
  static String getUnknownCallerLabel(String language) {
    return switch (language) {
      'hi-IN' => 'अज्ञात नंबर',
      'rathawi-IN' => 'अनजान नंबर',
      'te-IN' => 'తెలియని నంబర్',
      'mr-IN' => 'अनोळखी नंबर',
      'ta-IN' => 'தெரியாத எண்',
      'gu-IN' => 'અજાણ્યો નંબર',
      'kn-IN' => 'ಅಪರಿಚಿತ ಸಂಖ್ಯೆ',
      'ml-IN' => 'അജ്ഞാത നമ്പർ',
      'pa-IN' => 'ਅਣਜਾਣ ਨੰਬਰ',
      'ne-IN' || 'ne-NP' => 'अपरिचित नम्बर',
      _ => 'Unknown Number',
    };
  }
}
