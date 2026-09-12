import '../app_strings.dart';

class MlStrings extends AppStrings {
  const MlStrings() : super(languageCode: 'ml-IN');

  @override
  String get navHome => 'ഹോം';
  @override
  String get navContacts => 'കോൺടാക്റ്റുകൾ';
  @override
  String get navRules => 'നിയമങ്ങൾ';
  @override
  String get navSmartAi => 'സ്മാർട്ട് AI';

  @override
  String get announcerActive => 'അനൗൺസർ സജീവം';
  @override
  String get announcerPaused => 'അനൗൺസർ താൽക്കാലികമായി നിർത്തി';
  @override
  String get announcerActiveDesc => 'ഇൻകമിംഗ് കോളുകളിൽ വിളിക്കുന്നയാളുടെ പേര് പറയുന്നു';
  @override
  String get announcerPausedDesc => 'പേരുകൾ സ്വയം കേൾക്കാൻ ഓൺ ചെയ്യുക';
  @override
  String get systemReady => 'സിസ്റ്റം സജ്ജമാണ്';
  @override
  String get permissionNeeded => 'അനുമതി ആവശ്യമാണ്';
  @override
  String get headsetConnected => 'ഹെഡ്‌സെറ്റ് ബന്ധിപ്പിച്ചു';
  @override
  String get phoneSpeaker => 'ഫോൺ സ്പീക്കർ';
  @override
  String get repeatLabel1 => '1 തവണ';
  @override
  String get repeatLabel2 => '2 തവണ';
  @override
  String get repeatLabel3 => '3 തവണ';
  @override
  String get repeatUntilAnswered => 'എടുക്കുന്നത് വരെ';

  @override
  String get aiPhonetics => 'AI ഉച്ചാരണം';
  @override
  String get aiOffline => 'AI ഓഫ്‌ലൈൻ';
  @override
  String get smartIndianSpeech => 'ഇന്ത്യൻ ശബ്ദങ്ങൾ';
  @override
  String get fullGuard => 'പൂർണ്ണ സുരക്ഷ';
  @override
  String get needsAction => 'നടപടി ആവശ്യമാണ്';
  @override
  String get secure => 'സുരക്ഷിതം';
  @override
  String get fix => 'പരിഹരിക്കുക';
  @override
  String get dndSilentActive => 'DND & സൈലന്റ് സജീവം';

  @override
  String get speechSettings => 'ശബ്ദ ക്രമീകരണങ്ങൾ';
  @override
  String get announcementLanguage => 'അനൗൺസ്മെന്റ് ഭാഷ';
  @override
  String get selectLanguage => 'സംസാരിക്കുന്ന ഭാഷ തിരഞ്ഞെടുക്കുക';
  @override
  String get speechRate => 'സംസാരിക്കുന്ന വേഗത';
  @override
  String get speechRateSlow => 'പതുക്കെ';
  @override
  String get speechRateNormal => 'സാധാരണ';
  @override
  String get speechRateFast => 'വേഗത്തിൽ';
  @override
  String get repeatMode => 'ആവർത്തന മോഡ്';
  @override
  String get bluetoothOnly => 'ബ്ലൂടൂത്ത് / ഹെഡ്‌സെറ്റ് മാത്രം';
  @override
  String get bluetoothOnlyDesc => 'വയർലെസ് ഓഡിയോ കണക്റ്റുചെയ്യുമ്പോൾ മാത്രം സംസാരിക്കുക';
  @override
  String get speakerOutput => 'സ്പീക്കറിലും സംസാരിക്കുക';
  @override
  String get speakerOutputDesc => 'ഇയർഫോൺ ഉള്ളപ്പോഴും ലൗഡ് സ്പീക്കറിൽ പറയുക';
  @override
  String get silenceInSilent => 'സൈലന്റ് മോഡ് പാലിക്കുക';
  @override
  String get silenceInSilentDesc => 'ഫോൺ സൈലന്റിലോ വൈബ്രേഷനിലോ ആയിരിക്കുമ്പോൾ പറയരുത്';
  @override
  String get silenceInDnd => 'DND മോഡ് പാലിക്കുക';
  @override
  String get silenceInDndDesc => 'ഡു നോട്ട് ഡിസ്റ്റർബ് ഓണായിരിക്കുമ്പോൾ പറയരുത്';

