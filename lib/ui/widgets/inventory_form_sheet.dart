import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/garage_item.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';

Future<bool> showInventoryFormSheet({
  required BuildContext context,
  required GarageController controller,
  GarageInventoryItem? editingItem,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _InventoryFormSheet(
      controller: controller,
      editingItem: editingItem,
    ),
  );
  return result ?? false;
}

class _InventoryFormSheet extends StatefulWidget {
  const _InventoryFormSheet({
    required this.controller,
    this.editingItem,
  });

  final GarageController controller;
  final GarageInventoryItem? editingItem;

  @override
  State<_InventoryFormSheet> createState() => _InventoryFormSheetState();
}

class _InventoryFormSheetState extends State<_InventoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late InventoryType _type;
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _minQtyController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final item = widget.editingItem;
    _type = item?.type ?? InventoryType.consumable;
    _nameController = TextEditingController(text: item?.name ?? '');
    _qtyController = TextEditingController(text: (item?.quantity ?? 1).toString());
    _minQtyController =
        TextEditingController(text: (item?.minQuantity ?? 1).toString());
    _unitController = TextEditingController(
      text: item?.unit ?? (_type == InventoryType.consumable ? 'botol' : 'set'),
    );
    _priceController = TextEditingController(
      text: item != null && item.unitPrice > 0
          ? widget.controller.strings.formatEditableAmount(item.unitPrice)
          : '',
    );
    _locationController = TextEditingController(text: item?.location ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _minQtyController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final isEdit = widget.editingItem != null;

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
                isEdit ? s.editInventoryItem : s.addInventoryItem,
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
                    child: _typeCard(
                      type: InventoryType.consumable,
                      icon: Icons.inventory_2_outlined,
                      label: s.typeConsumable,
                      accent: AppColors.emerald,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeCard(
                      type: InventoryType.tool,
                      icon: Icons.handyman_outlined,
                      label: s.typeTool,
                      accent: AppColors.sky,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: s.itemNameLabel,
                  hintText: _type == InventoryType.consumable
                      ? 'Oli Mesin / Filter Oli / Busi'
                      : 'Kunci T10 / Dongkrak / Kunci Torsi',
                  prefixIcon: Icon(
                    _type == InventoryType.consumable
                        ? Icons.oil_barrel_outlined
                        : Icons.construction_rounded,
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
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: s.quantityLabel,
                        prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
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
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: s.unitLabel,
                        hintText: _type == InventoryType.consumable
                            ? 'botol / pcs'
                            : 'set / pcs',
                      ),
                    ),
                  ),
                ],
              ),
              if (_type == InventoryType.consumable) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minQtyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: s.minStockLabel,
                          prefixIcon: const Icon(
                            Icons.warning_amber_rounded,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              '${s.unitPriceLabel} (${s.currency == AppCurrency.idr ? 'Rp' : '\$'})',
                          hintText: s.currency == AppCurrency.idr
                              ? '65000'
                              : '12.00',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: s.locationLabel,
                  hintText: 'Rak A1 / Toolbox / Bagasi',
                  prefixIcon: const Icon(Icons.place_outlined, size: 20),
                ),
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
                  icon: const Icon(Icons.check_rounded),
                  label: Text(s.saveItem),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeCard({
    required InventoryType type,
    required IconData icon,
    required String label,
    required Color accent,
  }) {
    final selected = _type == type;
    return InkWell(
      onTap: () => setState(() {
        _type = type;
        if (widget.editingItem == null) {
          _unitController.text =
              type == InventoryType.consumable ? 'botol' : 'set';
        }
      }),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.16) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? accent : AppColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final s = widget.controller.strings;
    final qty = int.parse(_qtyController.text.trim());
    final minQty = int.tryParse(_minQtyController.text.trim()) ?? 1;
    final rawPrice = double.tryParse(
          _priceController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
    final price = s.toBaseIdr(rawPrice);

    final existing = widget.editingItem;
    if (existing != null) {
      await widget.controller.updateInventoryItem(
        existing.copyWith(
          name: _nameController.text.trim(),
          type: _type,
          quantity: qty,
          minQuantity: minQty,
          unit: _unitController.text.trim().isEmpty
              ? 'pcs'
              : _unitController.text.trim(),
          unitPrice: _type == InventoryType.consumable ? price : 0,
          location: _locationController.text.trim(),
          notes: _notesController.text.trim(),
        ),
      );
    } else {
      await widget.controller.addInventoryItem(
        name: _nameController.text.trim(),
        type: _type,
        quantity: qty,
        minQuantity: minQty,
        unit: _unitController.text.trim(),
        unitPrice: _type == InventoryType.consumable ? price : 0,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
