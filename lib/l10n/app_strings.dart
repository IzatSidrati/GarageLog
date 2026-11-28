enum AppLanguage { id, en }

enum AppCurrency { idr, usd }

class AppStrings {
  const AppStrings(
    this.language,
    this.currency, {
    this.usdRateIdr = 16000,
  });

  final AppLanguage language;
  final AppCurrency currency;
  final double usdRateIdr;

  double get effectiveUsdRate => usdRateIdr > 0 ? usdRateIdr : 16000;

  /// Converts a user-entered display amount (in active currency) into base IDR.
  double toBaseIdr(double displayAmount) {
    return currency == AppCurrency.usd
        ? displayAmount * effectiveUsdRate
        : displayAmount;
  }

  /// Converts a stored base IDR amount into the currently active display currency.
  double fromBaseIdr(double baseIdrAmount) {
    return currency == AppCurrency.usd
        ? baseIdrAmount / effectiveUsdRate
        : baseIdrAmount;
  }

  String formatEditableAmount(double baseIdrAmount) {
    final val = fromBaseIdr(baseIdrAmount);
    return currency == AppCurrency.idr
        ? val.round().toString()
        : val.toStringAsFixed(2);
  }

  bool get isId => language == AppLanguage.id;

  String t(String idText, String enText) => isId ? idText : enText;

  // Navigation
  String get navDashboard => t('Dashboard', 'Dashboard');
  String get navFuel => t('Bensin', 'Fuel');
  String get navService => t('Servis', 'Service');
  String get navGarage => t('Garasi', 'Garage');

  // App header & badges
  String get appTitle => 'GarageLog';
  String get appSubtitle => t('Pelacak Servis & Bensin', 'Service & Fuel Tracker');
  String get offlineBadge => t('100% Offline', '100% Offline');
  String get proActive => 'PRO';
  String get freePlan => t('Gratis (1 Unit)', 'Free (1 Unit)');

  // Vehicle types
  String get motorcycle => t('Motor', 'Motorcycle');
  String get car => t('Mobil', 'Car');

  // Health statuses
  String get statusSafe => t('Aman', 'Healthy');
  String get statusSoon => t('Segera', 'Due Soon');
  String get statusOverdue => t('Lewat Jadwal', 'Overdue');
  String get statusNoData => t('Belum Dicatat', 'Not Logged');

  // Health categories
  String get catOil => t('Ganti Oli', 'Oil Change');
  String get catRoutine => t('Servis Rutin / CVT', 'Routine / CVT');
  String get catBrakesTires => t('Rem & Ban', 'Brakes & Tires');
  String get catOther => t('Servis Lainnya', 'Other Service');
  String get catStnk => t('Pajak STNK', 'Vehicle Tax / STNK');

  // Dashboard
  String get vehicleHealthTitle => t('Kesehatan Kendaraan', 'Vehicle Health');
  String get currentOdometer => t('Odometer Saat Ini', 'Current Odometer');
  String get updateOdo => t('Update KM', 'Update KM');
  String get avgEfficiency => t('Efisiensi BBM', 'Avg Economy');
  String get monthlySpend => t('Biaya Bulan Ini', 'This Month Spend');
  String get quickFuelCta => t('Isi Bensin 3 Detik', '3-Sec Fuel Log');
  String get quickServiceCta => t('Catat Servis', 'Log Service');
  String get fuelSpendLabel => t('Bensin', 'Fuel');
  String get serviceSpendLabel => t('Servis', 'Service');
  String get noFuelDataShort => t('Catat 2x isi BBM', 'Log 2 fills');
  String get tapToLog => t('Ketuk untuk catat', 'Tap to log');
  String get dueInDays => t('hari lagi', 'days left');
  String get overdueByDays => t('telat', 'overdue by');
  String get daysUnit => t('hari', 'days');
  String get kmLeft => t('km lagi', 'km left');
  String get kmOverdue => t('km lewat', 'km overdue');
  String get nextDue => t('Berikutnya', 'Next due');
  String get expiresOn => t('Jatuh tempo', 'Due date');

