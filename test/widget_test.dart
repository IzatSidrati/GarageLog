import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_log/l10n/app_strings.dart';
import 'package:garage_log/main.dart';
import 'package:garage_log/models/garage_item.dart';
import 'package:garage_log/models/health_status.dart';
import 'package:garage_log/models/master_profile.dart';
import 'package:garage_log/models/service_entry.dart';
import 'package:garage_log/models/vehicle.dart';
import 'package:garage_log/state/garage_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        plateNumber: 'B 5555 GLG',
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

    test('seeds 1 free vehicle and blocks 2nd vehicle until Pro Pass unlocked',
        () async {
      final ctrl = GarageController();
      await ctrl.init(now: DateTime(2026, 5, 10), seedDemoIfFresh: true);

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
      final ctrl = GarageController();
      await ctrl.init(now: DateTime(2026, 5, 10), seedDemoIfFresh: true);
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
      final ctrl = GarageController();
      await ctrl.init(now: now, seedDemoIfFresh: true);
      await ctrl.setProUnlocked(true);

      await ctrl.addVehicle(
        name: 'Honda Brio',
        plateNumber: 'B 7777 CAR',
        type: VehicleType.car,
        odometerKm: 20500,
        taxDueDate: now.subtract(const Duration(days: 3)), // Overdue tax
      );
      final vid = ctrl.activeVehicle!.id;

      // Oil overdue by 500 km (15000 + 5000 = 20000 < 20500)
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
      // Routine due soon (11000 + 10000 = 21000 -> 500 km left <= 15% of 10000)
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
      // Brakes safe (18000 + 15000 = 33000 -> 12500 km left)
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
      final ctrl = GarageController();
      await ctrl.init(now: DateTime(2026, 5, 10), seedDemoIfFresh: true);
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
      final ctrl = GarageController();
      await ctrl.init(now: DateTime(2026, 5, 10), seedDemoIfFresh: true);

      // Seeded with 3 sample inventory items (limit free = 5)
      expect(ctrl.inventoryItems.length, 3);
      final initialOil = ctrl.inventoryItems.firstWhere((i) => i.id == 'inv_1');
      expect(initialOil.quantity, 2);

      // Log service using stock item -> auto-deducts quantity by 1
      await ctrl.addServiceEntry(
        vehicleId: ctrl.activeVehicle!.id,
        category: ServiceCategory.oil,
        title: 'Ganti Oli Mandiri',
        odometerKm: 14700,
        cost: 68000,
        consumedItemIds: const ['inv_1'],
      );
      final afterOil = ctrl.inventoryItems.firstWhere((i) => i.id == 'inv_1');
      expect(afterOil.quantity, 1);
      expect(afterOil.isLowStock, isTrue);

      // Loan & return tool
      await ctrl.loanTool('inv_3', 'Budi', now: DateTime(2026, 5, 10));
      var tool = ctrl.inventoryItems.firstWhere((i) => i.id == 'inv_3');
      expect(tool.isBorrowed, isTrue);
      expect(tool.borrowedBy, 'Budi');

      await ctrl.returnTool('inv_3');
      tool = ctrl.inventoryItems.firstWhere((i) => i.id == 'inv_3');
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
      final ctrl = GarageController();
      await ctrl.init(now: DateTime(2026, 5, 10), seedDemoIfFresh: true);
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

      // Invalid JSON must fail safely without mutating state
      expect(await ctrl.importBackupJson('not-json'), isFalse);
      expect(await ctrl.importBackupJson('{"app":"OtherApp"}'), isFalse);

      // Restore into a fresh controller
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
  });

  group('GarageLogApp UI smoke tests', () {
    testWidgets('shows first-install master data form and enters dashboard on submit',
        (WidgetTester tester) async {
      final ctrl = GarageController();
      await ctrl.init(now: DateTime(2026, 5, 10));

      await tester.pumpWidget(GarageLogApp(controller: ctrl));
      await tester.pumpAndSettle();

      // Fresh install shows FirstRunSetupScreen
      expect(find.text('Selamat Datang di GarageLog'), findsOneWidget);

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
      await tester.enterText(
        find.byKey(const Key('setup_plate_field')),
        'B 5555 GLG',
      );
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

      // Should transition to Dashboard with the new master data & vehicle
      expect(find.text('Kesehatan Kendaraan'), findsOneWidget);
      expect(find.text('Yamaha Aerox 155'), findsOneWidget);
      expect(find.text('B 5555 GLG'), findsOneWidget);
      expect(find.text('8.500 km'), findsOneWidget);
    });

    testWidgets('renders dashboard, switches ID/EN & Rp/\$, gates 2nd vehicle, and shows Stock & Backup',
        (WidgetTester tester) async {
      final ctrl = GarageController();
      await ctrl.init(now: DateTime(2026, 5, 10), seedDemoIfFresh: true);

      await tester.pumpWidget(GarageLogApp(controller: ctrl));
      await tester.pumpAndSettle();

      // Default is Indonesian + Rp
      expect(find.text('GarageLog'), findsOneWidget);
      expect(find.text('Kesehatan Kendaraan'), findsOneWidget);
      expect(find.text('ID'), findsOneWidget);
      expect(find.text('Rp'), findsOneWidget);

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
      await tester.tap(find.byKey(const Key('add_vehicle_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade to GarageLog Pro Pass'), findsOneWidget);
      expect(find.byKey(const Key('dev_pro_toggle_button')), findsOneWidget);

      // Activate Pro Pass via Dev Simulation button
      await tester.tap(find.byKey(const Key('dev_pro_toggle_button')));
      await tester.pumpAndSettle();
      expect(ctrl.isProUnlocked, isTrue);

      // Close vehicle form sheet that opened after Pro unlock
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await tester.pumpAndSettle();

      // Switch to Stock & Tools sub-tab inside Garage
      await tester.tap(find.byKey(const Key('garage_subtab_stock')));
      await tester.pumpAndSettle();
      expect(find.text('Oli Mesin SPX2 0.8L'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Kunci Sok Set 8–24mm'),
        200,
      );
      expect(find.text('Kunci Sok Set 8–24mm'), findsOneWidget);

      // Scroll down to open Offline Backup & Restore sheet
      await tester.scrollUntilVisible(
        find.byKey(const Key('open_backup_restore_btn')),
        200,
      );
      await tester.tap(find.byKey(const Key('open_backup_restore_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('copy_backup_json_btn')), findsOneWidget);
    });
  });
}
