import 'package:flutter/material.dart';

import '../../models/vehicle.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';

Future<bool> showVehicleFormSheet({
  required BuildContext context,
  required GarageController controller,
  Vehicle? editingVehicle,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _VehicleFormSheet(
      controller: controller,
      editingVehicle: editingVehicle,
    ),
  );
  return result ?? false;
}

class _VehicleFormSheet extends StatefulWidget {
  const _VehicleFormSheet({
    required this.controller,
    this.editingVehicle,
  });

  final GarageController controller;
  final Vehicle? editingVehicle;

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late VehicleType _type;
  late final TextEditingController _nameController;
  late final TextEditingController _plateController;
  late final TextEditingController _odoController;
  late DateTime _taxDueDate;

  @override
  void initState() {
    super.initState();
    final v = widget.editingVehicle;
    _type = v?.type ?? VehicleType.motorcycle;
    _nameController = TextEditingController(text: v?.name ?? '');
    _plateController = TextEditingController(text: v?.plateNumber ?? '');
    _odoController =
        TextEditingController(text: v != null ? v.odometerKm.toString() : '');
    _taxDueDate = v?.taxDueDate ??
        DateTime.now().add(const Duration(days: 180));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _odoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final isEdit = widget.editingVehicle != null;

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
              Text(
                isEdit ? s.editVehicle : s.addVehicle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _typeSelectorCard(
                      type: VehicleType.motorcycle,
                      icon: Icons.two_wheeler_rounded,
                      label: s.motorcycle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeSelectorCard(
                      type: VehicleType.car,
                      icon: Icons.directions_car_rounded,
                      label: s.car,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: s.vehicleNameLabel,
                  hintText: _type == VehicleType.motorcycle
                      ? 'Yamaha NMAX 155 / Honda Beat'
                      : 'Toyota Avanza / Honda Brio',
                  prefixIcon: Icon(
                    _type == VehicleType.motorcycle
                        ? Icons.two_wheeler_rounded
                        : Icons.directions_car_rounded,
                    size: 20,
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.requiredField : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _plateController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: s.plateNumberLabel,
                        hintText: 'B 1234 XYZ',
                        prefixIcon:
                            const Icon(Icons.badge_outlined, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s.requiredField
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _odoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: s.odometerLabel,
                        hintText: '12500',
                        prefixIcon: const Icon(Icons.speed_rounded, size: 20),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 0) return s.invalidNumber;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickTaxDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: s.taxDueDateLabel,
                    prefixIcon:
                        const Icon(Icons.calendar_month_rounded, size: 20),
                    suffixIcon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  ),
                  child: Text(
                    s.formatDate(_taxDueDate),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(s.saveVehicle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeSelectorCard({
    required VehicleType type,
    required IconData icon,
    required String label,
  }) {
    final selected = _type == type;
    return InkWell(
      onTap: () => setState(() => _type = type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.racingOrange.withOpacity(0.18)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.racingOrange : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.racingOrange : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color:
                    selected ? AppColors.racingOrange : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTaxDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _taxDueDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 6),
    );
    if (picked != null) {
      setState(() => _taxDueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final odo = int.parse(_odoController.text.trim());
    final existing = widget.editingVehicle;
    if (existing != null) {
      await widget.controller.updateVehicle(
        existing.copyWith(
          name: _nameController.text.trim(),
          plateNumber: _plateController.text.trim().toUpperCase(),
          type: _type,
          odometerKm: odo,
          taxDueDate: _taxDueDate,
        ),
      );
    } else {
      await widget.controller.addVehicle(
        name: _nameController.text.trim(),
        plateNumber: _plateController.text.trim().toUpperCase(),
        type: _type,
        odometerKm: odo,
        taxDueDate: _taxDueDate,
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
