import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/backend_config_service.dart';
import 'services/locale_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackendConfigService.init();
  await AuthService.init();
  await LocaleService.init();
  unawaited(BackendConfigService.refreshFromPointer());
  runApp(const LegalGuideApp());
}

class LegalGuideApp extends StatelessWidget {
  const LegalGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LegalGuide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        primaryColor: AppColors.accent,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
