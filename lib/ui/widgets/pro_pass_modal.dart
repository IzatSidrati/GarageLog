import 'package:flutter/material.dart';

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

class _ProPassSheet extends StatelessWidget {
  const _ProPassSheet({
    required this.controller,
    required this.triggeredByLimit,
    this.customLimitNote,
  });

  final GarageController controller;
  final bool triggeredByLimit;
  final String? customLimitNote;

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    final isPro = controller.isProUnlocked;

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
                  AppColors.amber.withOpacity(0.22),
                  AppColors.sky.withOpacity(0.14),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.amber.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.amber,
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
          if (triggeredByLimit && !isPro) ...[
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
                  const Icon(Icons.lock_outline_rounded,
                      color: AppColors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customLimitNote ?? s.proLimitNote,
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
          _benefitRow(Icons.description_outlined, s.proFeature2),
          const SizedBox(height: 10),
          _benefitRow(Icons.notifications_active_outlined, s.proFeature3),
          const SizedBox(height: 18),
          if (!isPro)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.proStoreHint)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: const Color(0xFF1F1300),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text('${s.proBuyCta} • ${s.proPrice}'),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('dev_pro_toggle_button'),
              onPressed: () async {
                final next = !isPro;
                await controller.setProUnlocked(next);
                if (context.mounted) {
                  Navigator.of(context).pop(next);
                }
              },
              icon: Icon(
                isPro ? Icons.restart_alt_rounded : Icons.developer_mode_rounded,
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
      ),
    );
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
