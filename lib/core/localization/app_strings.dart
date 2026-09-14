class AppStrings {
  final String languageCode;

  const AppStrings({this.languageCode = 'en-US'});

  // Navigation
  String get navHome => 'Home';
  String get navContacts => 'Contacts';
  String get navRules => 'Rules';
  String get navSmartAi => 'Smart AI';

  // Hero & Status
  String get announcerActive => 'Announcer ON';
  String get announcerPaused => 'Announcer OFF';
  String get announcerActiveDesc => 'Speaks caller name when phone rings';
  String get announcerPausedDesc => 'Turn ON to speak caller names automatically';
  String get systemReady => 'Ready';
  String get permissionNeeded => 'Permission Needed';
  String get headsetConnected => 'Earphones Connected';
  String get phoneSpeaker => 'Phone Speaker';
  String get repeatLabel1 => '1 Time';
  String get repeatLabel2 => '2 Times';
  String get repeatLabel3 => '3 Times';
  String get repeatUntilAnswered => 'Until Answered';

  // Metric Tiles & Section Headers
  String get aiPhonetics => 'AI Voice';
  String get aiOffline => 'Voice Offline';
  String get smartIndianSpeech => 'Clear Indian voice';
  String get fullGuard => 'Fully Protected';
  String get needsAction => 'Action Needed';
  String get secure => 'Active';
  String get fix => 'Fix';
  String get dndSilentActive => 'Silent & DND protected';

  // Dashboard Section Headers
  String get sectionOverview => 'Overview & Status';
  String get sectionOverviewDesc => 'Live status and quick shortcuts';
  String get sectionAudioDelivery => 'Audio & Devices';
  String get sectionAudioDeliveryDesc => 'Choose speaker or earphones for announcements';
  String get sectionSilenceDnd => 'Silent & DND Settings';
  String get sectionSilenceDndDesc => 'Prevent speaking during quiet hours or meetings';
  String get sectionRepeatMode => 'Repeat Announcement';
  String get sectionRepeatModeDesc => 'How many times the caller name repeats aloud';
  String get sectionTheme => 'App Theme';
  String get sectionThemeDesc => 'Dark mode, Light mode, or System default';
  String get sectionShortcuts => 'Quick Shortcuts';
  String get sectionShortcutsDesc => 'Manage contacts and call rules';
  String get sectionSimulator => 'Test Voice Announcement';
  String get sectionSimulatorDesc => 'Hear a sample call announcement in selected voice';

  // Speech & Voice Settings
  String get speechSettings => 'Voice & Language';
  String get speechSettingsDesc => 'Choose voice language, speed, and repeats';
  String get appLanguage => 'App Language';
  String get appLanguageDesc => 'Language used for app screens and buttons';
  String get selectAppLanguage => 'Choose App Language';
  String get announcementLanguage => 'Caller Voice Language';
  String get announcementVoiceLanguage => 'Caller Voice Language';
  String get announcementVoiceDesc => 'Language used to speak caller names';
  String get selectLanguage => 'Choose voice language';
  String get speechRate => 'Voice Speed';
  String get speechRateSlow => 'Slow';
  String get speechRateNormal => 'Normal';
  String get speechRateFast => 'Fast';
  String get repeatMode => 'Repeat Announcement';
  String get repeatModeDesc => 'How many times caller name will be spoken';
  String get bluetoothOnly => 'Earphones / Bluetooth Only';
  String get bluetoothOnlyDesc => 'Only speak name when earphones or Bluetooth are connected';
  String get speakerOutput => 'Also Speak on Speaker';
  String get speakerOutputDesc => 'Speak on phone speaker even when earphones are plugged in';
  String get silenceInSilent => 'Stay Quiet in Silent Mode';
  String get silenceInSilentDesc => 'Do not speak name if phone is on Silent or Vibrate';
  String get silenceInDnd => 'Stay Quiet in DND (Do Not Disturb)';
  String get silenceInDndDesc => 'Do not speak name when Do Not Disturb is ON';

  // Permissions Dialog
  String get permissionsRequiredTitle => 'Permissions Needed';
  String get permissionsRequiredDesc =>
      'To speak caller names when calls arrive, the app needs access to:';
  String get phoneCallsState => 'Phone Calls';
  String get phoneCallsStateDesc => 'Detect when a call is arriving';
  String get contactsAccess => 'Contacts';
  String get contactsAccessDesc => 'Read contact names to speak them aloud';
  String get notificationsAudio => 'Notifications & Sound';
  String get notificationsAudioDesc => 'Keep announcer running in the background';
  String get grantAllPermissions => 'Allow Permissions';
  String get cancel => 'Cancel';
  String get allow => 'Allow';
  String get permissionsRequiredSnack =>
      'Please allow permissions to speak caller names.';
  String get callerAnnouncerActivated => 'Caller Announcer turned ON!';
  String get callerAnnouncementPaused => 'Caller Announcer turned OFF';
  String get permissionsPrivacyBadge =>
      '🔒 100% Private & Safe: All call details and contacts stay strictly on your phone. No data is ever collected, stored, or uploaded.';

  // Background Reliability & Battery Saver Prominent Disclosure
  String get batteryDisclosureTitle => 'Allow Background Reliability';
  String get batteryDisclosureSubtitle =>
      'Keep announcing caller names when screen is off or locked';
  String get batteryDisclosureMessage =>
      'To announce caller names without delay when your phone is locked or screen is turned off, CallSpeak requires exemption from battery restrictions.';
  String get batteryDisclosureOemWarning =>
      'On Xiaomi, Samsung, Vivo, Oppo & OnePlus devices, battery saver will silence incoming call announcements unless unrestricted.';
  String get batteryDisclosureBullet1 =>
      'Speaks only during incoming calls (zero idle battery drain)';
  String get batteryDisclosureBullet2 =>
      '100% private — caller info never leaves your phone';
  String get batteryDisclosureAllow => 'Allow (Recommended)';
  String get batteryDisclosureLater => 'Not Now';
  String get batteryOptimizationActive => 'Exempt (Reliable)';
  String get batteryOptimizationNotActive => 'Restricted (May miss calls)';

  // OEM Background & Auto-Start Guide
  String get oemGuideTitle => 'Background & Auto-Start Setup';
  String get oemGuideDesc =>
      'To ensure CallSpeak never misses a call when your phone is sleeping, check these 2 settings:';
  String get oemStep1Title => '1. Battery Restriction';
  String get oemStep1Desc =>
      'Set Battery usage to "Unrestricted" or "Don\'t optimize".';
  String get oemStep2Title => '2. Auto-Start / Background Activity';
  String get oemStep2Desc =>
      'Turn ON "Auto-start" or "Allow background activity" (Xiaomi, Vivo, Oppo, OnePlus).';
  String get oemOpenSettings => 'Open App Settings';

  // DND Access Disclosure
  String get dndDisclosureTitle => 'Allow Do Not Disturb Access';
  String get dndDisclosureDesc =>
      'Smart Silent needs Do Not Disturb permission to automatically silence your phone during meetings or quiet hours, and restore normal ringtone when done.';
  String get dndDisclosureOpen => 'Open DND Settings';

  // Live Preview & Simulation
  String get simulateIncomingCall => 'Test Voice Announcement';
  String get testVoice => 'Test Voice';
  String get stopVoice => 'Stop Voice';
  String get playingPreview => 'Playing voice sample...';
  String get previewStopped => 'Voice test stopped';
  String get vipContact => 'VIP Contact';
  String get savedContact => 'Saved Contact';
  String get officeColleague => 'Work Contact';
  String get unknownNumber => 'Unknown Number';

  // Contacts Screen
  String get searchContactsHint => 'Search contacts...';
  String get syncContacts => 'Load Contacts';
  String get syncingContacts => 'Loading contacts from phone...';
  String get contactsLoadedSuccess => 'Contacts loaded successfully!';
  String get contactsPermissionNeeded => 'Contact Permission Needed';
  String get contactsPermissionBannerDesc =>
      'Allow contact access so the app can announce who is calling.';
  String get contactsPermissionRequired => 'Contact Permission Required';
  String get contactsPermissionRequiredDesc =>
      'Allow contact access so the app can speak names from your phonebook.';
  String get grantPermission => 'Allow Permission';
  String get filterAll => 'All';
  String get filterCustomized => 'Custom';
  String get filterVip => 'VIP';
  String get filterMuted => 'Muted';
  String get noContactsFound => 'No contacts found';
  String get noContactsInList => 'No contacts in this list';
  String get tapSyncToReimport =>
      'Tap "Load Contacts" to refresh contacts from your phone.';
  String get addRule => 'Add Contact';
  String get newContactRule => 'New Contact Rule';
  String get name => 'Name';
  String get phoneNumber => 'Phone Number';
  String get customAnnouncementText => 'What to say for this contact';
  String get saveRule => 'Save';
  String get saveChanges => 'Save Changes';
  String get personalizeFor => 'Custom message for';
  String get aiSuggest => 'AI Ideas';
  String get insert => 'Insert:';
  String get previewAnnouncement => 'Listen';
  String get delete => 'Delete';

  // Rules Screen (Category Rules)
  String get categoryRulesTitle => 'Default Call Rules';
  String get categoryRulesSubtitle =>
      'How to announce calls when a contact does not have custom settings';
  String get savedContactsTitle => 'Saved Contacts';
  String get savedContactsSubtitle => 'Calls from people in your phonebook';
  String get unknownNumbersTitle => 'Unknown Numbers';
  String get unknownNumbersSubtitle =>
      'Calls from numbers not saved in your phone';
  String get vipContactsTitle => 'VIP Contacts';
  String get vipContactsSubtitle =>
      'Important contacts with special announcement';
  String get spamCallersTitle => 'Spam Callers';
  String get spamCallersSubtitle =>
      'Warning for suspected spam or telemarketer numbers';
  String get editCategoryRule => 'Edit Rule';
  String get announcementTemplate => 'Announcement Message';
  String get silentModeBehavior => 'In Silent & DND Mode';
  String get respectSilent => 'Stay Quiet';
  String get bypassSilent => 'Speak Even in Silent';
  String get saveCategoryRule => 'Save Rule';

  // Smart Features Screen (Legacy / Optional)
  String get smartFeaturesTitle => 'Smart AI & Features';
  String get smartFeaturesBannerTitle => 'Smart Voice Assistant';
  String get smartFeaturesBannerDesc =>
      'Helpful tools to make caller announcements clearer and smarter.';
  String get smartAiAnnounceTitle => 'AI Voice Suggestions';
  String get smartAiAnnounceDesc =>
      'Suggests friendly announcement messages based on the caller.';
  String get smartPhoneticTitle => 'Clear Indian Pronunciation';
  String get smartPhoneticDesc =>
      'Improves name pronunciation so Indian names sound natural.';
  String get smartVipTitle => 'VIP Call Priority';
  String get smartVipDesc =>
      'Speaks aloud for VIP calls even if phone is on Silent or DND.';
  String get smartSpamTitle => 'Spam Call Warning';
  String get smartSpamDesc =>
      'Says "Warning: Spam Call" before announcing unknown spam numbers.';
  String get smartEarbudTitle => 'Earphones Private Mode';
  String get smartEarbudDesc =>
      'Keeps speaker muted when earphones or Bluetooth are plugged in.';

  // Settings & Help
  String get navSettings => 'Settings';
  String get settingsTitle => 'Settings & Help';
  String get ttsEngineTitle => 'Text-to-Speech Engine';
  String get openSystemTts => 'System TTS Settings';
  String get openSystemTtsDesc => 'Install Google Speech Services or regional voices';
  String get batteryOptimizationTitle => 'Background Reliability';
  String get batteryOptimizationDesc => 'Keep CallSpeak running smoothly when screen is locked';
  String get disableBatteryOpt => 'Exempt from Battery Saver';
  String get troubleshootingTitle => 'Troubleshooting & FAQ';
  String get privacyPolicyTitle => 'Privacy Policy';
  String get termsOfService => 'Terms of Service';
  String get aboutTitle => 'About CallSpeak';
  String get version => 'Version';
  String get rateApp => 'Rate on Play Store';
  String get shareApp => 'Share CallSpeak';
  String get feedback => 'Send Feedback';

  // Onboarding
  String get onboardingWelcomeTitle => 'Know Who is Calling';
  String get onboardingWelcomeDesc => 'CallSpeak announces caller names aloud so you never have to scramble for your phone.';
  String get onboardingTestVoice => 'Listen to Voice Sample';
  String get onboardingPermissionsTitle => '100% Private & On-Device';
  String get onboardingPermissionsDesc => 'All caller information is processed locally on your device. Zero data is ever collected or uploaded.';
  String get onboardingGrantPermissions => 'Grant Required Permissions';
  String get onboardingBatteryTitle => 'Runs Reliably in Background';
  String get onboardingBatteryDesc => 'Allow background activity without battery restrictions to announce calls while phone is locked.';
  String get onboardingGetStarted => 'Get Started';
  String get onboardingNext => 'Next';
  String get onboardingSkip => 'Skip';

  // Smart Silent
  String get smartSilentTitle => 'Smart Silent';
  String get smartSilentSubtitle => 'Automate quiet hours for meetings, office & sleep';
  String get smartSilentDesc => 'Automatically silences your phone and restores normal mode based on schedule and location';
  String get addSchedule => 'Add Schedule';
  String get editSchedule => 'Edit Schedule';
  String get scheduleTitleLabel => 'Schedule Name';
  String get startTimeLabel => 'Start Time (Auto Silent 🔕)';
  String get endTimeLabel => 'End Time (Auto Normal 🔔)';
  String get autoSilentIndicator => 'Silent automatically';
  String get autoNormalIndicator => 'Normal automatically';
  String get locationTriggerOptional => 'Location Trigger (Optional)';
  String get locationTriggerDesc => 'Silences when at this location during the scheduled time';
  String get locationNameLabel => 'Location Name (e.g. Office, Meeting Room)';
  String get locationRadiusLabel => 'Trigger Radius';
  String get dndAccessNeeded => 'Do Not Disturb access is required to automate system silent mode.';
  String get grantDndAccess => 'Grant DND Access';
  String get activeNow => 'Active Now';
  String get currentlySilenced => 'Phone currently silenced';
  String get normalActive => 'Normal Mode';
}

