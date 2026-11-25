import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/garage_item.dart';
import '../../models/vehicle.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/backup_restore_sheet.dart';
import '../widgets/inventory_form_sheet.dart';
import '../widgets/master_profile_sheet.dart';
import '../widgets/pro_pass_modal.dart';
import '../widgets/vehicle_form_sheet.dart';

class GarageTab extends StatefulWidget {
  const GarageTab({
    super.key,
    required this.controller,
  });

  final GarageController controller;

  @override
  State<GarageTab> createState() => _GarageTabState();
}

class _GarageTabState extends State<GarageTab> {
  int _subTab = 0; // 0 = Vehicles, 1 = Stock & Tools

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final s = ctrl.strings;
    final isPro = ctrl.isProUnlocked;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // Pro Pass Status Banner
        InkWell(
          key: const Key('pro_pass_banner'),
          onTap: () => showProPassModal(
            context: context,
            controller: ctrl,
          ),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPro
                    ? [
                        AppColors.emerald.withOpacity(0.22),
                        AppColors.surface,
                      ]
                    : [
                        AppColors.amber.withOpacity(0.2),
                        AppColors.surface,
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isPro
                    ? AppColors.emerald.withOpacity(0.5)
                    : AppColors.amber.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: isPro ? AppColors.emerald : AppColors.amber,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? s.proUnlockedBanner : s.proUpgradeBanner,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPro ? s.proModalSubtitle : '${s.freePlan} • ${s.proPrice}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Sub-tab Switcher: Vehicles | Stock & Tools
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                icon: const Icon(Icons.directions_car_outlined, size: 16),
                label: Text('${s.subTabVehicles} (${ctrl.vehicles.length})'),
              ),
              ButtonSegment(
                value: 1,
                icon: const Icon(Icons.inventory_2_outlined, size: 16),
                label: Text(
                  '${s.subTabStock} (${ctrl.inventoryItems.length})',
                  key: const Key('garage_subtab_stock'),
                ),
              ),
            ],
            selected: {_subTab},
            onSelectionChanged: (set) => setState(() => _subTab = set.first),
          ),
        ),
        const SizedBox(height: 16),
        if (_subTab == 0)
          ..._buildVehiclesSection(context, ctrl, s)
        else
          ..._buildInventorySection(context, ctrl, s),
        const SizedBox(height: 20),
        Text(
          s.settingsSection,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.languageLabel,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SegmentedButton<AppLanguage>(
                    segments: const [
                      ButtonSegment(value: AppLanguage.id, label: Text('ID')),
                      ButtonSegment(value: AppLanguage.en, label: Text('EN')),
                    ],
                    selected: {ctrl.language},
                    onSelectionChanged: (set) => ctrl.setLanguage(set.first),
                  ),
                ],
              ),
              const Divider(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.currencyLabel,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SegmentedButton<AppCurrency>(
                    segments: const [
                      ButtonSegment(value: AppCurrency.idr, label: Text('Rp')),
                      ButtonSegment(value: AppCurrency.usd, label: Text('\$')),
                    ],
                    selected: {ctrl.currency},
                    onSelectionChanged: (set) => ctrl.setCurrency(set.first),
                  ),
                ],
              ),
              const Divider(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('edit_master_profile_btn'),
                  onPressed: () async {
                    final saved = await showMasterProfileSheet(
                      context: context,
                      controller: ctrl,
                    );
                    if (saved && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.masterDataSaved)),
                      );
                    }
                  },
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(s.editMasterData),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('open_backup_restore_btn'),
                  onPressed: () => showBackupRestoreSheet(
                    context: context,
                    controller: ctrl,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: AppColors.sky,
                    side: BorderSide(color: AppColors.sky.withOpacity(0.45)),
                  ),
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: Text(s.backupRestoreTitle),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ctrl.resetSampleData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.resetDemoDone)),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: Text(s.resetDemoLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildVehiclesSection(
    BuildContext context,
    GarageController ctrl,
    AppStrings s,
  ) {
    final vehicles = ctrl.vehicles;
    final activeId = ctrl.activeVehicle?.id;

    return [
      Row(
        children: [
          Expanded(
            child: Text(
              '${s.garageTabTitle} (${vehicles.length})',
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton.icon(
            key: const Key('add_vehicle_btn'),
            onPressed: () => _handleAddVehicle(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: Icon(
              ctrl.canAddMoreVehicles
                  ? Icons.add_rounded
                  : Icons.lock_outline_rounded,
              size: 18,
            ),
            label: Text(s.addVehicle),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...vehicles.map((v) {
        final selected = v.id == activeId;
        final isMoto = v.type == VehicleType.motorcycle;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => ctrl.selectVehicle(v.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.sky : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (selected
                                  ? AppColors.sky
                                  : AppColors.textSecondary)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isMoto
                              ? Icons.two_wheeler_rounded
                              : Icons.directions_car_rounded,
                          color: selected
                              ? AppColors.sky
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    v.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.sky.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      s.activeBadge,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.sky,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${v.plateNumber} • ${s.formatKm(v.odometerKm)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${s.catStnk}: ${s.formatDate(v.taxDueDate)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => showVehicleFormSheet(
                          context: context,
                          controller: ctrl,
                          editingVehicle: v,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(s.editVehicle),
                      ),
                      if (vehicles.length > 1) ...[
                        const SizedBox(width: 6),
                        TextButton.icon(
                          onPressed: () => _confirmDeleteVehicle(context, v),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.rose,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16),
                          label: Text(s.delete),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ];
  }

  List<Widget> _buildInventorySection(
    BuildContext context,
    GarageController ctrl,
    AppStrings s,
  ) {
    final items = ctrl.inventoryItems;
    final consumablesCount = items.where((i) => i.isConsumable).length;
    final lowCount = items.where((i) => i.isLowStock || i.isOutOfStock).length;
    final loanedCount = items.where((i) => i.isBorrowed).length;

    return [
      Row(
        children: [
          Expanded(
            child: _miniStatPill(
              label: s.stockSummaryConsumables,
              value: '$consumablesCount',
              color: AppColors.emerald,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _miniStatPill(
              label: s.stockSummaryLow,
              value: '$lowCount',
              color: lowCount > 0 ? AppColors.amber : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _miniStatPill(
              label: s.stockSummaryLoaned,
              value: '$loanedCount',
              color: loanedCount > 0 ? AppColors.sky : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: Text(
              s.inventoryTitle,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton.icon(
            key: const Key('add_inventory_btn'),
            onPressed: () => _handleAddInventory(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: const Color(0xFF022016),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: Icon(
              ctrl.canAddMoreInventory
                  ? Icons.add_rounded
                  : Icons.lock_outline_rounded,
              size: 18,
            ),
            label: Text(s.addInventoryItem),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            s.noInventoryYet,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        )
      else
        ...items.map((item) => _buildInventoryCard(context, ctrl, s, item)),
    ];
  }

  Widget _buildInventoryCard(
    BuildContext context,
    GarageController ctrl,
    AppStrings s,
    GarageInventoryItem item,
  ) {
    final Color statusColor;
    final String statusLabel;

    if (item.isConsumable) {
      if (item.isOutOfStock) {
        statusColor = AppColors.rose;
        statusLabel = s.stockEmpty;
      } else if (item.isLowStock) {
        statusColor = AppColors.amber;
        statusLabel = s.stockLow;
      } else {
        statusColor = AppColors.emerald;
        statusLabel = s.stockSafe;
      }
    } else {
      if (item.isBorrowed) {
        statusColor = AppColors.amber;
        statusLabel = s.toolBorrowed;
      } else {
        statusColor = AppColors.sky;
        statusLabel = s.toolAvailable;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (item.isOutOfStock || item.isLowStock || item.isBorrowed)
                ? statusColor.withOpacity(0.45)
                : AppColors.border,
          ),
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
                    color: statusColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.isConsumable
                        ? Icons.inventory_2_rounded
                        : Icons.handyman_rounded,
                    color: statusColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (item.location.isNotEmpty) item.location,
                          if (item.isConsumable && item.unitPrice > 0)
                            '${s.formatCurrency(item.unitPrice)}/${item.unit}',
                        ].join(' • '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.isBorrowed) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${s.borrowedByPrefix}: ${item.borrowedBy}'
                          '${item.borrowedDate != null ? ' (${s.formatShortDate(item.borrowedDate!)})' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.45)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (item.isConsumable) ...[
                  _stepperBtn(
                    icon: Icons.remove_rounded,
                    onTap: item.quantity > 0
                        ? () => ctrl.adjustInventoryQuantity(item.id, -1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${item.quantity} ${item.unit}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _stepperBtn(
                    icon: Icons.add_rounded,
                    onTap: () => ctrl.adjustInventoryQuantity(item.id, 1),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: item.isBorrowed
                        ? () => ctrl.returnTool(item.id)
                        : () => _showLoanToolDialog(context, item),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      foregroundColor:
                          item.isBorrowed ? AppColors.emerald : AppColors.amber,
                      side: BorderSide(
                        color: (item.isBorrowed
                                ? AppColors.emerald
                                : AppColors.amber)
                            .withOpacity(0.5),
                      ),
                    ),
                    icon: Icon(
                      item.isBorrowed
                          ? Icons.assignment_return_outlined
                          : Icons.person_outline_rounded,
                      size: 16,
                    ),
                    label: Text(
                      item.isBorrowed ? s.returnTool : s.loanTool,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showInventoryFormSheet(
                    context: context,
                    controller: ctrl,
                    editingItem: item,
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ctrl.deleteInventoryItem(item.id),
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
      ),
    );
  }

  Widget _stepperBtn({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 17,
          color: onTap != null ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _miniStatPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddVehicle(BuildContext context) async {
    final ctrl = widget.controller;
    if (ctrl.canAddMoreVehicles) {
      await showVehicleFormSheet(context: context, controller: ctrl);
      return;
    }

    final unlockedNow = await showProPassModal(
      context: context,
      controller: ctrl,
      triggeredByLimit: true,
    );
    if (unlockedNow && context.mounted) {
      await showVehicleFormSheet(context: context, controller: ctrl);
    }
  }

  Future<void> _handleAddInventory(BuildContext context) async {
    final ctrl = widget.controller;
    if (ctrl.canAddMoreInventory) {
      await showInventoryFormSheet(context: context, controller: ctrl);
      return;
    }

    final unlockedNow = await showProPassModal(
      context: context,
      controller: ctrl,
      triggeredByLimit: true,
      customLimitNote: ctrl.strings.proStockLimitNote,
    );
    if (unlockedNow && context.mounted) {
      await showInventoryFormSheet(context: context, controller: ctrl);
    }
  }

  Future<void> _showLoanToolDialog(
    BuildContext context,
    GarageInventoryItem item,
  ) async {
    final ctrl = widget.controller;
    final s = ctrl.strings;
    final nameCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('${s.loanTool}: ${item.name}'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: s.borrowerNameLabel,
            hintText: 'Budi / Andi',
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await ctrl.loanTool(item.id, nameCtrl.text.trim());
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: Text(s.loanTool),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
  }

  Future<void> _confirmDeleteVehicle(
    BuildContext context,
    Vehicle vehicle,
  ) async {
    final ctrl = widget.controller;
    final s = ctrl.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(s.deleteConfirmTitle),
        content: Text(s.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ctrl.deleteVehicle(vehicle.id);
    }
  }
}
