import 'iap_service_types.dart';

class IapService {
  const IapService._();

  static Future<void> initialize({
    required Future<void> Function() onProUnlocked,
  }) async {}

  static Future<IapActionResult> buyProPass() async {
    return const IapActionResult(status: IapActionStatus.unavailable);
  }

  static Future<IapActionResult> restorePurchases() async {
    return const IapActionResult(status: IapActionStatus.unavailable);
  }
}
