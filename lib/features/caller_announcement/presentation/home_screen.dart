import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/bluetooth_status_provider.dart';
import '../models/call_settings.dart';
import '../../navigation/main_navigation_scaffold.dart';
import '../../contact_announce/providers/contact_rule_provider.dart' hide nativeBridgeProvider;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/announcement_languages.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/app_strings.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedSimulatedCallerIndex = 0;
  bool _isPlayingPreview = false;

  static const List<Map<String, String>> _sampleCallers = [
    {'name': 'VIP Contact', 'tag': 'VIP', 'number': '+91 98000 00001'},
    {'name': 'Saved Contact', 'tag': 'Saved', 'number': '+91 98000 00002'},
    {'name': 'Office Colleague', 'tag': 'Work', 'number': '+91 98000 00003'},
    {'name': 'Unknown Number', 'tag': 'Unknown', 'number': '+91 98000 00004'},
  ];

  static const Map<String, String> _languageNames = AnnouncementLanguages.languageNames;

  String _getSampleCallerName(int index, AppStrings strings) {
    return switch (index) {
      0 => strings.vipContact,
      1 => strings.savedContact,
      2 => strings.officeColleague,
      3 => strings.unknownNumber,
      _ => strings.savedContact,
    };
  }

  String _getSimulatedMessage(String language, Map<String, String> caller, [AppStrings? strings, int? index]) {
    final isUnknown = caller['tag'] == 'Unknown';
    if (isUnknown) {
      return AnnouncementLanguages.getUnknownAnnouncement(
        language: language,
        phoneNumber: caller['number'],
      );
    } else {
      final name = (strings != null && index != null)
          ? _getSampleCallerName(index, strings)
          : (caller['name'] ?? 'Someone');
      return AnnouncementLanguages.getContactAnnouncement(
        language: language,
        name: name,
      );
    }
  }

  String _getRepeatLabel(String repeatMode, [AppStrings? strings]) {
    final AppStrings s = strings ?? ref.read(appStringsProvider);
    return switch (repeatMode) {
      'once' || '1' => s.repeatLabel1,
      'two_times' || '2' => s.repeatLabel2,
      'three_times' || '3_times' || '3' || 'twice' => s.repeatLabel3,
      'until_answered' || 'continuous' => s.repeatUntilAnswered,
      _ => s.repeatLabel3,
    };
  }

  Future<void> _testLiveVoice(CallSettings settings) async {
    final bridge = ref.read(nativeBridgeProvider);
    final strings = ref.read(appStringsProvider);
    if (_isPlayingPreview) {
      await bridge.stopAnnouncement();
      if (mounted) {
        setState(() => _isPlayingPreview = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.previewStopped),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    setState(() => _isPlayingPreview = true);
    final sample = _sampleCallers[_selectedSimulatedCallerIndex];
    final message = _getSimulatedMessage(settings.language, sample, strings, _selectedSimulatedCallerIndex);

    try {
      await bridge.previewAnnouncement(
        text: message,
        language: settings.language,
        speechRate: settings.speechRate,
        volume: 1.0,
        repeatMode: settings.repeatMode,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isPlayingPreview = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting voice preview: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    if (mounted) {
      final repeatSeconds = switch (settings.repeatMode) {
        'once' || '1' => 4,
        'two_times' || '2' => 8,
        'three_times' || 'twice' || '3' => 14,
        _ => 14,
      };

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${strings.playingPreview}: "$message" (${_getRepeatLabel(settings.repeatMode, strings)})'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: Duration(seconds: repeatSeconds),
          action: SnackBarAction(
            label: strings.stopVoice,
            onPressed: () {
              bridge.stopAnnouncement();
              if (mounted) {
                setState(() => _isPlayingPreview = false);
              }
            },
          ),
        ),
      );

      // Automatically reset preview state after expected speech duration
      Future.delayed(Duration(seconds: repeatSeconds), () {
        if (mounted && _isPlayingPreview) {
          setState(() => _isPlayingPreview = false);
        }
      });
    }
  }

  Future<void> _handleToggleAnnouncement(
    bool enable,
    CallSettings settings,
    bool permissionsGranted,
  ) async {
    final strings = ref.read(appStringsProvider);
    if (!enable) {
      // User turned toggle OFF
      await ref.read(settingsProvider.notifier).updateSettings(
            settings.copyWith(announcementEnabled: false),
          );
      await ref.read(nativeBridgeProvider).stopService();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.callerAnnouncementPaused),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // User turned toggle ON
    if (!permissionsGranted) {
      final proceed = await _showPermissionRequiredDialog(strings);
      if (proceed != true) {
        // User dismissed/cancelled
        return;
      }

      await ref.read(permissionStatusProvider.notifier).requestPermissions();
      final nowGranted = ref.read(permissionStatusProvider);

      if (!nowGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.permissionsRequiredSnack),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
    }

    // Permissions are granted, activate service
    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(announcementEnabled: true),
        );
    await ref.read(nativeBridgeProvider).startService();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Text(strings.callerAnnouncerActivated),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool?> _showPermissionRequiredDialog([AppStrings? strings]) {
    final AppStrings s = strings ?? ref.read(appStringsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          title: Text(
            s.permissionsRequiredTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.permissionsRequiredDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                icon: Icons.phone_in_talk_rounded,
                iconColor: Colors.blueAccent,
                title: s.phoneCallsState,
                subtitle: s.phoneCallsStateDesc,
              ),
              const SizedBox(height: 12),
              _buildPermissionItem(
                icon: Icons.contacts_rounded,
                iconColor: Colors.teal,
                title: s.contactsAccess,
                subtitle: s.contactsAccessDesc,
              ),
              const SizedBox(height: 12),
              _buildPermissionItem(
                icon: Icons.notifications_active_rounded,
                iconColor: Colors.orange,
                title: s.notificationsAudio,
                subtitle: s.notificationsAudioDesc,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(s.grantAllPermissions, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(200),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsyncValue = ref.watch(settingsProvider);
    final permissionsGranted = ref.watch(permissionStatusProvider);
    final bluetoothConnected = ref.watch(bluetoothStatusProvider);
    final allRulesAsync = ref.watch(contactRulesProvider);
    final smartConfigAsync = ref.watch(smartFeaturesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final strings = ref.watch(appStringsProvider);
    final currentAppLang = ref.watch(appLanguageProvider);

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
            tooltip: 'App Display Language (${_languageNames[currentAppLang] ?? currentAppLang})',
            icon: const Icon(
              Icons.translate_rounded,
              size: 20,
            ),
            onPressed: () => _showAppLanguageSheet(context, ref, currentAppLang),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: 'App Theme (Light/Dark/System)',
            icon: Icon(
              switch (themeMode) {
                ThemeMode.system => Icons.brightness_auto_rounded,
                ThemeMode.light => Icons.light_mode_rounded,
                ThemeMode.dark => Icons.dark_mode_rounded,
              },
              size: 20,
            ),
            onPressed: () => _showThemeModeSheet(context, ref, themeMode),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: _isPlayingPreview ? 'Stop Voice Test' : 'Quick Voice Test',
            icon: Icon(
              _isPlayingPreview ? Icons.stop_rounded : Icons.volume_up_rounded,
              size: 20,
              color: _isPlayingPreview ? Colors.red.shade700 : null,
            ),
            onPressed: () {
              final settings = settingsAsyncValue.value;
              if (settings != null) {
                _testLiveVoice(settings);
              } else {
                ref.read(nativeBridgeProvider).testAnnouncement();
              }
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
                strings: strings,
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
                strings: strings,
              ),
              const SizedBox(height: 22),

              // 3. Live Announcement Simulator Card
              _buildVoiceSimulatorCard(
                settings: settings,
                theme: theme,
                colorScheme: colorScheme,
                strings: strings,
              ),
              const SizedBox(height: 22),

              // 4. Repeat Announcement Policy (User's primary requirement!)
              _buildDashboardSectionHeader(
                title: strings.repeatMode,
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
                strings: strings,
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
                strings: strings,
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
                strings: strings,
              ),
              const SizedBox(height: 22),

              // 7. Voice Engine, Language & Speed
              _buildDashboardSectionHeader(
                title: strings.speechSettings,
                subtitle: strings.selectLanguage,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              _buildVoiceEngineCard(
                settings: settings,
                theme: theme,
                colorScheme: colorScheme,
                strings: strings,
                currentAppLang: currentAppLang,
              ),
              const SizedBox(height: 22),

              // 8. App Appearance & Theme
              _buildDashboardSectionHeader(
                title: 'App Theme & Display',
                subtitle: 'Dark mode, Light mode, or System default',
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              _buildThemeModeCard(
                themeMode: themeMode,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 26),

              // 9. Bottom Fast Shortcuts
              _buildQuickShortcutsBanner(
                colorScheme: colorScheme,
                strings: strings,
              ),
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
    required AppStrings strings,
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
                          isEnabled ? strings.announcerActive : strings.announcerPaused,
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
                          ? strings.announcerActiveDesc
                          : strings.announcerPausedDesc,
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
                  onChanged: (val) => _handleToggleAnnouncement(val, settings, permissionsGranted),
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
                label: permissionsGranted ? strings.systemReady : strings.permissionNeeded,
                bgColor: permissionsGranted
                    ? (isEnabled ? Colors.white.withAlpha(30) : Colors.green.withAlpha(30))
                    : Colors.amber.shade700.withAlpha(60),
                contentColor: permissionsGranted
                    ? (isEnabled || isDark ? Colors.white : Colors.green.shade800)
                    : Colors.amber.shade200,
                onTap: permissionsGranted
                    ? null
                    : () async {
                        final proceed = await _showPermissionRequiredDialog(strings);
                        if (proceed == true) {
                          await ref.read(permissionStatusProvider.notifier).requestPermissions();
                        }
                      },
              ),
              _buildHeroPill(
                icon: bluetoothConnected ? Icons.headphones_rounded : Icons.speaker_phone_rounded,
                label: bluetoothConnected ? strings.headsetConnected : strings.phoneSpeaker,
                bgColor: isEnabled ? Colors.white.withAlpha(30) : (isDark ? Colors.white12 : Colors.black12),
                contentColor: textColor,
              ),
              _buildHeroPill(
                icon: Icons.repeat_rounded,
                label: _getRepeatLabel(effectiveRepeat, strings),
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
    required AppStrings strings,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: '$totalContacts ${strings.navContacts}',
                subtitle: '$vipCount ${strings.filterVip}',
                badgeText: strings.navContacts,
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
                title: strings.navRules,
                subtitle: '4 Voice profiles',
                badgeText: strings.navRules,
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
                title: isAiActive ? strings.aiPhonetics : strings.aiOffline,
                subtitle: strings.smartIndianSpeech,
                badgeText: strings.navSmartAi,
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
                title: permissionsGranted ? strings.fullGuard : strings.needsAction,
                subtitle: strings.dndSilentActive,
                badgeText: permissionsGranted ? strings.secure : strings.fix,
                icon: Icons.security_rounded,
                iconColor: permissionsGranted ? Colors.teal : Colors.orange,
                containerBg: colorScheme.surfaceContainerLowest,
                colorScheme: colorScheme,
                onTap: permissionsGranted
                    ? null
                    : () async {
                        final proceed = await _showPermissionRequiredDialog(strings);
                        if (proceed == true) {
                          await ref.read(permissionStatusProvider.notifier).requestPermissions();
                        }
                      },
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
    required AppStrings strings,
  }) {
    final sample = _sampleCallers[_selectedSimulatedCallerIndex];
    final previewSpeech = _getSimulatedMessage(settings.language, sample, strings, _selectedSimulatedCallerIndex);
    final repeatLabel = _getRepeatLabel(settings.repeatMode, strings);

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
                    Text(
                      strings.simulateIncomingCall,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
                final localizedName = _getSampleCallerName(idx, strings);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text('$localizedName (${c['tag']})'),
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

          // Test Button (Toggles between Play and Stop)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _testLiveVoice(settings),
              icon: Icon(
                _isPlayingPreview ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
              ),
              label: Text(
                _isPlayingPreview ? strings.stopVoice : strings.testVoice,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _isPlayingPreview ? Colors.red.shade700 : null,
                foregroundColor: _isPlayingPreview ? Colors.white : null,
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
    required AppStrings strings,
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
                    Text(strings.repeatMode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
                label: Text('${strings.repeatLabel3} (Default)'),
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
                label: Text(strings.repeatUntilAnswered),
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
                label: Text(strings.repeatLabel2),
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
                label: Text(strings.repeatLabel1),
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
                            : 'Announces ${_getRepeatLabel(effectiveRepeat, strings)} during ringing.'),
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
    required AppStrings strings,
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
            title: Text(strings.bluetoothOnly, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              bluetoothConnected
                  ? 'Wireless audio connected — announcements will play'
                  : strings.bluetoothOnlyDesc,
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
            title: Text(strings.speakerOutput, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              strings.speakerOutputDesc,
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
    required AppStrings strings,
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
            title: Text(strings.silenceInSilent, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              strings.silenceInSilentDesc,
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
            title: Text(strings.silenceInDnd, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              strings.silenceInDndDesc,
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
    required AppStrings strings,
    required String currentAppLang,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        children: [
          // 1. App UI Display Language
          InkWell(
            onTap: () => _showAppLanguageSheet(context, ref, currentAppLang),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.translate_rounded, color: Colors.teal),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.appLanguage, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${_languageNames[currentAppLang] ?? currentAppLang} • ${strings.appLanguageDesc}',
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _languageNames[currentAppLang]?.split('(').first.trim() ?? currentAppLang,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 64),

          // 2. Announcement Voice Language (Caller TTS)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.record_voice_over_rounded, color: Colors.purple),
            ),
            title: Text(strings.announcementVoiceLanguage, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${_languageNames[settings.language] ?? settings.language} • ${strings.announcementVoiceDesc}',
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
                        Text(strings.speechRate, style: const TextStyle(fontWeight: FontWeight.w700)),
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
    required AppStrings strings,
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
                  label: Text(strings.navContacts, style: const TextStyle(fontSize: 12)),
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
                  label: Text(strings.navRules, style: const TextStyle(fontSize: 12)),
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
                  label: Text(strings.navSmartAi, style: const TextStyle(fontSize: 12)),
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

  // 8. App Appearance & Theme Card
  Widget _buildThemeModeCard({
    required ThemeMode themeMode,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  themeMode == ThemeMode.system
                      ? Icons.brightness_auto_rounded
                      : (themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                  color: Colors.indigo,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(
                      switch (themeMode) {
                        ThemeMode.system => 'System Default (Matches phone settings)',
                        ThemeMode.light => 'Light Mode (Always bright)',
                        ThemeMode.dark => 'Dark Mode (Always dark)',
                      },
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildThemeOptionPill(
                title: 'System',
                subtitle: 'Default',
                icon: Icons.brightness_auto_rounded,
                isSelected: themeMode == ThemeMode.system,
                onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _buildThemeOptionPill(
                title: 'Light',
                subtitle: 'Day',
                icon: Icons.light_mode_rounded,
                isSelected: themeMode == ThemeMode.light,
                onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _buildThemeOptionPill(
                title: 'Dark',
                subtitle: 'Night',
                icon: Icons.dark_mode_rounded,
                isSelected: themeMode == ThemeMode.dark,
                onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionPill({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? colorScheme.primary.withAlpha(200) : colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppLanguageSheet(BuildContext context, WidgetRef ref, String currentLang) {
    final sheetTheme = Theme.of(context);
    final sheetColorScheme = sheetTheme.colorScheme;
    final strings = ref.read(appStringsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: sheetTheme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetTheme.dividerColor.withAlpha(120),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sheetColorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.translate_rounded, color: sheetColorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.selectAppLanguage,
                            style: sheetTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            strings.appLanguageDesc,
                            style: TextStyle(fontSize: 12, color: sheetTheme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: _languageNames.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = _languageNames.entries.elementAt(index);
                      final code = entry.key;
                      final name = entry.value;
                      final isSelected = code == currentLang;

                      return InkWell(
                        onTap: () {
                          ref.read(appLanguageProvider.notifier).setLanguage(code);
                          Navigator.pop(sheetCtx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? sheetColorScheme.primaryContainer.withAlpha(120)
                                : sheetColorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? sheetColorScheme.primary
                                  : sheetColorScheme.outlineVariant.withAlpha(40),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? sheetColorScheme.primary
                                      : sheetColorScheme.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  code.split('-').first.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? sheetColorScheme.onPrimary
                                        : sheetColorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected
                                            ? sheetColorScheme.primary
                                            : sheetColorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      code,
                                      style: TextStyle(fontSize: 12, color: sheetTheme.hintColor),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: sheetColorScheme.primary, size: 22)
                              else
                                Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: sheetTheme.hintColor.withAlpha(100),
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeModeSheet(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final sheetTheme = Theme.of(sheetCtx);
        final sheetColorScheme = sheetTheme.colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: sheetTheme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetTheme.dividerColor.withAlpha(120),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sheetColorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.palette_rounded, color: sheetColorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose App Theme',
                          style: sheetTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          'Select your preferred display appearance',
                          style: TextStyle(fontSize: 12, color: sheetTheme.hintColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildThemeSheetTile(
                  context: sheetCtx,
                  ref: ref,
                  mode: ThemeMode.system,
                  currentMode: currentMode,
                  title: 'System Default (सिस्टम डिफ़ॉल्ट)',
                  subtitle: 'Automatically adapts to device dark/light theme',
                  icon: Icons.brightness_auto_rounded,
                  isDefault: true,
                ),
                const SizedBox(height: 8),
                _buildThemeSheetTile(
                  context: sheetCtx,
                  ref: ref,
                  mode: ThemeMode.light,
                  currentMode: currentMode,
                  title: 'Light Mode (लाइट मोड)',
                  subtitle: 'Bright, high-contrast look for day use',
                  icon: Icons.light_mode_rounded,
                ),
                const SizedBox(height: 8),
                _buildThemeSheetTile(
                  context: sheetCtx,
                  ref: ref,
                  mode: ThemeMode.dark,
                  currentMode: currentMode,
                  title: 'Dark Mode (डार्क मोड)',
                  subtitle: 'Dim, eye-friendly look that saves battery',
                  icon: Icons.dark_mode_rounded,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeSheetTile({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isDefault = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = mode == currentMode;

    return InkWell(
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withAlpha(120)
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withAlpha(40),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 22)
            else
              Icon(Icons.radio_button_unchecked_rounded, color: theme.hintColor.withAlpha(100), size: 22),
          ],
        ),
      ),
    );
  }
}
