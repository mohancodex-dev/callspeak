import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/bluetooth_status_provider.dart';
import '../models/call_settings.dart';
import '../../navigation/main_navigation_scaffold.dart';
import '../../contact_announce/providers/contact_rule_provider.dart' hide nativeBridgeProvider;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedSimulatedCallerIndex = 0;
  bool _isPlayingPreview = false;

  static const List<Map<String, String>> _sampleCallers = [
    {'name': 'Mom', 'tag': 'Family', 'number': '+91 98765 43210'},
    {'name': 'Rahul Sharma', 'tag': 'Friend', 'number': '+91 99887 76655'},
    {'name': 'Office Boss', 'tag': 'Work', 'number': '+91 91234 56789'},
    {'name': 'Unknown Number', 'tag': 'Unknown', 'number': '+91 90000 12345'},
  ];

  static const Map<String, String> _languageNames = {
    'hi-IN': 'Hindi (हिन्दी)',
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
    'rathawi-IN': 'Rathawi',
  };

  String _getSimulatedMessage(String language, String name) {
    return switch (language) {
      'hi-IN' => '$name का फोन आ रहा है।',
      'bn-IN' => '$name फोन করছেন।',
      'te-IN' => '$name నుండి కాల్ వస్తోంది.',
      'mr-IN' => '$name यांचा फोन येत आहे.',
      'ta-IN' => '$name அழைக்கிறார்.',
      'gu-IN' => '$name નો ફોન આવી રહ્યો છે.',
      'kn-IN' => '$name ಅವರಿಂದ ಕರೆ ಬರುತ್ತಿದೆ.',
      'ml-IN' => '$name വിളിക്കുന്നു.',
      'pa-IN' => '$name ਦਾ ਫ਼ੋਨ ਆ ਰਿਹਾ ਹੈ।',
      'or-IN' => '$name ଙ୍କର ଫୋନ୍ ଆସୁଛି।',
      'as-IN' => '$name ফোন কৰিছে।',
      'ur-IN' => '$name کی کال آ رہی ہے۔',
      'kok-IN' => '$name चो फोन येता.',
      'ne-IN' || 'ne-NP' => '$name को फोन आउँदैछ।',
      'sd-IN' => '$name جو فون اچي رهيو آهي.',
      'rathawi-IN' => '$name न फोन आ रयो है।',
      _ => 'Incoming call from $name.',
    };
  }

  String _getRepeatLabel(String repeatMode) {
    return switch (repeatMode) {
      'once' || '1' => '1 Time',
      'two_times' || '2' => '2 Times',
      'three_times' || '3_times' || '3' || 'twice' => '3 Times',
      'until_answered' || 'continuous' => 'Until Answered',
      _ => '3 Times',
    };
  }

  Future<void> _testLiveVoice(CallSettings settings) async {
    setState(() => _isPlayingPreview = true);
    final sample = _sampleCallers[_selectedSimulatedCallerIndex];
    final message = _getSimulatedMessage(settings.language, sample['name']!);

    final bridge = ref.read(nativeBridgeProvider);
    await bridge.previewAnnouncement(
      text: message,
      language: settings.language,
      speechRate: settings.speechRate,
      volume: 1.0,
    );

    if (mounted) {
      setState(() => _isPlayingPreview = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing preview: "$message" (${_getRepeatLabel(settings.repeatMode)})'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsyncValue = ref.watch(settingsProvider);
    final permissionsGranted = ref.watch(permissionStatusProvider);
    final bluetoothConnected = ref.watch(bluetoothStatusProvider);
    final allRulesAsync = ref.watch(contactRulesProvider);
    final smartConfigAsync = ref.watch(smartFeaturesProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final allRules = allRulesAsync.value ?? [];
    final totalContacts = allRules.length;
    final vipCount = allRules.where((r) => r.isVip).length;
    final isAiActive = smartConfigAsync.value?.phoneticNameRecognition ?? true;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.record_voice_over_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CallSpeak',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                Text(
                  'Smart Announcer Dashboard',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.hintColor),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Quick Voice Test',
            icon: const Icon(Icons.volume_up_rounded, size: 20),
            onPressed: () {
              ref.read(nativeBridgeProvider).testAnnouncement();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: settingsAsyncValue.when(
        data: (settings) {
          final effectiveRepeat = (settings.repeatMode == 'twice') ? 'three_times' : settings.repeatMode;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. Master Hero Status Card (Pixel Glassmorphic Gradient)
              _buildMasterHeroCard(
                context: context,
                settings: settings,
                permissionsGranted: permissionsGranted,
                bluetoothConnected: bluetoothConnected,
                effectiveRepeat: effectiveRepeat,
                isDark: isDark,
              ),
              const SizedBox(height: 18),

              // 2. Dashboard Statistics & Feature Hub (2x2 Quick Navigation Grid)
              _buildDashboardSectionHeader(
                title: 'Overview & Status',
                subtitle: 'Live engine metrics and fast tab shortcuts',
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              _buildMetricGrid(
                totalContacts: totalContacts,
                vipCount: vipCount,
                isAiActive: isAiActive,
                permissionsGranted: permissionsGranted,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 22),

              // 3. Live Announcement Simulator Card
              _buildVoiceSimulatorCard(
                settings: settings,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 22),

              // 4. Repeat Announcement Policy (User's primary requirement!)
              _buildDashboardSectionHeader(
                title: 'Announcement Repetition',
                subtitle: 'How many times the caller name repeats aloud',
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              _buildRepeatPolicyCard(
                settings: settings,
                effectiveRepeat: effectiveRepeat,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 22),

              // 5. Audio Delivery & Routing Controls
              _buildDashboardSectionHeader(
                title: 'Audio Delivery & Devices',
                subtitle: 'Routing rules for headset, speaker, and car audio',
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              _buildAudioDeliveryCard(
                settings: settings,
                bluetoothConnected: bluetoothConnected,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 22),

              // 6. Silence & DND Protection
              _buildDashboardSectionHeader(
                title: 'Silence & DND Guard',
                subtitle: 'Prevent announcements during quiet hours or meetings',
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              _buildSilenceProtectionCard(
                settings: settings,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 22),

              // 7. Voice Engine, Language & Speed
              _buildDashboardSectionHeader(
                title: 'Voice Engine Configuration',
                subtitle: 'Spoken dialect, speech speed, and pitch synthesis',
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              _buildVoiceEngineCard(
                settings: settings,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 26),

              // 8. Bottom Fast Shortcuts
              _buildQuickShortcutsBanner(colorScheme: colorScheme),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Center(child: Text('Error loading dashboard: $e')),
      ),
    );
  }

  Widget _buildDashboardSectionHeader({
    required String title,
    required String subtitle,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 1. Master Hero Card
  Widget _buildMasterHeroCard({
    required BuildContext context,
    required CallSettings settings,
    required bool permissionsGranted,
    required bool bluetoothConnected,
    required String effectiveRepeat,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = settings.announcementEnabled;

    final primaryGradient = isEnabled
        ? (isDark
            ? const LinearGradient(
                colors: [Color(0xFF0F2B5C), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF0B57D0), Color(0xFF19376D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ))
        : LinearGradient(
            colors: isDark
                ? [const Color(0xFF1F242C), const Color(0xFF181B20)]
                : [const Color(0xFFE2E7EE), const Color(0xFFD3DAE4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final textColor = isEnabled || isDark ? Colors.white : const Color(0xFF1B1B1F);
    final subTextColor = isEnabled || isDark ? Colors.white.withAlpha(200) : const Color(0xFF44474E);

    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isEnabled ? colorScheme.primary.withAlpha(70) : Colors.black.withAlpha(15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Colors.white.withAlpha(40)
                      : (isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(20)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isEnabled ? Colors.white.withAlpha(70) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isEnabled ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
                  color: isEnabled ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isEnabled ? 'Announcer Active' : 'Announcer Paused',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isEnabled ? const Color(0xFF4ADE80) : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnabled
                          ? 'Speaking caller name aloud for incoming calls'
                          : 'Turn on to speak caller names automatically',
                      style: TextStyle(fontSize: 12, color: subTextColor, height: 1.3),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.95,
                child: Switch(
                  value: isEnabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF38BDF8),
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.black26,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(announcementEnabled: val));
                    if (val) {
                      ref.read(nativeBridgeProvider).startService();
                    } else {
                      ref.read(nativeBridgeProvider).stopService();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Real-time Diagnostic Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroPill(
                icon: permissionsGranted ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                label: permissionsGranted ? 'System Ready' : 'Permission Needed',
                bgColor: permissionsGranted
                    ? (isEnabled ? Colors.white.withAlpha(30) : Colors.green.withAlpha(30))
                    : Colors.amber.shade700.withAlpha(60),
                contentColor: permissionsGranted
                    ? (isEnabled || isDark ? Colors.white : Colors.green.shade800)
                    : Colors.amber.shade200,
                onTap: permissionsGranted
                    ? null
                    : () => ref.read(permissionStatusProvider.notifier).requestPermissions(),
              ),
              _buildHeroPill(
                icon: bluetoothConnected ? Icons.headphones_rounded : Icons.speaker_phone_rounded,
                label: bluetoothConnected ? 'Headset Connected' : 'Phone Speaker',
                bgColor: isEnabled ? Colors.white.withAlpha(30) : (isDark ? Colors.white12 : Colors.black12),
                contentColor: textColor,
              ),
              _buildHeroPill(
                icon: Icons.repeat_rounded,
                label: _getRepeatLabel(effectiveRepeat),
                bgColor: isEnabled ? Colors.white.withAlpha(30) : (isDark ? Colors.white12 : Colors.black12),
                contentColor: textColor,
              ),
              _buildHeroPill(
                icon: Icons.language_rounded,
                label: _languageNames[settings.language] ?? settings.language,
                bgColor: isEnabled ? Colors.white.withAlpha(30) : (isDark ? Colors.white12 : Colors.black12),
                contentColor: textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color contentColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: contentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Metric Grid with Fast Tab Shortcuts
  Widget _buildMetricGrid({
    required int totalContacts,
    required int vipCount,
    required bool isAiActive,
    required bool permissionsGranted,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: '$totalContacts Contacts',
                subtitle: '$vipCount VIP prioritized',
                badgeText: 'Manage',
                icon: Icons.contacts_rounded,
                iconColor: const Color(0xFF0B57D0),
                containerBg: colorScheme.surfaceContainerLowest,
                colorScheme: colorScheme,
                onTap: () {
                  // Switch to Contacts Tab (Index 1)
                  ref.read(mainNavTabProvider.notifier).setTab(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Category Rules',
                subtitle: '4 Voice profiles',
                badgeText: 'Rules',
                icon: Icons.tune_rounded,
                iconColor: Colors.deepPurple,
                containerBg: colorScheme.surfaceContainerLowest,
                colorScheme: colorScheme,
                onTap: () {
                  // Switch to Rules Tab (Index 2)
                  ref.read(mainNavTabProvider.notifier).setTab(2);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: isAiActive ? 'AI Phonetics' : 'AI Offline',
                subtitle: 'Smart Indian speech',
                badgeText: 'Smart AI',
                icon: Icons.auto_awesome_rounded,
                iconColor: Colors.amber.shade800,
                containerBg: colorScheme.surfaceContainerLowest,
                colorScheme: colorScheme,
                onTap: () {
                  // Switch to Smart AI Tab (Index 3)
                  ref.read(mainNavTabProvider.notifier).setTab(3);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: permissionsGranted ? 'Full Guard' : 'Needs Action',
                subtitle: 'DND & Silent active',
                badgeText: permissionsGranted ? 'Secure' : 'Fix',
                icon: Icons.security_rounded,
                iconColor: permissionsGranted ? Colors.teal : Colors.orange,
                containerBg: colorScheme.surfaceContainerLowest,
                colorScheme: colorScheme,
                onTap: permissionsGranted
                    ? null
                    : () => ref.read(permissionStatusProvider.notifier).requestPermissions(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color iconColor,
    required Color containerBg,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
  }) {
    return Material(
      color: containerBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: iconColor,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 16, color: iconColor),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Live Announcement Voice Simulator Card
  Widget _buildVoiceSimulatorCard({
    required CallSettings settings,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final sample = _sampleCallers[_selectedSimulatedCallerIndex];
    final previewSpeech = _getSimulatedMessage(settings.language, sample['name']!);
    final repeatLabel = _getRepeatLabel(settings.repeatMode);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.indigo, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Voice Simulator',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Simulate incoming call to verify announcement output',
                      style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Caller selection chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_sampleCallers.length, (idx) {
                final isSelected = _selectedSimulatedCallerIndex == idx;
                final c = _sampleCallers[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text('${c['name']} (${c['tag']})'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedSimulatedCallerIndex = idx);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Speech Bubble Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withAlpha(120),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant.withAlpha(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hearing_rounded, size: 16, color: Colors.blueAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Speech Synthesizer',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Repeats $repeatLabel',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"$previewSpeech"',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dialect: ${_languageNames[settings.language] ?? settings.language} • Speed: ${settings.speechRate.toStringAsFixed(1)}x',
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Test Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isPlayingPreview ? null : () => _testLiveVoice(settings),
              icon: _isPlayingPreview
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_circle_fill_rounded),
              label: Text(
                _isPlayingPreview ? 'Announcing Test Voice...' : 'Play Voice Announcement Test',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Repeat Policy Card (At least 3 times requirement)
  Widget _buildRepeatPolicyCard({
    required CallSettings settings,
    required String effectiveRepeat,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.repeat_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Repeat Count', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(
                      'Controls how many times caller names repeat during a call',
                      style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                avatar: effectiveRepeat == 'three_times'
                    ? const Icon(Icons.check, size: 16)
                    : null,
                label: const Text('3 Times (Default)'),
                selected: effectiveRepeat == 'three_times',
                onSelected: (val) {
                  if (val) {
                    ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(repeatMode: 'three_times'));
                  }
                },
              ),
              ChoiceChip(
                avatar: effectiveRepeat == 'until_answered'
                    ? const Icon(Icons.check, size: 16)
                    : null,
                label: const Text('Until Answered'),
                selected: effectiveRepeat == 'until_answered',
                onSelected: (val) {
                  if (val) {
                    ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(repeatMode: 'until_answered'));
                  }
                },
              ),
              ChoiceChip(
                avatar: effectiveRepeat == 'two_times'
                    ? const Icon(Icons.check, size: 16)
                    : null,
                label: const Text('2 Times'),
                selected: effectiveRepeat == 'two_times',
                onSelected: (val) {
                  if (val) {
                    ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(repeatMode: 'two_times'));
                  }
                },
              ),
              ChoiceChip(
                avatar: effectiveRepeat == 'once'
                    ? const Icon(Icons.check, size: 16)
                    : null,
                label: const Text('1 Time'),
                selected: effectiveRepeat == 'once',
                onSelected: (val) {
                  if (val) {
                    ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(repeatMode: 'once'));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    effectiveRepeat == 'three_times'
                        ? 'Announces 3 times with a 3-second natural gap between repetitions.'
                        : (effectiveRepeat == 'until_answered'
                            ? 'Repeats continuously until you answer or decline the call.'
                            : 'Announces ${_getRepeatLabel(effectiveRepeat)} during ringing.'),
                    style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Audio Delivery & Routing Controls
  Widget _buildAudioDeliveryCard({
    required CallSettings settings,
    required bool bluetoothConnected,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.headphones_rounded, color: Colors.blue),
            ),
            title: const Text('Bluetooth / Headset Only', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              bluetoothConnected
                  ? 'Wireless audio connected — announcements will play'
                  : 'Only announce when headphones or car audio is paired',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            value: settings.announceOnlyWithBluetooth,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(announceOnlyWithBluetooth: val));
            },
          ),
          const Divider(height: 1, indent: 64),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.speaker_phone_rounded, color: Colors.teal),
            ),
            title: const Text('Also Announce on Speaker', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              'Broadcast on internal phone speaker even if Bluetooth is paired',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            value: settings.alsoAnnounceOnSpeaker,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(alsoAnnounceOnSpeaker: val));
            },
          ),
        ],
      ),
    );
  }

  // 6. Silence & DND Protection
  Widget _buildSilenceProtectionCard({
    required CallSettings settings,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_off_rounded, color: Colors.amber),
            ),
            title: const Text('Silence in Silent / Vibrate Mode', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              'Keep voice quiet when phone ringer is muted or vibrating',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            value: settings.silenceInSilentMode,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(silenceInSilentMode: val));
            },
          ),
          const Divider(height: 1, indent: 64),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.do_not_disturb_on_rounded, color: Colors.redAccent),
            ),
            title: const Text('Silence in Do Not Disturb (DND)', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              'Remain completely quiet during active phone DND mode',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            value: settings.silenceInDndMode,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(silenceInDndMode: val));
            },
          ),
        ],
      ),
    );
  }

  // 7. Voice Engine Configuration
  Widget _buildVoiceEngineCard({
    required CallSettings settings,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.language_rounded, color: Colors.purple),
            ),
            title: const Text('Spoken Language', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              _languageNames[settings.language] ?? settings.language,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            trailing: DropdownButton<String>(
              value: settings.language,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(18),
              items: _languageNames.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(language: val));
                }
              },
            ),
          ),
          const Divider(height: 1, indent: 64),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.speed_rounded, size: 18, color: Colors.deepOrange),
                        ),
                        const SizedBox(width: 10),
                        const Text('Speech Speed', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${settings.speechRate.toStringAsFixed(1)}x Speed',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: settings.speechRate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(speechRate: val));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. Bottom Fast Shortcuts
  Widget _buildQuickShortcutsBanner({
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withAlpha(120),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Quick Navigation Shortcuts',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(mainNavTabProvider.notifier).setTab(1),
                  icon: const Icon(Icons.contacts_rounded, size: 16),
                  label: const Text('Contacts', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(mainNavTabProvider.notifier).setTab(2),
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Rules', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(mainNavTabProvider.notifier).setTab(3),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Smart AI', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
