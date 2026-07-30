import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/providers/app_providers.dart';
import 'package:mobile/services/mdns_service.dart';

class QrConnectionScreen extends ConsumerStatefulWidget {
  const QrConnectionScreen({super.key});

  @override
  ConsumerState<QrConnectionScreen> createState() => _QrConnectionScreenState();
}

class _QrConnectionScreenState extends ConsumerState<QrConnectionScreen> {
  bool _isProcessing = false;
  String _statusMessage = "Searching for Gateway on Local Network...";
  final MdnsService _mdnsService = MdnsService();

  @override
  void initState() {
    super.initState();
    _mdnsService.onGatewayFound = _onGatewayFound;
    _mdnsService.start();
  }

  @override
  void dispose() {
    _mdnsService.stop();
    super.dispose();
  }

  void _onGatewayFound(String server, String deviceName, String pairingToken) async {
    if (_isProcessing) return;
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _statusMessage = "Pairing with $deviceName...";
      });
    }
    await _pairWithGateway(server, deviceName, pairingToken);
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcodeValue = barcodes.first.rawValue;
    if (barcodeValue == null) return;
    
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _statusMessage = "Pairing via QR Code...";
      });
    }

    try {
      final data = jsonDecode(barcodeValue);
      final server = data['server'];
      final deviceName = data['device_name'];
      final pairingToken = data['pairing_token'];

      if (server != null && deviceName != null && pairingToken != null) {
        await _pairWithGateway(server, deviceName, pairingToken);
      } else {
        throw Exception('Invalid QR code format.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() {
          _isProcessing = false;
          _statusMessage = "Searching for Gateway on Local Network...";
        });
      }
    }
  }

  Future<void> _pairWithGateway(String server, String deviceName, String pairingToken) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final storageService = ref.read(storageServiceProvider);
      
      if (apiService != null && storageService != null) {
        final deviceId = await apiService.pairDevice(server, deviceName, pairingToken);
        
        if (deviceId != null) {
          await storageService.saveServerUrl(server);
          await storageService.saveDeviceToken(deviceId); 
          ref.read(connectionStateProvider.notifier).setConnected(true);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Successfully paired!')),
            );
            Navigator.of(context).pushReplacementNamed('/chat');
          }
          return;
        } else {
          throw Exception('Pairing failed, invalid device ID returned.');
        }
      } else {
        throw Exception('API service is null!');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() {
          _isProcessing = false;
          _statusMessage = "Searching for Gateway on Local Network...";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            const Text(
              "Connect to your Local AI",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      onDetect: _onDetect,
                    ),
                    if (_isProcessing)
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            const Text(
              "Or scan the QR code displayed on your laptop.",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.laptop_mac,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 16),
                Text(
                  "↔",
                  style: TextStyle(
                    fontSize: 24,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 16),
                Icon(
                  Icons.phone_iphone,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
