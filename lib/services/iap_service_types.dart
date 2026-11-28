class IapConfig {
  const IapConfig._();

  /// Must match the One-Time Product ID created in Google Play Console & App Store Connect.
  static const String proPassProductId = 'garagelog_pro_pass';
}

enum IapActionStatus {
  launched,
  unavailable,
  productNotConfigured,
  restoredRequested,
  failed,
}

class IapActionResult {
  const IapActionResult({
    required this.status,
    this.detail,
  });

  final IapActionStatus status;
  final String? detail;
}
