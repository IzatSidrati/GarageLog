enum VehicleType { motorcycle, car }

class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.type,
    required this.odometerKm,
    required this.taxDueDate,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String plateNumber;
  final VehicleType type;
  final int odometerKm;
  final DateTime taxDueDate;
  final DateTime createdAt;

  Vehicle copyWith({
    String? id,
    String? name,
    String? plateNumber,
    VehicleType? type,
    int? odometerKm,
    DateTime? taxDueDate,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      type: type ?? this.type,
      odometerKm: odometerKm ?? this.odometerKm,
      taxDueDate: taxDueDate ?? this.taxDueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plateNumber': plateNumber,
      'type': type.name,
      'odometerKm': odometerKm,
      'taxDueDate': taxDueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      name: json['name'] as String,
      plateNumber: json['plateNumber'] as String,
      type: VehicleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VehicleType.motorcycle,
      ),
      odometerKm: (json['odometerKm'] as num).toInt(),
      taxDueDate: DateTime.parse(json['taxDueDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