  // Fuel
  String get fuelTabTitle => t('Catatan & Tren BBM', 'Fuel Log & Trend');
  String get fuelQuickCardTitle => t('Catat Isi Bensin 3 Detik', '3-Second Fuel Log');
  String get fuelTrendTitle => t('Grafik Tren Irit / Boros', 'Fuel Economy Trend');
  String get trendEfficient => t('Lebih Irit', 'More Efficient');
  String get trendHeavy => t('Lebih Boros', 'Higher Burn');
  String get trendSteady => t('Stabil', 'Steady');
  String get costPerKm => t('Biaya / km', 'Cost / km');
  String get totalFills => t('Total Isi', 'Total Fills');
  String get odometerLabel => t('Odometer (km)', 'Odometer (km)');
  String get litersLabel => t('Jumlah Liter', 'Liters');
  String get totalCostLabel => t('Total Biaya', 'Total Cost');
  String get fuelTypeLabel => t('Jenis BBM', 'Fuel Type');
  String get saveFuel => t('Simpan Isi Bensin', 'Save Fuel Log');
  String get fuelSaved => t('Catatan bensin tersimpan!', 'Fuel entry saved!');
  String get needMoreFuelPoints => t(
        'Catat minimal 2 pengisian bensin untuk melihat grafik tren km/L.',
        'Log at least 2 fuel fills to unlock the km/L trend chart.',
      );
  String get fuelHistory => t('Riwayat Pengisian', 'Fill-up History');
  String get liveEstimate => t('Estimasi Otomatis', 'Live Estimate');
  String get firstFillHint => t(
        'Isi pertama jadi acuan odometer. Isi berikutnya otomatis menghitung km/L.',
        'First fill sets baseline odometer. Next fill auto-calculates km/L.',
      );

  // Service
  String get serviceTabTitle => t('Buku Servis & Pengingat', 'Service Book & Reminders');
  String get exportServiceBook => t('Salin / Ekspor Buku Servis', 'Copy / Export Service Book');
  String get exportSubtitle => t(
        'Ringkasan rapi siap tempel untuk jual kendaraan bekas',
        'Clean resale-ready maintenance summary',
      );
  String get upcomingReminders => t('Pengingat Otomatis', 'Auto Reminders');
  String get serviceHistory => t('Riwayat Servis', 'Service History');
  String get addServiceTitle => t('Catat Servis Baru', 'Log New Service');
  String get serviceTitleLabel => t('Pekerjaan / Item Servis', 'Service Title / Work Done');
  String get workshopLabel => t('Bengkel (Opsional)', 'Workshop (Optional)');
  String get nextReminderKm => t('Pengingat +KM', 'Remind +KM');
  String get nextReminderMonths => t('Pengingat +Bulan', 'Remind +Months');
  String get notesLabel => t('Catatan (Opsional)', 'Notes (Optional)');
  String get saveService => t('Simpan Riwayat Servis', 'Save Service Log');
  String get serviceSaved => t('Riwayat servis & pengingat diperbarui!', 'Service & reminder updated!');
  String get noServiceYet => t(
        'Belum ada riwayat servis untuk kendaraan ini.',
        'No service records logged for this vehicle yet.',
      );
  String get copyToClipboard => t('Salin Ringkasan', 'Copy Summary');
  String get copiedSuccess => t(
        'Ringkasan Buku Servis berhasil disalin ke clipboard!',
        'Service Book summary copied to clipboard!',
      );
  String get exportModalTitle => t('Ringkasan Buku Servis', 'Service Book Summary');

