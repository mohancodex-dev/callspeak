import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/navigation/main_navigation_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SmartCallAnnounceApp()));
}

class SmartCallAnnounceApp extends StatelessWidget {
  const SmartCallAnnounceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Google Material 3 Expressive Pixel Blue / Indigo palette
    const primarySeed = Color(0xFF0B57D0);

    return MaterialApp(
      title: 'Smart Call Announce',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primarySeed,
          brightness: Brightness.light,
          surface: const Color(0xFFF8F9FC),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF2F4F8),
          surfaceContainer: const Color(0xFFEBEEF3),
          surfaceContainerHigh: const Color(0xFFE3E8EF),
          surfaceContainerHighest: const Color(0xFFDDE3EB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: Color(0xFFF8F9FC),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B1B1F),
            letterSpacing: -0.2,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        chipTheme: ChipThemeData(
          shape: const StadiumBorder(),
          side: BorderSide.none,
          backgroundColor: const Color(0xFFEBEEF3),
          selectedColor: const Color(0xFFD3E3FD),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: const Color(0xFFF1F4F9),
          indicatorColor: const Color(0xFFD3E3FD),
          indicatorShape: const StadiumBorder(),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF041E49));
            }
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF44474E));
          }),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 2,
          highlightElevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: const Color(0xFFD3E3FD),
          foregroundColor: const Color(0xFF041E49),
        ),
        switchTheme: SwitchThemeData(
          thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Icon(Icons.check, size: 16, color: Color(0xFF041E49));
            }
            return const Icon(Icons.close, size: 14, color: Color(0xFF74777F));
          }),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primarySeed,
          brightness: Brightness.dark,
          surface: const Color(0xFF111318),
          surfaceContainerLowest: const Color(0xFF0C0E12),
          surfaceContainerLow: const Color(0xFF181B20),
          surfaceContainer: const Color(0xFF1D2026),
          surfaceContainerHigh: const Color(0xFF262A30),
          surfaceContainerHighest: const Color(0xFF31353C),
        ),
        scaffoldBackgroundColor: const Color(0xFF111318),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: Color(0xFF111318),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE2E2E6),
            letterSpacing: -0.2,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: const Color(0xFF1D2026),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        chipTheme: ChipThemeData(
          shape: const StadiumBorder(),
          side: BorderSide.none,
          backgroundColor: const Color(0xFF262A30),
          selectedColor: const Color(0xFF004A77),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: const Color(0xFF181B20),
          indicatorColor: const Color(0xFF004A77),
          indicatorShape: const StadiumBorder(),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD3E3FD));
            }
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8E9199));
          }),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 2,
          highlightElevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: const Color(0xFF004A77),
          foregroundColor: const Color(0xFFD3E3FD),
        ),
        switchTheme: SwitchThemeData(
          thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Icon(Icons.check, size: 16, color: Color(0xFF003258));
            }
            return const Icon(Icons.close, size: 14, color: Color(0xFF8E9199));
          }),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainNavigationScaffold(),
    );
  }
}
