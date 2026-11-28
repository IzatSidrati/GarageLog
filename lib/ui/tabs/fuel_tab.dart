import 'package:flutter/material.dart';

import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/fuel_trend_chart.dart';
import '../widgets/quick_fuel_sheet.dart';

class FuelTab extends StatelessWidget {
  const FuelTab({
    super.key,
    required this.controller,
  });

  final GarageController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    final vehicle = controller.activeVehicle;

    if (vehicle == null) {
      return Center(
        child: Text(
          s.t('Tambahkan kendaraan di tab Garasi.', 'Add a vehicle in Garage tab.'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final analytics = controller.computeFuelAnalytics(vehicle.id);
    final entries = analytics.computedDescending;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // 3-Second Fuel Log Hero CTA
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.racingOrange.withOpacity(0.22),
                AppColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.racingOrange.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: AppColors.racingGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fuelQuickCardTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.t(
                        'Odometer, liter, biaya -> otomatis km/L',
                        'Odometer, liters, cost -> instant km/L',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                key: const Key('fuel_tab_add_btn'),
                onPressed: () async {
                  final saved = await showQuickFuelSheet(
                    context: context,
                    controller: controller,
                    vehicle: vehicle,
                  );
                  if (saved && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.fuelSaved)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.racingOrange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: Text(s.t('+ Catat', '+ Log')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Metrics Strip
        Row(
          children: [
            Expanded(
              child: _FuelMetricTile(
                label: s.avgEfficiency,
                value: analytics.avgKmPerLiter != null
                    ? '${s.formatNumber(analytics.avgKmPerLiter!)} km/L'
                    : '--',
                valueColor: AppColors.emerald,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FuelMetricTile(
                label: s.costPerKm,
                value: analytics.avgCostPerKm != null
                    ? s.formatCurrency(analytics.avgCostPerKm!)
                    : '--',
                valueColor: AppColors.sky,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FuelMetricTile(
                label: s.totalFills,
                value: '${entries.length}x',
                valueColor: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FuelTrendChart(analytics: analytics, strings: s),
        const SizedBox(height: 18),
        Text(
          s.fuelHistory,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              s.firstFillHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...entries.map((computed) {
            final item = computed.entry;
            final avg = analytics.avgKmPerLiter;
            final kmL = computed.kmPerLiter;
            final Color effColor = (kmL != null && avg != null)
                ? (kmL >= avg ? AppColors.emerald : AppColors.amber)
                : AppColors.sky;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            item.fuelType,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sky,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.formatDate(item.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (kmL != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: effColor.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${s.formatNumber(kmL)} km/L',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: effColor,
                              ),
                            ),
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => controller.deleteFuelEntry(item.id),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${s.formatKm(item.odometerKm)} • ${s.formatNumber(item.liters, decimals: 2)} L',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          s.formatCurrency(item.totalCost),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (computed.costPerKm != null &&
                        computed.distanceKm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${s.formatKm(computed.distanceKm!)} • ${s.formatCurrency(computed.costPerKm!)}/km',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _FuelMetricTile extends StatelessWidget {
  const _FuelMetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
