import '../l10n/app_strings.dart';
import '../models/service_entry.dart';
import 'brand_detector.dart';

class ParsedServiceReceipt {
  const ParsedServiceReceipt({
    required this.category,
    required this.title,
    this.totalCost,
    this.workshop,
    this.odometerKm,
    this.partBrand,
    this.detectedItems = const [],
    this.rawText = '',
  });

  final ServiceCategory category;
  final String title;
  final double? totalCost;
  final String? workshop;
  final int? odometerKm;
  final String? partBrand;
  final List<String> detectedItems;
  final String rawText;

  bool get hasAnyDetection =>
      totalCost != null ||
      (workshop != null && workshop!.isNotEmpty) ||
      odometerKm != null ||
      (partBrand != null && partBrand!.isNotEmpty) ||
      detectedItems.isNotEmpty;
}

class ReceiptParser {
  const ReceiptParser._();

  static const _oilKeywords = [
    'oli',
    'oil',
    'mpx',
    'spx',
    'yamalube',
    'motul',
    'shell advance',
    'shell helix',
    'castrol',
    'pertamina enduro',
    'fastron',
    'gardan',
    'gear oil',
    'pelumas',
    'filter oli',
    'oil filter',
    '5w-30',
    '10w-40',
    'synthetic',
  ];

  static const _routineKeywords = [
    'cvt',
    'v-belt',
    'vbelt',
    'roller',
    'throttle',
    'injeksi',
    'injector',
    'tune up',
    'tuneup',
    'servis berkala',
    'service berkala',
    'servis rutin',
    'servis lengkap',
    'paket servis',
    'busi',
    'spark plug',
    'filter udara',
    'air filter',
    'radiator',
    'coolant',
    'aki',
    'battery',
    'routine',
    'maintenance',
  ];

  static const _brakesTiresKeywords = [
    'kampas',
    'rem',
    'brake',
    'diskpad',
    'disc pad',
    'cakram',
    'ban ',
    'ban depan',
    'ban belakang',
    'tubeless',
    'tire',
    'tyre',
    'pentil',
    'spooring',
    'balancing',
    'shock',
    'velg',
  ];

  static const _workshopMarkers = [
    'ahass',
    'auto2000',
    'auto 2000',
    'planet ban',
    'shop & drive',
    'shop&drive',
    'bengkel',
    'motor',
    'garage',
    'autocare',
    'auto care',
    'service center',
    'yamaha',
    'honda',
    'toyota',
    'suzuki',
    'daihatsu',
    'mitsubishi',
    'astra',
    'nawilis',
    'otoklix',
  ];

  static const _totalLineKeywords = [
    'grand total',
    'total bayar',
    'total tagihan',
    'jumlah bayar',
    'total',
    'netto',
    'amount due',
    'balance due',
    'subtotal',
    'jumlah',
  ];

  static const _ignoreItemWords = [
    'total',
    'subtotal',
    'tunai',
    'cash',
    'kembali',
    'change',
    'kembalian',
    'ppn',
    'pajak',
    'tax',
    'diskon',
    'discount',
    'terima kasih',
    'thank you',
    'nota',
    'invoice',
    'tanggal',
    'date',
    'kasir',
    'mekanik',
    'no. pol',
    'nopol',
    'plat',
    'km',
    'odo',
    'telp',
    'hp',
    'jl.',
    'jalan',
  ];

