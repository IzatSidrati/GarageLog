import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/garage_item.dart';
import '../../models/service_entry.dart';
import '../../models/vehicle.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';

Future<bool> showAddServiceSheet({
  required BuildContext context,
  required GarageController controller,
  required Vehicle vehicle,
  ServiceCategory initialCategory = ServiceCategory.oil,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AddServiceSheet(
      controller: controller,
      vehicle: vehicle,
      initialCategory: initialCategory,
    ),
  );
  return result ?? false;
}

class _AddServiceSheet extends StatefulWidget {
  const _AddServiceSheet({
    required this.controller,
    required this.vehicle,
    required this.initialCategory,
  });

  final GarageController controller;
  final Vehicle vehicle;
  final ServiceCategory initialCategory;

  @override
  State<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<_AddServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late ServiceCategory _category;
  late final TextEditingController _titleController;
  late final TextEditingController _odoController;
  late final TextEditingController _costController;
  late final TextEditingController _workshopController;
  late final TextEditingController _nextKmController;
  late final TextEditingController _nextMonthsController;
  late final TextEditingController _notesController;
  final Set<String> _selectedStockIds = {};
  bool _costManuallyEdited = false;

  ({int km, int months}) _intervalsFor(ServiceCategory cat) {
    final master = widget.controller.masterProfile.intervalFor(cat);
    if (master.km > 0 || master.months > 0) return master;
    return ServiceEntry.defaultIntervals(widget.vehicle.type, cat);
  }

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    final defaults = _intervalsFor(_category);
    _titleController = TextEditingController(
      text: _defaultTitle(_category, widget.controller.strings),
    );
    _odoController =
        TextEditingController(text: widget.vehicle.odometerKm.toString());
    _costController = TextEditingController();
    _workshopController = TextEditingController(
      text: widget.controller.masterProfile.defaultWorkshop,
    );
    _nextKmController = TextEditingController(
      text: defaults.km > 0 ? defaults.km.toString() : '',
    );
    _nextMonthsController = TextEditingController(
      text: defaults.months > 0 ? defaults.months.toString() : '',
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _odoController.dispose();
    _costController.dispose();
    _workshopController.dispose();
    _nextKmController.dispose();
    _nextMonthsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _defaultTitle(ServiceCategory cat, AppStrings s) {
    switch (cat) {
      case ServiceCategory.oil:
        return s.catOil;
      case ServiceCategory.routine:
        return s.catRoutine;
      case ServiceCategory.brakesTires:
        return s.catBrakesTires;
      case ServiceCategory.other:
        return '';
    }
  }

  void _selectCategory(ServiceCategory cat) {
    final s = widget.controller.strings;
    final prevDefault = _defaultTitle(_category, s);
    setState(() {
      _category = cat;
      if (_titleController.text.trim().isEmpty ||
          _titleController.text.trim() == prevDefault) {
        _titleController.text = _defaultTitle(cat, s);
      }
      final defaults = _intervalsFor(cat);
      _nextKmController.text = defaults.km > 0 ? defaults.km.toString() : '';
      _nextMonthsController.text =
          defaults.months > 0 ? defaults.months.toString() : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final consumables = widget.controller.availableConsumables;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.sky.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.build_circle_outlined,
                      color: AppColors.sky,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.addServiceTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.vehicle.name} • ${widget.vehicle.plateNumber}',
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
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _catChip(ServiceCategory.oil, s.catOil),
                  _catChip(ServiceCategory.routine, s.catRoutine),
                  _catChip(ServiceCategory.brakesTires, s.catBrakesTires),
                  _catChip(ServiceCategory.other, s.catOther),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: s.serviceTitleLabel,
                  prefixIcon: const Icon(Icons.handyman_outlined, size: 20),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.requiredField : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _odoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: s.odometerLabel,
                        prefixIcon: const Icon(Icons.speed_rounded, size: 20),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 0) return s.invalidNumber;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText:
                            '${s.totalCostLabel} (${s.currency == AppCurrency.idr ? 'Rp' : '\$'})',
                        hintText: s.currency == AppCurrency.idr
                            ? '120000'
                            : '45.00',
                        prefixIcon:
                            const Icon(Icons.payments_outlined, size: 20),
                      ),
                      onChanged: (_) => _costManuallyEdited = true,
                      validator: (v) {
                        final n = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.'),
                        );
                        if (n == null || n < 0) return s.invalidNumber;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (consumables.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.emerald.withOpacity(0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s.useFromStockTitle,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.useFromStockHint,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: consumables.map((item) {
                          final selected = _selectedStockIds.contains(item.id);
                          return FilterChip(
                            label: Text(
                              '${item.name} (${item.quantity} ${item.unit})',
                            ),
                            selected: selected,
                            selectedColor: AppColors.emerald.withOpacity(0.24),
                            checkmarkColor: AppColors.emerald,
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.emerald
                                  : AppColors.textPrimary,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.emerald
                                  : AppColors.border,
                            ),
                            onSelected: (isSel) =>
                                _toggleStockItem(item, isSel, consumables),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _workshopController,
                decoration: InputDecoration(
                  labelText: s.workshopLabel,
                  prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nextKmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: s.nextReminderKm,
                        hintText: '2000',
                        prefixIcon: const Icon(Icons.add_road_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nextMonthsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: s.nextReminderMonths,
                        hintText: '3',
                        prefixIcon:
                            const Icon(Icons.event_repeat_rounded, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: s.notesLabel,
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(s.saveService),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catChip(ServiceCategory cat, String label) {
    final selected = _category == cat;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.sky.withOpacity(0.22),
      labelStyle: TextStyle(
        color: selected ? AppColors.sky : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(color: selected ? AppColors.sky : AppColors.border),
      onSelected: (_) => _selectCategory(cat),
    );
  }

  void _toggleStockItem(
    GarageInventoryItem item,
    bool isSelected,
    List<GarageInventoryItem> allConsumables,
  ) {
    setState(() {
      if (isSelected) {
        _selectedStockIds.add(item.id);
      } else {
        _selectedStockIds.remove(item.id);
      }
      if (!_costManuallyEdited || _costController.text.trim().isEmpty) {
        final stockTotal = allConsumables
            .where((c) => _selectedStockIds.contains(c.id))
            .fold<double>(0, (sum, c) => sum + c.unitPrice);
        if (stockTotal > 0) {
          _costController.text = stockTotal.toStringAsFixed(0);
        } else if (!_costManuallyEdited) {
          _costController.clear();
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final odo = int.parse(_odoController.text.trim());
    final cost =
        double.parse(_costController.text.trim().replaceAll(',', '.'));
    final nextKm = int.tryParse(_nextKmController.text.trim()) ?? 0;
    final nextMonths = int.tryParse(_nextMonthsController.text.trim()) ?? 0;

    await widget.controller.addServiceEntry(
      vehicleId: widget.vehicle.id,
      category: _category,
      title: _titleController.text.trim(),
      odometerKm: odo,
      cost: cost,
      workshop: _workshopController.text.trim(),
      nextIntervalKm: nextKm,
      nextIntervalMonths: nextMonths,
      notes: _notesController.text.trim(),
      consumedItemIds: _selectedStockIds.toList(),
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
