import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';

Future<bool> showMasterProfileSheet({
  required BuildContext context,
  required GarageController controller,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _MasterProfileSheet(controller: controller),
  );
  return result ?? false;
}

class _MasterProfileSheet extends StatefulWidget {
  const _MasterProfileSheet({required this.controller});

  final GarageController controller;

  @override
  State<_MasterProfileSheet> createState() => _MasterProfileSheetState();
}

class _MasterProfileSheetState extends State<_MasterProfileSheet> {
  late final TextEditingController _garageNameCtrl;
  late final TextEditingController _workshopCtrl;
  late final TextEditingController _oilKmCtrl;
  late final TextEditingController _oilMoCtrl;
  late final TextEditingController _routineKmCtrl;
  late final TextEditingController _routineMoCtrl;
  late final TextEditingController _brakesKmCtrl;
  late final TextEditingController _brakesMoCtrl;
  late String _defaultFuel;

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

  @override
  void initState() {
    super.initState();
    final p = widget.controller.masterProfile;
    _garageNameCtrl = TextEditingController(text: p.garageName);
    _workshopCtrl = TextEditingController(text: p.defaultWorkshop);
    _defaultFuel = p.defaultFuelType;
    _oilKmCtrl = TextEditingController(text: p.oilIntervalKm.toString());
    _oilMoCtrl = TextEditingController(text: p.oilIntervalMonths.toString());
    _routineKmCtrl =
        TextEditingController(text: p.routineIntervalKm.toString());
    _routineMoCtrl =
        TextEditingController(text: p.routineIntervalMonths.toString());
    _brakesKmCtrl = TextEditingController(text: p.brakesIntervalKm.toString());
    _brakesMoCtrl =
        TextEditingController(text: p.brakesIntervalMonths.toString());
  }

  @override
  void dispose() {
    _garageNameCtrl.dispose();
    _workshopCtrl.dispose();
    _oilKmCtrl.dispose();
    _oilMoCtrl.dispose();
    _routineKmCtrl.dispose();
    _routineMoCtrl.dispose();
    _brakesKmCtrl.dispose();
    _brakesMoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final presets = widget.controller.language == AppLanguage.id
        ? _fuelPresetsId
        : _fuelPresetsEn;
    final allPresets =
        presets.contains(_defaultFuel) ? presets : [_defaultFuel, ...presets];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
            Text(
              s.editMasterData,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _garageNameCtrl,
              decoration: InputDecoration(
                labelText: s.garageNameLabel,
                prefixIcon:
                    const Icon(Icons.home_repair_service_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _workshopCtrl,
              decoration: InputDecoration(
                labelText: s.defaultWorkshopLabel,
                prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.defaultFuelLabel,
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
                final selected = fuel == _defaultFuel;
                return ChoiceChip(
                  label: Text(fuel),
                  selected: selected,
                  selectedColor: AppColors.emerald.withOpacity(0.22),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.emerald
                        : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.emerald : AppColors.border,
                  ),
                  onSelected: (_) => setState(() => _defaultFuel = fuel),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text(
              s.setupSectionIntervals,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _intervalInput(s.catOil, _oilKmCtrl, _oilMoCtrl, s),
            const SizedBox(height: 8),
            _intervalInput(s.catRoutine, _routineKmCtrl, _routineMoCtrl, s),
            const SizedBox(height: 8),
            _intervalInput(s.catBrakesTires, _brakesKmCtrl, _brakesMoCtrl, s),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(s.saveItem),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intervalInput(
    String label,
    TextEditingController kmCtrl,
    TextEditingController moCtrl,
    AppStrings s,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 4,
          child: TextField(
            controller: kmCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              suffixText: 'km',
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: TextField(
            controller: moCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              suffixText: s.t('bln', 'mo'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final current = widget.controller.masterProfile;
    await widget.controller.updateMasterProfile(
      current.copyWith(
        garageName: _garageNameCtrl.text.trim(),
        defaultWorkshop: _workshopCtrl.text.trim(),
        defaultFuelType: _defaultFuel,
        oilIntervalKm:
            int.tryParse(_oilKmCtrl.text.trim()) ?? current.oilIntervalKm,
        oilIntervalMonths:
            int.tryParse(_oilMoCtrl.text.trim()) ?? current.oilIntervalMonths,
        routineIntervalKm: int.tryParse(_routineKmCtrl.text.trim()) ??
            current.routineIntervalKm,
        routineIntervalMonths: int.tryParse(_routineMoCtrl.text.trim()) ??
            current.routineIntervalMonths,
        brakesIntervalKm: int.tryParse(_brakesKmCtrl.text.trim()) ??
            current.brakesIntervalKm,
        brakesIntervalMonths: int.tryParse(_brakesMoCtrl.text.trim()) ??
            current.brakesIntervalMonths,
      ),
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
