import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/screens/splash/splash_screen.dart';
import 'package:mobile/screens/personality/personality_screen.dart';
import 'package:mobile/screens/qr_connection/qr_connection_screen.dart';
import 'package:mobile/screens/chat/chat_screen.dart';
import 'package:mobile/screens/settings/settings_screen.dart';
import 'package:mobile/providers/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: MaatApp()));
}

class MaatApp extends ConsumerWidget {
  const MaatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the storage service to initialize connection state
    final storage = ref.watch(storageServiceProvider);
    
    if (storage != null) {
      // Async initialization of connection state based on saved token
      storage.getDeviceToken().then((token) {
        if (token != null && token.isNotEmpty) {
          ref.read(connectionStateProvider.notifier).setConnected(true);
        }
      });
    }

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
