import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/service_entry.dart';
import '../../models/vehicle.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';

class TopBrandsCard extends StatefulWidget {
  const TopBrandsCard({
    super.key,
    required this.controller,
    required this.activeVehicle,
    required this.onQuickLogService,
  });

  final GarageController controller;
  final Vehicle activeVehicle;
  final VoidCallback onQuickLogService;

  @override
  State<TopBrandsCard> createState() => _TopBrandsCardState();
}

class _TopBrandsCardState extends State<TopBrandsCard> {
  bool _allGarageScope = false;

  static const _rankColors = [
    AppColors.racingOrange,
    AppColors.sky,
    AppColors.emerald,
    AppColors.amber,
    AppColors.textSecondary,
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final s = ctrl.strings;
    final hasMultipleVehicles = ctrl.vehicles.length > 1;
    final stats = ctrl.computeTopSparepartBrands(
      vehicleId: (_allGarageScope && hasMultipleVehicles)
          ? null
          : widget.activeVehicle.id,
      limit: 5,
    );

    final maxCount = stats.isNotEmpty ? stats.first.usageCount : 1;

    return Container(
      key: const Key('top_brands_dashboard_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.racingOrange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppColors.racingOrange,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.topBrandsTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      s.topBrandsSubtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasMultipleVehicles)
                InkWell(
                  key: const Key('top_brands_scope_toggle'),
                  onTap: () =>
                      setState(() => _allGarageScope = !_allGarageScope),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.sky.withOpacity(0.45),
                      ),
                    ),
                    child: Text(
                      _allGarageScope
                          ? s.scopeAllGarage
                          : s.scopeActiveVehicle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sky,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (stats.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    s.noBrandDataYet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: widget.onQuickLogService,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(s.quickServiceCta),
                  ),
                ],
              ),
            )
          else
            ...List.generate(stats.length, (index) {
              final stat = stats[index];
              final color = _rankColors[index % _rankColors.length];
              final barFraction = (stat.usageCount / maxCount).clamp(0.12, 1.0);
              final pct = (stat.share * 100).round();

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == stats.length - 1 ? 0 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  stat.brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (index == 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.racingOrange
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    s.topBrandBadge,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.racingOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '${stat.usageCount}${s.brandUsedSuffix} ($pct%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: barFraction,
                        minHeight: 7,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _categoryLabel(stat.topCategory, s),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          s.formatCurrency(
                            stat.totalSpend,
                            allowDecimalsForUsd: false,
                          ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _categoryLabel(ServiceCategory cat, AppStrings s) {
    switch (cat) {
      case ServiceCategory.oil:
        return s.catOil;
      case ServiceCategory.routine:
        return s.catRoutine;
      case ServiceCategory.brakesTires:
        return s.catBrakesTires;
      case ServiceCategory.other:
        return s.catOther;
    }
  }
}
