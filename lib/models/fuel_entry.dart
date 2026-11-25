class FuelEntry {
  const FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometerKm,
    required this.liters,
    required this.totalCost,
    required this.fuelType,
    this.notes = '',
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final int odometerKm;
  final double liters;
  final double totalCost;
  final String fuelType;
  final String notes;

  double get pricePerLiter => liters > 0 ? totalCost / liters : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'odometerKm': odometerKm,
      'liters': liters,
      'totalCost': totalCost,
      'fuelType': fuelType,
      'notes': notes,
    };
  }

  factory FuelEntry.fromJson(Map<String, dynamic> json) {
    return FuelEntry(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      date: DateTime.parse(json['date'] as String),
      odometerKm: (json['odometerKm'] as num).toInt(),
      liters: (json['liters'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      fuelType: json['fuelType'] as String,
      notes: (json['notes'] as String?) ?? '',
    );
  }
}
