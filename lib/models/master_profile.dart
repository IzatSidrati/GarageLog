import 'service_entry.dart';
import 'vehicle.dart';

class GarageMasterProfile {
  const GarageMasterProfile({
    this.garageName = '',
    this.ownerName = '',
    this.defaultWorkshop = '',
    this.defaultFuelType = 'Pertamax',
    this.oilIntervalKm = 2000,
    this.oilIntervalMonths = 2,
    this.routineIntervalKm = 4000,
    this.routineIntervalMonths = 4,
    this.brakesIntervalKm = 8000,
    this.brakesIntervalMonths = 8,
  });

  final String garageName;
  final String ownerName;
  final String defaultWorkshop;
  final String defaultFuelType;
  final int oilIntervalKm;
  final int oilIntervalMonths;
  final int routineIntervalKm;
  final int routineIntervalMonths;
  final int brakesIntervalKm;
  final int brakesIntervalMonths;

  factory GarageMasterProfile.defaultsFor(
    VehicleType primaryType, {
    String defaultFuelType = 'Pertamax',
  }) {
    final oil = ServiceEntry.defaultIntervals(primaryType, ServiceCategory.oil);
    final routine =
        ServiceEntry.defaultIntervals(primaryType, ServiceCategory.routine);
    final brakes =
        ServiceEntry.defaultIntervals(primaryType, ServiceCategory.brakesTires);

    return GarageMasterProfile(
      defaultFuelType: defaultFuelType,
      oilIntervalKm: oil.km,
      oilIntervalMonths: oil.months,
      routineIntervalKm: routine.km,
      routineIntervalMonths: routine.months,
      brakesIntervalKm: brakes.km,
      brakesIntervalMonths: brakes.months,
    );
  }

  ({int km, int months}) intervalFor(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.oil:
        return (km: oilIntervalKm, months: oilIntervalMonths);
      case ServiceCategory.routine:
        return (km: routineIntervalKm, months: routineIntervalMonths);
      case ServiceCategory.brakesTires:
        return (km: brakesIntervalKm, months: brakesIntervalMonths);
      case ServiceCategory.other:
        return (km: 0, months: 0);
    }
  }

  GarageMasterProfile copyWith({
    String? garageName,
    String? ownerName,
    String? defaultWorkshop,
    String? defaultFuelType,
    int? oilIntervalKm,
    int? oilIntervalMonths,
    int? routineIntervalKm,
    int? routineIntervalMonths,
    int? brakesIntervalKm,
    int? brakesIntervalMonths,
  }) {
    return GarageMasterProfile(
      garageName: garageName ?? this.garageName,
      ownerName: ownerName ?? this.ownerName,
      defaultWorkshop: defaultWorkshop ?? this.defaultWorkshop,
      defaultFuelType: defaultFuelType ?? this.defaultFuelType,
      oilIntervalKm: oilIntervalKm ?? this.oilIntervalKm,
      oilIntervalMonths: oilIntervalMonths ?? this.oilIntervalMonths,
      routineIntervalKm: routineIntervalKm ?? this.routineIntervalKm,
      routineIntervalMonths:
          routineIntervalMonths ?? this.routineIntervalMonths,
      brakesIntervalKm: brakesIntervalKm ?? this.brakesIntervalKm,
      brakesIntervalMonths: brakesIntervalMonths ?? this.brakesIntervalMonths,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'garageName': garageName,
      'ownerName': ownerName,
      'defaultWorkshop': defaultWorkshop,
      'defaultFuelType': defaultFuelType,
      'oilIntervalKm': oilIntervalKm,
      'oilIntervalMonths': oilIntervalMonths,
      'routineIntervalKm': routineIntervalKm,
      'routineIntervalMonths': routineIntervalMonths,
      'brakesIntervalKm': brakesIntervalKm,
      'brakesIntervalMonths': brakesIntervalMonths,
    };
  }

  factory GarageMasterProfile.fromJson(Map<String, dynamic> json) {
    return GarageMasterProfile(
      garageName: (json['garageName'] as String?) ?? '',
      ownerName: (json['ownerName'] as String?) ?? '',
      defaultWorkshop: (json['defaultWorkshop'] as String?) ?? '',
      defaultFuelType: (json['defaultFuelType'] as String?) ?? 'Pertamax',
      oilIntervalKm: (json['oilIntervalKm'] as num?)?.toInt() ?? 2000,
      oilIntervalMonths: (json['oilIntervalMonths'] as num?)?.toInt() ?? 2,
      routineIntervalKm: (json['routineIntervalKm'] as num?)?.toInt() ?? 4000,
      routineIntervalMonths:
          (json['routineIntervalMonths'] as num?)?.toInt() ?? 4,
      brakesIntervalKm: (json['brakesIntervalKm'] as num?)?.toInt() ?? 8000,
      brakesIntervalMonths:
          (json['brakesIntervalMonths'] as num?)?.toInt() ?? 8,
    );
  }
}
