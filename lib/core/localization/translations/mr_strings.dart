import '../app_strings.dart';

class MrStrings extends AppStrings {
  const MrStrings() : super(languageCode: 'mr-IN');

  @override
  String get navHome => 'मुख्यपृष्ठ';
  @override
  String get navContacts => 'संपर्क';
  @override
  String get navRules => 'नियम';
  @override
  String get navSmartAi => 'स्मार्ट AI';

  @override
  String get announcerActive => 'अनाउन्सर सुरू';
  @override
  String get announcerPaused => 'अनाउन्सर बंद';
  @override
  String get announcerActiveDesc => 'इनकमिंग कॉल आल्यावर कॉलरचे नाव बोलत आहे';
  @override
  String get announcerPausedDesc => 'नाव आपोआप बोलण्यासाठी चालू करा';
  @override
  String get systemReady => 'प्रणाली सज्ज';
  @override
  String get permissionNeeded => 'परवानगी आवश्यक';
  @override
  String get headsetConnected => 'हेडसेट जोडलेला';
  @override
  String get phoneSpeaker => 'फोन स्पीकर';
  @override
  String get repeatLabel1 => '1 वेळ';
  @override
  String get repeatLabel2 => '2 वेळा';
  @override
  String get repeatLabel3 => '3 वेळा';
  @override
  String get repeatUntilAnswered => 'कॉल उचलेपर्यंत';

  @override
  String get aiPhonetics => 'AI उच्चार';
  @override
  String get aiOffline => 'AI ऑफलाइन';
  @override
  String get smartIndianSpeech => 'भारतीय उच्चार';
  @override
  String get fullGuard => 'पूर्ण सुरक्षा';
  @override
  String get needsAction => 'कृती आवश्यक';
  @override
  String get secure => 'सुरक्षित';
  @override
  String get fix => 'दुरुस्त करा';
  @override
  String get dndSilentActive => 'DND आणि सायलेंट सक्रिय';

  @override
  String get speechSettings => 'आवाज सेटिंग्ज';
  @override
  String get announcementLanguage => 'घोषणेची भाषा';
  @override
  String get selectLanguage => 'बोलण्याची भाषा निवडा';
  @override
  String get speechRate => 'बोलण्याचा वेग';
  @override
  String get speechRateSlow => 'हळू';
  @override
  String get speechRateNormal => 'सामान्य';
  @override
  String get speechRateFast => 'जलद';
  @override
  String get repeatMode => 'पुनरावृत्ती मोड';
  @override
  String get bluetoothOnly => 'केवळ ब्लूटूथ / हेडसेट';
  @override
  String get bluetoothOnlyDesc => 'केवळ वायरलेस ऑडिओ जोडलेला असतानाच बोला';
  @override
  String get speakerOutput => 'स्पीकरवरही बोला';
  @override
  String get speakerOutputDesc => 'इअरफोन जोडलेले असतानाही लाउडस्पीकरवर बोला';
  @override
  String get silenceInSilent => 'सायलंट मोडचे पालन करा';
  @override
  String get silenceInSilentDesc => 'फोन सायलेंट किंवा व्हायब्रेट असताना बोलू नका';
  @override
  String get silenceInDnd => 'DND मोडचे पालन करा';
  @override
  String get silenceInDndDesc => 'डू नॉट डिस्टर्ब सुरू असताना बोलू नका';

  @override
  String get permissionsRequiredTitle => 'परवानग्या आवश्यक आहेत';
  @override
  String get permissionsRequiredDesc =>
      'कॉल आल्यावर नाव बोलण्यासाठी, ॲपला या परवानग्या आवश्यक आहेत:';
  @override
  String get phoneCallsState => 'फोन कॉल आणि स्थिती';
  @override
  String get phoneCallsStateDesc => 'इनकमिंग कॉल आणि नंबर ओळखण्यासाठी';
  @override
  String get contactsAccess => 'संपर्क प्रवेश';
  @override
  String get contactsAccessDesc => 'फोन बुकातून कॉलरचे नाव बोलण्यासाठी';
  @override
  String get notificationsAudio => 'सूचना आणि ऑडिओ';
  @override
  String get notificationsAudioDesc => 'पार्श्वभूमी सेवा आणि हेडसेटसाठी';
  @override
  String get grantAllPermissions => 'सर्व परवानग्या द्या';
  @override
  String get cancel => 'रद्द करा';
  @override
  String get allow => 'परवानगी द्या';
  @override
  String get permissionsRequiredSnack => 'कॉलरचे नाव बोलण्यासाठी परवानग्या आवश्यक आहेत.';
  @override
  String get callerAnnouncerActivated => 'कॉलर अनाउन्सर सक्रिय झाले!';
  @override
  String get callerAnnouncementPaused => 'कॉलर अनाउन्सर थांबवले गेले';

