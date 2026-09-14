import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../caller_announcement/providers/permission_provider.dart';
import '../../caller_announcement/presentation/widgets/background_reliability_dialog.dart';
import '../../navigation/main_navigation_scaffold.dart';
import '../../../services/native_bridge_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isPlayingVoice = false;
  final NativeBridgeService _bridge = NativeBridgeService();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _testSampleVoice() async {
    HapticFeedback.lightImpact();
    setState(() => _isPlayingVoice = true);

    try {
      await _bridge.testAnnouncement();
    } catch (_) {}

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isPlayingVoice = false);
    });
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScaffold()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final permissionsGranted = ref.watch(permissionStatusProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Brand & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.record_voice_over_rounded, color: colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'CallSpeak',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: -0.2),
                      ),
                    ],
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            // Carousel Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // Slide 1: Welcome & Live Voice Demo
                  _buildSlide(
                    context: context,
                    icon: Icons.campaign_rounded,
                    iconColor: Colors.blueAccent,
                    title: 'Know Who is Calling',
                    subtitle:
                        'CallSpeak announces incoming caller names aloud in crystal-clear voice, even when your phone is across the room or in your pocket.',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPlayingVoice ? Icons.volume_up_rounded : Icons.hearing_rounded,
                                color: Colors.blueAccent,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isPlayingVoice ? 'Speaking Now...' : 'Experience It Live',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"Incoming call from Rahul"',
                            style: TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _testSampleVoice,
                            icon: Icon(_isPlayingVoice ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded),
                            label: Text(_isPlayingVoice ? 'Playing Sample...' : 'Hear Sample Announcement'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _isPlayingVoice ? Colors.red.shade700 : null,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Slide 2: Safe, On-Device & Permissions
                  _buildSlide(
                    context: context,
                    icon: Icons.verified_user_rounded,
                    iconColor: Colors.teal,
                    title: '100% Private & On-Device',
                    subtitle:
                        'Your contacts and incoming call info are processed strictly on your phone. Nothing is ever uploaded to any server.',
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
                      ),
                      child: Column(
                        children: [
                          _buildPermissionRow(
                            icon: Icons.phone_in_talk_rounded,
                            title: 'Phone Calls',
                            subtitle: 'Detect incoming calls in real-time',
                            isGranted: permissionsGranted,
                          ),
                          const Divider(height: 16, indent: 44),
                          _buildPermissionRow(
                            icon: Icons.contacts_rounded,
                            title: 'Contacts List',
                            subtitle: 'Identify names for incoming numbers',
                            isGranted: permissionsGranted,
                          ),
                          const Divider(height: 16, indent: 44),
                          _buildPermissionRow(
                            icon: Icons.notifications_active_rounded,
                            title: 'Foreground Service',
                            subtitle: 'Keep announcer active in background',
                            isGranted: permissionsGranted,
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              await ref.read(permissionStatusProvider.notifier).requestPermissions();
                            },
                            icon: Icon(permissionsGranted ? Icons.check_circle_rounded : Icons.lock_open_rounded),
                            label: Text(permissionsGranted ? 'Permissions Granted' : 'Grant Permissions'),
                            style: FilledButton.styleFrom(
                              backgroundColor: permissionsGranted ? Colors.teal : null,
                              foregroundColor: permissionsGranted ? Colors.white : null,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Slide 3: Background Reliability & Finish
                  _buildSlide(
                    context: context,
                    icon: Icons.bolt_rounded,
                    iconColor: Colors.orange,
                    title: 'Reliable in Background',
                    subtitle:
                        'Android battery savers can put background apps to sleep. Exempt CallSpeak from battery restrictions so it never misses a call.',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.battery_alert_rounded, color: Colors.orange, size: 24),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Battery Optimization',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      'Allow background activity without restrictions',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: () async {
                              HapticFeedback.selectionClick();
                              final strings = ref.read(appStringsProvider);
                              final allow = await BackgroundReliabilityDialog.show(context, strings);
                              if (allow == true) {
                                await _bridge.requestIgnoreBatteryOptimizations();
                              }
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Disable Battery Restriction'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Dots & Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(3, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? colorScheme.primary : colorScheme.outlineVariant.withAlpha(80),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Button
                  FilledButton(
                    onPressed: () {
                      if (_currentPage < 2) {
                        HapticFeedback.lightImpact();
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'Get Started' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            ],
          ),
        ),
        Icon(
          isGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isGranted ? Colors.green : Colors.grey,
          size: 20,
        ),
      ],
    );
  }
}