  // Garage & Pro Pass
  String get garageTabTitle => t('Garasi Kendaraan', 'Vehicle Garage');
  String get addVehicle => t('Tambah Kendaraan', 'Add Vehicle');
  String get editVehicle => t('Edit Kendaraan', 'Edit Vehicle');
  String get vehicleNameLabel => t('Nama Kendaraan', 'Vehicle Name');
  String get plateNumberLabel => t('Plat Nomor', 'License Plate');
  String get taxDueDateLabel => t('Jatuh Tempo Pajak STNK', 'Tax / STNK Due Date');
  String get vehicleTypeLabel => t('Jenis Kendaraan', 'Vehicle Type');
  String get activeBadge => t('Aktif', 'Active');
  String get setActive => t('Pilih', 'Select');
  String get saveVehicle => t('Simpan Kendaraan', 'Save Vehicle');
  String get deleteConfirmTitle => t('Hapus Kendaraan?', 'Delete Vehicle?');
  String get deleteConfirmBody => t(
        'Semua catatan bensin dan servis untuk kendaraan ini juga akan dihapus.',
        'All fuel and service logs for this vehicle will also be removed.',
      );
  String get cancel => t('Batal', 'Cancel');
  String get delete => t('Hapus', 'Delete');
  String get close => t('Tutup', 'Close');
  String get settingsSection => t('Preferensi & Offline Data', 'Preferences & Offline Data');
  String get languageLabel => t('Bahasa Aplikasi', 'App Language');
  String get currencyLabel => t('Mata Uang', 'Currency');
  String get resetDemoLabel => t('Muat Ulang Data Contoh', 'Reset Sample Data');
  String get resetDemoDone => t('Data contoh berhasil dimuat ulang.', 'Sample data restored.');

  // Pro Pass Modal
  String get proModalTitle => t('Upgrade ke GarageLog Pro Pass', 'Upgrade to GarageLog Pro Pass');
  String get proModalSubtitle => t(
        'Bayar sekali seumur hidup. Tanpa langganan bulanan, 100% offline.',
        'One-time purchase for life. No subscriptions, 100% offline.',
      );
  String get proLimitNote => t(
        'Paket Gratis mendukung 1 kendaraan. Buka Pro Pass untuk kendaraan ke-2 dan seterusnya.',
        'Free plan includes 1 vehicle. Unlock Pro Pass for 2nd+ vehicles.',
      );
  String get proFeature1 => t('Garasi Motor & Mobil Tanpa Batas', 'Unlimited Motorcycles & Cars');
  String get proFeature2 => t('Stok Sparepart & Peralatan Tanpa Batas', 'Unlimited Garage Stock & Tools');
  String get proFeature3 => t('Ekspor Buku Servis Siap Jual & Backup JSON', 'Resale Service Book & JSON Backup');
  String get proPrice => currency == AppCurrency.idr ? 'Rp 49.000' : '\$3.99';
  String get proBuyCta => t(
        'Beli Pro Pass Sekali Bayar',
        'Buy One-Time Pro Pass',
      );
  String get proStoreHint => t(
        'Integrasi Google Play Billing siap dihubungkan saat rilis Play Console. Gunakan tombol simulasi dev di bawah untuk uji fitur Pro sekarang.',
        'Google Play Billing hook ready for Play Console release. Use the Dev Simulation button below to test Pro features right now.',
      );
  String get proDevActivate => t(
        'Simulasi Dev: Aktifkan Pro Pass',
        'Dev Simulation: Unlock Pro Pass',
      );
  String get proDevDeactivate => t(
        'Simulasi Dev: Kembali ke Gratis',
        'Dev Simulation: Revert to Free',
      );
  String get proUnlockedBanner => t(
        'Pro Pass Aktif — Kendaraan & Stok Tanpa Batas',
        'Pro Pass Active — Unlimited Vehicles & Stock',
      );
  String get proUpgradeBanner => t(
        'Buka Pro Pass (Bayar Sekali)',
        'Unlock Pro Pass (One-Time)',
      );

