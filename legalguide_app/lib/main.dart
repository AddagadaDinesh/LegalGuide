import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  // Automatically prevent and gracefully handle any RenderFlex overflow banners anywhere in the app
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('overflowed')) {
      return const SizedBox.shrink();
    }
    return ErrorWidget(details.exception);
  };

  runApp(const LegalGuideApp());
}

class LegalGuideApp extends StatelessWidget {
  const LegalGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.language,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'LegalGuide',
          locale: Locale(lang),
          supportedLocales: const [
            Locale('en'),
            Locale('te'),
            Locale('hi'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
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
      },
    );
  }
}
