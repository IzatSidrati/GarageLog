import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../models/fuel_entry.dart';
import '../models/garage_item.dart';
import '../models/health_status.dart';
import '../models/master_profile.dart';
import '../models/service_entry.dart';
import '../models/vehicle.dart';
import '../services/brand_detector.dart';
import '../services/reminder_notification_service.dart';

class GarageController extends ChangeNotifier {
  GarageController({SharedPreferences? prefs}) : _prefs = prefs;

  static const int freeInventoryLimit = 5;

  static const _kInitialized = 'garagelog_initialized_v1';
  static const _kSetupCompleted = 'garagelog_setup_completed_v1';
  static const _kMasterProfile = 'garagelog_master_profile_v1';
  static const _kVehicles = 'garagelog_vehicles_v1';
  static const _kFuelEntries = 'garagelog_fuel_v1';
  static const _kServiceEntries = 'garagelog_service_v1';
  static const _kInventoryItems = 'garagelog_inventory_v1';
  static const _kSelectedVehicleId = 'garagelog_selected_vehicle_v1';
  static const _kLanguage = 'garagelog_language_v1';
  static const _kCurrency = 'garagelog_currency_v1';
  static const _kProUnlocked = 'garagelog_pro_unlocked_v1';
  static const _kNotificationsEnabled = 'garagelog_notif_enabled_v1';

  SharedPreferences? _prefs;
  bool _loaded = false;
  bool _setupCompleted = false;

  GarageMasterProfile _masterProfile = const GarageMasterProfile();
  List<Vehicle> _vehicles = [];
  List<FuelEntry> _fuelEntries = [];
  List<ServiceEntry> _serviceEntries = [];
  List<GarageInventoryItem> _inventoryItems = [];
  String? _selectedVehicleId;
  AppLanguage _language = AppLanguage.id;
  AppCurrency _currency = AppCurrency.idr;
  bool _isProUnlocked = false;
  bool _notificationsEnabled = true;

  bool get isLoaded => _loaded;
  bool get isSetupCompleted => _setupCompleted;
  bool get needsInitialSetup => _loaded && !_setupCompleted;
  bool get notificationsEnabled => _notificationsEnabled;
  GarageMasterProfile get masterProfile => _masterProfile;
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  List<FuelEntry> get allFuelEntries => List.unmodifiable(_fuelEntries);
  List<ServiceEntry> get allServiceEntries => List.unmodifiable(_serviceEntries);
  List<GarageInventoryItem> get inventoryItems =>
      List.unmodifiable(_inventoryItems);
  List<GarageInventoryItem> get availableConsumables => _inventoryItems
      .where((i) => i.isConsumable && i.quantity > 0)
      .toList();
  AppLanguage get language => _language;
  AppCurrency get currency => _currency;
  bool get isProUnlocked => _isProUnlocked;
  AppStrings get strings => AppStrings(
        _language,
        _currency,
        usdRateIdr: _masterProfile.usdRateIdr,
      );

  bool get canAddMoreVehicles => _isProUnlocked || _vehicles.isEmpty;
  bool get canAddMoreInventory =>
      _isProUnlocked || _inventoryItems.length < freeInventoryLimit;

  Vehicle? get activeVehicle {
    if (_vehicles.isEmpty) return null;
    if (_selectedVehicleId != null) {
      for (final v in _vehicles) {
        if (v.id == _selectedVehicleId) return v;
      }
    }
    return _vehicles.first;
  }

  Future<void> init({DateTime? now, bool seedDemoIfFresh = false}) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;

    final langStr = prefs.getString(_kLanguage);
    if (langStr != null) {
      _language = AppLanguage.values.firstWhere(
        (e) => e.name == langStr,
        orElse: () => AppLanguage.id,
      );
    }

    final currStr = prefs.getString(_kCurrency);
    if (currStr != null) {
      _currency = AppCurrency.values.firstWhere(
        (e) => e.name == currStr,
        orElse: () => AppCurrency.idr,
      );
    }

    _isProUnlocked = prefs.getBool(_kProUnlocked) ?? false;
    _notificationsEnabled = prefs.getBool(_kNotificationsEnabled) ?? true;
    final initialized = prefs.getBool(_kInitialized) ?? false;

    if (!initialized) {
      if (seedDemoIfFresh) {
        _seedSampleData(now: now ?? DateTime.now());
        _setupCompleted = true;
        await _persistAll();
      } else {
        _setupCompleted = false;
      }
    } else {
      _loadFromPrefs(prefs);
      _setupCompleted = prefs.getBool(_kSetupCompleted) ?? true;
    }

