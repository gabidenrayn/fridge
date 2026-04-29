import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_colors.dart';
import 'providers/product_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/scanner/scanner_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/account_screen.dart';
import 'widgets/bottom_nav_bar.dart';

class SmartFridgeApp extends StatelessWidget {
  const SmartFridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const _AppContent(),
        );
      },
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'SmartFridge',
      debugShowCheckedModeBanner: false,

      // ── Светлая тема ──────────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.lightAccent,
          primaryContainer: Color(0xFFDCEAFF),
          secondary: Color(0xFF0EA5E9),
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          onPrimary: Colors.white,
          error: AppColors.lightExpired,
          outline: AppColors.lightBorder,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightCardBg,
          shadowColor: Colors.black12,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.lightBorder, width: 0.8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.lightAccent, width: 2),
          ),
          hintStyle: const TextStyle(color: AppColors.lightTextMuted),
          labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
        ),
        dividerColor: AppColors.lightBorder,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.lightAccent
                  : Colors.grey),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.lightAccent.withOpacity(0.35)
                  : Colors.grey.withOpacity(0.25)),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18),
          titleMedium: TextStyle(
              color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
          bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.lightSurface),
          ),
        ),
      ),

      // ── Тёмная тема ──────────────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          shadowColor: Colors.black45,
          elevation: 2,
        ),
        dividerColor: AppColors.border,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.accent
                  : AppColors.textMuted),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.accent.withOpacity(0.35)
                  : AppColors.border),
        ),
      ),

      themeMode: themeProvider.themeMode,
      home: const _AuthWrapper(),
      routes: {'/register': (context) => const RegisterScreen()},
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      final productProvider = context.read<ProductProvider>();
      productProvider.setAuthProvider(authProvider);
      return const _RootNavigator();
    } else {
      return const LoginScreen();
    }
  }
}

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    ScannerScreen(),
    SearchScreen(),
    StatsScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
