import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../caller_announcement/presentation/home_screen.dart';
import '../contact_announce/presentation/screens/contact_list_screen.dart';
import '../contact_announce/presentation/screens/default_rules_screen.dart';
import '../contact_announce/presentation/screens/smart_features_screen.dart';

class NavTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final mainNavTabProvider = NotifierProvider<NavTabNotifier, int>(NavTabNotifier.new);

class MainNavigationScaffold extends ConsumerWidget {
  const MainNavigationScaffold({super.key});

  final List<Widget> _screens = const [
    HomeScreen(),
    ContactListScreen(),
    DefaultRulesScreen(),
    SmartFeaturesScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavTabProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts_rounded),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Rules',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Smart AI',
          ),
        ],
      ),
    );
  }
}
