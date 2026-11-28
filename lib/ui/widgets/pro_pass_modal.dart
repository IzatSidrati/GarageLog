import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/iap_service.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';

Future<bool> showProPassModal({
  required BuildContext context,
  required GarageController controller,
  bool triggeredByLimit = false,
  String? customLimitNote,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ProPassSheet(
      controller: controller,
      triggeredByLimit: triggeredByLimit,
      customLimitNote: customLimitNote,
    ),
  );
  return result ?? false;
}

class _ProPassSheet extends StatefulWidget {
  const _ProPassSheet({
    required this.controller,
    required this.triggeredByLimit,
    this.customLimitNote,
  });

  final GarageController controller;
  final bool triggeredByLimit;
  final String? customLimitNote;

  @override
  State<_ProPassSheet> createState() => _ProPassSheetState();
}

class _ProPassSheetState extends State<_ProPassSheet> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final isPro = widget.controller.isProUnlocked;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.racingOrange.withOpacity(0.18),
                  AppColors.racingRed.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.racingOrange.withOpacity(0.45),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.racingGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.proModalTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.proModalSubtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.triggeredByLimit && !isPro) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.customLimitNote ?? s.proLimitNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _benefitRow(Icons.garage_rounded, s.proFeature1),
          const SizedBox(height: 10),
          _benefitRow(Icons.inventory_2_outlined, s.proFeature2),
          const SizedBox(height: 10),
          _benefitRow(Icons.block_rounded, s.proFeature3),
          const SizedBox(height: 18),
          if (!isPro) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('pro_buy_button'),
                onPressed: _isBusy ? null : _handleBuyPro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.racingOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('${s.proBuyCta} • ${s.proPrice}'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                key: const Key('pro_restore_button'),
                onPressed: _isBusy ? null : _handleRestorePurchase,
                icon: const Icon(Icons.restore_rounded, size: 17),
                label: Text(s.restorePurchaseCta),
              ),
            ),
          ],
          // Dev simulation button is strictly hidden in Release builds!
          if (kDebugMode) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('dev_pro_toggle_button'),
                onPressed: () async {
                  final next = !isPro;
                  await widget.controller.setProUnlocked(next);
                  if (context.mounted) {
                    Navigator.of(context).pop(next);
                  }
                },
                icon: Icon(
                  isPro
                      ? Icons.restart_alt_rounded
                      : Icons.developer_mode_rounded,
                  size: 18,
                  color: AppColors.sky,
                ),
                label: Text(
                  isPro ? s.proDevDeactivate : s.proDevActivate,
                  style: const TextStyle(color: AppColors.sky),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleBuyPro() async {
    final s = widget.controller.strings;
    setState(() => _isBusy = true);
    final res = await IapService.buyProPass();
    if (!mounted) return;
    setState(() => _isBusy = false);

    switch (res.status) {
      case IapActionStatus.launched:
        return;
      case IapActionStatus.productNotConfigured:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.proProductPending)),
        );
        return;
      case IapActionStatus.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.proStoreUnavailable)),
        );
        return;
      case IapActionStatus.failed:
      case IapActionStatus.restoredRequested:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.proStoreHint)),
        );
        return;
    }
  }

  Future<void> _handleRestorePurchase() async {
    final s = widget.controller.strings;
    setState(() => _isBusy = true);
    final res = await IapService.restorePurchases();
    if (!mounted) return;
    setState(() => _isBusy = false);

    final msg = res.status == IapActionStatus.restoredRequested
        ? s.restorePurchaseChecked
        : s.proStoreUnavailable;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _benefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.emerald),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
