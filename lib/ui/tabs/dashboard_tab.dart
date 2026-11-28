import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/health_status.dart';
import '../../models/service_entry.dart';
import '../../models/vehicle.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/ad_native_widget.dart';
import '../widgets/add_service_sheet.dart';
import '../widgets/quick_fuel_sheet.dart';
import '../widgets/top_brands_card.dart';
import '../widgets/vehicle_form_sheet.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({
    super.key,
    required this.controller,
    required this.onNavigateToGarage,
  });

  final GarageController controller;
  final VoidCallback onNavigateToGarage;

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    final vehicle = controller.activeVehicle;

    if (vehicle == null) {
      return _EmptyGarageState(
        strings: s,
        onAddVehicle: () => showVehicleFormSheet(
          context: context,
          controller: controller,
        ),
      );
    }

    final healthItems = controller.computeHealthItems(vehicle);
    final fuelAnalytics = controller.computeFuelAnalytics(vehicle.id);
    final monthly = controller.computeMonthlySpend(vehicle.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _VehicleHeroCard(
          vehicle: vehicle,
          strings: s,
          onUpdateOdometer: () => _showUpdateOdometerDialog(context, vehicle),
          onEditVehicle: () => showVehicleFormSheet(
            context: context,
            controller: controller,
            editingVehicle: vehicle,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('dashboard_quick_fuel_btn'),
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
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.local_gas_station_rounded, size: 18),
                label: Text(
                  s.quickFuelCta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('dashboard_quick_service_btn'),
                onPressed: () async {
                  final saved = await showAddServiceSheet(
                    context: context,
                    controller: controller,
                    vehicle: vehicle,
                  );
                  if (saved && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.serviceSaved)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.build_rounded, size: 18),
                label: Text(
                  s.quickServiceCta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.speed_rounded,
                iconColor: AppColors.emerald,
                title: s.avgEfficiency,
                value: fuelAnalytics.avgKmPerLiter != null
                    ? '${s.formatNumber(fuelAnalytics.avgKmPerLiter!)} km/L'
                    : '-- km/L',
                subtitle: fuelAnalytics.avgCostPerKm != null
                    ? '${s.formatCurrency(fuelAnalytics.avgCostPerKm!)}/km'
                    : s.noFuelDataShort,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.sky,
                title: s.monthlySpend,
                value: s.formatCurrency(monthly.total, allowDecimalsForUsd: false),
                subtitle:
                    '${s.fuelSpendLabel}: ${s.formatCurrency(monthly.fuel, allowDecimalsForUsd: false)} • ${s.serviceSpendLabel}: ${s.formatCurrency(monthly.service, allowDecimalsForUsd: false)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.health_and_safety_rounded,
                color: AppColors.racingOrange, size: 20),
            const SizedBox(width: 8),
            Text(
              s.vehicleHealthTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...healthItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HealthStatusCard(
              item: item,
              strings: s,
              onTap: () async {
                if (item.isTax) {
                  await showVehicleFormSheet(
                    context: context,
                    controller: controller,
                    editingVehicle: vehicle,
                  );
                } else {
                  final saved = await showAddServiceSheet(
                    context: context,
                    controller: controller,
                    vehicle: vehicle,
                    initialCategory: item.category ?? ServiceCategory.oil,
                  );
                  if (saved && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.serviceSaved)),
                    );
                  }
                }
              },
            ),
          ),
        ),
        AdNativeWidget(isProUnlocked: controller.isProUnlocked),
        const SizedBox(height: 12),
        TopBrandsCard(
          controller: controller,
          activeVehicle: vehicle,
          onQuickLogService: () async {
            final saved = await showAddServiceSheet(
              context: context,
              controller: controller,
              vehicle: vehicle,
            );
            if (saved && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.serviceSaved)),
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _showUpdateOdometerDialog(
    BuildContext context,
    Vehicle vehicle,
  ) async {
    final s = controller.strings;
    final textCtrl =
        TextEditingController(text: vehicle.odometerKm.toString());

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(s.updateOdo),
        content: TextField(
          controller: textCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: s.odometerLabel,
            prefixIcon: const Icon(Icons.speed_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final parsed = int.tryParse(textCtrl.text.trim());
              if (parsed != null && parsed >= 0) {
                await controller.updateActiveOdometer(parsed);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: Text(s.updateOdo),
          ),
        ],
      ),
    );
    textCtrl.dispose();
  }
}

class _VehicleHeroCard extends StatelessWidget {
  const _VehicleHeroCard({
    required this.vehicle,
    required this.strings,
    required this.onUpdateOdometer,
    required this.onEditVehicle,
  });

  final Vehicle vehicle;
  final AppStrings strings;
  final VoidCallback onUpdateOdometer;
  final VoidCallback onEditVehicle;

