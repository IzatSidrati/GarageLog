import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/health_status.dart';
import '../../models/service_entry.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/add_service_sheet.dart';
import '../widgets/service_book_export_sheet.dart';

class ServiceTab extends StatelessWidget {
  const ServiceTab({
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

    final services = controller.serviceEntriesFor(vehicle.id);
    final reminders = controller
        .computeHealthItems(vehicle)
        .where((item) => !item.isTax)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // Export Service Book for Resale CTA Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.racingOrange.withOpacity(0.18),
                AppColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.racingOrange.withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.racingOrange.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.racingOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.exportServiceBook,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.exportSubtitle,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('export_service_book_btn'),
                      onPressed: () => showServiceBookExportSheet(
                        context: context,
                        controller: controller,
                        vehicle: vehicle,
                      ),
                      icon: const Icon(Icons.copy_all_rounded, size: 18),
                      label: Text(s.copyToClipboard),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const Key('service_tab_add_btn'),
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
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(s.quickServiceCta),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          s.upcomingReminders,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: reminders.map((r) {
            final color = _levelColor(r.level);
            final label = _categoryLabel(r.category ?? ServiceCategory.other, s);
            final kmText = r.nextDueKm != null
                ? s.formatKm(r.nextDueKm!)
                : s.statusNoData;
            final dateText = r.nextDueDate != null
                ? s.formatShortDate(r.nextDueDate!)
                : '-';

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: r == reminders.last ? 0 : 8,
                ),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      kmText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Text(
          '${s.serviceHistory} (${services.length})',
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (services.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              s.noServiceYet,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...services.map((srv) {
            final catColor = _categoryColor(srv.category);
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _categoryIcon(srv.category),
                            color: catColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                srv.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${s.formatDate(srv.date)} • ${s.formatKm(srv.odometerKm)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (srv.partBrand.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.racingOrange
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    srv.partBrand,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.racingOrange,
                                    ),
                                  ),
                                ),
                              ],
                              if (srv.workshop.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  srv.workshop,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              s.formatCurrency(srv.cost),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  controller.deleteServiceEntry(srv.id),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (srv.nextDueKm != null || srv.nextDueDate != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              size: 14,
                              color: AppColors.sky,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${s.nextDue}: '
                              '${srv.nextDueKm != null ? s.formatKm(srv.nextDueKm!) : ''}'
                              '${srv.nextDueKm != null && srv.nextDueDate != null ? ' / ' : ''}'
                              '${srv.nextDueDate != null ? s.formatDate(srv.nextDueDate!) : ''}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sky,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (srv.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        srv.notes,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (srv.hasReceiptPhoto) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => _showReceiptPreview(context, srv, s),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.racingOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.racingOrange.withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.receipt_long_rounded,
                                size: 15,
                                color: AppColors.racingOrange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.viewReceiptPhoto,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.racingOrange,
                                ),
                              ),
                            ],
                          ),
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

  Future<void> _showReceiptPreview(
    BuildContext context,
    ServiceEntry srv,
    AppStrings s,
  ) async {
    if (!srv.hasReceiptPhoto) return;
    final bytes = base64Decode(srv.receiptImageBase64!);

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.racingOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      srv.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: InteractiveViewer(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _levelColor(HealthLevel level) {
    switch (level) {
      case HealthLevel.safe:
        return AppColors.emerald;
      case HealthLevel.soon:
        return AppColors.amber;
      case HealthLevel.overdue:
        return AppColors.rose;
      case HealthLevel.unknown:
        return AppColors.textMuted;
    }
  }

  Color _categoryColor(ServiceCategory cat) {
    switch (cat) {
      case ServiceCategory.oil:
        return AppColors.amber;
      case ServiceCategory.routine:
        return AppColors.sky;
      case ServiceCategory.brakesTires:
        return AppColors.emerald;
      case ServiceCategory.other:
        return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(ServiceCategory cat) {
    switch (cat) {
      case ServiceCategory.oil:
        return Icons.oil_barrel_rounded;
      case ServiceCategory.routine:
        return Icons.settings_suggest_rounded;
      case ServiceCategory.brakesTires:
        return Icons.tire_repair_rounded;
      case ServiceCategory.other:
        return Icons.handyman_outlined;
    }
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
