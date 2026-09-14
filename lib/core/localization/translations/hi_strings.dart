import '../app_strings.dart';

class HiStrings extends AppStrings {
  const HiStrings() : super(languageCode: 'hi-IN');

  @override
  String get navHome => 'होम';
  @override
  String get navContacts => 'कॉन्टैक्ट्स';
  @override
  String get navRules => 'नियम';
  @override
  String get navSmartAi => 'स्मार्ट AI';

  @override
  String get announcerActive => 'कॉलर अनाउंसर चालू';
  @override
  String get announcerPaused => 'कॉलर अनाउंसर बंद';
  @override
  String get announcerActiveDesc => 'कॉल आने पर कॉलर का नाम बोलेगा';
  @override
  String get announcerPausedDesc => 'कॉल करने वाले का नाम सुनने के लिए चालू करें';
  @override
  String get systemReady => 'सब तैयार है';
  @override
  String get permissionNeeded => 'परमिशन चाहिए';
  @override
  String get headsetConnected => 'ईयरफोन कनेक्टेड';
  @override
  String get phoneSpeaker => 'फोन स्पीकर';
  @override
  String get repeatLabel1 => '1 बार';
  @override
  String get repeatLabel2 => '2 बार';
  @override
  String get repeatLabel3 => '3 बार';
  @override
  String get repeatUntilAnswered => 'कॉल उठाने तक';

  @override
  String get aiPhonetics => 'साफ AI आवाज';
  @override
  String get aiOffline => 'आवाज ऑफलाइन';
  @override
  String get smartIndianSpeech => 'साफ भारतीय आवाज';
  @override
  String get fullGuard => 'सब सुरक्षित';
  @override
  String get needsAction => 'सेटिंग ठीक करें';
  @override
  String get secure => 'चालू';
  @override
  String get fix => 'ठीक करें';
  @override
  String get dndSilentActive => 'साइलेंट और DND सेटिंग';

  // Dashboard Section Headers (Simple Hindi)
  @override
  String get sectionOverview => 'स्टेटस और जानकारी';
  @override
  String get sectionOverviewDesc => 'वर्तमान सेटिंग्स और जरूरी शॉर्टकट';
  @override
  String get sectionAudioDelivery => 'ऑडियो और डिवाइस';
  @override
  String get sectionAudioDeliveryDesc => 'आवाज कहाँ सुनाई दे (ईयरफोन या स्पीकर)';
  @override
  String get sectionSilenceDnd => 'साइलेंट और DND सेटिंग';
  @override
  String get sectionSilenceDndDesc => 'मीटिंग या शांत समय में आवाज बंद रखें';
  @override
  String get sectionRepeatMode => 'रिपीट सेटिंग्स';
  @override
  String get sectionRepeatModeDesc => 'कॉलर का नाम कितनी बार दोहराया जाए';
  @override
  String get sectionTheme => 'ऐप थीम';
  @override
  String get sectionThemeDesc => 'डार्क मोड, लाइट मोड या सिस्टम डिफ़ॉल्ट';
  @override
  String get sectionShortcuts => 'क्विक शॉर्टकट';
  @override
  String get sectionShortcutsDesc => 'कॉन्टैक्ट्स और नियम मैनेज करें';
  @override
  String get sectionSimulator => 'कॉल आवाज टेस्ट करें';
  @override
  String get sectionSimulatorDesc => 'चुनी हुई भाषा में आवाज सुनकर देखें';

