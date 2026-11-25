import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/vehicle.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';

Future<bool> showQuickFuelSheet({
  required BuildContext context,
  required GarageController controller,
  required Vehicle vehicle,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _QuickFuelSheet(
      controller: controller,
      vehicle: vehicle,
    ),
  );
  return result ?? false;
}

class _QuickFuelSheet extends StatefulWidget {
  const _QuickFuelSheet({
    required this.controller,
    required this.vehicle,
  });

  final GarageController controller;
  final Vehicle vehicle;

  @override
  State<_QuickFuelSheet> createState() => _QuickFuelSheetState();
}

class _QuickFuelSheetState extends State<_QuickFuelSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _odoController;
  late final TextEditingController _litersController;
  late final TextEditingController _costController;
  String _selectedFuelType = 'Pertamax';

  static const _fuelPresetsId = [
    'Pertalite',
    'Pertamax',
    'Pertamax Turbo',
    'Shell Super',
    'Solar / Dex',
  ];

  static const _fuelPresetsEn = [
    'Regular 87',
    'Midgrade 89',
    'Premium 93',
    'Diesel',
    'Pertamax',
  ];

  int? _previousOdo;

  @override
  void initState() {
    super.initState();
    final history = widget.controller.fuelEntriesFor(widget.vehicle.id);
    if (history.isNotEmpty) {
      _previousOdo = history.first.odometerKm;
      _selectedFuelType = history.first.fuelType;
    } else if (widget.controller.masterProfile.defaultFuelType.isNotEmpty) {
      _selectedFuelType = widget.controller.masterProfile.defaultFuelType;
    } else {
      _selectedFuelType = widget.controller.language == AppLanguage.id
          ? 'Pertamax'
          : 'Regular 87';
    }
    final suggestedOdo = widget.vehicle.odometerKm;
    _odoController = TextEditingController(text: suggestedOdo.toString());
    _litersController = TextEditingController();
    _costController = TextEditingController();
  }

  @override
  void dispose() {
    _odoController.dispose();
    _litersController.dispose();
    _costController.dispose();
    super.dispose();
  }

  double? _parseNum(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final presets = widget.controller.language == AppLanguage.id
        ? _fuelPresetsId
        : _fuelPresetsEn;
    final allPresets = presets.contains(_selectedFuelType)
        ? presets
        : [_selectedFuelType, ...presets];

    final odoVal = int.tryParse(_odoController.text.trim());
    final litersVal = _parseNum(_litersController.text);
    final costVal = _parseNum(_costController.text);

    double? estKmPerL;
    double? estCostPerKm;
    if (_previousOdo != null &&
        odoVal != null &&
        odoVal > _previousOdo! &&
        litersVal != null &&
        litersVal > 0) {
      final delta = odoVal - _previousOdo!;
      estKmPerL = delta / litersVal;
      if (costVal != null && costVal > 0) {
        estCostPerKm = costVal / delta;
      }
    }

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
                      color: AppColors.emerald.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_gas_station_rounded,
                      color: AppColors.emerald,
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
              const SizedBox(height: 16),
              Text(
                s.fuelTypeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allPresets.map((fuel) {
                  final selected = fuel == _selectedFuelType;
                  return ChoiceChip(
                    label: Text(fuel),
                    selected: selected,
                    selectedColor: AppColors.emerald.withOpacity(0.22),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.emerald
                          : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.emerald : AppColors.border,
                    ),
                    onSelected: (_) => setState(() => _selectedFuelType = fuel),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _odoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.odometerLabel,
                  prefixIcon: const Icon(Icons.speed_rounded, size: 20),
                  helperText: _previousOdo != null
                      ? '${s.t('Isi terakhir', 'Last fill')}: ${s.formatKm(_previousOdo!)}'
                      : s.firstFillHint,
                  helperMaxLines: 2,
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  final parsed = int.tryParse(val?.trim() ?? '');
                  if (parsed == null || parsed <= 0) return s.invalidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _litersController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: s.litersLabel,
                        hintText: '4.5',
                        prefixIcon:
                            const Icon(Icons.water_drop_outlined, size: 20),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        final parsed = _parseNum(val ?? '');
                        if (parsed == null || parsed <= 0) {
                          return s.mustBeGreaterZero;
                        }
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
                            ? '60000'
                            : '15.00',
                        prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        final parsed = _parseNum(val ?? '');
                        if (parsed == null || parsed <= 0) {
                          return s.mustBeGreaterZero;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (estKmPerL != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.emerald.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.liveEstimate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s.formatNumber(estKmPerL)} km/L',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (estCostPerKm != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              s.costPerKm,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${s.formatCurrency(estCostPerKm)}/km',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sky,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: const Color(0xFF022016),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(s.saveFuel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final odo = int.parse(_odoController.text.trim());
    final liters = _parseNum(_litersController.text)!;
    final cost = _parseNum(_costController.text)!;

    await widget.controller.addFuelEntry(
      vehicleId: widget.vehicle.id,
      odometerKm: odo,
      liters: liters,
      totalCost: cost,
      fuelType: _selectedFuelType,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
