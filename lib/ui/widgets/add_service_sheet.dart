import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_strings.dart';
import '../../models/garage_item.dart';
import '../../models/service_entry.dart';
import '../../models/vehicle.dart';
import '../../services/brand_detector.dart';
import '../../services/receipt_ocr_service.dart';
import '../../services/receipt_parser.dart';
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
  final _imagePicker = ImagePicker();

  late ServiceCategory _category;
  late final TextEditingController _titleController;
  late final TextEditingController _odoController;
  late final TextEditingController _costController;
  late final TextEditingController _brandController;
  late final TextEditingController _workshopController;
  late final TextEditingController _nextKmController;
  late final TextEditingController _nextMonthsController;
  late final TextEditingController _notesController;

  final Set<String> _selectedStockIds = {};
  bool _costManuallyEdited = false;

  // Photo receipt + Offline OCR state
  Uint8List? _receiptBytes;
  String? _receiptBase64;
  bool _isScanning = false;
  String? _scanFeedback;
  bool _scanSuccess = false;

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
    _brandController = TextEditingController();
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
    _brandController.dispose();
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

  void _selectCategory(ServiceCategory cat, {bool updateTitleIfDefault = true}) {
    final s = widget.controller.strings;
    final prevDefault = _defaultTitle(_category, s);
    setState(() {
      _category = cat;
      if (updateTitleIfDefault &&
          (_titleController.text.trim().isEmpty ||
              _titleController.text.trim() == prevDefault)) {
        _titleController.text = _defaultTitle(cat, s);
      }
      final defaults = _intervalsFor(cat);
      _nextKmController.text = defaults.km > 0 ? defaults.km.toString() : '';
      _nextMonthsController.text =
          defaults.months > 0 ? defaults.months.toString() : '';
    });
  }

  Future<void> _pickAndScanReceipt(ImageSource source) async {
    final s = widget.controller.strings;
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 960,
        imageQuality: 65,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _receiptBytes = bytes;
        _receiptBase64 = base64Encode(bytes);
        _isScanning = true;
        _scanFeedback = null;
      });

      final ocr = await extractTextFromReceiptPath(picked.path);
      if (!mounted) return;

      if (!ocr.supported) {
        setState(() {
          _isScanning = false;
          _scanSuccess = false;
          _scanFeedback = s.scanWebHint;
        });
        return;
      }

      if (ocr.hasText) {
        _applyParsedReceipt(ocr.rawText);
      } else {
        setState(() {
          _isScanning = false;
          _scanSuccess = false;
          _scanFeedback = s.scanNoTextFound;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanSuccess = false;
        _scanFeedback = s.scanNoTextFound;
      });
    }
  }

  void _applyParsedReceipt(String rawText) {
    final s = widget.controller.strings;
    final parsed = ReceiptParser.parse(rawText, s);

    setState(() {
      _isScanning = false;
      _category = parsed.category;
      final defaults = _intervalsFor(parsed.category);
      _nextKmController.text = defaults.km > 0 ? defaults.km.toString() : '';
      _nextMonthsController.text =
          defaults.months > 0 ? defaults.months.toString() : '';

      if (parsed.title.isNotEmpty) {
        _titleController.text = parsed.title;
      }
      if (parsed.totalCost != null && parsed.totalCost! > 0) {
        _costController.text = s.currency == AppCurrency.idr
            ? parsed.totalCost!.round().toString()
            : parsed.totalCost!.toStringAsFixed(2);
        _costManuallyEdited = true;
      }
      if (parsed.workshop != null && parsed.workshop!.isNotEmpty) {
        _workshopController.text = parsed.workshop!;
      }
      if (parsed.partBrand != null && parsed.partBrand!.isNotEmpty) {
        _brandController.text = parsed.partBrand!;
      }
      if (parsed.odometerKm != null && parsed.odometerKm! > 0) {
        _odoController.text = parsed.odometerKm!.toString();
      }
      if (parsed.detectedItems.isNotEmpty) {
        _notesController.text = parsed.detectedItems.join(' • ');
      }

      _scanSuccess = parsed.hasAnyDetection;
      _scanFeedback =
          parsed.hasAnyDetection ? s.scanAutoFilled : s.scanNoTextFound;
    });
  }

  Future<void> _showSmartPasteDialog() async {
    final s = widget.controller.strings;
    final textCtrl = TextEditingController();

    final sampleText = s.isId
        ? 'AHASS MOTOR MANDIRI\n'
            'Jl. Raya Utama No. 12\n'
            'KM : ${widget.vehicle.odometerKm + 120}\n'
            '1. Oli Mesin SPX2 0.8L   Rp 68.000\n'
            '2. Servis CVT & Roller   Rp 95.000\n'
            'GRAND TOTAL              Rp 163.000\n'
        : 'PRECISION AUTO CARE\n'
            'ODO: ${widget.vehicle.odometerKm + 120} km\n'
            '1. Synthetic Oil Change  \$45.00\n'
            '2. Brake Pad Inspection  \$20.00\n'
            'GRAND TOTAL              \$65.00\n';

    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          s.pasteReceiptDialogTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('paste_receipt_text_field'),
              controller: textCtrl,
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
              decoration: InputDecoration(hintText: s.pasteReceiptHint),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('load_sample_receipt_btn'),
                onPressed: () => textCtrl.text = sampleText,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(s.loadSampleReceipt),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          ElevatedButton.icon(
            key: const Key('parse_receipt_submit_btn'),
            onPressed: () => Navigator.of(ctx).pop(textCtrl.text),
            icon: const Icon(Icons.document_scanner_rounded, size: 17),
            label: Text(s.parseReceiptNow),
          ),
        ],
      ),
    );
    textCtrl.dispose();

    if (raw != null && raw.trim().isNotEmpty && mounted) {
      _applyParsedReceipt(raw);
    }
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
                      color: AppColors.racingOrange.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.build_circle_outlined,
                      color: AppColors.racingOrange,
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
                            fontWeight: FontWeight.w800,
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

              // Offline Photo Receipt & OCR Auto-Fill Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sky.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sky.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.document_scanner_rounded,
                          size: 18,
                          color: AppColors.sky,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            s.scanReceiptTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.scanReceiptSubtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isScanning
                                ? null
                                : () => _pickAndScanReceipt(ImageSource.camera),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 9,
                              ),
                              foregroundColor: AppColors.racingOrange,
                              side: BorderSide(
                                color: AppColors.racingOrange.withOpacity(0.5),
                              ),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: Text(
                              s.pickFromCamera,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isScanning
                                ? null
                                : () =>
                                    _pickAndScanReceipt(ImageSource.gallery),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 9,
                              ),
                              foregroundColor: AppColors.sky,
                              side: BorderSide(
                                color: AppColors.sky.withOpacity(0.5),
                              ),
                            ),
                            icon: const Icon(Icons.photo_library_outlined,
                                size: 16),
                            label: Text(
                              s.pickFromGallery,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('smart_paste_receipt_btn'),
                        onPressed: _isScanning ? null : _showSmartPasteDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.text_snippet_outlined, size: 15),
                        label: Text(
                          s.smartPasteReceipt,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_isScanning) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.scanningReceipt,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sky,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_receiptBytes != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _receiptBytes!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.receiptAttachedBadge,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _receiptBytes = null;
                              _receiptBase64 = null;
                            }),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.rose,
                            ),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 16),
                            label: Text(
                              s.removePhoto,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_scanFeedback != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: (_scanSuccess
                                  ? AppColors.emerald
                                  : AppColors.amber)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _scanSuccess
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.info_outline_rounded,
                              size: 16,
                              color: _scanSuccess
                                  ? AppColors.emerald
                                  : AppColors.amber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _scanFeedback!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _scanSuccess
                                      ? AppColors.emerald
                                      : AppColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
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
                key: const Key('service_title_field'),
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
                      key: const Key('service_cost_field'),
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
                            selectedColor: AppColors.emerald.withOpacity(0.2),
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
                key: const Key('service_brand_field'),
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: s.partBrandLabel,
                  hintText: s.partBrandHint,
                  prefixIcon: const Icon(
                    Icons.workspace_premium_outlined,
                    size: 20,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.controller.suggestedBrands.take(10).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, idx) {
                    final brand = widget.controller.suggestedBrands[idx];
                    final selected = _brandController.text.trim().toLowerCase() ==
                        brand.toLowerCase();
                    return ChoiceChip(
                      label: Text(brand),
                      selected: selected,
                      visualDensity: VisualDensity.compact,
                      selectedColor: AppColors.racingOrange.withOpacity(0.18),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.racingOrange
                            : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.racingOrange
                            : AppColors.border,
                      ),
                      onSelected: (_) => setState(() {
                        _brandController.text = selected ? '' : brand;
                      }),
                    );
                  },
                ),
              ),
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
      selectedColor: AppColors.racingOrange.withOpacity(0.18),
      labelStyle: TextStyle(
        color: selected ? AppColors.racingOrange : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? AppColors.racingOrange : AppColors.border,
      ),
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
        if (_brandController.text.trim().isEmpty) {
          final detected = BrandDetector.detectFromText(item.name);
          if (detected != null) {
            _brandController.text = detected;
          }
        }
      } else {
        _selectedStockIds.remove(item.id);
      }
      if (!_costManuallyEdited || _costController.text.trim().isEmpty) {
        final stockTotal = allConsumables
            .where((c) => _selectedStockIds.contains(c.id))
            .fold<double>(0, (sum, c) => sum + c.unitPrice);
        if (stockTotal > 0) {
          _costController.text =
              widget.controller.strings.formatEditableAmount(stockTotal);
        } else if (!_costManuallyEdited) {
          _costController.clear();
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final s = widget.controller.strings;
    final odo = int.parse(_odoController.text.trim());
    final rawCost =
        double.parse(_costController.text.trim().replaceAll(',', '.'));
    final cost = s.toBaseIdr(rawCost);
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
      partBrand: _brandController.text.trim(),
      consumedItemIds: _selectedStockIds.toList(),
      receiptImageBase64: _receiptBase64,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
