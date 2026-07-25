import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/screens/splash/splash_screen.dart';
import 'package:mobile/screens/personality/personality_screen.dart';
import 'package:mobile/screens/qr_connection/qr_connection_screen.dart';
import 'package:mobile/screens/chat/chat_screen.dart';
import 'package:mobile/screens/settings/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set status bar style to match the light background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const MaatApp());
}

/// Root application widget for the Maat Local AI app.
class MaatApp extends StatelessWidget {
  const MaatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maat - Local AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/personality': (context) => const PersonalityScreen(),
        '/qr_connection': (context) => const QrConnectionScreen(),
        '/chat': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