  // Garage Stock & Tools
  String get subTabVehicles => t('Unit Kendaraan', 'Vehicles');
  String get subTabStock => t('Stok & Alat', 'Stock & Tools');
  String get inventoryTitle => t('Stok & Peralatan Garasi', 'Garage Stock & Tools');
  String get addInventoryItem => t('Tambah Stok / Alat', 'Add Stock / Tool');
  String get editInventoryItem => t('Edit Item Garasi', 'Edit Garage Item');
  String get typeConsumable => t('Sparepart / Oli', 'Parts / Fluids');
  String get typeTool => t('Peralatan (Tools)', 'Tools');
  String get itemNameLabel => t('Nama Barang / Alat', 'Item / Tool Name');
  String get quantityLabel => t('Jumlah Stok', 'Quantity');
  String get minStockLabel => t('Batas Hampir Habis', 'Low Stock Alert');
  String get unitLabel => t('Satuan (botol/pcs/set)', 'Unit (bottle/pcs/set)');
  String get unitPriceLabel => t('Harga Satuan (Opsional)', 'Unit Price (Optional)');
  String get locationLabel => t('Lokasi Simpan (Rak/Box)', 'Storage Location');
  String get saveItem => t('Simpan Item', 'Save Item');
  String get stockSafe => t('Stok Aman', 'In Stock');
  String get stockLow => t('Hampir Habis', 'Low Stock');
  String get stockEmpty => t('Habis', 'Out of Stock');
  String get toolAvailable => t('Tersedia', 'Available');
  String get toolBorrowed => t('Dipinjam', 'Loaned Out');
  String get loanTool => t('Catat Pinjam', 'Loan Tool');
  String get returnTool => t('Kembalikan', 'Mark Returned');
  String get borrowerNameLabel => t('Nama Peminjam', 'Borrower Name');
  String get borrowedByPrefix => t('Dipinjam', 'Loaned to');
  String get noInventoryYet => t(
        'Belum ada stok sparepart atau peralatan tercatat.',
        'No garage parts or tools tracked yet.',
      );
  String get proStockLimitNote => t(
        'Paket Gratis mendukung hingga 5 item stok/alat. Buka Pro Pass untuk inventaris garasi tanpa batas.',
        'Free plan includes up to 5 stock/tool items. Unlock Pro Pass for unlimited garage inventory.',
      );
  String get useFromStockTitle => t(
        'Pakai dari Stok Garasi (Opsional)',
        'Use from Garage Stock (Optional)',
      );
  String get useFromStockHint => t(
        'Pilih item untuk otomatis kurangi stok (-1) & isi biaya',
        'Select items to auto-deduct stock (-1) & estimate cost',
      );
  String get stockSummaryConsumables => t('Stok Part', 'Parts');
  String get stockSummaryLow => t('Menipis', 'Low');
  String get stockSummaryLoaned => t('Dipinjam', 'Loaned');

  // Backup & Restore Offline JSON
  String get backupRestoreTitle => t('Backup & Restore Offline (.json)', 'Offline Backup & Restore (.json)');
  String get backupRestoreSubtitle => t(
        'Amankan atau pindahkan data antar HP 100% offline',
        'Back up or migrate data across devices 100% offline',
      );
  String get backupTabLabel => t('Ekspor Backup', 'Export Backup');
  String get restoreTabLabel => t('Pulihkan Data', 'Restore Data');
  String get copyBackupJson => t('Salin Backup JSON', 'Copy Backup JSON');
  String get backupCopied => t(
        'Backup JSON berhasil disalin! Simpan di catatan/Drive Anda.',
        'Backup JSON copied! Save it safely in your notes or Drive.',
      );
  String get pasteBackupHint => t(
        'Tempel (paste) teks Backup JSON GarageLog di sini...',
        'Paste GarageLog Backup JSON text here...',
      );
  String get pasteFromClipboard => t('Tempel dari Clipboard', 'Paste from Clipboard');
  String get restoreNow => t('Pulihkan Sekarang', 'Restore Now');
  String get restoreSuccess => t(
        'Data garasi berhasil dipulihkan dari backup!',
        'Garage data restored successfully from backup!',
      );
  String get restoreInvalid => t(
        'Format JSON backup tidak valid. Pastikan salin secara utuh.',
        'Invalid backup JSON format. Please paste the complete backup.',
      );
  String get restoreWarning => t(
        'Memulihkan backup akan mengganti data lokal saat ini dengan isi file backup.',
        'Restoring a backup will replace your current local data with the backup contents.',
      );

