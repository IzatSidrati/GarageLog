import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'iap_service_types.dart';

class IapService {
  const IapService._();

  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static Future<void> Function()? _onProUnlocked;

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  static Future<void> initialize({
    required Future<void> Function() onProUnlocked,
  }) async {
    _onProUnlocked = onProUnlocked;
    if (!_isMobile) return;
    if (_subscription != null) return;

    try {
      final iap = InAppPurchase.instance;
      final available = await iap.isAvailable();
      if (!available) return;

      _subscription = iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (_) {},
      );
    } catch (_) {
      // Offline or store unavailable: fail gracefully.
    }
  }

  static Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    final iap = InAppPurchase.instance;
    for (final purchase in purchases) {
      if (purchase.productID == IapConfig.proPassProductId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        await _onProUnlocked?.call();
      }
      if (purchase.pendingCompletePurchase) {
        try {
          await iap.completePurchase(purchase);
        } catch (_) {}
      }
    }
  }

  static Future<IapActionResult> buyProPass() async {
    if (!_isMobile) {
      return const IapActionResult(status: IapActionStatus.unavailable);
    }
    try {
      final iap = InAppPurchase.instance;
      final available = await iap.isAvailable();
      if (!available) {
        return const IapActionResult(status: IapActionStatus.unavailable);
      }

      final response = await iap.queryProductDetails({
        IapConfig.proPassProductId,
      });

      if (response.productDetails.isEmpty) {
        return const IapActionResult(
          status: IapActionStatus.productNotConfigured,
        );
      }

      final product = response.productDetails.first;
      final param = PurchaseParam(productDetails: product);
      final launched = await iap.buyNonConsumable(purchaseParam: param);
      return IapActionResult(
        status: launched ? IapActionStatus.launched : IapActionStatus.failed,
      );
    } catch (e) {
      return IapActionResult(
        status: IapActionStatus.failed,
        detail: e.toString(),
      );
    }
  }

  static Future<IapActionResult> restorePurchases() async {
    if (!_isMobile) {
      return const IapActionResult(status: IapActionStatus.unavailable);
    }
    try {
      final iap = InAppPurchase.instance;
      final available = await iap.isAvailable();
      if (!available) {
        return const IapActionResult(status: IapActionStatus.unavailable);
      }
      await iap.restorePurchases();
      return const IapActionResult(status: IapActionStatus.restoredRequested);
    } catch (e) {
      return IapActionResult(
        status: IapActionStatus.failed,
        detail: e.toString(),
      );
    }
  }
}