  @override
  String get speechSettings => 'आवाज और भाषा सेटिंग्स';
  @override
  String get speechSettingsDesc => 'बोलने की भाषा, स्पीड और रिपीट चुनें';
  @override
  String get appLanguage => 'ऐप की भाषा';
  @override
  String get appLanguageDesc => 'ऐप के बटन और स्क्रीन की भाषा';
  @override
  String get selectAppLanguage => 'ऐप की भाषा चुनें';
  @override
  String get announcementLanguage => 'कॉलर बोलने की भाषा';
  @override
  String get announcementVoiceLanguage => 'कॉलर बोलने की भाषा';
  @override
  String get announcementVoiceDesc => 'कॉल आने पर किस भाषा में नाम बोले';
  @override
  String get selectLanguage => 'बोलने की भाषा चुनें';
  @override
  String get speechRate => 'बोलने की स्पीड';
  @override
  String get speechRateSlow => 'धीमी';
  @override
  String get speechRateNormal => 'सामान्य';
  @override
  String get speechRateFast => 'तेज';
  @override
  String get repeatMode => 'कितनी बार बोले (रिपीट)';
  @override
  String get repeatModeDesc => 'कॉल आने पर नाम कितनी बार दोहराया जाए';
  @override
  String get bluetoothOnly => 'सिर्फ ईयरफोन / ब्लूटूथ पर बोलें';
  @override
  String get bluetoothOnlyDesc => 'सिर्फ ईयरफोन या ब्लूटूथ कनेक्ट होने पर ही नाम बोले';
  @override
  String get speakerOutput => 'लाउडस्पीकर पर भी बोलें';
  @override
  String get speakerOutputDesc => 'ईयरफोन लगे होने पर भी फोन स्पीकर पर आवाज आए';
  @override
  String get silenceInSilent => 'साइलेंट मोड में शांत रहें';
  @override
  String get silenceInSilentDesc => 'फोन साइलेंट या वाइब्रेट होने पर नाम न बोले';
  @override
  String get silenceInDnd => 'DND मोड में शांत रहें';
  @override
  String get silenceInDndDesc => 'डू नॉट डिस्टर्ब (DND) ऑन होने पर नाम न बोले';

  @override
  String get permissionsRequiredTitle => 'परमिशन की जरूरत है';
  @override
  String get permissionsRequiredDesc =>
      'कॉल आने पर नाम बोलने के लिए ऐप को इन परमिशन की जरूरत है:';
  @override
  String get phoneCallsState => 'फोन कॉल';
  @override
  String get phoneCallsStateDesc => 'आने वाली कॉल और नंबर पहचानने के लिए';
  @override
  String get contactsAccess => 'कॉन्टैक्ट्स (फोन बुक)';
  @override
  String get contactsAccessDesc => 'सेव किए गए नाम बोलने के लिए';
  @override
  String get notificationsAudio => 'नोटिफिकेशन और आवाज';
  @override
  String get notificationsAudioDesc => 'बैकग्राउंड में नाम बोलने और ईयरफोन सपोर्ट के लिए';
  @override
  String get grantAllPermissions => 'परमिशन दें';
  @override
  String get cancel => 'कैंसिल';
  @override
  String get allow => 'अनुमति दें';
  @override
  String get permissionsRequiredSnack => 'नाम बोलने के लिए परमिशन देना जरूरी है।';
  @override
  String get callerAnnouncerActivated => 'कॉलर अनाउंसर चालू हो गया!';
  @override
  String get callerAnnouncementPaused => 'कॉलर अनाउंसर बंद कर दिया गया';

  @override
  String get simulateIncomingCall => 'कॉल आवाज टेस्ट करें';
  @override
  String get testVoice => 'आवाज सुनें (टेस्ट)';
  @override
  String get stopVoice => 'बंद करें';
  @override
  String get playingPreview => 'आवाज बज रही है...';
  @override
  String get previewStopped => 'आवाज बंद हुई';
  @override
  String get vipContact => 'VIP कॉन्टैक्ट';
  @override
  String get savedContact => 'सेव किया गया नंबर';
  @override
  String get officeColleague => 'ऑफिस कॉन्टैक्ट';
  @override
  String get unknownNumber => 'अनजान नंबर';

