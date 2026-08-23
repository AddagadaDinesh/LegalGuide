import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'services/backend_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackendConfigService.init();
  await AuthService.init();
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF6366F1),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}
