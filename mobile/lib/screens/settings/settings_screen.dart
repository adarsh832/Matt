import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/settings_row.dart';
import 'package:mobile/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<String?>(
        future: ref.read(storageServiceProvider)?.getServerUrl(),
        builder: (context, snapshot) {
          final serverUrl = snapshot.data ?? 'Not connected';
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              const Text(
                'Connection',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SettingsRow(
                      icon: Icons.qr_code_scanner,
                      title: 'QR Connection',
                      subtitle: serverUrl,
                      onTap: () {
                        Navigator.pushNamed(context, '/qr_connection');
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    SettingsRow(
                      icon: Icons.face,
                      title: 'AI Personality',
                      subtitle: 'Change how Matt acts',
                      onTap: () {
                        Navigator.pushNamed(context, '/personality');
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    SettingsRow(
                      icon: Icons.link_off,
                      title: 'Disconnect',
                      subtitle: 'Remove pairing from this device',
                      isDestructive: true,
                      onTap: () async {
                        await ref.read(storageServiceProvider)?.clearAll();
                        ref.read(connectionStateProvider.notifier).setConnected(false);
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/personality',
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'App',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SettingsRow(
                      icon: Icons.code,
                      title: 'GitHub',
                      subtitle: 'View source code',
                      onTap: () async {
                        final uri = Uri.parse('https://github.com/adarsh832/Matt.git');
                        try {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          debugPrint('Could not launch $uri: $e');
                        }
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    SettingsRow(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Matt AI',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(Icons.smart_toy, size: 48, color: AppColors.primary),
                          children: [
                            const Text(
                              'Matt is a personal AI assistant built with Flutter and Python. '
                              'It securely pairs with a local backend to provide private, fast AI completions '
                              'using LM Studio running on your own hardware.'
                            ),
                          ],
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    SettingsRow(
                      icon: Icons.new_releases_outlined,
                      title: 'Version',
                      subtitle: '1.0.0',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