  @override
  String get simulateIncomingCall => 'कॉल सिम्युलेट करा';
  @override
  String get testVoice => 'आवाज तपासा';
  @override
  String get stopVoice => 'थांबवा';
  @override
  String get playingPreview => 'पूर्वावलोकन सुरू आहे';
  @override
  String get previewStopped => 'पूर्वावलोकन थांबवले';
  @override
  String get vipContact => 'VIP संपर्क';
  @override
  String get savedContact => 'जतन केलेला संपर्क';
  @override
  String get officeColleague => 'कार्यालयीन सहकारी';
  @override
  String get unknownNumber => 'अनोळखी नंबर';

  @override
  String get searchContactsHint => 'संपर्क आणि नियम शोधा';
  @override
  String get syncContacts => 'संपर्क सिंक करा';
  @override
  String get syncingContacts => 'संपर्क सिंक होत आहेत...';
  @override
  String get contactsLoadedSuccess => 'संपर्क यशस्वीरीत्या लोड झाले!';
  @override
  String get contactsPermissionNeeded => 'संपर्क परवानगी आवश्यक';
  @override
  String get contactsPermissionBannerDesc =>
      'संपर्क दाखवण्यासाठी आणि कॉलरचे नाव बोलण्यासाठी परवानगी द्या.';
  @override
  String get contactsPermissionRequired => 'संपर्क परवानगी आवश्यक आहे';
  @override
  String get contactsPermissionRequiredDesc =>
      'परवानगी द्या जेणेकरून ॲप कोण कॉल करत आहे ते सांगू शकेल.';
  @override
  String get grantPermission => 'परवानगी द्या';
  @override
  String get filterAll => 'सर्व';
  @override
  String get filterCustomized => 'सानुकूलित';
  @override
  String get filterVip => 'VIP';
  @override
  String get filterMuted => 'म्यूट';
  @override
  String get noContactsFound => 'कोणताही संपर्क सापडला नाही';
  @override
  String get noContactsInList => 'या सूचीमध्ये कोणतेही संपर्क नाहीत';
  @override
  String get tapSyncToReimport =>
      'डिव्हाइसवरून संपर्क पुन्हा मिळवण्यासाठी "संपर्क सिंक करा" वर टॅप करा.';
  @override
  String get addRule => 'नियम जोडा';
  @override
  String get newContactRule => 'नवीन संपर्क नियम';
  @override
  String get name => 'नाव';
  @override
  String get phoneNumber => 'फोन नंबर';
  @override
  String get customAnnouncementText => 'सानुकूल घोषणा मजकूर';
  @override
  String get saveRule => 'नियम जतन करा';
  @override
  String get saveChanges => 'बदल जतन करा';
  @override
  String get personalizeFor => 'यांच्यासाठी सानुकूलित करा';
  @override
  String get aiSuggest => 'AI सूचना';
  @override
  String get insert => 'समाविष्ट करा:';
  @override
  String get previewAnnouncement => 'घोषणा ऐका';
  @override
  String get delete => 'हटवा';

  @override
  String get categoryRulesTitle => 'श्रेणीनुसार नियम';
  @override
  String get categoryRulesSubtitle =>
      'वैयक्तिक नियम नसताना कॉल कसा घोषित करावा ते ठरवा.';
  @override
  String get savedContactsTitle => 'जतन केलेले संपर्क';
  @override
  String get savedContactsSubtitle => 'ओळखीच्या फोन बुक संपर्कांसाठी डीफॉल्ट वर्तन';
  @override
  String get unknownNumbersTitle => 'अनोळखी नंबर';
  @override
  String get unknownNumbersSubtitle => 'संपर्कात नसलेल्या नंबरवरून येणाऱ्या कॉलसाठी नियम';
  @override
  String get vipContactsTitle => 'VIP संपर्क';
  @override
  String get vipContactsSubtitle => 'विशेष घोषणेसह प्राधान्य संपर्क';
  @override
  String get editCategoryRule => 'नियम संपादित करा';
  @override
  String get announcementTemplate => 'घोषणेचे स्वरूप';
  @override
  String get silentModeBehavior => 'सायलंट आणि DND वर्तन';
  @override
  String get respectSilent => 'सायलंटचे पालन करा';
  @override
  String get bypassSilent => 'सायलंट बायपास करा';
  @override
  String get saveCategoryRule => 'श्रेणी नियम जतन करा';
}
