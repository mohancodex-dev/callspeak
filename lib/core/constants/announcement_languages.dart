class AnnouncementLanguages {
  static const String defaultLanguage = 'en-US';

  static const Map<String, String> languageNames = {
    'hi-IN': 'Hindi (हिन्दी)',
    'rathawi-IN': 'Rathawi (राठवी)',
    'en-US': 'English (US)',
    'bn-IN': 'Bengali (বাংলা)',
    'te-IN': 'Telugu (తెలుగు)',
    'mr-IN': 'Marathi (मराठी)',
    'ta-IN': 'Tamil (தமிழ்)',
    'gu-IN': 'Gujarati (ગુજરાતી)',
    'kn-IN': 'Kannada (ಕನ್ನಡ)',
    'ml-IN': 'Malayalam (മലയാളം)',
    'pa-IN': 'Punjabi (ਪੰਜਾਬੀ)',
    'or-IN': 'Odia (ଓଡ଼ିଆ)',
    'as-IN': 'Assamese (অসমীয়া)',
    'ur-IN': 'Urdu (اردو)',
    'kok-IN': 'Konkani (कोंकणी)',
    'ne-IN': 'Nepali (नेपाली)',
    'sd-IN': 'Sindhi (سنڌي)',
  };

  /// Template / Phrase when a saved or known contact calls.
  static String getContactAnnouncement({
    required String language,
    required String name,
  }) {
    final contactName = name.trim().isNotEmpty ? name.trim() : 'Someone';

    return switch (language) {
      'hi-IN' => '$contactName का फोन आ रहा है।',
      'rathawi-IN' => '$contactName ने फोन आय रयो',
      'bn-IN' => '$contactName ফোন করছেন।',
      'te-IN' => '$contactName నుండి కాల్ వస్తోంది.',
      'mr-IN' => '$contactName यांचा फोन येत आहे.',
      'ta-IN' => '$contactName அழைக்கிறார்.',
      'gu-IN' => '$contactName નો ફોન આવી રહ્યો છે.',
      'kn-IN' => '$contactName ಅವರಿಂದ ಕರೆ ಬರುತ್ತಿದೆ.',
      'ml-IN' => '$contactName വിളിക്കുന്നു.',
      'pa-IN' => '$contactName ਦਾ ਫ਼ੋਨ ਆ ਰਿਹਾ ਹੈ।',
      'or-IN' => '$contactName ଙ୍କର ଫୋନ୍ ଆସୁଛି।',
      'as-IN' => '$contactName ফোন কৰিছে।',
      'ur-IN' => '$contactName کی کال آ رہی ہے۔',
      'kok-IN' => '$contactName चो फोन येता.',
      'ne-IN' || 'ne-NP' => '$contactName को फोन आउँदैछ।',
      'sd-IN' => '$contactName جو فون اچي رهيو آهي.',
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
      'rathawi-IN' => '$target ने फोन आय रयो',
      'bn-IN' => '$target থেকে ফোন আসছে।',
      'te-IN' => '$target నుండి కాల్ వస్తోంది.',
      'mr-IN' => '$target वरून फोन येत आहे.',
      'ta-IN' => '$target இலிருந்து அழைப்பு வருகிறது.',
      'gu-IN' => '$target નો ફોન આવી રહ્યો છે.',
      'kn-IN' => '$target ಇಂದ ಕರೆ ಬರುತ್ತಿದೆ.',
      'ml-IN' => '$target ൽ നിന്ന് കോൾ വരുന്നു.',
      'pa-IN' => '$target ਦਾ ਫ਼ੋਨ ਆ ਰਿਹਾ ਹੈ।',
      'or-IN' => '$target ରୁ ଫୋନ୍ ଆସୁଛି।',
      'as-IN' => '$target ৰ পৰা ফোন আহিছে।',
      'ur-IN' => '$target سے کال آ رہی ہے۔',
      'kok-IN' => '$target चो फोन येता.',
      'ne-IN' || 'ne-NP' => '$target बाट फोन आउँदैछ।',
      'sd-IN' => '$target مان ڪال اچي رهي آهي.',
      _ => 'Incoming call from $target.',
    };
  }

  /// Localized default text for "Unknown Caller" or "Unknown Number".
  static String getUnknownCallerLabel(String language) {
    return switch (language) {
      'hi-IN' => 'अज्ञात नंबर',
      'rathawi-IN' => 'अनजान नंबर',
      'bn-IN' => 'অজানা নম্বর',
      'te-IN' => 'తెలియని నంబర్',
      'mr-IN' => 'अनोळखी नंबर',
      'ta-IN' => 'தெரியாத எண்',
      'gu-IN' => 'અજાણ્યો નંબર',
      'kn-IN' => 'ಅಪರಿಚಿತ ಸಂಖ್ಯೆ',
      'ml-IN' => 'അജ്ഞാത നമ്പർ',
      'pa-IN' => 'ਅਣਜਾਣ ਨੰਬਰ',
      'or-IN' => 'ଅଜଣା ନମ୍ବର',
      'as-IN' => 'অচিনাকী নম্বৰ',
      'ur-IN' => 'نامعلوم نمبر',
      'kok-IN' => 'अनोळखी नंबर',
      'ne-IN' || 'ne-NP' => 'अपरिचित नम्बर',
      'sd-IN' => 'اڻڄাত نمبر',
      _ => 'Unknown Number',
    };
  }
}
