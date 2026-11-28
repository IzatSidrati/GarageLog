import 'vehicle.dart';

enum ServiceCategory { oil, routine, brakesTires, other }

class ServiceEntry {
  const ServiceEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometerKm,
    required this.category,
    required this.title,
    required this.cost,
    this.workshop = '',
    this.nextIntervalKm = 0,
    this.nextIntervalMonths = 0,
    this.notes = '',
    this.partBrand = '',
    this.receiptImageBase64,
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final int odometerKm;
  final ServiceCategory category;
  final String title;
  final double cost;
  final String workshop;
  final int nextIntervalKm;
  final int nextIntervalMonths;
  final String notes;
  final String partBrand;
  final String? receiptImageBase64;

  bool get hasReceiptPhoto =>
      receiptImageBase64 != null && receiptImageBase64!.isNotEmpty;

  int? get nextDueKm => nextIntervalKm > 0 ? odometerKm + nextIntervalKm : null;

  DateTime? get nextDueDate {
    if (nextIntervalMonths <= 0) return null;
    final totalMonths = (date.month - 1) + nextIntervalMonths;
    final targetYear = date.year + (totalMonths ~/ 12);
    final targetMonth = (totalMonths % 12) + 1;
    final maxDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = date.day > maxDay ? maxDay : date.day;
    return DateTime(targetYear, targetMonth, targetDay);
  }

  static ({int km, int months}) defaultIntervals(
    VehicleType type,
    ServiceCategory category,
  ) {
    switch (category) {
      case ServiceCategory.oil:
        return type == VehicleType.motorcycle
            ? (km: 2000, months: 2)
            : (km: 5000, months: 6);
      case ServiceCategory.routine:
        return type == VehicleType.motorcycle
            ? (km: 4000, months: 4)
            : (km: 10000, months: 6);
      case ServiceCategory.brakesTires:
        return type == VehicleType.motorcycle
            ? (km: 8000, months: 8)
            : (km: 15000, months: 12);
      case ServiceCategory.other:
        return (km: 0, months: 0);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'odometerKm': odometerKm,
      'category': category.name,
      'title': title,
      'cost': cost,
      'workshop': workshop,
      'nextIntervalKm': nextIntervalKm,
      'nextIntervalMonths': nextIntervalMonths,
      'notes': notes,
      'partBrand': partBrand,
      if (receiptImageBase64 != null) 'receiptImageBase64': receiptImageBase64,
    };
  }

  factory ServiceEntry.fromJson(Map<String, dynamic> json) {
    return ServiceEntry(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      date: DateTime.parse(json['date'] as String),
      odometerKm: (json['odometerKm'] as num).toInt(),
      category: ServiceCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ServiceCategory.other,
      ),
      title: json['title'] as String,
      cost: (json['cost'] as num).toDouble(),
      workshop: (json['workshop'] as String?) ?? '',
      nextIntervalKm: (json['nextIntervalKm'] as num?)?.toInt() ?? 0,
      nextIntervalMonths: (json['nextIntervalMonths'] as num?)?.toInt() ?? 0,
      notes: (json['notes'] as String?) ?? '',
      partBrand: (json['partBrand'] as String?) ?? '',
      receiptImageBase64: json['receiptImageBase64'] as String?,
    );
  }
}
