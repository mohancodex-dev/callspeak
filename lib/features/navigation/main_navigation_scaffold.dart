import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../caller_announcement/presentation/home_screen.dart';
import '../contact_announce/presentation/screens/contact_list_screen.dart';
import '../contact_announce/presentation/screens/default_rules_screen.dart';
import '../contact_announce/presentation/screens/smart_features_screen.dart';

import '../caller_announcement/providers/permission_provider.dart';
import '../contact_announce/providers/contact_rule_provider.dart';

import '../../core/localization/app_localizations.dart';

class NavTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final mainNavTabProvider = NotifierProvider<NavTabNotifier, int>(NavTabNotifier.new);

class MainNavigationScaffold extends ConsumerStatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  ConsumerState<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends ConsumerState<MainNavigationScaffold> with WidgetsBindingObserver {
  final List<Widget> _screens = const [
    HomeScreen(),
    ContactListScreen(),
    DefaultRulesScreen(),
    SmartFeaturesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions when returning from native permission dialog or system settings
      ref.read(permissionStatusProvider.notifier).checkPermissions();
      ref.read(contactsPermissionProvider.notifier).checkPermission();

      final currentRules = ref.read(contactRulesProvider).value ?? [];
      if (currentRules.isEmpty) {
        ref.read(contactRulesProvider.notifier).refreshFromDevice();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainNavTabProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = ref.watch(appStringsProvider);
    final isRtl = ref.watch(isRtlLanguageProvider);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (idx) => ref.read(mainNavTabProvider.notifier).setTab(idx),
          elevation: 0,
          backgroundColor: colorScheme.surfaceContainerLow,
          indicatorColor: colorScheme.primaryContainer,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard_rounded),
              label: strings.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.contacts_outlined),
              selectedIcon: const Icon(Icons.contacts_rounded),
              label: strings.navContacts,
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune_outlined),
              selectedIcon: const Icon(Icons.tune_rounded),
              label: strings.navRules,
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome_outlined),
              selectedIcon: const Icon(Icons.auto_awesome_rounded),
              label: strings.navSmartAi,
            ),
          ],
        ),
      ),
    );
  }
}
