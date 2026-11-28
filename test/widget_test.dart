import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_log/l10n/app_strings.dart';
import 'package:garage_log/main.dart';
import 'package:garage_log/models/garage_item.dart';
import 'package:garage_log/models/health_status.dart';
import 'package:garage_log/models/master_profile.dart';
import 'package:garage_log/models/service_entry.dart';
import 'package:garage_log/models/vehicle.dart';
import 'package:garage_log/services/ad_config.dart';
import 'package:garage_log/services/iap_service.dart';
import 'package:garage_log/services/receipt_parser.dart';
import 'package:garage_log/state/garage_controller.dart';
import 'package:garage_log/ui/widgets/branded_splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GarageController> _createPopulatedTestController(DateTime now) async {
  final ctrl = GarageController();
  await ctrl.init(now: now);
  await ctrl.completeInitialSetup(
    profile: const GarageMasterProfile(
      garageName: 'Garasi Izat',
      defaultWorkshop: 'AHASS Motor Mandiri',
      defaultFuelType: 'Pertamax',
    ),
    vehicleName: 'Honda Vario 160 ABS',
    plateNumber: 'B 4821 KGL',
    vehicleType: VehicleType.motorcycle,
    odometerKm: 14680,
    taxDueDate: now.add(const Duration(days: 22)),
    createServiceBaselines: false,
    now: now,
  );

  final vid = ctrl.activeVehicle!.id;
  await ctrl.addServiceEntry(
    vehicleId: vid,
    category: ServiceCategory.oil,
    title: 'Ganti Oli Mesin + Gardan',
    odometerKm: 12850,
    cost: 115000,
    workshop: 'AHASS Motor Mandiri',
    nextIntervalKm: 2000,
    nextIntervalMonths: 2,
    partBrand: 'AHM Oil',
    date: now.subtract(const Duration(days: 54)),
  );
  await ctrl.addServiceEntry(
    vehicleId: vid,
    category: ServiceCategory.oil,
    title: 'Ganti Oli Rutin',
    odometerKm: 10900,
    cost: 75000,
    workshop: 'AHASS Motor Mandiri',
    nextIntervalKm: 2000,
    nextIntervalMonths: 2,
    partBrand: 'AHM Oil',
    date: now.subtract(const Duration(days: 105)),
  );
  await ctrl.addServiceEntry(
    vehicleId: vid,
    category: ServiceCategory.routine,
    title: 'Servis CVT',
    odometerKm: 13600,
    cost: 165000,
    workshop: 'AHASS Motor Mandiri',
    nextIntervalKm: 4000,
    nextIntervalMonths: 4,
    partBrand: 'Daytona',
    date: now.subtract(const Duration(days: 35)),
  );

  await ctrl.addInventoryItem(
    name: 'Oli Mesin SPX2 0.8L',
    type: InventoryType.consumable,
    quantity: 2,
    minQuantity: 1,
    unit: 'botol',
    unitPrice: 68000,
    location: 'Rak Oli A1',
  );
  await ctrl.addInventoryItem(
    name: 'Chain Lube',
    type: InventoryType.consumable,
    quantity: 1,
    minQuantity: 1,
    unit: 'kaleng',
    unitPrice: 45000,
  );
  await ctrl.addInventoryItem(
    name: 'Kunci Sok Set 8–24mm',
    type: InventoryType.tool,
    quantity: 1,
    unit: 'set',
    location: 'Toolbox Utama',
  );

  return ctrl;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GarageController logic & offline persistence', () {
    test('fresh install requires initial master data setup and persists after completion',
        () async {
      final ctrl = GarageController();
      await ctrl.init(now: DateTime(2026, 5, 10));

      expect(ctrl.needsInitialSetup, isTrue);
      expect(ctrl.vehicles, isEmpty);

      await ctrl.completeInitialSetup(
        profile: const GarageMasterProfile(
          garageName: 'Garasi Izat',
          defaultWorkshop: 'AHASS Utama',
          defaultFuelType: 'Pertamax Turbo',
          oilIntervalKm: 2500,
          oilIntervalMonths: 3,
          routineIntervalKm: 5000,
          routineIntervalMonths: 5,
          brakesIntervalKm: 9000,
          brakesIntervalMonths: 9,
        ),
        vehicleName: 'Yamaha Aerox 155',
        plateNumber: 'b 5555 glg',
        vehicleType: VehicleType.motorcycle,
        odometerKm: 8500,
        taxDueDate: DateTime(2027, 2, 15),
        createServiceBaselines: true,
        now: DateTime(2026, 5, 10),
      );

      expect(ctrl.needsInitialSetup, isFalse);
      expect(ctrl.isSetupCompleted, isTrue);
      expect(ctrl.vehicles.length, 1);
      expect(ctrl.activeVehicle?.name, 'Yamaha Aerox 155');
      expect(ctrl.activeVehicle?.plateNumber, 'B 5555 GLG');
      expect(ctrl.allServiceEntries.length, 3);
      expect(ctrl.masterProfile.garageName, 'Garasi Izat');
      expect(ctrl.masterProfile.defaultFuelType, 'Pertamax Turbo');

      // Reload from SharedPreferences to verify persistence
      final reloaded = GarageController();
      await reloaded.init(now: DateTime(2026, 5, 10));
      expect(reloaded.needsInitialSetup, isFalse);
      expect(reloaded.masterProfile.garageName, 'Garasi Izat');
      expect(reloaded.masterProfile.defaultWorkshop, 'AHASS Utama');
      expect(reloaded.activeVehicle?.plateNumber, 'B 5555 GLG');
    });

    test('blocks 2nd vehicle on free plan until Pro Pass unlocked', () async {
      final ctrl = await _createPopulatedTestController(DateTime(2026, 5, 10));

      expect(ctrl.vehicles.length, 1);
      expect(ctrl.isProUnlocked, isFalse);
      expect(ctrl.canAddMoreVehicles, isFalse);

      // Attempting to add 2nd vehicle while free returns false
      final blocked = await ctrl.addVehicle(
        name: 'Toyota Avanza',
        plateNumber: 'B 9999 GLG',
        type: VehicleType.car,
        odometerKm: 32000,
        taxDueDate: DateTime(2027, 1, 10),
      );
      expect(blocked, isFalse);
      expect(ctrl.vehicles.length, 1);

      // Unlock Pro Pass via dev simulation and add 2nd vehicle
      await ctrl.setProUnlocked(true);
      expect(ctrl.canAddMoreVehicles, isTrue);

      final added = await ctrl.addVehicle(
        name: 'Toyota Avanza',
        plateNumber: 'B 9999 GLG',
        type: VehicleType.car,
        odometerKm: 32000,
        taxDueDate: DateTime(2027, 1, 10),
      );
      expect(added, isTrue);
      expect(ctrl.vehicles.length, 2);
      expect(ctrl.activeVehicle?.name, 'Toyota Avanza');

      // Re-instantiate controller to confirm SharedPreferences persistence
      final reloaded = GarageController();
      await reloaded.init(now: DateTime(2026, 5, 10));
      expect(reloaded.isProUnlocked, isTrue);
      expect(reloaded.vehicles.length, 2);
      expect(reloaded.activeVehicle?.plateNumber, 'B 9999 GLG');
    });

    test('computes fuel economy (km/L), cost/km, and bumps vehicle odometer',
        () async {
      final ctrl = await _createPopulatedTestController(DateTime(2026, 5, 10));
      await ctrl.setProUnlocked(true);

      await ctrl.addVehicle(
        name: 'Yamaha NMAX',
        plateNumber: 'D 1111 ABC',
        type: VehicleType.motorcycle,
        odometerKm: 1000,
        taxDueDate: DateTime(2027, 1, 1),
      );
      final vid = ctrl.activeVehicle!.id;

      await ctrl.addFuelEntry(
        vehicleId: vid,
        odometerKm: 1000,
        liters: 5.0,
        totalCost: 65000,
        fuelType: 'Pertamax',
        date: DateTime(2026, 5, 1),
      );
      await ctrl.addFuelEntry(
        vehicleId: vid,
        odometerKm: 1200,
        liters: 5.0,
        totalCost: 65000,
        fuelType: 'Pertamax',
        date: DateTime(2026, 5, 8),
      );

      final analytics = ctrl.computeFuelAnalytics(vid);
      expect(analytics.avgKmPerLiter, closeTo(40.0, 0.01));
      expect(analytics.avgCostPerKm, closeTo(325.0, 0.01));
      expect(ctrl.activeVehicle?.odometerKm, 1200);
    });

    test('evaluates health status (safe / soon / overdue) and STNK countdown',
        () async {
      final now = DateTime(2026, 5, 10);
      final ctrl = await _createPopulatedTestController(now);
      await ctrl.setProUnlocked(true);

      await ctrl.addVehicle(
        name: 'Honda Brio',
        plateNumber: 'B 7777 CAR',
        type: VehicleType.car,
        odometerKm: 20500,
        taxDueDate: now.subtract(const Duration(days: 3)),
      );
      final vid = ctrl.activeVehicle!.id;

      await ctrl.addServiceEntry(
        vehicleId: vid,
        category: ServiceCategory.oil,
        title: 'Ganti Oli',
        odometerKm: 15000,
        cost: 450000,
        nextIntervalKm: 5000,
        nextIntervalMonths: 6,
        date: now.subtract(const Duration(days: 40)),
      );
      await ctrl.addServiceEntry(
        vehicleId: vid,
        category: ServiceCategory.routine,
        title: 'Servis Berkala',
        odometerKm: 11000,
        cost: 800000,
        nextIntervalKm: 10000,
        nextIntervalMonths: 6,
        date: now.subtract(const Duration(days: 30)),
      );
      await ctrl.addServiceEntry(
        vehicleId: vid,
        category: ServiceCategory.brakesTires,
        title: 'Cek Rem & Ban',
        odometerKm: 18000,
        cost: 250000,
        nextIntervalKm: 15000,
        nextIntervalMonths: 12,
        date: now.subtract(const Duration(days: 15)),
      );

      final items = ctrl.computeHealthItems(ctrl.activeVehicle!, now: now);
      final byKey = {for (final i in items) i.keyId: i};

      expect(byKey['oil']?.level, HealthLevel.overdue);
      expect(byKey['routine']?.level, HealthLevel.soon);
      expect(byKey['brakesTires']?.level, HealthLevel.safe);
      expect(byKey['stnk']?.level, HealthLevel.overdue);
      expect(byKey['stnk']?.daysRemaining, -3);
    });

    test('exports resale Service Book summary in Indonesian and English',
        () async {
      final ctrl = await _createPopulatedTestController(DateTime(2026, 5, 10));
      final v = ctrl.activeVehicle!;

      final exportId = ctrl.buildServiceBookExport(v, now: DateTime(2026, 5, 10));
      expect(exportId, contains('BUKU SERVIS DIGITAL'));
      expect(exportId, contains(v.name));
      expect(exportId, contains(v.plateNumber));

      await ctrl.setLanguage(AppLanguage.en);
      await ctrl.setCurrency(AppCurrency.usd);
      final exportEn = ctrl.buildServiceBookExport(v, now: DateTime(2026, 5, 10));
      expect(exportEn, contains('DIGITAL SERVICE BOOK'));
      expect(exportEn, contains('\$'));
    });

    test('manages garage stock & tools, auto-deducts stock on service, and enforces free limit',
        () async {
      final ctrl = await _createPopulatedTestController(DateTime(2026, 5, 10));

      expect(ctrl.inventoryItems.length, 3);
      final oilItem = ctrl.inventoryItems
          .firstWhere((i) => i.name == 'Oli Mesin SPX2 0.8L');
      final toolItem = ctrl.inventoryItems
          .firstWhere((i) => i.name == 'Kunci Sok Set 8–24mm');
      expect(oilItem.quantity, 2);

      // Log service using stock item -> auto-deducts quantity by 1
      await ctrl.addServiceEntry(
        vehicleId: ctrl.activeVehicle!.id,
        category: ServiceCategory.oil,
        title: 'Ganti Oli Mandiri',
        odometerKm: 14700,
        cost: 68000,
        consumedItemIds: [oilItem.id],
      );
      final afterOil =
          ctrl.inventoryItems.firstWhere((i) => i.id == oilItem.id);
      expect(afterOil.quantity, 1);
      expect(afterOil.isLowStock, isTrue);

      // Loan & return tool
      await ctrl.loanTool(toolItem.id, 'Budi', now: DateTime(2026, 5, 10));
      var tool = ctrl.inventoryItems.firstWhere((i) => i.id == toolItem.id);
      expect(tool.isBorrowed, isTrue);
      expect(tool.borrowedBy, 'Budi');

      await ctrl.returnTool(toolItem.id);
      tool = ctrl.inventoryItems.firstWhere((i) => i.id == toolItem.id);
      expect(tool.isBorrowed, isFalse);

      // Add up to 5 items on free plan, 6th blocked until Pro Pass
      expect(
        await ctrl.addInventoryItem(
          name: 'Busi NGK',
          type: InventoryType.consumable,
          quantity: 2,
        ),
        isTrue,
      );
      expect(
        await ctrl.addInventoryItem(
          name: 'Kunci T10',
          type: InventoryType.tool,
          quantity: 1,
        ),
        isTrue,
      );
      expect(ctrl.inventoryItems.length, 5);
      expect(ctrl.canAddMoreInventory, isFalse);
      expect(
        await ctrl.addInventoryItem(
          name: 'Dongkrak',
          type: InventoryType.tool,
          quantity: 1,
        ),
        isFalse,
      );

      await ctrl.setProUnlocked(true);
      expect(
        await ctrl.addInventoryItem(
          name: 'Dongkrak',
          type: InventoryType.tool,
          quantity: 1,
        ),
        isTrue,
      );
      expect(ctrl.inventoryItems.length, 6);
    });

    test('exports and restores offline JSON backup safely', () async {
      final ctrl = await _createPopulatedTestController(DateTime(2026, 5, 10));
      await ctrl.setProUnlocked(true);
      await ctrl.addVehicle(
        name: 'Honda Civic',
        plateNumber: 'B 2026 CVC',
        type: VehicleType.car,
        odometerKm: 55000,
        taxDueDate: DateTime(2027, 6, 1),
      );
      await ctrl.addInventoryItem(
        name: 'Filter Oli Civic',
        type: InventoryType.consumable,
        quantity: 3,
      );

      final backupJson = ctrl.exportBackupJson(now: DateTime(2026, 5, 10));
      expect(backupJson, contains('"app": "GarageLog"'));
      expect(backupJson, contains('Honda Civic'));
      expect(backupJson, contains('Filter Oli Civic'));

      expect(await ctrl.importBackupJson('not-json'), isFalse);
      expect(await ctrl.importBackupJson('{"app":"OtherApp"}'), isFalse);

      SharedPreferences.setMockInitialValues({});
      final fresh = GarageController();
      await fresh.init(now: DateTime(2026, 5, 10));
      expect(fresh.needsInitialSetup, isTrue);

      final restored = await fresh.importBackupJson(backupJson);
      expect(restored, isTrue);
      expect(fresh.needsInitialSetup, isFalse);
      expect(fresh.vehicles.length, 2);
      expect(fresh.activeVehicle?.name, 'Honda Civic');
      expect(
        fresh.inventoryItems.any((i) => i.name == 'Filter Oli Civic'),
        isTrue,
      );
    });

    test('parses Indonesian & English workshop receipts automatically offline', () {
      const idStrings = AppStrings(AppLanguage.id, AppCurrency.idr);
      const idReceipt = '''
AHASS MOTOR MANDIRI
Jl. Merdeka No. 10
KM : 15.240
1. Oli Mesin SPX2 0.8L     Rp 68.000
2. Servis CVT & Roller     Rp 95.000
GRAND TOTAL                Rp 163.000
''';
      final parsedId = ReceiptParser.parse(idReceipt, idStrings);
      expect(parsedId.workshop, 'AHASS MOTOR MANDIRI');
      expect(parsedId.odometerKm, 15240);
      expect(parsedId.totalCost, closeTo(163000, 0.01));
      expect(parsedId.category, ServiceCategory.oil);
      expect(parsedId.partBrand, 'AHM Oil');
      expect(parsedId.title, contains('Oli Mesin SPX2'));

      const enStrings = AppStrings(AppLanguage.en, AppCurrency.usd);
      const enReceipt = '''
PRECISION AUTO CARE
ODO: 25400 km
1. Brake Pad Replacement   \$120.50
2. Tire Balancing          \$35.00
GRAND TOTAL                \$155.50
''';
      final parsedEn = ReceiptParser.parse(enReceipt, enStrings);
      expect(parsedEn.workshop, 'PRECISION AUTO CARE');
      expect(parsedEn.odometerKm, 25400);
      expect(parsedEn.totalCost, closeTo(155.50, 0.01));
      expect(parsedEn.category, ServiceCategory.brakesTires);
    });

    test('ranks most frequently used sparepart brands per unit and across garage',
        () async {
      final ctrl = await _createPopulatedTestController(DateTime(2026, 5, 10));
      final vid = ctrl.activeVehicle!.id;

      var top = ctrl.computeTopSparepartBrands(vehicleId: vid);
      expect(top.first.brand, 'AHM Oil');
      expect(top.first.usageCount, 2);

      for (int i = 0; i < 3; i++) {
        await ctrl.addServiceEntry(
          vehicleId: vid,
          category: ServiceCategory.oil,
          title: 'Ganti Oli Motul Scooter LE',
          odometerKm: 15000 + (i * 2000),
          cost: 120000,
        );
      }

      top = ctrl.computeTopSparepartBrands(vehicleId: vid);
      expect(top.first.brand, 'Motul');
      expect(top.first.usageCount, 3);
      expect(top.first.totalSpend, closeTo(360000, 0.01));
    });

    test('auto-converts values between IDR and USD using offline exchange rate',
        () async {
      final ctrl = await _createPopulatedTestController(DateTime(2026, 5, 10));

      expect(ctrl.strings.formatCurrency(160000), 'Rp 160.000');

      await ctrl.setCurrency(AppCurrency.usd);
      expect(ctrl.strings.formatCurrency(160000), '\$10.00');
      expect(ctrl.strings.toBaseIdr(10.0), closeTo(160000, 0.01));

      await ctrl.updateMasterProfile(
        ctrl.masterProfile.copyWith(usdRateIdr: 20000),
      );
      expect(ctrl.strings.formatCurrency(160000), '\$8.00');
      expect(ctrl.strings.toBaseIdr(5.0), closeTo(100000, 0.01));
    });

    test('schedules upcoming offline STNK & service push reminders', () async {
      final now = DateTime(2026, 5, 10, 8, 0);
      final ctrl = await _createPopulatedTestController(now);

      final reminders = ctrl.buildUpcomingReminders(now: now);
      expect(reminders, isNotEmpty);
      expect(
        reminders.any((r) => r.title.contains('Pajak STNK')),
        isTrue,
      );

      final testDispatch =
          await ctrl.triggerTestReminderNotification(now: now);
      expect(testDispatch.title, contains('Honda Vario 160 ABS'));
      expect(testDispatch.body, isNotEmpty);
    });

    test('resolves AdMob production IDs in release mode and Google test IDs in debug mode',
        () {
      expect(AdConfig.appId, 'ca-app-pub-9171274707010006~2398578292');

      expect(
        AdConfig.resolveBannerUnitId(isReleaseMode: true, isIos: false),
        'ca-app-pub-9171274707010006/3819471178',
      );
      expect(
        AdConfig.resolveNativeUnitId(isReleaseMode: true, isIos: false),
        'ca-app-pub-9171274707010006/5681161843',
      );

      // Debug builds always use official Google test IDs
      expect(
        AdConfig.resolveBannerUnitId(isReleaseMode: false, isIos: false),
        AdConfig.androidTestBannerUnitId,
      );
      expect(
        AdConfig.resolveNativeUnitId(isReleaseMode: false, isIos: false),
        AdConfig.androidTestNativeUnitId,
      );
      expect(
        AdConfig.resolveBannerUnitId(isReleaseMode: false, isIos: true),
        AdConfig.iosTestBannerUnitId,
      );
      expect(IapConfig.proPassProductId, 'garagelog_pro_pass');
    });
  });

  group('GarageLogApp UI smoke tests', () {
    testWidgets('shows branded splash screen while controller is loading',
        (WidgetTester tester) async {
      final ctrl = GarageController(); // Not initialized yet -> isLoaded == false
      await tester.pumpWidget(GarageLogApp(controller: ctrl));
      await tester.pump();

      expect(find.byType(BrandedSplashScreen), findsOneWidget);
    });

    testWidgets('shows first-install master data form, auto-uppercases plate, and enters dashboard',
        (WidgetTester tester) async {
      final ctrl = GarageController();
      await ctrl.init(now: DateTime(2026, 5, 10));

      await tester.pumpWidget(GarageLogApp(controller: ctrl));
      await tester.pumpAndSettle();

      // Fresh install shows FirstRunSetupScreen without demo button or 100% Offline badge
      expect(find.text('Selamat Datang di GarageLog'), findsOneWidget);
      expect(find.text('100% Offline'), findsNothing);
      expect(find.text('Lewati & Coba Data Contoh'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('setup_garage_name_field')),
        'Garasi Izat',
      );
      await tester.enterText(
        find.byKey(const Key('setup_workshop_field')),
        'Bengkel Jaya',
      );

      final setupScrollable = find.byType(Scrollable).first;

      await tester.scrollUntilVisible(
        find.byKey(const Key('setup_vehicle_name_field')),
        200,
        scrollable: setupScrollable,
      );
      await tester.enterText(
        find.byKey(const Key('setup_vehicle_name_field')),
        'Yamaha Aerox 155',
      );
      // Enter lowercase plate -> UpperCaseTextFormatter converts immediately!
      await tester.enterText(
        find.byKey(const Key('setup_plate_field')),
        'b 5555 glg',
      );
      await tester.pump();
      expect(find.text('B 5555 GLG'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('setup_odo_field')),
        '8500',
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('setup_submit_btn')),
        250,
        scrollable: setupScrollable,
      );
      await tester.tap(find.byKey(const Key('setup_submit_btn')));
      await tester.pumpAndSettle();

      // Should transition to Dashboard with clean garage name header (no "100% Offline")
      expect(find.text('Kesehatan Kendaraan'), findsOneWidget);
      expect(find.text('Garasi Izat'), findsOneWidget);
      expect(find.textContaining('100% Offline'), findsNothing);
      expect(find.text('Yamaha Aerox 155'), findsOneWidget);
      expect(find.text('B 5555 GLG'), findsOneWidget);
      expect(find.text('8.500 km'), findsOneWidget);
    });

    testWidgets('renders dashboard, switches ID/EN & Rp/\$, gates 2nd vehicle, and shows Stock & Backup without demo reset',
        (WidgetTester tester) async {
      final ctrl = await _createPopulatedTestController(DateTime(2026, 5, 10));

      await tester.pumpWidget(GarageLogApp(controller: ctrl));
      await tester.pumpAndSettle();

      expect(find.text('GarageLog'), findsOneWidget);
      expect(find.text('Kesehatan Kendaraan'), findsOneWidget);
      expect(find.text('ID'), findsOneWidget);
      expect(find.text('Rp'), findsOneWidget);
      expect(find.textContaining('100% Offline'), findsNothing);

      // Quick toggle to English
      await tester.tap(find.byKey(const Key('lang_toggle_button')));
      await tester.pumpAndSettle();
      expect(find.text('Vehicle Health'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);

      // Quick toggle currency to $
      await tester.tap(find.byKey(const Key('currency_toggle_button')));
      await tester.pumpAndSettle();
      expect(find.text('\$'), findsOneWidget);

      // Navigate to Garage tab and tap Add Vehicle -> should show Pro Pass modal
      await tester.tap(find.text('Garage'));
      await tester.pumpAndSettle();
      expect(find.text('Reset Sample Data'), findsNothing);
      expect(find.text('Muat Ulang Data Contoh'), findsNothing);

      await tester.tap(find.byKey(const Key('add_vehicle_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade to GarageLog Pro Pass'), findsOneWidget);
      expect(find.byKey(const Key('pro_restore_button')), findsOneWidget);
      expect(find.byKey(const Key('dev_pro_toggle_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('dev_pro_toggle_button')));
      await tester.pumpAndSettle();
      expect(ctrl.isProUnlocked, isTrue);

      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('garage_subtab_stock')));
      await tester.pumpAndSettle();
      expect(find.text('Oli Mesin SPX2 0.8L'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Kunci Sok Set 8–24mm'),
        200,
      );
      expect(find.text('Kunci Sok Set 8–24mm'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('open_backup_restore_btn')),
        200,
      );
      await tester.tap(find.byKey(const Key('open_backup_restore_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('copy_backup_json_btn')), findsOneWidget);

      // Close backup sheet and verify About & Privacy Policy sheet
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('open_about_privacy_btn')),
        200,
      );
      await tester.tap(find.byKey(const Key('open_about_privacy_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Google AdMob Advertising'), findsOneWidget);
      expect(find.textContaining('1.0.0'), findsOneWidget);
    });

    testWidgets('auto-fills service form, displays Top Brands, and triggers Push Notification banner',
        (WidgetTester tester) async {
      final ctrl = await _createPopulatedTestController(DateTime(2026, 5, 10));

      await tester.pumpWidget(GarageLogApp(controller: ctrl));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_quick_service_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('smart_paste_receipt_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('load_sample_receipt_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('parse_receipt_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('163000'), findsOneWidget);
      expect(
        find.textContaining('Oli Mesin SPX2'),
        findsWidgets,
      );

      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('top_brands_dashboard_card')),
        250,
      );
      expect(find.text('Merek Sparepart Favorit'), findsOneWidget);
      expect(find.text('AHM Oil'), findsOneWidget);
      expect(find.text('Favorit #1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('appbar_test_notif_btn')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('push_notification_banner')), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