  @override
  String get permissionsRequiredTitle => 'അനുമതികൾ ആവശ്യമാണ്';
  @override
  String get permissionsRequiredDesc =>
      'വിളിക്കുന്നയാളുടെ പേര് പറയാൻ ഈ അനുമതികൾ നൽകേണ്ടതുണ്ട്:';
  @override
  String get phoneCallsState => 'ഫോൺ കോളുകളും നിലയും';
  @override
  String get phoneCallsStateDesc => 'കോളുകളും നമ്പറുകളും തിരിച്ചറിയാൻ';
  @override
  String get contactsAccess => 'കോൺടാക്റ്റ്സ് ആക്സസ്';
  @override
  String get contactsAccessDesc => 'വിലാസ പുസ്തകത്തിൽ നിന്ന് പേര് പറയാൻ';
  @override
  String get notificationsAudio => 'അറിയിപ്പുകളും ഓഡിയോയും';
  @override
  String get notificationsAudioDesc => 'പശ്ചാത്തല സേവനത്തിനും ഹെഡ്‌സെറ്റിനും';
  @override
  String get grantAllPermissions => 'എല്ലാ അനുമതികളും നൽകുക';
  @override
  String get cancel => 'റദ്ദാക്കുക';
  @override
  String get allow => 'അനുവദിക്കുക';
  @override
  String get permissionsRequiredSnack => 'പേര് അനൗൺസ് ചെയ്യാൻ അനുമതികൾ ആവശ്യമാണ്.';
  @override
  String get callerAnnouncerActivated => 'കോളർ അനൗൺസർ പ്രവർത്തനക്ഷമമാക്കി!';
  @override
  String get callerAnnouncementPaused => 'അനൗൺസർ താൽക്കാലികമായി നിർത്തി';

  @override
  String get simulateIncomingCall => 'കോൾ പരീക്ഷിക്കുക';
  @override
  String get testVoice => 'ശബ്ദം പരിശോധിക്കുക';
  @override
  String get stopVoice => 'നിർത്തുക';
  @override
  String get playingPreview => 'പ്രിവ്യൂ പ്ലേ ചെയ്യുന്നു';
  @override
  String get previewStopped => 'പ്രിവ്യൂ നിർത്തി';
  @override
  String get vipContact => 'VIP കോൺടാക്റ്റ്';
  @override
  String get savedContact => 'സേവ് ചെയ്ത കോൺടാക്റ്റ്';
  @override
  String get officeColleague => 'ഓഫീസ് സഹപ്രവർത്തകൻ';
  @override
  String get unknownNumber => 'അജ്ഞാത നമ്പർ';

