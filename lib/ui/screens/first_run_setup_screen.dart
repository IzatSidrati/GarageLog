import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/master_profile.dart';
import '../../models/service_entry.dart';
import '../../models/vehicle.dart';
import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';

class FirstRunSetupScreen extends StatefulWidget {
  const FirstRunSetupScreen({
    super.key,
    required this.controller,
  });

  final GarageController controller;

  @override
  State<FirstRunSetupScreen> createState() => _FirstRunSetupScreenState();
}

class _FirstRunSetupScreenState extends State<FirstRunSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Section 1: Master Profile
  final _garageNameCtrl = TextEditingController();
  final _workshopCtrl = TextEditingController();
  String _defaultFuel = 'Pertamax';

  // Section 2: First Vehicle
  VehicleType _vehicleType = VehicleType.motorcycle;
  final _vehicleNameCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _odoCtrl = TextEditingController();
  DateTime _taxDueDate = DateTime.now().add(const Duration(days: 180));

  // Section 3: Default Intervals
  late final TextEditingController _oilKmCtrl;
  late final TextEditingController _oilMonthsCtrl;
  late final TextEditingController _routineKmCtrl;
  late final TextEditingController _routineMonthsCtrl;
  late final TextEditingController _brakesKmCtrl;
  late final TextEditingController _brakesMonthsCtrl;
  bool _createBaselines = true;

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
    final defaults = GarageMasterProfile.defaultsFor(_vehicleType);
    _oilKmCtrl = TextEditingController(text: defaults.oilIntervalKm.toString());
    _oilMonthsCtrl =
        TextEditingController(text: defaults.oilIntervalMonths.toString());
    _routineKmCtrl =
        TextEditingController(text: defaults.routineIntervalKm.toString());
    _routineMonthsCtrl =
        TextEditingController(text: defaults.routineIntervalMonths.toString());
    _brakesKmCtrl =
        TextEditingController(text: defaults.brakesIntervalKm.toString());
    _brakesMonthsCtrl =
        TextEditingController(text: defaults.brakesIntervalMonths.toString());
  }

  @override
  void dispose() {
    _garageNameCtrl.dispose();
    _workshopCtrl.dispose();
    _vehicleNameCtrl.dispose();
    _plateCtrl.dispose();
    _odoCtrl.dispose();
    _oilKmCtrl.dispose();
    _oilMonthsCtrl.dispose();
    _routineKmCtrl.dispose();
    _routineMonthsCtrl.dispose();
    _brakesKmCtrl.dispose();
    _brakesMonthsCtrl.dispose();
    super.dispose();
  }

  void _onVehicleTypeChanged(VehicleType nextType) {
    final oil = ServiceEntry.defaultIntervals(nextType, ServiceCategory.oil);
    final routine =
        ServiceEntry.defaultIntervals(nextType, ServiceCategory.routine);
    final brakes =
        ServiceEntry.defaultIntervals(nextType, ServiceCategory.brakesTires);

    setState(() {
      _vehicleType = nextType;
      _oilKmCtrl.text = oil.km.toString();
      _oilMonthsCtrl.text = oil.months.toString();
      _routineKmCtrl.text = routine.km.toString();
      _routineMonthsCtrl.text = routine.months.toString();
      _brakesKmCtrl.text = brakes.km.toString();
      _brakesMonthsCtrl.text = brakes.months.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final s = ctrl.strings;
    final presets =
        ctrl.language == AppLanguage.id ? _fuelPresetsId : _fuelPresetsEn;
    final allPresets =
        presets.contains(_defaultFuel) ? presets : [_defaultFuel, ...presets];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              // Top Bar: Brand + Quick Language & Currency toggles
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.sky, AppColors.emerald],
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.speed_rounded,
                      color: Color(0xFF04131E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.appTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          s.offlineBadge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _quickPill(
                    key: const Key('setup_currency_toggle'),
                    label: ctrl.currency == AppCurrency.idr ? 'Rp' : '\$',
                    accent: AppColors.emerald,
                    onTap: ctrl.toggleCurrency,
                  ),
                  const SizedBox(width: 6),
                  _quickPill(
                    key: const Key('setup_lang_toggle'),
                    label: ctrl.language == AppLanguage.id ? 'ID' : 'EN',
                    accent: AppColors.sky,
                    onTap: ctrl.toggleLanguage,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Welcome Hero Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF17253B), Color(0xFF0F1929)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.sky.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.setupWelcomeTitle,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.setupWelcomeSubtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Master Garage Profile
              _sectionTitle(s.setupSectionProfile, Icons.garage_rounded),
              const SizedBox(height: 10),
              _cardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: const Key('setup_garage_name_field'),
                      controller: _garageNameCtrl,
                      decoration: InputDecoration(
                        labelText: s.garageNameLabel,
                        hintText: s.t('Contoh: Garasi Izat', 'e.g. Alex Garage'),
                        prefixIcon: const Icon(Icons.home_repair_service_outlined,
                            size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('setup_workshop_field'),
                      controller: _workshopCtrl,
                      decoration: InputDecoration(
                        labelText: s.defaultWorkshopLabel,
                        hintText: s.t(
                          'Contoh: AHASS / Bengkel Resmi',
                          'e.g. Precision Auto Care',
                        ),
                        prefixIcon:
                            const Icon(Icons.storefront_outlined, size: 20),
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
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? AppColors.emerald
                                : AppColors.textSecondary,
                          ),
                          side: BorderSide(
                            color:
                                selected ? AppColors.emerald : AppColors.border,
                          ),
                          onSelected: (_) =>
                              setState(() => _defaultFuel = fuel),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Section 2: First Vehicle
              _sectionTitle(s.setupSectionVehicle, Icons.two_wheeler_rounded),
              const SizedBox(height: 10),
              _cardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _vehicleTypeTile(
                            type: VehicleType.motorcycle,
                            icon: Icons.two_wheeler_rounded,
                            label: s.motorcycle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _vehicleTypeTile(
                            type: VehicleType.car,
                            icon: Icons.directions_car_rounded,
                            label: s.car,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('setup_vehicle_name_field'),
                      controller: _vehicleNameCtrl,
                      decoration: InputDecoration(
                        labelText: s.vehicleNameLabel,
                        hintText: _vehicleType == VehicleType.motorcycle
                            ? 'Honda Vario 160 / Yamaha NMAX'
                            : 'Toyota Avanza / Honda Brio',
                        prefixIcon: Icon(
                          _vehicleType == VehicleType.motorcycle
                              ? Icons.two_wheeler_rounded
                              : Icons.directions_car_rounded,
                          size: 20,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s.requiredField
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const Key('setup_plate_field'),
                            controller: _plateCtrl,
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            key: const Key('setup_odo_field'),
                            controller: _odoCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: s.odometerLabel,
                              hintText: '12500',
                              prefixIcon:
                                  const Icon(Icons.speed_rounded, size: 20),
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
                          prefixIcon: const Icon(
                            Icons.calendar_month_rounded,
                            size: 20,
                          ),
                          suffixIcon: const Icon(
                            Icons.edit_calendar_rounded,
                            size: 18,
                          ),
                        ),
                        child: Text(
                          s.formatDate(_taxDueDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Section 3: Default Maintenance Intervals
              _sectionTitle(
                s.setupSectionIntervals,
                Icons.notifications_active_outlined,
              ),
              const SizedBox(height: 10),
              _cardContainer(
                child: Column(
                  children: [
                    _intervalRow(
                      label: s.catOil,
                      icon: Icons.oil_barrel_rounded,
                      color: AppColors.amber,
                      kmCtrl: _oilKmCtrl,
                      monthsCtrl: _oilMonthsCtrl,
                      s: s,
                    ),
                    const SizedBox(height: 10),
                    _intervalRow(
                      label: s.catRoutine,
                      icon: Icons.settings_suggest_rounded,
                      color: AppColors.sky,
                      kmCtrl: _routineKmCtrl,
                      monthsCtrl: _routineMonthsCtrl,
                      s: s,
                    ),
                    const SizedBox(height: 10),
                    _intervalRow(
                      label: s.catBrakesTires,
                      icon: Icons.tire_repair_rounded,
                      color: AppColors.emerald,
                      kmCtrl: _brakesKmCtrl,
                      monthsCtrl: _brakesMonthsCtrl,
                      s: s,
                    ),
                    const Divider(height: 22),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _createBaselines,
                      activeColor: AppColors.emerald,
                      title: Text(
                        s.baselineToggleTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        s.baselineToggleSubtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => _createBaselines = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('setup_submit_btn'),
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: const Color(0xFF022016),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 19),
                  label: Text(s.startUsingApp),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('setup_demo_btn'),
                  onPressed: () => ctrl.loadDemoAndCompleteSetup(),
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: Text(s.useDemoDataCta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.sky),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _cardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _vehicleTypeTile({
    required VehicleType type,
    required IconData icon,
    required String label,
  }) {
    final selected = _vehicleType == type;
    return InkWell(
      onTap: () => _onVehicleTypeChanged(type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sky.withOpacity(0.16)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.sky : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? AppColors.sky : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.sky : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intervalRow({
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController kmCtrl,
    required TextEditingController monthsCtrl,
    required AppStrings s,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: kmCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              suffixText: 'km',
              hintText: s.intervalKmHint,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: monthsCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              suffixText: s.t('bln', 'mo'),
              hintText: s.intervalMonthHint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickPill({
    Key? key,
    required String label,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withOpacity(0.45)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
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

    final profile = GarageMasterProfile(
      garageName: _garageNameCtrl.text.trim(),
      defaultWorkshop: _workshopCtrl.text.trim(),
      defaultFuelType: _defaultFuel,
      oilIntervalKm: int.tryParse(_oilKmCtrl.text.trim()) ?? 2000,
      oilIntervalMonths: int.tryParse(_oilMonthsCtrl.text.trim()) ?? 2,
      routineIntervalKm: int.tryParse(_routineKmCtrl.text.trim()) ?? 4000,
      routineIntervalMonths: int.tryParse(_routineMonthsCtrl.text.trim()) ?? 4,
      brakesIntervalKm: int.tryParse(_brakesKmCtrl.text.trim()) ?? 8000,
      brakesIntervalMonths: int.tryParse(_brakesMonthsCtrl.text.trim()) ?? 8,
    );

    await widget.controller.completeInitialSetup(
      profile: profile,
      vehicleName: _vehicleNameCtrl.text.trim(),
      plateNumber: _plateCtrl.text.trim(),
      vehicleType: _vehicleType,
      odometerKm: int.parse(_odoCtrl.text.trim()),
      taxDueDate: _taxDueDate,
      createServiceBaselines: _createBaselines,
    );
  }
}
