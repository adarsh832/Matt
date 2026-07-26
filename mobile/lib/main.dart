import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/screens/splash/splash_screen.dart';
import 'package:mobile/screens/personality/personality_screen.dart';
import 'package:mobile/screens/qr_connection/qr_connection_screen.dart';
import 'package:mobile/screens/chat/chat_screen.dart';
import 'package:mobile/screens/settings/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: MattApp()));
}

class MattApp extends ConsumerWidget {
  const MattApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Storage service is available, but connection state 
    // will be checked in the SplashScreen

    return MaterialApp(
      title: 'Matt - Local AI',
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
