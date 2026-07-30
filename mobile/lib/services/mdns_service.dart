import 'dart:async';
import 'package:nsd/nsd.dart';
import 'package:flutter/foundation.dart';

class MdnsService {
  Discovery? _discovery;
  
  // Callback when a Maat Gateway is found
  // Returns server url, device name, and pairing token
  Function(String server, String deviceName, String pairingToken)? onGatewayFound;

  /// Starts searching for the Maat Gateway on the local network
  Future<void> start() async {
    try {
      // _maat._tcp.local.
      _discovery = await startDiscovery('_maat._tcp', ipLookupType: IpLookupType.v4);
      
      _discovery?.addListener(() {
        for (final service in _discovery?.services ?? []) {
          _handleDiscoveredService(service);
        }
      });
      debugPrint("mDNS Discovery started for _maat._tcp");
    } catch (e) {
      debugPrint("Failed to start mDNS discovery: $e");
    }
  }

  void _handleDiscoveredService(Service service) {
    if (service.host == null || service.port == null) return;
    
    debugPrint("Found service: ${service.name} at ${service.host}:${service.port}");
    
    // Extract txt records
    final txt = service.txt ?? {};
    debugPrint("TXT records keys: ${txt.keys.join(', ')}");
    
    // Decode txt record bytes if necessary
    String deviceName = "Unknown Device";
    String pairingToken = "";
    
    if (txt.containsKey('device')) {
      deviceName = String.fromCharCodes(txt['device']!);
    }
    
    if (txt.containsKey('pairing_token')) {
      pairingToken = String.fromCharCodes(txt['pairing_token']!);
    }
    
    String host = service.host ?? '';
    if (txt.containsKey('ip')) {
      final ipStr = String.fromCharCodes(txt['ip']!);
      if (ipStr.isNotEmpty) {
        host = ipStr;
      }
    }
    
    if (host.endsWith('.')) {
      host = host.substring(0, host.length - 1);
    }
    
    // Prefer IP address if available, as Android HTTP clients can't resolve .local
    try {
      final addresses = (service as dynamic).addresses;
      if (addresses != null && addresses.isNotEmpty && !host.contains(RegExp(r'[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'))) {
        final addr = addresses.first;
        if (addr is String) {
          host = addr;
        } else {
          host = addr.address;
        }
      }
    } catch (_) {}
    
    final serverUrl = "http://$host:${service.port}";
    
    debugPrint("Resolved Gateway: $serverUrl ($deviceName) | Token: $pairingToken");
    
    if (pairingToken.isNotEmpty && onGatewayFound != null) {
      debugPrint("Triggering auto-pair...");
      onGatewayFound!(serverUrl, deviceName, pairingToken);
    } else if (pairingToken.isEmpty) {
      debugPrint("Pairing token is empty, cannot auto-pair!");
    }
  }

  /// Stops the mDNS discovery
  Future<void> stop() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
    }
    debugPrint("mDNS Discovery stopped");
  }
}
