import 'fuel_entry.dart';
import 'service_entry.dart';

enum HealthLevel { safe, soon, overdue, unknown }

enum EfficiencyTrend { efficient, steady, heavy, none }

class HealthStatusItem {
  const HealthStatusItem({
    required this.keyId,
    required this.level,
    this.category,
    this.isTax = false,
    this.lastService,
    this.nextDueKm,
    this.kmRemaining,
    this.nextDueDate,
    this.daysRemaining,
    this.progress = 0.0,
  });

  final String keyId;
  final HealthLevel level;
  final ServiceCategory? category;
  final bool isTax;
  final ServiceEntry? lastService;
  final int? nextDueKm;
  final int? kmRemaining;
  final DateTime? nextDueDate;
  final int? daysRemaining;

  /// Progress from 0.0 (just serviced) to 1.0 (due/overdue).
  final double progress;
}

class FuelComputedEntry {
  const FuelComputedEntry({
    required this.entry,
    this.distanceKm,
    this.kmPerLiter,
    this.costPerKm,
  });

  final FuelEntry entry;
  final int? distanceKm;
  final double? kmPerLiter;
  final double? costPerKm;
}

class FuelAnalytics {
  const FuelAnalytics({
    required this.computedDescending,
    required this.trendPoints,
    required this.avgKmPerLiter,
    required this.avgCostPerKm,
    required this.latestKmPerLiter,
    required this.trend,
    required this.trendDeltaPercent,
  });

  final List<FuelComputedEntry> computedDescending;
  final List<FuelComputedEntry> trendPoints;
  final double? avgKmPerLiter;
  final double? avgCostPerKm;
  final double? latestKmPerLiter;
  final EfficiencyTrend trend;
  final double trendDeltaPercent;
}
