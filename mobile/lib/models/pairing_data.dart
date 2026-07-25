class PairingData {
  final String server;
  final String deviceName;
  final String pairingToken;

  PairingData({
    required this.server,
    required this.deviceName,
    required this.pairingToken,
  });

  factory PairingData.fromJson(Map<String, dynamic> json) {
    return PairingData(
      server: json['server'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      pairingToken: json['pairing_token'] as String? ?? '',
    );
  }
}
