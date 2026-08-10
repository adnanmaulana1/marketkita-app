import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/pembeli/home_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_radius.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const MarketKitaApp());
  // Set refresh rate setelah frame pertama: saat itu window sudah menempel ke
  // display, sehingga request 120Hz lebih besar kemungkinannya diterima vendor.
  WidgetsBinding.instance.addPostFrameCallback((_) => _setHighRefreshRate());
}

/// Pilih mode tampilan dengan refresh rate tertinggi yang didukung perangkat
/// (mis. 120Hz), sehingga UI tidak ter-kunci di 60Hz. Aman: bila vendor
/// menolak, aplikasi tetap berjalan dengan mode default.
Future<void> _setHighRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
    final active = await FlutterDisplayMode.active;
    debugPrint('[refresh] active=${active.refreshRate}Hz '
        '(max=${(await FlutterDisplayMode.supported).map((m) => m.refreshRate).reduce((a, b) => a > b ? a : b)}Hz)');
  } catch (e) {
    // Vendor menolak → pakai mode default. Log untuk diagnosa.
    debugPrint('[refresh] setHighRefreshRate gagal: $e');
  }
}

class MarketKitaApp extends StatelessWidget {
  const MarketKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'MarketKita',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.1),
            ),
            child: child!,
          );
        },
        theme: _buildTheme(),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

ThemeData _buildTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.accent,
    onSecondary: AppColors.onAccent,
    error: AppColors.danger,
    surface: AppColors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.neutral100,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white,
      elevation: 0,
      height: 64,
      indicatorColor: AppColors.primary.withValues(alpha: 0.08),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.neutral600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primary : AppColors.neutral600,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.neutral900,
      contentTextStyle: const TextStyle(color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.neutral100,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(fontSize: 12, color: AppColors.neutral900),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.neutral200, thickness: 1, space: 1),
  );
}