  // First-Install Master Data Setup
  String get setupWelcomeTitle => t('Selamat Datang di GarageLog', 'Welcome to GarageLog');
  String get setupWelcomeSubtitle => t(
        'Atur data master garasi & kendaraan pertama Anda sekali saja. 100% tersimpan offline di perangkat.',
        'Set up your garage master data & first vehicle once. 100% stored offline on your device.',
      );
  String get setupSectionProfile => t('1. Data Master Garasi', '1. Garage Master Profile');
  String get setupSectionVehicle => t('2. Kendaraan Pertama Anda', '2. Your First Vehicle');
  String get setupSectionIntervals => t('3. Standar Interval Pengingat', '3. Default Reminder Intervals');
  String get garageNameLabel => t('Nama Garasi / Pemilik', 'Garage / Owner Name');
  String get defaultWorkshopLabel => t('Bengkel Langganan Default (Opsional)', 'Default Workshop (Optional)');
  String get defaultFuelLabel => t('Jenis BBM Utama', 'Default Fuel Type');
  String get baselineToggleTitle => t(
        'Mulai status servis dari odometer sekarang',
        'Start service tracking from current odometer',
      );
  String get baselineToggleSubtitle => t(
        'Otomatis buat acuan awal Ganti Oli, Servis Rutin & Rem/Ban di KM saat ini.',
        'Creates initial Oil, Routine & Brakes baseline at your current odometer.',
      );
  String get startUsingApp => t('Simpan & Masuk ke Dashboard', 'Save & Open Dashboard');
  String get useDemoDataCta => t('Lewati & Coba Data Contoh', 'Skip & Try Demo Data');
  String get editMasterData => t('Edit Data Master Garasi', 'Edit Garage Master Data');
  String get masterDataSaved => t('Data master garasi diperbarui!', 'Garage master data updated!');
  String get intervalKmHint => t('+KM', '+KM');
  String get intervalMonthHint => t('+Bln', '+Mo');
  String get initialBaselineTitle => t('Acuan Awal', 'Initial Baseline');

  // Offline Photo Receipt & OCR Auto-Fill
  String get scanReceiptTitle => t('Scan Foto Nota Otomatis', 'Auto-Scan Receipt Photo');
  String get scanReceiptSubtitle => t(
        'Foto nota bengkel -> otomatis isi item, biaya, bengkel & KM (100% offline)',
        'Snap workshop receipt -> auto-fills service, cost, shop & KM (100% offline)',
      );
  String get pickFromCamera => t('Kamera', 'Camera');
  String get pickFromGallery => t('Galeri', 'Gallery');
  String get smartPasteReceipt => t('Tempel Teks Nota', 'Paste Receipt Text');
  String get scanningReceipt => t('Membaca teks nota secara offline...', 'Scanning receipt offline...');
  String get scanAutoFilled => t(
        'Data servis berhasil diekstrak otomatis dari nota! Silakan cek sebelum simpan.',
        'Service details auto-filled from receipt! Please review before saving.',
      );
  String get scanNoTextFound => t(
        'Foto nota terlampir, tapi teks kurang terbaca. Silakan lengkapi manual.',
        'Receipt photo attached, but text was unclear. Please fill in manually.',
      );
  String get scanWebHint => t(
        'Foto nota terlampir! OCR otomatis berjalan native di Android/iOS. Di Chrome, gunakan "Tempel Teks Nota" untuk uji parser otomatis.',
        'Receipt photo attached! Native OCR runs on Android/iOS. On Chrome, use "Paste Receipt Text" to try auto-parsing.',
      );
  String get pasteReceiptDialogTitle => t('Tempel Teks Nota Bengkel', 'Paste Workshop Receipt Text');
  String get pasteReceiptHint => t(
        'Tempel teks nota/struk bengkel di sini, atau klik "Isi Contoh Nota" untuk mencoba...',
        'Paste workshop receipt text here, or tap "Load Sample" to try...',
      );
  String get loadSampleReceipt => t('Isi Contoh Nota', 'Load Sample');
  String get parseReceiptNow => t('Ekstrak Otomatis', 'Auto-Fill Form');
  String get receiptAttachedBadge => t('Foto Nota', 'Receipt');
  String get viewReceiptPhoto => t('Lihat Foto Nota', 'View Receipt Photo');
  String get removePhoto => t('Hapus Foto', 'Remove Photo');

