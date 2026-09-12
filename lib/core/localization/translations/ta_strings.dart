import '../app_strings.dart';

class TaStrings extends AppStrings {
  const TaStrings() : super(languageCode: 'ta-IN');

  @override
  String get navHome => 'முகப்பு';
  @override
  String get navContacts => 'தொடர்புகள்';
  @override
  String get navRules => 'விதிகள்';
  @override
  String get navSmartAi => 'ஸ்மார்ட் AI';

  @override
  String get announcerActive => 'அறிவிப்பாளர் இயக்கத்தில் உள்ளது';
  @override
  String get announcerPaused => 'அறிவிப்பாளர் இடைநிறுத்தப்பட்டது';
  @override
  String get announcerActiveDesc => 'அழைப்பாளரின் பெயரை ஒலிக்கிறது';
  @override
  String get announcerPausedDesc => 'தானாகப் பெயரைப் பேச இயக்கவும்';
  @override
  String get systemReady => 'அமைப்பு தயார்';
  @override
  String get permissionNeeded => 'அனுமதி தேவை';
  @override
  String get headsetConnected => 'ஹெட்செட் இணைக்கப்பட்டுள்ளது';
  @override
  String get phoneSpeaker => 'ஃபோன் ஸ்பீக்கர்';
  @override
  String get repeatLabel1 => '1 முறை';
  @override
  String get repeatLabel2 => '2 முறை';
  @override
  String get repeatLabel3 => '3 முறை';
  @override
  String get repeatUntilAnswered => 'பதிலளிக்கும் வரை';

  @override
  String get aiPhonetics => 'AI உச்சரிப்பு';
  @override
  String get aiOffline => 'AI ஆஃப்லைன்';
  @override
  String get smartIndianSpeech => 'இந்திய குரல்கள்';
  @override
  String get fullGuard => 'முழு பாதுகாப்பு';
  @override
  String get needsAction => 'நடவடிக்கை தேவை';
  @override
  String get secure => 'பாதுகாப்பானது';
  @override
  String get fix => 'சரிசெய்க';
  @override
  String get dndSilentActive => 'DND & சைலண்ட் இயக்கத்தில் உள்ளது';

  @override
  String get speechSettings => 'குரல் அமைப்புகள்';
  @override
  String get announcementLanguage => 'அறிவிப்பு மொழி';
  @override
  String get selectLanguage => 'பேசும் மொழியைத் தேர்ந்தெடுக்கவும்';
  @override
  String get speechRate => 'பேசும் வேகம்';
  @override
  String get speechRateSlow => 'மெதுவாக';
  @override
  String get speechRateNormal => 'சாதாரணம்';
  @override
  String get speechRateFast => 'வேகமாக';
  @override
  String get repeatMode => 'மீண்டும் ஒலிக்கும் முறை';
  @override
  String get bluetoothOnly => 'புளூடூத் / ஹெட்செட் மட்டும்';
  @override
  String get bluetoothOnlyDesc => 'வயர்லெஸ் ஆடியோ இணைக்கப்படும் போது மட்டுமே பேசவும்';
  @override
  String get speakerOutput => 'ஸ்பீக்கரிலும் பேசவும்';
  @override
  String get speakerOutputDesc => 'இயர்போன்கள் இணைக்கப்பட்டிருந்தாலும் ஸ்பீக்கரில் பேசவும்';
  @override
  String get silenceInSilent => 'சைலண்ட் பயன்முறையை மதிக்கவும்';
  @override
  String get silenceInSilentDesc => 'ஃபோன் சைலண்ட் அல்லது வைப்ரேட்டில் இருக்கும்போது பேச வேண்டாம்';
  @override
  String get silenceInDnd => 'DND பயன்முறையை மதிக்கவும்';
  @override
  String get silenceInDndDesc => 'Do Not Disturb இயக்கத்தில் இருக்கும்போது பேச வேண்டாம்';

  @override
  String get permissionsRequiredTitle => 'அனுமதிகள் தேவை';
  @override
  String get permissionsRequiredDesc =>
      'அழைப்பாளர் பெயரைப் பேச இந்த அனுமதிகள் தேவைப்படுகின்றன:';
  @override
  String get phoneCallsState => 'ஃபோன் அழைப்புகள் & நிலை';
  @override
  String get phoneCallsStateDesc => 'உள்வரும் அழைப்புகள் மற்றும் எண்களைக் கண்டறிய';
  @override
  String get contactsAccess => 'தொடர்புகள் அணுகல்';
  @override
  String get contactsAccessDesc => 'தொடர்பு புத்தகத்திலிருந்து பெயரைப் பேச';
  @override
  String get notificationsAudio => 'அறிவிப்புகள் & ஆடியோ';
  @override
  String get notificationsAudioDesc => 'பின்னணி சேவை மற்றும் ஹெட்செட்டுக்கு';
  @override
  String get grantAllPermissions => 'அனைத்து அனுமதிகளையும் வழங்கவும்';
  @override
  String get cancel => 'ரத்துசெய்';
  @override
  String get allow => 'அனுமதி';
  @override
  String get permissionsRequiredSnack => 'அழைப்பாளர் பெயரை அறிவிக்க அனுமதிகள் தேவை.';
  @override
  String get callerAnnouncerActivated => 'அழைப்பாளர் அறிவிப்பாளர் செயல்படுத்தப்பட்டது!';
  @override
  String get callerAnnouncementPaused => 'அறிவிப்பு இடைநிறுத்தப்பட்டது';