  @override
  Widget build(BuildContext context) {
    final isMoto = vehicle.type == VehicleType.motorcycle;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.carbonHeroGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.racingOrange.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.racingOrange.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dual-Tone Logo Brand Accent Stripe (Deep Navy -> Vivid Orange)
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: AppColors.brandStripeGradient,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.brandNavy,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandNavy.withOpacity(0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isMoto
                            ? Icons.two_wheeler_rounded
                            : Icons.directions_car_rounded,
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
                            vehicle.name,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.racingOrange
                                        .withOpacity(0.45),
                                  ),
                                ),
                                child: Text(
                                  vehicle.plateNumber,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.9,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isMoto ? strings.motorcycle : strings.car,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onEditVehicle,
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: strings.editVehicle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.currentOdometer.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.formatKm(vehicle.odometerKm),
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                fontFeatures: [FontFeature.tabularFigures()],
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onUpdateOdometer,
                        style: TextButton.styleFrom(
                          backgroundColor:
                              AppColors.racingOrange.withOpacity(0.16),
                          foregroundColor: AppColors.racingOrange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: AppColors.racingOrange.withOpacity(0.4),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 15),
                        label: Text(
                          strings.updateOdo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthStatusCard extends StatelessWidget {
  const _HealthStatusCard({
    required this.item,
    required this.strings,
    required this.onTap,
  });

  final HealthStatusItem item;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = _badgeStyle(item.level, strings);
    final meta = _itemMeta(item, strings);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.level == HealthLevel.overdue
                ? AppColors.rose.withOpacity(0.5)
                : item.level == HealthLevel.soon
                    ? AppColors.amber.withOpacity(0.45)
                    : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: badge.color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(meta.icon, color: badge.color, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta.detail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badge.color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badge.color.withOpacity(0.45)),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badge.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: item.level == HealthLevel.unknown ? 0.08 : item.progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(badge.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({String label, Color color}) _badgeStyle(HealthLevel level, AppStrings s) {
    switch (level) {
      case HealthLevel.safe:
        return (label: s.statusSafe, color: AppColors.emerald);
      case HealthLevel.soon:
        return (label: s.statusSoon, color: AppColors.amber);
      case HealthLevel.overdue:
        return (label: s.statusOverdue, color: AppColors.rose);
      case HealthLevel.unknown:
        return (label: s.statusNoData, color: AppColors.textMuted);
    }
  }

  ({String title, String detail, IconData icon}) _itemMeta(
    HealthStatusItem item,
    AppStrings s,
  ) {
    if (item.isTax) {
      final days = item.daysRemaining ?? 0;
      final countdown = days >= 0
          ? '$days ${s.dueInDays} • ${s.formatDate(item.nextDueDate!)}'
          : '${s.overdueByDays} ${days.abs()} ${s.daysUnit} • ${s.formatDate(item.nextDueDate!)}';
      return (
        title: s.catStnk,
        detail: countdown,
        icon: Icons.event_available_rounded,
      );
    }

    IconData icon;
    String title;
    switch (item.category) {
      case ServiceCategory.oil:
        icon = Icons.oil_barrel_rounded;
        title = s.catOil;
        break;
      case ServiceCategory.routine:
        icon = Icons.settings_suggest_rounded;
        title = s.catRoutine;
        break;
      case ServiceCategory.brakesTires:
        icon = Icons.tire_repair_rounded;
        title = s.catBrakesTires;
        break;
      default:
        icon = Icons.build_rounded;
        title = s.catOther;
    }

    if (item.level == HealthLevel.unknown) {
      return (title: title, detail: s.tapToLog, icon: icon);
    }

    final parts = <String>[];
    if (item.kmRemaining != null) {
      if (item.kmRemaining! >= 0) {
        parts.add('${s.formatKm(item.kmRemaining!)} ${s.t('lagi', 'left')}');
      } else {
        parts.add(
          '${s.formatKm(item.kmRemaining!.abs())} ${s.t('lewat', 'overdue')}',
        );
      }
    }
    if (item.daysRemaining != null) {
      if (item.daysRemaining! >= 0) {
        parts.add('${item.daysRemaining} ${s.dueInDays}');
      } else {
        parts.add('${s.overdueByDays} ${item.daysRemaining!.abs()} ${s.daysUnit}');
      }
    }

    return (
      title: title,
      detail: parts.isNotEmpty ? parts.join(' • ') : s.tapToLog,
      icon: icon,
    );
  }
}

class _EmptyGarageState extends StatelessWidget {
  const _EmptyGarageState({
    required this.strings,
    required this.onAddVehicle,
  });

  final AppStrings strings;
  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.garage_outlined, size: 56, color: AppColors.sky),
            const SizedBox(height: 12),
            Text(
              strings.t(
                'Garasi masih kosong',
                'Your garage is empty',
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.addVehicle),
            ),
          ],
        ),
      ),
    );
  }
}