    _loaded = true;
    notifyListeners();
  }

  void _loadFromPrefs(SharedPreferences prefs) {
    final mRaw = prefs.getString(_kMasterProfile);
    if (mRaw != null && mRaw.isNotEmpty) {
      _masterProfile = GarageMasterProfile.fromJson(
        jsonDecode(mRaw) as Map<String, dynamic>,
      );
    }

    final vRaw = prefs.getString(_kVehicles);
    if (vRaw != null && vRaw.isNotEmpty) {
      final decoded = jsonDecode(vRaw) as List<dynamic>;
      _vehicles = decoded
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final fRaw = prefs.getString(_kFuelEntries);
    if (fRaw != null && fRaw.isNotEmpty) {
      final decoded = jsonDecode(fRaw) as List<dynamic>;
      _fuelEntries = decoded
          .map((e) => FuelEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final sRaw = prefs.getString(_kServiceEntries);
    if (sRaw != null && sRaw.isNotEmpty) {
      final decoded = jsonDecode(sRaw) as List<dynamic>;
      _serviceEntries = decoded
          .map((e) => ServiceEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final iRaw = prefs.getString(_kInventoryItems);
    if (iRaw != null && iRaw.isNotEmpty) {
      final decoded = jsonDecode(iRaw) as List<dynamic>;
      _inventoryItems = decoded
          .map((e) => GarageInventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    _selectedVehicleId = prefs.getString(_kSelectedVehicleId);
    if (_vehicles.isNotEmpty &&
        !_vehicles.any((v) => v.id == _selectedVehicleId)) {
      _selectedVehicleId = _vehicles.first.id;
    }
  }

  void _seedSampleData({required DateTime now}) {
    final today = DateTime(now.year, now.month, now.day);
    const sampleVehicleId = 'veh_vario_160';

    _masterProfile = const GarageMasterProfile(
      garageName: 'Garasi Pribadi',
      defaultWorkshop: 'AHASS Motor Mandiri',
      defaultFuelType: 'Pertamax',
      oilIntervalKm: 2000,
      oilIntervalMonths: 2,
      routineIntervalKm: 4000,
      routineIntervalMonths: 4,
      brakesIntervalKm: 8000,
      brakesIntervalMonths: 8,
    );

    _vehicles = [
      Vehicle(
        id: sampleVehicleId,
        name: 'Honda Vario 160 ABS',
        plateNumber: 'B 4821 KGL',
        type: VehicleType.motorcycle,
        odometerKm: 14680,
        taxDueDate: today.add(const Duration(days: 22)),
        createdAt: today.subtract(const Duration(days: 120)),
      ),
    ];
    _selectedVehicleId = sampleVehicleId;

    _fuelEntries = [
      FuelEntry(
        id: 'fuel_1',
        vehicleId: sampleVehicleId,
        date: today.subtract(const Duration(days: 38)),
        odometerKm: 13840,
        liters: 4.5,
        totalCost: 58500,
        fuelType: 'Pertamax',
      ),
      FuelEntry(
        id: 'fuel_2',
        vehicleId: sampleVehicleId,
        date: today.subtract(const Duration(days: 29)),
        odometerKm: 14038,
        liters: 4.6,
        totalCost: 59800,
        fuelType: 'Pertamax',
      ),
      FuelEntry(
        id: 'fuel_3',
        vehicleId: sampleVehicleId,
        date: today.subtract(const Duration(days: 19)),
        odometerKm: 14232,
        liters: 4.7,
        totalCost: 61100,
        fuelType: 'Pertamax',
      ),
      FuelEntry(
        id: 'fuel_4',
        vehicleId: sampleVehicleId,
        date: today.subtract(const Duration(days: 9)),
        odometerKm: 14450,
        liters: 4.8,
        totalCost: 62400,
        fuelType: 'Pertamax',
      ),
      FuelEntry(
        id: 'fuel_5',
        vehicleId: sampleVehicleId,
        date: today.subtract(const Duration(days: 2)),
        odometerKm: 14665,
        liters: 4.5,
        totalCost: 58500,
        fuelType: 'Pertamax',
      ),
    ];

    _serviceEntries = [
      ServiceEntry(
        id: 'srv_1',
        vehicleId: sampleVehicleId,
        date: today.subtract(const Duration(days: 54)),
        odometerKm: 12850,
        category: ServiceCategory.oil,
        title: 'Ganti Oli Mesin + Oli Gardan',
        cost: 115000,
        workshop: 'AHASS Motor Mandiri',
        nextIntervalKm: 2000,
        nextIntervalMonths: 2,
        notes: 'SPX2 0.8L + Gear Oil',
        partBrand: 'AHM Oil',
      ),
      ServiceEntry(
        id: 'srv_2',
        vehicleId: sampleVehicleId,
        date: today.subtract(const Duration(days: 35)),
        odometerKm: 13600,
        category: ServiceCategory.routine,
        title: 'Servis CVT & Bersihkan Throttle Body',
        cost: 165000,
        workshop: 'AHASS Motor Mandiri',
        nextIntervalKm: 4000,
        nextIntervalMonths: 4,
        notes: 'Roller & V-Belt masih aman 80%',
        partBrand: 'Daytona',
      ),
      ServiceEntry(
        id: 'srv_3',
        vehicleId: sampleVehicleId,
        date: today.subtract(const Duration(days: 80)),
        odometerKm: 11500,
        category: ServiceCategory.brakesTires,
        title: 'Ganti Kampas Rem Depan & Cek Tekanan Ban',
        cost: 135000,
        workshop: 'Planet Ban & Rem',
        nextIntervalKm: 8000,
        nextIntervalMonths: 8,
        notes: 'Kampas original, ban depan/belakang tebal',
        partBrand: 'Nissin',
      ),
      ServiceEntry(
        id: 'srv_4',
        vehicleId: sampleVehicleId,
        date: today.subtract(const Duration(days: 105)),
        odometerKm: 10900,
        category: ServiceCategory.oil,
        title: 'Ganti Oli Mesin Rutin',
        cost: 75000,
        workshop: 'AHASS Motor Mandiri',
        nextIntervalKm: 2000,
        nextIntervalMonths: 2,
        notes: 'SPX2 0.8L',
        partBrand: 'AHM Oil',
      ),
    ];

    _inventoryItems = [
      const GarageInventoryItem(
        id: 'inv_1',
        name: 'Oli Mesin SPX2 0.8L',
        type: InventoryType.consumable,
        quantity: 2,
        minQuantity: 1,
        unit: 'botol',
        unitPrice: 68000,
        location: 'Rak Oli A1',
        notes: 'Stok cadangan ganti oli mandiri',
      ),
      const GarageInventoryItem(
        id: 'inv_2',
        name: 'Chain Lube & Brake Cleaner',
        type: InventoryType.consumable,
        quantity: 1,
        minQuantity: 1,
        unit: 'kaleng',
        unitPrice: 45000,
        location: 'Rak Cairan A2',
      ),
      const GarageInventoryItem(
        id: 'inv_3',
        name: 'Kunci Sok Set 8–24mm',
        type: InventoryType.tool,
        quantity: 1,
        minQuantity: 1,
        unit: 'set',
        location: 'Toolbox Utama',
        notes: 'Lengkap ratchet + extension bar',
      ),
    ];
  }

  Future<void> resetSampleData({DateTime? now}) async {
    _seedSampleData(now: now ?? DateTime.now());
    _setupCompleted = true;
    await _persistAll();
    notifyListeners();
  }

  Future<void> loadDemoAndCompleteSetup({DateTime? now}) async {
    await resetSampleData(now: now);
  }

  Future<void> completeInitialSetup({
    required GarageMasterProfile profile,
    required String vehicleName,
    required String plateNumber,
    required VehicleType vehicleType,
    required int odometerKm,
    required DateTime taxDueDate,
    bool createServiceBaselines = false,
    DateTime? now,
  }) async {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    _masterProfile = profile;

    final firstVehicle = Vehicle(
      id: _newId('veh'),
      name: vehicleName.trim(),
      plateNumber: plateNumber.trim().toUpperCase(),
      type: vehicleType,
      odometerKm: odometerKm,
      taxDueDate: DateTime(taxDueDate.year, taxDueDate.month, taxDueDate.day),
      createdAt: ref,
    );

    _vehicles = [firstVehicle];
    _selectedVehicleId = firstVehicle.id;
    _fuelEntries = [];
    _inventoryItems = [];

    if (createServiceBaselines) {
      final s = strings;
      _serviceEntries = [
        ServiceEntry(
          id: '${_newId('srv')}_oil',
          vehicleId: firstVehicle.id,
          date: today,
          odometerKm: odometerKm,
          category: ServiceCategory.oil,
          title: '${s.initialBaselineTitle} — ${s.catOil}',
          cost: 0,
          workshop: profile.defaultWorkshop,
          nextIntervalKm: profile.oilIntervalKm,
          nextIntervalMonths: profile.oilIntervalMonths,
        ),
        ServiceEntry(
          id: '${_newId('srv')}_routine',
          vehicleId: firstVehicle.id,
          date: today,
          odometerKm: odometerKm,
          category: ServiceCategory.routine,
          title: '${s.initialBaselineTitle} — ${s.catRoutine}',
          cost: 0,
          workshop: profile.defaultWorkshop,
          nextIntervalKm: profile.routineIntervalKm,
          nextIntervalMonths: profile.routineIntervalMonths,
        ),
        ServiceEntry(
          id: '${_newId('srv')}_brakes',
          vehicleId: firstVehicle.id,
          date: today,
          odometerKm: odometerKm,
          category: ServiceCategory.brakesTires,
          title: '${s.initialBaselineTitle} — ${s.catBrakesTires}',
          cost: 0,
          workshop: profile.defaultWorkshop,
          nextIntervalKm: profile.brakesIntervalKm,
          nextIntervalMonths: profile.brakesIntervalMonths,
        ),
      ];
    } else {
      _serviceEntries = [];
    }

    _setupCompleted = true;
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateMasterProfile(GarageMasterProfile profile) async {
    _masterProfile = profile;
    await _persistAll();
    notifyListeners();
  }

  Future<void> _persistAll() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(_kInitialized, true);
    await prefs.setBool(_kSetupCompleted, _setupCompleted);
    await prefs.setString(_kMasterProfile, jsonEncode(_masterProfile.toJson()));
    await prefs.setString(
      _kVehicles,
      jsonEncode(_vehicles.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _kFuelEntries,
      jsonEncode(_fuelEntries.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _kServiceEntries,
      jsonEncode(_serviceEntries.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _kInventoryItems,
      jsonEncode(_inventoryItems.map((e) => e.toJson()).toList()),
    );
    if (_selectedVehicleId != null) {
      await prefs.setString(_kSelectedVehicleId, _selectedVehicleId!);
    } else {
      await prefs.remove(_kSelectedVehicleId);
    }
    await prefs.setString(_kLanguage, _language.name);
    await prefs.setString(_kCurrency, _currency.name);
    await prefs.setBool(_kProUnlocked, _isProUnlocked);
    await prefs.setBool(_kNotificationsEnabled, _notificationsEnabled);

    await ReminderNotificationService.syncReminders(
      enabled: _notificationsEnabled,
      reminders: buildUpcomingReminders(),
    );
  }

  // Preferences
  Future<void> toggleLanguage() async {
    _language =
        _language == AppLanguage.id ? AppLanguage.en : AppLanguage.id;
    await _persistAll();
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    await _persistAll();
    notifyListeners();
  }

  Future<void> toggleCurrency() async {
    _currency =
        _currency == AppCurrency.idr ? AppCurrency.usd : AppCurrency.idr;
    await _persistAll();
    notifyListeners();
  }

  Future<void> setCurrency(AppCurrency curr) async {
    if (_currency == curr) return;
    _currency = curr;
    await _persistAll();
    notifyListeners();
  }

  Future<void> setProUnlocked(bool unlocked) async {
    _isProUnlocked = unlocked;
    await _persistAll();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    if (enabled) {
      await ReminderNotificationService.initAndRequestPermission();
    }
    await _persistAll();
    notifyListeners();
  }

  /// Builds all upcoming offline push notifications (STNK H-14/H-3 & Service H-3).
  List<ScheduledReminderItem> buildUpcomingReminders({DateTime? now}) {
    final ref = now ?? DateTime.now();
    final s = strings;
    final list = <ScheduledReminderItem>[];
    int nextId = 1000;

    for (final vehicle in _vehicles) {
      final taxDate = DateTime(
        vehicle.taxDueDate.year,
        vehicle.taxDueDate.month,
        vehicle.taxDueDate.day,
        9,
        0,
      );

      for (final leadDays in [14, 3]) {
        final fireAt = taxDate.subtract(Duration(days: leadDays));
        if (fireAt.isAfter(ref)) {
          list.add(
            ScheduledReminderItem(
              id: nextId++,
              vehicleName: vehicle.name,
              scheduledAt: fireAt,
              title: s.t(
                'Pengingat Pajak STNK (${vehicle.plateNumber})',
                'Vehicle Tax Reminder (${vehicle.plateNumber})',
              ),
              body: s.t(
                '${vehicle.name} jatuh tempo pajak $leadDays hari lagi (${s.formatDate(taxDate)}).',
                '${vehicle.name} tax is due in $leadDays days (${s.formatDate(taxDate)}).',
              ),
            ),
          );
        }
      }

      final health = computeHealthItems(vehicle, now: ref);
      for (final item in health) {
        if (item.isTax || item.nextDueDate == null) continue;
        final dueDate = DateTime(
          item.nextDueDate!.year,
          item.nextDueDate!.month,
          item.nextDueDate!.day,
          9,
          0,
        );
        final fireAt = dueDate.subtract(const Duration(days: 3));
        if (fireAt.isAfter(ref)) {
          final catName =
              _categoryLabel(item.category ?? ServiceCategory.other, s);
          list.add(
            ScheduledReminderItem(
              id: nextId++,
              vehicleName: vehicle.name,
              scheduledAt: fireAt,
              title: s.t(
                'Jadwal $catName — ${vehicle.name}',
                '$catName Due Soon — ${vehicle.name}',
              ),
              body: s.t(
                '3 hari lagi jadwal $catName (${s.formatDate(dueDate)}). Siapkan servis di bengkel langganan.',
                '$catName is due in 3 days (${s.formatDate(dueDate)}).',
              ),
            ),
          );
        }
      }
    }

    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  /// Sends an immediate contextual reminder notification (for user testing).
  Future<NotificationDispatchResult> triggerTestReminderNotification({
    DateTime? now,
  }) async {
    final s = strings;
    final vehicle = activeVehicle;
    String title = s.t(
      'Pengingat Servis GarageLog',
      'GarageLog Maintenance Alert',
    );
    String body = s.t(
      'Notifikasi pengingat offline aktif! Anda akan diingatkan otomatis sebelum jadwal servis & pajak STNK.',
      'Offline reminder notifications are active! You will be alerted before service & tax due dates.',
    );

    if (vehicle != null) {
      final health = computeHealthItems(vehicle, now: now);
      final urgent = health.where(
        (h) => h.level == HealthLevel.overdue || h.level == HealthLevel.soon,
      );
      if (urgent.isNotEmpty) {
        final top = urgent.first;
        final label = _healthLabel(top, s);
        title = s.t(
          '$label • ${vehicle.name}',
          '$label • ${vehicle.name}',
        );
        if (top.isTax && top.daysRemaining != null) {
          body = top.daysRemaining! >= 0
              ? s.t(
                  'Pajak STNK (${vehicle.plateNumber}) jatuh tempo ${top.daysRemaining} hari lagi (${s.formatDate(top.nextDueDate!)}).',
                  'Tax (${vehicle.plateNumber}) is due in ${top.daysRemaining} days (${s.formatDate(top.nextDueDate!)}).',
                )
              : s.t(
                  'Pajak STNK (${vehicle.plateNumber}) sudah lewat ${top.daysRemaining!.abs()} hari!',
                  'Tax (${vehicle.plateNumber}) is overdue by ${top.daysRemaining!.abs()} days!',
                );
        } else if (top.kmRemaining != null) {
          body = top.kmRemaining! >= 0
              ? s.t(
                  'Sisa ${s.formatKm(top.kmRemaining!)} menuju jadwal $label berikutnya.',
                  '${s.formatKm(top.kmRemaining!)} left until your next $label.',
                )
              : s.t(
                  'Jadwal $label sudah lewat ${s.formatKm(top.kmRemaining!.abs())}. Segera servis!',
                  '$label is overdue by ${s.formatKm(top.kmRemaining!.abs())}. Service recommended!',
                );
        }
      } else {
        title = s.t(
          'Semua Aman • ${vehicle.name}',
          'All Healthy • ${vehicle.name}',
        );
        body = s.t(
          'Odometer ${s.formatKm(vehicle.odometerKm)} • Pajak STNK ${s.formatDate(vehicle.taxDueDate)}. Pengingat offline aktif!',
          'Odometer ${s.formatKm(vehicle.odometerKm)} • Tax due ${s.formatDate(vehicle.taxDueDate)}. Offline alerts ready!',
        );
      }
    }

    return ReminderNotificationService.sendTestNotification(
      title: title,
      body: body,
    );
  }

  // Vehicles
  Future<void> selectVehicle(String id) async {
    if (!_vehicles.any((v) => v.id == id)) return;
    _selectedVehicleId = id;
    await _persistAll();
    notifyListeners();
  }

  Future<bool> addVehicle({
    required String name,
    required String plateNumber,
    required VehicleType type,
    required int odometerKm,
    required DateTime taxDueDate,
  }) async {
    if (!canAddMoreVehicles) return false;
    final vehicle = Vehicle(
      id: _newId('veh'),
      name: name.trim(),
      plateNumber: plateNumber.trim().toUpperCase(),
      type: type,
      odometerKm: odometerKm,
      taxDueDate: DateTime(taxDueDate.year, taxDueDate.month, taxDueDate.day),
      createdAt: DateTime.now(),
    );
    _vehicles = [..._vehicles, vehicle];
    _selectedVehicleId = vehicle.id;
    await _persistAll();
    notifyListeners();
    return true;
  }

  Future<void> updateVehicle(Vehicle updated) async {
    _vehicles = _vehicles.map((v) => v.id == updated.id ? updated : v).toList();
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateActiveOdometer(int newOdometerKm) async {
    final current = activeVehicle;
    if (current == null || newOdometerKm < 0) return;
    await updateVehicle(current.copyWith(odometerKm: newOdometerKm));
  }

  Future<void> deleteVehicle(String vehicleId) async {
    _vehicles = _vehicles.where((v) => v.id != vehicleId).toList();
    _fuelEntries = _fuelEntries.where((f) => f.vehicleId != vehicleId).toList();
    _serviceEntries =
        _serviceEntries.where((s) => s.vehicleId != vehicleId).toList();
    if (_selectedVehicleId == vehicleId) {
      _selectedVehicleId = _vehicles.isNotEmpty ? _vehicles.first.id : null;
    }
    await _persistAll();
    notifyListeners();
  }

  // Fuel Entries
  List<FuelEntry> fuelEntriesFor(String vehicleId) {
    final list = _fuelEntries.where((f) => f.vehicleId == vehicleId).toList();
    list.sort((a, b) {
      final odoCmp = b.odometerKm.compareTo(a.odometerKm);
      if (odoCmp != 0) return odoCmp;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  Future<void> addFuelEntry({
    required String vehicleId,
    required int odometerKm,
    required double liters,
    required double totalCost,
    required String fuelType,
    DateTime? date,
    String notes = '',
  }) async {
    final entry = FuelEntry(
      id: _newId('fuel'),
      vehicleId: vehicleId,
      date: date ?? DateTime.now(),
      odometerKm: odometerKm,
      liters: liters,
      totalCost: totalCost,
      fuelType: fuelType.trim(),
      notes: notes.trim(),
    );
    _fuelEntries = [..._fuelEntries, entry];

    // Auto-bump vehicle odometer if this fill is higher.
    _vehicles = _vehicles.map((v) {
      if (v.id == vehicleId && odometerKm > v.odometerKm) {
        return v.copyWith(odometerKm: odometerKm);
      }
      return v;
    }).toList();

    await _persistAll();
    notifyListeners();
  }

  Future<void> deleteFuelEntry(String id) async {
    _fuelEntries = _fuelEntries.where((f) => f.id != id).toList();
    await _persistAll();
    notifyListeners();
  }

  // Service Entries
  List<ServiceEntry> serviceEntriesFor(String vehicleId) {
    final list =
        _serviceEntries.where((s) => s.vehicleId == vehicleId).toList();
    list.sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      return b.odometerKm.compareTo(a.odometerKm);
    });
    return list;
  }

  Future<void> addServiceEntry({
    required String vehicleId,
    required ServiceCategory category,
    required String title,
    required int odometerKm,
    required double cost,
    String workshop = '',
    int nextIntervalKm = 0,
    int nextIntervalMonths = 0,
    DateTime? date,
    String notes = '',
    String partBrand = '',
    List<String> consumedItemIds = const [],
    String? receiptImageBase64,
  }) async {
    final usedNames = <String>[];
    if (consumedItemIds.isNotEmpty) {
      final consumedSet = consumedItemIds.toSet();
      _inventoryItems = _inventoryItems.map((item) {
        if (consumedSet.contains(item.id) &&
            item.isConsumable &&
            item.quantity > 0) {
          usedNames.add(item.name);
          return item.copyWith(quantity: math.max(0, item.quantity - 1));
        }
        return item;
      }).toList();
    }

    final stockNote = usedNames.isNotEmpty
        ? '[${strings.t('Stok terpakai', 'Stock used')}: ${usedNames.join(', ')}]'
        : '';
    final combinedNotes = [notes.trim(), stockNote]
        .where((part) => part.isNotEmpty)
        .join('\n');

    final resolvedBrand = partBrand.trim().isNotEmpty
        ? partBrand.trim()
        : (BrandDetector.detectFromText('$title $combinedNotes') ?? '');

    final entry = ServiceEntry(
      id: _newId('srv'),
      vehicleId: vehicleId,
      date: date ?? DateTime.now(),
      odometerKm: odometerKm,
      category: category,
      title: title.trim(),
      cost: cost,
      workshop: workshop.trim(),
      nextIntervalKm: nextIntervalKm,
      nextIntervalMonths: nextIntervalMonths,
      notes: combinedNotes,
      partBrand: resolvedBrand,
      receiptImageBase64: receiptImageBase64,
    );
    _serviceEntries = [..._serviceEntries, entry];

    // Auto-bump vehicle odometer if this service odometer is higher.
    _vehicles = _vehicles.map((v) {
      if (v.id == vehicleId && odometerKm > v.odometerKm) {
        return v.copyWith(odometerKm: odometerKm);
      }
      return v;
    }).toList();

    await _persistAll();
    notifyListeners();
  }

  Future<void> deleteServiceEntry(String id) async {
    _serviceEntries = _serviceEntries.where((s) => s.id != id).toList();
    await _persistAll();
    notifyListeners();
  }

  // Garage Inventory (Stock & Tools)
  Future<bool> addInventoryItem({
    required String name,
    required InventoryType type,
    required int quantity,
    int minQuantity = 1,
    String unit = 'pcs',
    double unitPrice = 0,
    String location = '',
    String notes = '',
  }) async {
    if (!canAddMoreInventory) return false;
    final item = GarageInventoryItem(
      id: _newId('inv'),
      name: name.trim(),
      type: type,
      quantity: math.max(0, quantity),
      minQuantity: math.max(0, minQuantity),
      unit: unit.trim().isEmpty ? 'pcs' : unit.trim(),
      unitPrice: math.max(0, unitPrice),
      location: location.trim(),
      notes: notes.trim(),
    );
    _inventoryItems = [..._inventoryItems, item];
    await _persistAll();
    notifyListeners();
    return true;
  }

  Future<void> updateInventoryItem(GarageInventoryItem updated) async {
    _inventoryItems = _inventoryItems
        .map((i) => i.id == updated.id ? updated : i)
        .toList();
    await _persistAll();
    notifyListeners();
  }

  Future<void> adjustInventoryQuantity(String id, int delta) async {
    _inventoryItems = _inventoryItems.map((i) {
      if (i.id == id) {
        return i.copyWith(quantity: math.max(0, i.quantity + delta));
      }
      return i;
    }).toList();
    await _persistAll();
    notifyListeners();
  }

  Future<void> loanTool(String id, String borrowerName, {DateTime? now}) async {
    final trimmed = borrowerName.trim();
    if (trimmed.isEmpty) return;
    _inventoryItems = _inventoryItems.map((i) {
      if (i.id == id && i.isTool) {
        return i.copyWith(
          borrowedBy: trimmed,
          borrowedDate: now ?? DateTime.now(),
        );
      }
      return i;
    }).toList();
    await _persistAll();
    notifyListeners();
  }

  Future<void> returnTool(String id) async {
    _inventoryItems = _inventoryItems.map((i) {
      if (i.id == id && i.isTool) {
        return i.copyWith(
          borrowedBy: '',
          clearBorrowedDate: true,
        );
      }
      return i;
    }).toList();
    await _persistAll();
    notifyListeners();
  }

  Future<void> deleteInventoryItem(String id) async {
    _inventoryItems = _inventoryItems.where((i) => i.id != id).toList();
    await _persistAll();
    notifyListeners();
  }

  // Offline Backup & Restore (.json)
  String exportBackupJson({DateTime? now}) {
    final payload = {
      'app': 'GarageLog',
      'schemaVersion': 1,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'language': _language.name,
      'currency': _currency.name,
      'masterProfile': _masterProfile.toJson(),
      'selectedVehicleId': _selectedVehicleId,
      'vehicles': _vehicles.map((e) => e.toJson()).toList(),
      'fuelEntries': _fuelEntries.map((e) => e.toJson()).toList(),
      'serviceEntries': _serviceEntries.map((e) => e.toJson()).toList(),
      'inventoryItems': _inventoryItems.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<bool> importBackupJson(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson.trim());
      if (decoded is! Map<String, dynamic>) return false;
      if (decoded['app'] != 'GarageLog') return false;

      final vList = decoded['vehicles'];
      final fList = decoded['fuelEntries'];
      final sList = decoded['serviceEntries'];
      final iList = decoded['inventoryItems'];
      if (vList is! List || fList is! List || sList is! List) return false;

      final parsedVehicles = vList
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList();
      final parsedFuel = fList
          .map((e) => FuelEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final parsedServices = sList
          .map((e) => ServiceEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final parsedInventory = iList is List
          ? iList
              .map(
                (e) => GarageInventoryItem.fromJson(e as Map<String, dynamic>),
              )
              .toList()
          : <GarageInventoryItem>[];

      if (decoded['masterProfile'] is Map<String, dynamic>) {
        _masterProfile = GarageMasterProfile.fromJson(
          decoded['masterProfile'] as Map<String, dynamic>,
        );
      }

      _vehicles = parsedVehicles;
      _fuelEntries = parsedFuel;
      _serviceEntries = parsedServices;
      _inventoryItems = parsedInventory;
      _setupCompleted = true;

      final langStr = decoded['language'] as String?;
      if (langStr != null) {
        _language = AppLanguage.values.firstWhere(
          (e) => e.name == langStr,
          orElse: () => _language,
        );
      }
      final currStr = decoded['currency'] as String?;
      if (currStr != null) {
        _currency = AppCurrency.values.firstWhere(
          (e) => e.name == currStr,
          orElse: () => _currency,
        );
      }

      final selId = decoded['selectedVehicleId'] as String?;
      if (selId != null && _vehicles.any((v) => v.id == selId)) {
        _selectedVehicleId = selId;
      } else {
        _selectedVehicleId = _vehicles.isNotEmpty ? _vehicles.first.id : null;
      }

      await _persistAll();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Analytics & Health Calculations
  FuelAnalytics computeFuelAnalytics(String vehicleId) {
    final entries =
        _fuelEntries.where((f) => f.vehicleId == vehicleId).toList();
    if (entries.isEmpty) {
      return const FuelAnalytics(
        computedDescending: [],
        trendPoints: [],
        avgKmPerLiter: null,
        avgCostPerKm: null,
        latestKmPerLiter: null,
        trend: EfficiencyTrend.none,
        trendDeltaPercent: 0,
      );
    }

    // Sort ascending by odometer then date to compute intervals.
    entries.sort((a, b) {
      final odoCmp = a.odometerKm.compareTo(b.odometerKm);
      if (odoCmp != 0) return odoCmp;
      return a.date.compareTo(b.date);
    });

    final computedAsc = <FuelComputedEntry>[];
    int totalDistance = 0;
    double totalLitersForDistance = 0;
    double totalCostForDistance = 0;

    for (int i = 0; i < entries.length; i++) {
      final current = entries[i];
      if (i == 0) {
        computedAsc.add(FuelComputedEntry(entry: current));
        continue;
      }
      final prev = entries[i - 1];
      final deltaKm = current.odometerKm - prev.odometerKm;
      if (deltaKm > 0 && current.liters > 0) {
        final kmPerL = deltaKm / current.liters;
        final costPerKm = current.totalCost / deltaKm;
        totalDistance += deltaKm;
        totalLitersForDistance += current.liters;
        totalCostForDistance += current.totalCost;
        computedAsc.add(
          FuelComputedEntry(
            entry: current,
            distanceKm: deltaKm,
            kmPerLiter: kmPerL,
            costPerKm: costPerKm,
          ),
        );
      } else {
        computedAsc.add(FuelComputedEntry(entry: current));
      }
    }

    final trendPoints =
        computedAsc.where((c) => c.kmPerLiter != null).toList();
    final double? avgKmPerL = totalLitersForDistance > 0
        ? totalDistance / totalLitersForDistance
        : null;
    final double? avgCostPerKm =
        totalDistance > 0 ? totalCostForDistance / totalDistance : null;
    final double? latestKmPerL =
        trendPoints.isNotEmpty ? trendPoints.last.kmPerLiter : null;

    EfficiencyTrend trend = EfficiencyTrend.none;
    double deltaPct = 0;
    if (avgKmPerL != null && latestKmPerL != null && trendPoints.length >= 2) {
      deltaPct = ((latestKmPerL - avgKmPerL) / avgKmPerL) * 100;
      if (deltaPct >= 3.0) {
        trend = EfficiencyTrend.efficient;
      } else if (deltaPct <= -3.0) {
        trend = EfficiencyTrend.heavy;
      } else {
        trend = EfficiencyTrend.steady;
      }
    } else if (latestKmPerL != null) {
      trend = EfficiencyTrend.steady;
    }

    return FuelAnalytics(
      computedDescending: computedAsc.reversed.toList(),
      trendPoints: trendPoints,
      avgKmPerLiter: avgKmPerL,
      avgCostPerKm: avgCostPerKm,
      latestKmPerLiter: latestKmPerL,
      trend: trend,
      trendDeltaPercent: deltaPct,
    );
  }

  ({double total, double fuel, double service}) computeMonthlySpend(
    String vehicleId, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    double fuel = 0;
    for (final f in _fuelEntries) {
      if (f.vehicleId == vehicleId &&
          f.date.year == ref.year &&
          f.date.month == ref.month) {
        fuel += f.totalCost;
      }
    }

    double service = 0;
    for (final s in _serviceEntries) {
      if (s.vehicleId == vehicleId &&
          s.date.year == ref.year &&
          s.date.month == ref.month) {
        service += s.cost;
      }
    }

    return (total: fuel + service, fuel: fuel, service: service);
  }

  /// Returns known sparepart brands (user's past brands first, then popular presets).
  List<String> get suggestedBrands {
    final seen = <String>{};
    final result = <String>[];
    for (final s in _serviceEntries) {
      final b = s.partBrand.trim();
      if (b.isNotEmpty && seen.add(b.toLowerCase())) {
        result.add(b);
      }
    }
    for (final b in BrandDetector.popularBrands) {
      if (seen.add(b.toLowerCase())) {
        result.add(b);
      }
    }
    return result;
  }

  /// Computes top most frequently used sparepart/oil brands.
  /// Pass [vehicleId] to scope to a single vehicle, or `null` for all vehicles.
  List<BrandUsageStat> computeTopSparepartBrands({
    String? vehicleId,
    int limit = 5,
  }) {
    final relevant = vehicleId != null
        ? _serviceEntries.where((s) => s.vehicleId == vehicleId)
        : _serviceEntries;

    final counts = <String, int>{};
    final displayNames = <String, String>{};
    final spends = <String, double>{};
    final categoryCounts = <String, Map<ServiceCategory, int>>{};
    int totalUsages = 0;

    for (final srv in relevant) {
      final rawBrand = srv.partBrand.trim().isNotEmpty
          ? srv.partBrand.trim()
          : (BrandDetector.detectFromText('${srv.title} ${srv.notes}') ?? '');
      if (rawBrand.isEmpty) continue;

      final key = rawBrand.toLowerCase();
      displayNames.putIfAbsent(key, () => rawBrand);
      counts[key] = (counts[key] ?? 0) + 1;
      spends[key] = (spends[key] ?? 0) + srv.cost;
      categoryCounts.putIfAbsent(key, () => {});
      categoryCounts[key]![srv.category] =
          (categoryCounts[key]![srv.category] ?? 0) + 1;
      totalUsages++;
    }

    if (counts.isEmpty || totalUsages == 0) return const [];

    final stats = counts.keys.map((key) {
      final catMap = categoryCounts[key]!;
      ServiceCategory topCat = ServiceCategory.other;
      int topCatCount = -1;
      for (final entry in catMap.entries) {
        if (entry.value > topCatCount) {
          topCatCount = entry.value;
          topCat = entry.key;
        }
      }
      final count = counts[key]!;
      return BrandUsageStat(
        brand: displayNames[key]!,
        usageCount: count,
        totalSpend: spends[key] ?? 0,
        share: count / totalUsages,
        topCategory: topCat,
      );
    }).toList();

    stats.sort((a, b) {
      final countCmp = b.usageCount.compareTo(a.usageCount);
      if (countCmp != 0) return countCmp;
      final spendCmp = b.totalSpend.compareTo(a.totalSpend);
      if (spendCmp != 0) return spendCmp;
      return a.brand.compareTo(b.brand);
    });

    return stats.length > limit ? stats.sublist(0, limit) : stats;
  }

  List<HealthStatusItem> computeHealthItems(
    Vehicle vehicle, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final vehicleServices = serviceEntriesFor(vehicle.id);

    final trackedCategories = [
      ServiceCategory.oil,
      ServiceCategory.routine,
      ServiceCategory.brakesTires,
    ];

    final items = <HealthStatusItem>[];

    for (final cat in trackedCategories) {
      final matching =
          vehicleServices.where((s) => s.category == cat).toList();
      if (matching.isEmpty) {
        items.add(
          HealthStatusItem(
            keyId: cat.name,
            level: HealthLevel.unknown,
            category: cat,
            progress: 0.0,
          ),
        );
        continue;
      }

      // Most recent by odometer / date
      matching.sort((a, b) {
        final odoCmp = b.odometerKm.compareTo(a.odometerKm);
        if (odoCmp != 0) return odoCmp;
        return b.date.compareTo(a.date);
      });
      final latest = matching.first;
      final defaults = ServiceEntry.defaultIntervals(vehicle.type, cat);
      final intervalKm =
          latest.nextIntervalKm > 0 ? latest.nextIntervalKm : defaults.km;
      final intervalMonths = latest.nextIntervalMonths > 0
          ? latest.nextIntervalMonths
          : defaults.months;

      final nextDueKm = intervalKm > 0 ? latest.odometerKm + intervalKm : null;
      final kmRemaining =
          nextDueKm != null ? nextDueKm - vehicle.odometerKm : null;

      DateTime? nextDueDate;
      int? daysRemaining;
      if (intervalMonths > 0) {
        final withInterval = latest.nextIntervalMonths > 0
            ? latest
            : ServiceEntry(
                id: latest.id,
                vehicleId: latest.vehicleId,
                date: latest.date,
                odometerKm: latest.odometerKm,
                category: latest.category,
                title: latest.title,
                cost: latest.cost,
                nextIntervalMonths: intervalMonths,
              );
        nextDueDate = withInterval.nextDueDate;
        if (nextDueDate != null) {
          daysRemaining = nextDueDate.difference(today).inDays;
        }
      }

      HealthLevel kmLevel = HealthLevel.safe;
      double kmProgress = 0.0;
      if (kmRemaining != null && intervalKm > 0) {
        final usedKm = vehicle.odometerKm - latest.odometerKm;
        kmProgress = (usedKm / intervalKm).clamp(0.0, 1.0);
        final soonThreshold = math.max(300, (intervalKm * 0.15).round());
        if (kmRemaining <= 0) {
          kmLevel = HealthLevel.overdue;
        } else if (kmRemaining <= soonThreshold) {
          kmLevel = HealthLevel.soon;
        }
      }

      HealthLevel dateLevel = HealthLevel.safe;
      double dateProgress = 0.0;
      if (daysRemaining != null && nextDueDate != null) {
        final startDay =
            DateTime(latest.date.year, latest.date.month, latest.date.day);
        final totalDays = math.max(1, nextDueDate.difference(startDay).inDays);
        final elapsedDays = today.difference(startDay).inDays;
        dateProgress = (elapsedDays / totalDays).clamp(0.0, 1.0);
        if (daysRemaining < 0) {
          dateLevel = HealthLevel.overdue;
        } else if (daysRemaining <= 14) {
          dateLevel = HealthLevel.soon;
        }
      }

      final worstLevel = _worstHealth(kmLevel, dateLevel);
      items.add(
        HealthStatusItem(
          keyId: cat.name,
          level: worstLevel,
          category: cat,
          lastService: latest,
          nextDueKm: nextDueKm,
          kmRemaining: kmRemaining,
          nextDueDate: nextDueDate,
          daysRemaining: daysRemaining,
          progress: math.max(kmProgress, dateProgress),
        ),
      );
    }

    // STNK / Vehicle Tax item
    final taxDate = DateTime(
      vehicle.taxDueDate.year,
      vehicle.taxDueDate.month,
      vehicle.taxDueDate.day,
    );
    final taxDaysLeft = taxDate.difference(today).inDays;
    HealthLevel taxLevel;
    if (taxDaysLeft < 0) {
      taxLevel = HealthLevel.overdue;
    } else if (taxDaysLeft <= 30) {
      taxLevel = HealthLevel.soon;
    } else {
      taxLevel = HealthLevel.safe;
    }
    final taxProgress = ((365 - taxDaysLeft) / 365).clamp(0.0, 1.0);

    items.add(
      HealthStatusItem(
        keyId: 'stnk',
        level: taxLevel,
        isTax: true,
        nextDueDate: taxDate,
        daysRemaining: taxDaysLeft,
        progress: taxProgress,
      ),
    );

    return items;
  }

  HealthLevel _worstHealth(HealthLevel a, HealthLevel b) {
    if (a == HealthLevel.overdue || b == HealthLevel.overdue) {
      return HealthLevel.overdue;
    }
    if (a == HealthLevel.soon || b == HealthLevel.soon) {
      return HealthLevel.soon;
    }
    return HealthLevel.safe;
  }

  /// Generates a clean, resale-ready plain text Service Book summary.
  String buildServiceBookExport(Vehicle vehicle, {DateTime? now}) {
    final s = strings;
    final ref = now ?? DateTime.now();
    final services = serviceEntriesFor(vehicle.id);
    final analytics = computeFuelAnalytics(vehicle.id);
    final healthItems = computeHealthItems(vehicle, now: ref);

    final totalServiceCost =
        services.fold<double>(0, (sum, item) => sum + item.cost);

    final buf = StringBuffer();
    buf.writeln('══════════════════════════════════════');
    buf.writeln(
      s.t(
        'BUKU SERVIS DIGITAL — GARAGELOG',
        'DIGITAL SERVICE BOOK — GARAGELOG',
      ),
    );
    buf.writeln('══════════════════════════════════════');
    if (_masterProfile.garageName.trim().isNotEmpty) {
      buf.writeln(
        '${s.t('Garasi', 'Garage')}       : ${_masterProfile.garageName.trim()}',
      );
    }
    buf.writeln(
      '${s.t('Kendaraan', 'Vehicle')}    : ${vehicle.name} (${vehicle.type == VehicleType.motorcycle ? s.motorcycle : s.car})',
    );
    buf.writeln(
      '${s.t('Plat Nomor', 'Plate')}        : ${vehicle.plateNumber}',
    );
    buf.writeln(
      '${s.t('Odometer', 'Odometer')}     : ${s.formatKm(vehicle.odometerKm)}',
    );
    buf.writeln(
      '${s.t('Pajak STNK', 'Tax / STNK')}   : ${s.formatDate(vehicle.taxDueDate)}',
    );
    if (analytics.avgKmPerLiter != null) {
      buf.writeln(
        '${s.t('Efisiensi BBM', 'Avg Fuel Eco')} : ${s.formatNumber(analytics.avgKmPerLiter!)} km/L',
      );
    }
    buf.writeln(
      '${s.t('Dicetak Tgl', 'Export Date')}  : ${s.formatDate(ref)}',
    );
    buf.writeln('');
    buf.writeln(
      s.t('--- STATUS PERAWATAN TERKINI ---', '--- CURRENT HEALTH STATUS ---'),
    );
    for (final item in healthItems) {
      final label = _healthLabel(item, s);
      final statusText = _statusText(item.level, s);
      if (item.isTax && item.daysRemaining != null) {
        final detail = item.daysRemaining! >= 0
            ? '${item.daysRemaining} ${s.dueInDays}'
            : '${s.overdueByDays} ${item.daysRemaining!.abs()} ${s.daysUnit}';
        buf.writeln('• $label: [$statusText] ($detail)');
      } else if (item.kmRemaining != null) {
        final detail = item.kmRemaining! >= 0
            ? '${s.formatKm(item.kmRemaining!)} ${s.t('lagi', 'left')}'
            : '${s.formatKm(item.kmRemaining!.abs())} ${s.t('lewat', 'overdue')}';
        buf.writeln('• $label: [$statusText] ($detail)');
      } else {
        buf.writeln('• $label: [$statusText]');
      }
    }

    buf.writeln('');
    buf.writeln(
      s.t(
        '--- RIWAYAT SERVIS (${services.length} CATATAN) ---',
        '--- SERVICE HISTORY (${services.length} RECORDS) ---',
      ),
    );

    if (services.isEmpty) {
      buf.writeln(s.noServiceYet);
    } else {
      for (int i = 0; i < services.length; i++) {
        final srv = services[i];
        buf.writeln(
          '${i + 1}. [${s.formatDate(srv.date)}] ${s.formatKm(srv.odometerKm)} — ${srv.title}',
        );
        final catName = _categoryLabel(srv.category, s);
        final brandTag = srv.partBrand.isNotEmpty
            ? ' • ${s.t('Merek', 'Brand')}: ${srv.partBrand}'
            : '';
        final shop = srv.workshop.isNotEmpty ? ' • ${srv.workshop}' : '';
        buf.writeln(
          '   $catName$brandTag$shop • ${s.formatCurrency(srv.cost)}',
        );
        if (srv.notes.isNotEmpty) {
          buf.writeln('   ${s.t('Catatan', 'Notes')}: ${srv.notes}');
        }
      }
    }

    buf.writeln('');
    buf.writeln(
      '${s.t('Total Biaya Perawatan Tercatat', 'Total Logged Maintenance')}: ${s.formatCurrency(totalServiceCost)}',
    );
    buf.writeln('──────────────────────────────────────');
    buf.writeln(
      s.t(
        'Diekspor 100% offline melalui aplikasi GarageLog.',
        'Exported 100% offline via GarageLog.',
      ),
    );
    return buf.toString();
  }

  String _healthLabel(HealthStatusItem item, AppStrings s) {
    if (item.isTax) return s.catStnk;
    return _categoryLabel(item.category ?? ServiceCategory.other, s);
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

  String _statusText(HealthLevel level, AppStrings s) {
    switch (level) {
      case HealthLevel.safe:
        return s.statusSafe;
      case HealthLevel.soon:
        return s.statusSoon;
      case HealthLevel.overdue:
        return s.statusOverdue;
      case HealthLevel.unknown:
        return s.statusNoData;
    }
  }

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
