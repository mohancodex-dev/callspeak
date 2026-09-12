class AppStrings {
  final String languageCode;

  const AppStrings({this.languageCode = 'en-US'});

  // Navigation
  String get navHome => 'Home';
  String get navContacts => 'Contacts';
  String get navRules => 'Rules';
  String get navSmartAi => 'Smart AI';

  // Hero & Status
  String get announcerActive => 'Announcer Active';
  String get announcerPaused => 'Announcer Paused';
  String get announcerActiveDesc => 'Speaking caller name aloud for incoming calls';
  String get announcerPausedDesc => 'Turn on to speak caller names automatically';
  String get systemReady => 'System Ready';
  String get permissionNeeded => 'Permission Needed';
  String get headsetConnected => 'Headset Connected';
  String get phoneSpeaker => 'Phone Speaker';
  String get repeatLabel1 => '1 Time';
  String get repeatLabel2 => '2 Times';
  String get repeatLabel3 => '3 Times';
  String get repeatUntilAnswered => 'Until Answered';

  // Metric Tiles
  String get aiPhonetics => 'AI Phonetics';
  String get aiOffline => 'AI Offline';
  String get smartIndianSpeech => 'Smart Indian speech';
  String get fullGuard => 'Full Guard';
  String get needsAction => 'Needs Action';
  String get secure => 'Secure';
  String get fix => 'Fix';
  String get dndSilentActive => 'DND & Silent active';

  // Speech & Voice Settings
  String get speechSettings => 'Speech & Voice Settings';
  String get appLanguage => 'App Display Language';
  String get appLanguageDesc => 'Language of screens, menus, and buttons';
  String get selectAppLanguage => 'Select App Language';
  String get announcementLanguage => 'Announcement Language';
  String get announcementVoiceLanguage => 'Announcement Voice Language';
  String get announcementVoiceDesc => 'Voice dialect used to speak caller names';
  String get selectLanguage => 'Select spoken voice language';
  String get speechRate => 'Speech Rate';
  String get speechRateSlow => 'Slow';
  String get speechRateNormal => 'Normal';
  String get speechRateFast => 'Fast';
  String get repeatMode => 'Repeat Mode';
  String get bluetoothOnly => 'Bluetooth / Headset Only';
  String get bluetoothOnlyDesc => 'Only announce when wireless audio is connected';
  String get speakerOutput => 'Also on Speaker';
  String get speakerOutputDesc => 'Announce on loudspeaker even if earphones connected';
  String get silenceInSilent => 'Respect Silent Mode';
  String get silenceInSilentDesc => 'Muted when phone is in silent or vibrate mode';
  String get silenceInDnd => 'Respect DND Mode';
  String get silenceInDndDesc => 'Muted when Do Not Disturb is active';

  // Permissions Dialog
  String get permissionsRequiredTitle => 'Permissions Required';
  String get permissionsRequiredDesc =>
      'To speak caller names for incoming calls, Smart Call Announce needs access to:';
  String get phoneCallsState => 'Phone Calls & State';
  String get phoneCallsStateDesc => 'Detect incoming calls & numbers';
  String get contactsAccess => 'Contacts Access';
  String get contactsAccessDesc => 'Speak caller names from address book';
  String get notificationsAudio => 'Notifications & Audio';
  String get notificationsAudioDesc => 'Run background announcer and support headsets';
  String get grantAllPermissions => 'Grant All Permissions';
  String get cancel => 'Cancel';
  String get allow => 'Allow';
  String get permissionsRequiredSnack =>
      'Permissions are required to announce caller names.';
  String get callerAnnouncerActivated => 'Caller Announcer activated!';
  String get callerAnnouncementPaused => 'Caller announcement paused';

  // Live Preview & Simulation
  String get simulateIncomingCall => 'Simulate Incoming Call';
  String get testVoice => 'Test Live Voice';
  String get stopVoice => 'Stop Voice';
  String get playingPreview => 'Playing preview';
  String get previewStopped => 'Announcement preview stopped';
  String get vipContact => 'VIP Contact';
  String get savedContact => 'Saved Contact';
  String get officeColleague => 'Office Colleague';
  String get unknownNumber => 'Unknown Number';

  // Contacts Screen
  String get searchContactsHint => 'Search contacts & rules';
  String get syncContacts => 'Sync Contacts';
  String get syncingContacts => 'Syncing device contacts...';
  String get contactsLoadedSuccess => 'Contacts loaded successfully!';
  String get contactsPermissionNeeded => 'Contacts Permission Needed';
  String get contactsPermissionBannerDesc =>
      'Allow access to automatically display contacts and announce caller names.';
  String get contactsPermissionRequired => 'Contacts Permission Required';
  String get contactsPermissionRequiredDesc =>
      'Grant contacts permission so Smart Call Announce can show and announce who is calling.';
  String get grantPermission => 'Grant Permission';
  String get filterAll => 'All';
  String get filterCustomized => 'Customized';
  String get filterVip => 'VIP';
  String get filterMuted => 'Muted';
  String get noContactsFound => 'No contacts match';
  String get noContactsInList => 'No contacts in this list';
  String get tapSyncToReimport =>
      'Tap "Sync Contacts" to re-import from your device or "Add Rule" below.';
  String get addRule => 'Add Rule';
  String get newContactRule => 'New Contact Rule';
  String get name => 'Name';
  String get phoneNumber => 'Phone Number';
  String get customAnnouncementText => 'Custom Announcement Text';
  String get saveRule => 'Save Rule';
  String get saveChanges => 'Save Changes';
  String get personalizeFor => 'Personalize for';
  String get aiSuggest => 'AI Suggest';
  String get insert => 'Insert:';
  String get previewAnnouncement => 'Preview Announcement';
  String get delete => 'Delete';

  // Rules Screen (Category Rules)
  String get categoryRulesTitle => 'Category-Based Rules';
  String get categoryRulesSubtitle =>
      'Define how calls are announced when an individual contact does not have a custom rule.';
  String get savedContactsTitle => 'Saved Contacts';
  String get savedContactsSubtitle => 'Default behavior for known address book contacts';
  String get unknownNumbersTitle => 'Unknown Numbers';
  String get unknownNumbersSubtitle =>
      'Announce calls from numbers not saved in contacts';
  String get vipContactsTitle => 'VIP Contacts';
  String get vipContactsSubtitle =>
      'Priority contacts with special announcement behavior';
  String get editCategoryRule => 'Edit Default Rule';
  String get announcementTemplate => 'Announcement Template';
  String get silentModeBehavior => 'Silent & DND Mode Behavior';
  String get respectSilent => 'Respect Silent';
  String get bypassSilent => 'Bypass Silent';
  String get saveCategoryRule => 'Save Category Rule';
}