  @override
  String get searchContactsHint => 'കോൺടാക്റ്റുകളും നിയമങ്ങളും തിരയുക';
  @override
  String get syncContacts => 'സിങ്ക് ചെയ്യുക';
  @override
  String get syncingContacts => 'കോൺടാക്റ്റുകൾ സിങ്ക് ചെയ്യുന്നു...';
  @override
  String get contactsLoadedSuccess => 'കോൺടാക്റ്റുകൾ വിജയകരമായി ലോഡുചെയ്തു!';
  @override
  String get contactsPermissionNeeded => 'കോൺടാക്റ്റ് അനുമതി ആവശ്യമാണ്';
  @override
  String get contactsPermissionBannerDesc =>
      'കോൺടാക്റ്റുകൾ കാണിക്കാനും പേര് പറയാനും അനുമതി നൽകുക.';
  @override
  String get contactsPermissionRequired => 'കോൺടാക്റ്റ് അനുമതി നിർബന്ധമാണ്';
  @override
  String get contactsPermissionRequiredDesc =>
      'ആരാണ് വിളിക്കുന്നതെന്ന് ആപ്പിന് പറയാൻ അനുമതി നൽകുക.';
  @override
  String get grantPermission => 'അനുമതി നൽകുക';
  @override
  String get filterAll => 'എല്ലാം';
  @override
  String get filterCustomized => 'മാറ്റങ്ങൾ വരുത്തിയത്';
  @override
  String get filterVip => 'VIP';
  @override
  String get filterMuted => 'മ്യൂട്ട് ചെയ്തവ';
  @override
  String get noContactsFound => 'കോൺടാക്റ്റുകളൊന്നും കണ്ടെത്തിയില്ല';
  @override
  String get noContactsInList => 'ഈ പട്ടികയിൽ കോൺടാക്റ്റുകളൊന്നുമില്ല';
  @override
  String get tapSyncToReimport =>
      'ഡിവൈസിൽ നിന്ന് വീണ്ടുമെടുക്കാൻ "സിങ്ക് ചെയ്യുക" അമർത്തുക.';
  @override
  String get addRule => 'നിയമം ചേർക്കുക';
  @override
  String get newContactRule => 'പുതിയ കോൺടാക്റ്റ് നിയമം';
  @override
  String get name => 'പേര്';
  @override
  String get phoneNumber => 'ഫോൺ നമ്പർ';
  @override
  String get customAnnouncementText => 'കസ്റ്റം അനൗൺസ്മെന്റ് വാചകം';
  @override
  String get saveRule => 'നിയമം സംരക്ഷിക്കുക';
  @override
  String get saveChanges => 'മാറ്റങ്ങൾ സംരക്ഷിക്കുക';
  @override
  String get personalizeFor => 'ഇതിനായി മാറ്റുക';
  @override
  String get aiSuggest => 'AI നിർദ്ദേശം';
  @override
  String get insert => 'ചേർക്കുക:';
  @override
  String get previewAnnouncement => 'അനൗൺസ്മെന്റ് കേൾക്കുക';
  @override
  String get delete => 'ഡിലീറ്റ്';

  @override
  String get categoryRulesTitle => 'വിഭാഗം അടിസ്ഥാനമാക്കിയുള്ള നിയമങ്ങൾ';
  @override
  String get categoryRulesSubtitle =>
      'പ്രത്യേക നിയമമില്ലെങ്കിൽ കോൾ എങ്ങനെ അനൗൺസ് ചെയ്യണമെന്ന് തീരുമാനിക്കുക.';
  @override
  String get savedContactsTitle => 'സേവ് ചെയ്ത കോൺടാക്റ്റുകൾ';
  @override
  String get savedContactsSubtitle => 'ഫോൺ ബുക്കിലെ കോൺടാക്റ്റുകൾക്കുള്ള സ്വഭാവം';
  @override
  String get unknownNumbersTitle => 'അപരിചിത നമ്പറുകൾ';
  @override
  String get unknownNumbersSubtitle => 'സേവ് ചെയ്യാത്ത നമ്പറുകൾക്കുള്ള നിയമങ്ങൾ';
  @override
  String get vipContactsTitle => 'VIP കോൺടാക്റ്റുകൾ';
  @override
  String get vipContactsSubtitle => 'മുൻഗണനാ കോൺടാക്റ്റുകൾക്കുള്ള പ്രത്യേക അറിയിപ്പ്';
  @override
  String get editCategoryRule => 'നിയമം തിരുത്തുക';
  @override
  String get announcementTemplate => 'അനൗൺസ്മെന്റ് ശൈലി';
  @override
  String get silentModeBehavior => 'സൈലന്റ് & DND രീതി';
  @override
  String get respectSilent => 'സൈലന്റ് പാലിക്കുക';
  @override
  String get bypassSilent => 'സൈലന്റിലും സംസാരിക്കുക';
  @override
  String get saveCategoryRule => 'നിയമം സംരക്ഷിക്കുക';
}