  @override
  String get simulateIncomingCall => 'அழைப்பை உருவகப்படுத்துக';
  @override
  String get testVoice => 'குரலை சோதிக்கவும்';
  @override
  String get stopVoice => 'நிறுத்து';
  @override
  String get playingPreview => 'முன்னோட்டம் ஒலிக்கிறது';
  @override
  String get previewStopped => 'முன்னோட்டம் நிறுத்தப்பட்டது';
  @override
  String get vipContact => 'VIP தொடர்பு';
  @override
  String get savedContact => 'சேமிக்கப்பட்ட தொடர்பு';
  @override
  String get officeColleague => 'அலுவலக சக ஊழியர்';
  @override
  String get unknownNumber => 'தெரியாத எண்';

  @override
  String get searchContactsHint => 'தொடர்புகள் & விதிகளைத் தேடுங்கள்';
  @override
  String get syncContacts => 'ஒத்திசைக்கவும்';
  @override
  String get syncingContacts => 'தொடர்புகள் ஒத்திசைக்கப்படுகின்றன...';
  @override
  String get contactsLoadedSuccess => 'தொடர்புகள் வெற்றிகரமாக ஏற்றப்பட்டன!';
  @override
  String get contactsPermissionNeeded => 'தொடர்புகள் அனுமதி தேவை';
  @override
  String get contactsPermissionBannerDesc =>
      'தொடர்புகளைக் காட்டவும் பெயர்களை அறிவிக்கவும் அனுமதி வழங்கவும்.';
  @override
  String get contactsPermissionRequired => 'தொடர்புகள் அனுமதி அவசியம்';
  @override
  String get contactsPermissionRequiredDesc =>
      'யார் அழைக்கிறார்கள் என்று செயலி கூற அனுமதி வழங்கவும்.';
  @override
  String get grantPermission => 'அனுமதி வழங்கவும்';
  @override
  String get filterAll => 'அனைத்தும்';
  @override
  String get filterCustomized => 'தனிப்பயனாக்கப்பட்டது';
  @override
  String get filterVip => 'VIP';
  @override
  String get filterMuted => 'முடக்கப்பட்டது';
  @override
  String get noContactsFound => 'பொருத்தமான தொடர்புகள் இல்லை';
  @override
  String get noContactsInList => 'பட்டியலில் தொடர்புகள் இல்லை';
  @override
  String get tapSyncToReimport =>
      'மீண்டும் இறக்குமதி செய்ய "ஒத்திசைக்கவும்" என்பதைத் தட்டவும்.';
  @override
  String get addRule => 'விதியைச் சேர்க்கவும்';
  @override
  String get newContactRule => 'புதிய தொடர்பு விதி';
  @override
  String get name => 'பெயர்';
  @override
  String get phoneNumber => 'ஃபோன் எண்';
  @override
  String get customAnnouncementText => 'தனிப்பயன் அறிவிப்பு உரை';
  @override
  String get saveRule => 'விதியைச் சேமிக்கவும்';
  @override
  String get saveChanges => 'மாற்றங்களைச் சேமிக்கவும்';
  @override
  String get personalizeFor => 'இதற்காகத் தனிப்பயனாக்குங்கள்';
  @override
  String get aiSuggest => 'AI ஆலோசனை';
  @override
  String get insert => 'சேர்க்கவும்:';
  @override
  String get previewAnnouncement => 'அறிவிப்பைக் கேளுங்கள்';
  @override
  String get delete => 'நீக்கு';

  @override
  String get categoryRulesTitle => 'வகை சார்ந்த விதிகள்';
  @override
  String get categoryRulesSubtitle =>
      'தனிப்பயன் விதி இல்லாத போது அழைப்பு எவ்வாறு அறிவிக்கப்பட வேண்டும் என்பதை அமைக்கவும்.';
  @override
  String get savedContactsTitle => 'சேமிக்கப்பட்ட தொடர்புகள்';
  @override
  String get savedContactsSubtitle => 'தெரிந்த தொடர்புகளுக்கான இயல்புநிலை நடத்தை';
  @override
  String get unknownNumbersTitle => 'தெரியாத எண்கள்';
  @override
  String get unknownNumbersSubtitle => 'சேமிக்கப்படாத எண்களுக்கான விதிகள்';
  @override
  String get vipContactsTitle => 'VIP தொடர்புகள்';
  @override
  String get vipContactsSubtitle => 'முன்னுரிமை தொடர்புகளுக்கான சிறப்பு அறிவிப்பு';
  @override
  String get editCategoryRule => 'விதியைத் திருத்தவும்';
  @override
  String get announcementTemplate => 'அறிவிப்பு வடிவம்';
  @override
  String get silentModeBehavior => 'சைலண்ட் & DND நடத்தை';
  @override
  String get respectSilent => 'சைலண்ட்டைப் பின்பற்றுங்கள்';
  @override
  String get bypassSilent => 'சைலண்ட்டைத் தவிர்க்கவும்';
  @override
  String get saveCategoryRule => 'விதியைச் சேமிக்கவும்';
}