  @override
  String get searchContactsHint => 'कॉन्टैक्ट्स खोजें...';
  @override
  String get syncContacts => 'कॉन्टैक्ट्स लोड करें';
  @override
  String get syncingContacts => 'फोन से कॉन्टैक्ट्स लोड हो रहे हैं...';
  @override
  String get contactsLoadedSuccess => 'कॉन्टैक्ट्स लोड हो गए!';
  @override
  String get contactsPermissionNeeded => 'कॉन्टैक्ट परमिशन चाहिए';
  @override
  String get contactsPermissionBannerDesc =>
      'कॉलर का नाम बोलने के लिए फोन कॉन्टैक्ट्स की परमिशन दें।';
  @override
  String get contactsPermissionRequired => 'कॉन्टैक्ट परमिशन जरूरी है';
  @override
  String get contactsPermissionRequiredDesc =>
      'परमिशन दें ताकि ऐप बता सके कौन कॉल कर रहा है।';
  @override
  String get grantPermission => 'परमिशन दें';
  @override
  String get filterAll => 'सभी';
  @override
  String get filterCustomized => 'कस्टम';
  @override
  String get filterVip => 'VIP';
  @override
  String get filterMuted => 'म्यूट';
  @override
  String get noContactsFound => 'कोई कॉन्टैक्ट नहीं मिला';
  @override
  String get noContactsInList => 'यहाँ कोई कॉन्टैक्ट नहीं है';
  @override
  String get tapSyncToReimport =>
      'फोन से कॉन्टैक्ट्स लाने के लिए "कॉन्टैक्ट्स लोड करें" दबाएं।';
  @override
  String get addRule => 'कॉन्टैक्ट जोड़ें';
  @override
  String get newContactRule => 'नया कॉन्टैक्ट नियम';
  @override
  String get name => 'नाम';
  @override
  String get phoneNumber => 'फोन नंबर';
  @override
  String get customAnnouncementText => 'इस नंबर के लिए क्या बोले';
  @override
  String get saveRule => 'सेव करें';
  @override
  String get saveChanges => 'सेव करें';
  @override
  String get personalizeFor => 'के लिए अलग मैसेज';
  @override
  String get aiSuggest => 'AI सुझाव';
  @override
  String get insert => 'जोड़ें:';
  @override
  String get previewAnnouncement => 'आवाज सुनें';
  @override
  String get delete => 'हटाएं';

  @override
  String get categoryRulesTitle => 'डिफ़ॉल्ट कॉल नियम';
  @override
  String get categoryRulesSubtitle =>
      'जब किसी नंबर का अलग नियम न हो, तब कैसे बोले';
  @override
  String get savedContactsTitle => 'सेव किए गए कॉन्टैक्ट्स';
  @override
  String get savedContactsSubtitle => 'फोन बुक में सेव नंबरों के लिए नियम';
  @override
  String get unknownNumbersTitle => 'अनजान नंबर (Unknown)';
  @override
  String get unknownNumbersSubtitle => 'जो नंबर फोन में सेव नहीं हैं उनके लिए नियम';
  @override
  String get vipContactsTitle => 'VIP कॉन्टैक्ट्स';
  @override
  String get vipContactsSubtitle => 'खास संपर्कों के लिए खास नियम';
  @override
  String get spamCallersTitle => 'स्पैम और फ्रॉड नंबर';
  @override
  String get spamCallersSubtitle => 'स्पैम या टेलीमार्केटिंग कॉल पर चेतावनी दे';
  @override
  String get editCategoryRule => 'नियम बदलें';
  @override
  String get announcementTemplate => 'बोलने का मैसेज';
  @override
  String get silentModeBehavior => 'साइलेंट और DND में क्या करें';
  @override
  String get respectSilent => 'शांत रहें (आवाज न आए)';
  @override
  String get bypassSilent => 'साइलेंट में भी बोले';
  @override
  String get saveCategoryRule => 'नियम सेव करें';

  // Smart Features Screen (Simple Hindi)
  @override
  String get smartFeaturesTitle => 'स्मार्ट AI फीचर्स';
  @override
  String get smartFeaturesBannerTitle => 'स्मार्ट वॉइस असिस्टेंट';
  @override
  String get smartFeaturesBannerDesc =>
      'कॉल घोषणा को और आसान व स्मार्ट बनाने की सेटिंग्स।';
  @override
  String get smartAiAnnounceTitle => 'AI वॉइस सुझाव';
  @override
  String get smartAiAnnounceDesc =>
      'कॉलर के अनुसार अच्छे और अलग मैसेज सुझाता है।';
  @override
  String get smartPhoneticTitle => 'साफ भारतीय उच्चारण';
  @override
  String get smartPhoneticDesc =>
      'भारतीय नामों को बिल्कुल सही और साफ तरीके से बोलता है।';
  @override
  String get smartVipTitle => 'VIP कॉल प्राथमिकता';
  @override
  String get smartVipDesc =>
      'फोन साइलेंट या DND में होने पर भी VIP कॉल का नाम बोलता है।';
  @override
  String get smartSpamTitle => 'स्पैम कॉल चेतावनी';
  @override
  String get smartSpamDesc =>
      'अनजान या स्पैम नंबर पर पहले "चेतावनी: स्पैम कॉल" बोलता है।';
  @override
  String get smartEarbudTitle => 'ईयरफोन प्राइवेट मोड';
  @override
  String get smartEarbudDesc =>
      'ईयरफोन लगे होने पर फोन स्पीकर को शांत रखता है।';
}