  // Top Sparepart Brands Dashboard
  String get topBrandsTitle => t('Merek Sparepart Favorit', 'Top Sparepart Brands');
  String get topBrandsSubtitle => t(
        'Merek oli & sparepart yang paling sering dipakai',
        'Most frequently used oil & sparepart brands',
      );
  String get partBrandLabel => t('Merek Sparepart / Oli (Opsional)', 'Sparepart / Oil Brand (Optional)');
  String get partBrandHint => t('Contoh: Motul, AHM Oil, Nissin, Michelin', 'e.g. Motul, Shell, Brembo, Michelin');
  String get brandUsedSuffix => t('x dipakai', 'x used');
  String get topBrandBadge => t('Favorit #1', '#1 Favorite');
  String get scopeActiveVehicle => t('Unit Ini', 'This Unit');
  String get scopeAllGarage => t('Semua Garasi', 'All Garage');
  String get noBrandDataYet => t(
        'Isi merek sparepart saat mencatat servis untuk melihat peringkat merek andalan Anda.',
        'Add a sparepart brand when logging services to see your top brands ranking.',
      );
  String get exchangeRateLabel => t('Kurs Konversi (1 USD = Rp)', 'Exchange Rate (1 USD = IDR)');

  // Local Push Notifications (Offline)
  String get notifSectionTitle => t('Push Notification Pengingat', 'Reminder Push Notifications');
  String get notifToggleLabel => t('Aktifkan Notifikasi Pengingat', 'Enable Reminder Notifications');
  String get notifToggleSubtitle => t(
        'Otomatis ingatkan H-14 & H-3 Pajak STNK serta H-3 jadwal servis (100% offline)',
        'Auto-alerts 14d & 3d before STNK tax and 3d before scheduled service (100% offline)',
      );
  String get testNotificationBtn => t('Tes Kirim Push Notification', 'Test Push Notification');
  String get notifScheduledSuffix => t('pengingat terjadwal', 'reminders scheduled');
  String get notifSentNative => t(
        'Push notification terkirim ke status bar HP Anda!',
        'Push notification sent to your device!',
      );
  String get notifPreviewHint => t(
        'Preview Push Notification (mode native aktif otomatis saat di-install di Android/iOS)',
        'Push Notification preview (native OS alerts run when installed on Android/iOS)',
      );
  String get notifNowLabel => t('sekarang', 'now');

  // Validation
  String get requiredField => t('Wajib diisi', 'Required');
  String get invalidNumber => t('Masukkan angka yang valid', 'Enter a valid number');
  String get mustBeGreaterZero => t('Harus lebih dari 0', 'Must be greater than 0');

  // Formatting helpers
  String formatKm(int km) {
    final sep = currency == AppCurrency.idr ? '.' : ',';
    return '${_groupInt(km, sep)} km';
  }

  String formatNumber(num value, {int decimals = 1}) {
    final fixed = value.toStringAsFixed(decimals);
    if (currency == AppCurrency.idr) {
      return fixed.replaceAll('.', ',');
    }
    return fixed;
  }

  String formatCurrency(double amountInBaseIdr, {bool allowDecimalsForUsd = true}) {
    if (currency == AppCurrency.idr) {
      final rounded = amountInBaseIdr.round();
      final prefix = rounded < 0 ? '-Rp ' : 'Rp ';
      return '$prefix${_groupInt(rounded.abs(), '.')}';
    } else {
      final converted = fromBaseIdr(amountInBaseIdr);
      final absVal = converted.abs();
      final prefix = converted < 0 ? '-\$' : '\$';
      if (!allowDecimalsForUsd && absVal >= 100) {
        return '$prefix${_groupInt(absVal.round(), ',')}';
      }
      if (absVal >= 1000) {
        return '$prefix${_groupInt(absVal.round(), ',')}';
      }
      final parts = absVal.toStringAsFixed(2).split('.');
      final intPart = _groupInt(int.parse(parts[0]), ',');
      return '$prefix$intPart.${parts[1]}';
    }
  }

  String formatDate(DateTime date) {
    const idMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    const enMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = isId ? idMonths[date.month - 1] : enMonths[date.month - 1];
    return '${date.day} $m ${date.year}';
  }

  String formatShortDate(DateTime date) {
    const idMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    const enMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = isId ? idMonths[date.month - 1] : enMonths[date.month - 1];
    return '${date.day} $m';
  }

  static String _groupInt(int value, String sep) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      if (i > 0 && remaining % 3 == 0) {
        buf.write(sep);
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
