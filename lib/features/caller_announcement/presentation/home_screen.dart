import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/announcement_languages.dart';
import '../../../core/localization/app_localizations.dart';
import '../../contact_announce/providers/contact_rule_provider.dart' hide nativeBridgeProvider;
import '../../navigation/main_navigation_scaffold.dart';
import '../models/call_settings.dart';
import '../providers/bluetooth_status_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/settings_provider.dart';

// Modular Widgets
import 'widgets/audio_delivery_card.dart';
import 'widgets/dashboard_section_header.dart';
import 'widgets/master_hero_card.dart';
import 'widgets/metric_grid.dart';
import 'widgets/background_reliability_dialog.dart';
import 'widgets/permission_dialog.dart';
import 'widgets/repeat_policy_card.dart';
import 'widgets/silence_protection_card.dart';
import 'widgets/voice_engine_card.dart';
import 'widgets/voice_simulator_card.dart';
import '../../smart_silent/presentation/widgets/smart_silent_home_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isPlayingPreview = false;

  static const Map<String, String> _languageNames = AnnouncementLanguages.languageNames;

  String _getSimulatedMessage(String language) {
    return AnnouncementLanguages.getContactAnnouncement(
      language: language,
      name: 'Rahul',
    );
  }

  void _simulateIncomingCall(CallSettings settings, [Object? _]) {
    _testLiveVoice(settings);
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
    final message = _getSimulatedMessage(settings.language);

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
        _ => 14,
      };

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${strings.playingPreview}: "$message"'),
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
    HapticFeedback.lightImpact();

    if (!enable) {
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

    if (!permissionsGranted) {
      final proceed = await PermissionRequiredDialog.show(context, strings);
      if (proceed != true) return;

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

    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(announcementEnabled: true),
        );
    final bridge = ref.read(nativeBridgeProvider);
    await bridge.startService();

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

    // Prominent disclosure for background reliability & battery saver exemption
    final isBatteryIgnored = await bridge.isBatteryOptimizationIgnored();
    if (!isBatteryIgnored && mounted) {
      final allowBattery = await BackgroundReliabilityDialog.show(context, strings);
      if (allowBattery == true) {
        await bridge.requestIgnoreBatteryOptimizations();
      }
    }
  }

  void _showAppLanguageSheet(BuildContext context, WidgetRef ref, String currentLang) {
    final sheetTheme = Theme.of(context);
    final strings = ref.read(appStringsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75),
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
                Text(
                  strings.selectAppLanguage,
                  style: sheetTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _languageNames.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final entry = _languageNames.entries.elementAt(index);
                      final isSelected = entry.key == currentLang;

                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        tileColor: isSelected ? sheetTheme.colorScheme.primaryContainer.withAlpha(80) : null,
                        title: Text(entry.value, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        trailing: isSelected ? Icon(Icons.check_circle_rounded, color: sheetTheme.colorScheme.primary) : null,
                        onTap: () {
                          ref.read(appLanguageProvider.notifier).setLanguage(entry.key);
                          Navigator.pop(sheetCtx);
                        },
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

  void _showAnnouncementVoiceLanguageSheet(BuildContext context, WidgetRef ref, String currentLang) {
    final sheetTheme = Theme.of(context);
    final strings = ref.read(appStringsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75),
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
                Text(
                  strings.announcementVoiceLanguage,
                  style: sheetTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _languageNames.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final entry = _languageNames.entries.elementAt(index);
                      final isSelected = entry.key == currentLang;

                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        tileColor: isSelected ? sheetTheme.colorScheme.primaryContainer.withAlpha(80) : null,
                        title: Text(entry.value, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        trailing: isSelected ? Icon(Icons.check_circle_rounded, color: sheetTheme.colorScheme.primary) : null,
                        onTap: () {
                          final currentSettings = ref.read(settingsProvider).value ?? const CallSettings();
                          ref.read(settingsProvider.notifier).updateSettings(currentSettings.copyWith(language: entry.key));
                          Navigator.pop(sheetCtx);
                        },
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

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value ?? const CallSettings();
    final permissionsGranted = ref.watch(permissionStatusProvider);
    final bluetoothConnected = ref.watch(bluetoothStatusProvider);
    final allRules = ref.watch(contactRulesProvider).value ?? [];
    final totalContacts = allRules.length;
    final vipCount = allRules.where((r) => r.isVip).length;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = ref.watch(appStringsProvider);
    final currentAppLang = ref.watch(appLanguageProvider);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveRepeat = settings.repeatMode == 'twice' ? 'three_times' : settings.repeatMode;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CallSpeak',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Smart Announcer Dashboard',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        actions: [
          // 1. Language Button (Translate 文A)
          _buildCircleActionButton(
            context: context,
            tooltip: 'Language Settings',
            icon: const Icon(Icons.translate_rounded, size: 20),
            onTap: () {
              HapticFeedback.lightImpact();
              _showQuickLanguageSheet(context, ref, currentAppLang, settings.language);
            },
          ),
          const SizedBox(width: 8),
          // 2. TTS & Voice Engine Button (Rosette Badge with 'A')
          _buildCircleActionButton(
            context: context,
            tooltip: 'TTS & Voice Engine',
            icon: _buildTtsBadgeIcon(colorScheme.onSurfaceVariant),
            onTap: () {
              HapticFeedback.lightImpact();
              _showQuickTtsEngineSheet(context, settings);
            },
          ),
          const SizedBox(width: 8),
          // 3. Audio / Sound Preview Button (Speaker)
          _buildCircleActionButton(
            context: context,
            tooltip: _isPlayingPreview ? strings.stopVoice : strings.testVoice,
            isActive: _isPlayingPreview,
            icon: Icon(
              _isPlayingPreview ? Icons.stop_rounded : Icons.volume_up_rounded,
              size: 20,
              color: _isPlayingPreview ? Colors.redAccent : colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _simulateIncomingCall(settings, strings);
            },
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // 1. Master Announcer Hero Card
          MasterHeroCard(
            settings: settings,
            permissionsGranted: permissionsGranted,
            bluetoothConnected: bluetoothConnected,
            effectiveRepeat: effectiveRepeat,
            isDark: isDark,
            strings: strings,
            onToggle: (val) => _handleToggleAnnouncement(val, settings, permissionsGranted),
            onFixPermissions: () async {
              final proceed = await PermissionRequiredDialog.show(context, strings);
              if (proceed == true) {
                await ref.read(permissionStatusProvider.notifier).requestPermissions();
              }
            },
          ),
          const SizedBox(height: 20),

          // 2. Metric Grid
          MetricGrid(
            totalContacts: totalContacts,
            vipCount: vipCount,
            permissionsGranted: permissionsGranted,
            colorScheme: colorScheme,
            strings: strings,
            onNavigateContacts: () => ref.read(mainNavTabProvider.notifier).setTab(1),
            onNavigateRules: () => ref.read(mainNavTabProvider.notifier).setTab(2),
            onNavigateSettings: () => ref.read(mainNavTabProvider.notifier).setTab(3),
            onFixPermissions: () async {
              final proceed = await PermissionRequiredDialog.show(context, strings);
              if (proceed == true) {
                await ref.read(permissionStatusProvider.notifier).requestPermissions();
              }
            },
          ),
          const SizedBox(height: 24),

          // 3. Silence & DND Protection
          DashboardSectionHeader(
            title: strings.sectionSilenceDnd,
            subtitle: strings.sectionSilenceDndDesc,
          ),
          const SizedBox(height: 10),
          SilenceProtectionCard(
            settings: settings,
            strings: strings,
            onToggleSilentMode: (val) {
              ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(silenceInSilentMode: val));
            },
            onToggleDndMode: (val) {
              ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(silenceInDndMode: val));
            },
          ),
          const SizedBox(height: 12),
          SmartSilentHomeCard(strings: strings),
          const SizedBox(height: 24),

          // 4. Audio Delivery Settings (Bluetooth / Speaker)
          DashboardSectionHeader(
            title: strings.sectionAudioDelivery,
            subtitle: strings.sectionAudioDeliveryDesc,
          ),
          const SizedBox(height: 10),
          AudioDeliveryCard(
            settings: settings,
            bluetoothConnected: bluetoothConnected,
            strings: strings,
            onToggleBluetoothOnly: (val) async {
              if (val) {
                final granted = await ref.read(bluetoothPermissionProvider.notifier).requestPermission();
                if (!granted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bluetooth permission needed to detect connected earphones.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
              ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(announceOnlyWithBluetooth: val));
            },
            onToggleSpeaker: (val) {
              ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(alsoAnnounceOnSpeaker: val));
            },
          ),
          const SizedBox(height: 24),

          // 5. Repeat Announcement Policy
          DashboardSectionHeader(
            title: strings.sectionRepeatMode,
            subtitle: strings.sectionRepeatModeDesc,
          ),
          const SizedBox(height: 10),
          RepeatPolicyCard(
            settings: settings,
            effectiveRepeat: effectiveRepeat,
            strings: strings,
            onSelectRepeatMode: (mode) {
              ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(repeatMode: mode));
            },
          ),
          const SizedBox(height: 24),

          // 6. Voice Engine & Speech Rate (Voice Speed)
          DashboardSectionHeader(
            title: strings.speechRate,
            subtitle: strings.announcementVoiceDesc,
          ),
          const SizedBox(height: 10),
          VoiceEngineCard(
            settings: settings,
            currentAppLang: currentAppLang,
            strings: strings,
            onSelectAppLanguage: () => _showAppLanguageSheet(context, ref, currentAppLang),
            onSelectAnnouncementLanguage: () => _showAnnouncementVoiceLanguageSheet(context, ref, settings.language),
            onSpeechRateChanged: (val) {
              ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(speechRate: val));
            },
          ),
          const SizedBox(height: 24),

          // 7. Voice Simulator Card (Test Voice Announce)
          DashboardSectionHeader(
            title: strings.simulateIncomingCall,
            subtitle: strings.sectionSimulatorDesc,
          ),
          const SizedBox(height: 10),
          VoiceSimulatorCard(
            settings: settings,
            isPlayingPreview: _isPlayingPreview,
            strings: strings,
            onTogglePlay: () => _testLiveVoice(settings),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required BuildContext context,
    required Widget icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest.withAlpha(160),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTtsBadgeIcon(Color color) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _ScallopedBadgePainter(color: color),
        child: Center(
          child: Text(
            'A',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'sans-serif',
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    String currentAppLang,
    String currentVoiceLang,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    int selectedTab = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetCtx).size.height * 0.78),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withAlpha(120),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.translate_rounded, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Text(
                          'Language Settings',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          label: Text('App Display'),
                          icon: Icon(Icons.phone_android_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Caller Voice'),
                          icon: Icon(Icons.record_voice_over_rounded, size: 16),
                        ),
                      ],
                      selected: {selectedTab},
                      onSelectionChanged: (newVal) {
                        setModalState(() => selectedTab = newVal.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _languageNames.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final entry = _languageNames.entries.elementAt(index);
                          final isSelected = selectedTab == 0
                              ? entry.key == ref.watch(appLanguageProvider)
                              : entry.key == (ref.watch(settingsProvider).value?.language ?? 'en-US');

                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            tileColor: isSelected ? colorScheme.primaryContainer.withAlpha(90) : null,
                            title: Text(
                              entry.value,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? colorScheme.primary : null,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20)
                                : null,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              if (selectedTab == 0) {
                                ref.read(appLanguageProvider.notifier).setLanguage(entry.key);
                              } else {
                                final current = ref.read(settingsProvider).value ?? const CallSettings();
                                ref.read(settingsProvider.notifier).updateSettings(current.copyWith(language: entry.key));
                              }
                              setModalState(() {});
                            },
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
      },
    );
  }

  void _showQuickTtsEngineSheet(BuildContext context, CallSettings settings) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = ref.read(appStringsProvider);
    final bridge = ref.read(nativeBridgeProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                      color: theme.dividerColor.withAlpha(120),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildTtsBadgeIcon(colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'TTS & Voice Engine',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage system speech synthesizer, voice rate, and engine',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 18),

                // Tile 1: Open System TTS Settings
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings_voice_rounded, color: Colors.deepPurple, size: 22),
                    ),
                    title: Text(strings.openSystemTts, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(strings.openSystemTtsDesc, style: TextStyle(fontSize: 12, color: theme.hintColor)),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(sheetCtx);
                      bridge.openTtsSettings();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Section 2: Speech Rate
                Text(
                  strings.speechRate,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildRateChip(0.8, strings.speechRateSlow, settings.speechRate),
                    _buildRateChip(1.0, strings.speechRateNormal, settings.speechRate),
                    _buildRateChip(1.2, strings.speechRateFast, settings.speechRate),
                  ],
                ),
                const SizedBox(height: 20),

                // Button to Test Voice
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _simulateIncomingCall(settings, strings);
                    },
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(strings.simulateIncomingCall),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRateChip(double rate, String label, double currentRate) {
    final isSelected = (rate - currentRate).abs() < 0.1;
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text('$label (${rate}x)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          HapticFeedback.selectionClick();
          final current = ref.read(settingsProvider).value ?? const CallSettings();
          ref.read(settingsProvider.notifier).updateSettings(current.copyWith(speechRate: rate));
        }
      },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colorScheme.primary : null,
      ),
    );
  }
}

class _ScallopedBadgePainter extends CustomPainter {
  final Color color;
  const _ScallopedBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rOuter = size.width / 2;
    final rInner = rOuter - 2.5;
    final path = Path();
    const points = 12;

    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? rOuter : rInner;
      final angle = (i * math.pi) / points;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScallopedBadgePainter oldDelegate) => oldDelegate.color != color;
}