  static ParsedServiceReceipt parse(String rawText, AppStrings strings) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return ParsedServiceReceipt(
        category: ServiceCategory.other,
        title: strings.catOther,
        rawText: rawText,
      );
    }

    final workshop = _extractWorkshop(lines);
    final odometerKm = _extractOdometer(lines);
    final totalCost = _extractTotalCost(lines, strings.currency);
    final itemResult = _extractItemsAndCategory(lines);
    final detectedBrand = BrandDetector.detectFromText(rawText);

    String title;
    if (itemResult.items.isNotEmpty) {
      final cleanTop = itemResult.items.take(2).map(_cleanItemLabel).toList();
      title = cleanTop.join(' + ');
    } else {
      title = _defaultTitleForCategory(itemResult.category, strings);
    }

    return ParsedServiceReceipt(
      category: itemResult.category,
      title: title,
      totalCost: totalCost,
      workshop: workshop,
      odometerKm: odometerKm,
      partBrand: detectedBrand,
      detectedItems: itemResult.items,
      rawText: rawText,
    );
  }

  static String? _extractWorkshop(List<String> lines) {
    final topLimit = lines.length < 5 ? lines.length : 5;
    for (int i = 0; i < topLimit; i++) {
      final lower = lines[i].toLowerCase();
      if (_workshopMarkers.any((m) => lower.contains(m))) {
        return _cleanSpaces(lines[i]);
      }
    }
    // Fallback: first non-numeric/non-date line in top 2 lines
    for (int i = 0; i < (lines.length < 2 ? lines.length : 2); i++) {
      final candidate = _cleanSpaces(lines[i]);
      final lower = candidate.toLowerCase();
      if (candidate.length >= 4 &&
          !RegExp(r'^\d').hasMatch(candidate) &&
          !lower.contains('nota') &&
          !lower.contains('struk') &&
          !lower.contains('invoice')) {
        return candidate;
      }
    }
    return null;
  }

  static int? _extractOdometer(List<String> lines) {
    final patterns = [
      RegExp(
        r'(?:odometer|odo|km)\s*[:=\-]?\s*(\d{1,3}(?:[.,]\d{3})+|\d{3,6})\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(\d{1,3}(?:[.,]\d{3})+|\d{3,6})\s*km\b',
        caseSensitive: false,
      ),
    ];

    for (final line in lines) {
      for (final regex in patterns) {
        final match = regex.firstMatch(line);
        if (match != null) {
          final digits = match.group(1)!.replaceAll(RegExp(r'[.,]'), '');
          final value = int.tryParse(digits);
          if (value != null && value >= 100 && value <= 999999) {
            return value;
          }
        }
      }
    }
    return null;
  }

  static double? _extractTotalCost(List<String> lines, AppCurrency currency) {
    double? bestFromTotalLine;
    int bestPriority = -1;

    for (final line in lines) {
      final lower = line.toLowerCase();
      int priority = -1;
      for (int p = 0; p < _totalLineKeywords.length; p++) {
        if (lower.contains(_totalLineKeywords[p])) {
          // Earlier keyword in list = higher priority
          priority = _totalLineKeywords.length - p;
          break;
        }
      }
      if (priority >= 0) {
        final nums = _extractMoneyValues(line, currency);
        if (nums.isNotEmpty) {
          final val = nums.last;
          if (priority >= bestPriority) {
            bestPriority = priority;
            bestFromTotalLine = val;
          }
        }
      }
    }

    if (bestFromTotalLine != null) return bestFromTotalLine;

    // Fallback: pick largest money value across receipt
    double? maxVal;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('km') || lower.contains('odo')) continue;
      for (final val in _extractMoneyValues(line, currency)) {
        if (maxVal == null || val > maxVal) {
          maxVal = val;
        }
      }
    }
    return maxVal;
  }

  static List<double> _extractMoneyValues(String line, AppCurrency currency) {
    final results = <double>[];
    final hasDollar = line.contains('\$');
    final hasRp = RegExp(r'\b(?:rp|idr)\b', caseSensitive: false).hasMatch(line);

    final numRegex = RegExp(r'(?:rp\.?\s*|\$\s*)?(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:\.\d{1,2})?)',
        caseSensitive: false);

    for (final m in numRegex.allMatches(line)) {
      final raw = m.group(1)!;
      // Ignore likely phone numbers or dates (> 9 digits)
      final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length > 9) continue;

      final parsed = _parseMoneyToken(
        raw,
        treatAsUsd: hasDollar || (!hasRp && currency == AppCurrency.usd),
      );
      if (parsed == null) continue;

      // Filter unrealistic tiny integers unless USD
      if (hasDollar || (!hasRp && currency == AppCurrency.usd)) {
        if (parsed >= 1.0 && parsed <= 100000) results.add(parsed);
      } else {
        if (parsed >= 5000 && parsed <= 500000000) results.add(parsed);
      }
    }
    return results;
  }

  static double? _parseMoneyToken(String raw, {required bool treatAsUsd}) {
    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(raw)) {
      return double.tryParse(raw.replaceAll('.', ''));
    }
    if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(raw)) {
      return double.tryParse(raw.replaceAll(',', ''));
    }
    if (RegExp(r'^\d{1,3}(,\d{3})+\.\d{1,2}$').hasMatch(raw)) {
      return double.tryParse(raw.replaceAll(',', ''));
    }
    if (RegExp(r'^\d{1,3}(\.\d{3})+,\d{1,2}$').hasMatch(raw)) {
      return double.tryParse(raw.replaceAll('.', '').replaceAll(',', '.'));
    }
    if (treatAsUsd) {
      return double.tryParse(raw.replaceAll(',', '.'));
    }
    return double.tryParse(raw.replaceAll(RegExp(r'[.,]'), ''));
  }

  static ({ServiceCategory category, List<String> items})
      _extractItemsAndCategory(List<String> lines) {
    int oilScore = 0;
    int routineScore = 0;
    int brakesScore = 0;
    final matchedItems = <String>[];

    for (final line in lines) {
      final lower = ' ${line.toLowerCase()} ';
      if (_ignoreItemWords.any((w) => lower.contains(w))) {
        // Still allow scoring if it mentions specific service keywords
      }

      final hasOil = _oilKeywords.any((k) => lower.contains(k));
      final hasRoutine = _routineKeywords.any((k) => lower.contains(k));
      final hasBrakes = _brakesTiresKeywords.any((k) => lower.contains(k));

      if (hasOil) oilScore += 2;
      if (hasRoutine) routineScore += 2;
      if (hasBrakes) brakesScore += 2;

      final isIgnored = _ignoreItemWords.any((w) => lower.trim().startsWith(w));
      if ((hasOil || hasRoutine || hasBrakes) && !isIgnored) {
        final cleaned = _cleanItemLabel(line);
        if (cleaned.length >= 3 && !matchedItems.contains(cleaned)) {
          matchedItems.add(cleaned);
        }
      }
    }

    ServiceCategory category = ServiceCategory.other;
    if (oilScore == 0 && routineScore == 0 && brakesScore == 0) {
      category = ServiceCategory.other;
    } else if (oilScore >= routineScore && oilScore >= brakesScore) {
      category = ServiceCategory.oil;
    } else if (routineScore >= brakesScore) {
      category = ServiceCategory.routine;
    } else {
      category = ServiceCategory.brakesTires;
    }

    return (category: category, items: matchedItems);
  }

  static String _cleanItemLabel(String raw) {
    // Remove trailing price/currency tokens from an item line
    var s = raw.replaceAll(
      RegExp(
        r'(?:rp\.?\s*|\$\s*)?\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?\s*$',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(RegExp(r'\s*\$\s*\d+(?:\.\d{1,2})?\s*$'), '');
    s = s.replaceAll(RegExp(r'^\s*[-•*\d.)]+\s*'), '');
    s = _cleanSpaces(s);
    if (s.length > 48) {
      s = '${s.substring(0, 48).trim()}…';
    }
    return s;
  }

  static String _cleanSpaces(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _defaultTitleForCategory(ServiceCategory cat, AppStrings s) {
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
}
