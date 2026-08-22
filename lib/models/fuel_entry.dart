class FuelEntry {
  final int? id;
  final int vehicleId;
  final double odometer;
  final double litres;
  final DateTime date;
  final double? reserveOdometer;
  final double? reserveOffset;
  final double? distance;
  final double? mileage;
  final double? rate;
  final String? fuelType;
  final String? bunkName;

  FuelEntry({
    this.id,
    required this.vehicleId,
    required this.odometer,
    required this.litres,
    required this.date,
    this.reserveOdometer,
    this.reserveOffset,
    this.distance,
    this.mileage,
    this.rate,
    this.fuelType,
    this.bunkName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'odometer': odometer,
      'litres': litres,
      'date': date.toIso8601String(),
      'reserveOdometer': reserveOdometer,
      'reserveOffset': reserveOffset,
      'distance': distance,
      'mileage': mileage,
      'rate': rate,
      'fuelType': fuelType,
      'bunkName': bunkName,
    };
  }

  factory FuelEntry.fromMap(Map<String, dynamic> map) {
    return FuelEntry(
      id: map['id'] as int?,
      vehicleId: map['vehicleId'] as int,
      odometer: (map['odometer'] as num).toDouble(),
      litres: (map['litres'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      reserveOdometer: map['reserveOdometer'] != null ? (map['reserveOdometer'] as num).toDouble() : null,
      reserveOffset: map['reserveOffset'] != null ? (map['reserveOffset'] as num).toDouble() : null,
      distance: map['distance'] != null ? (map['distance'] as num).toDouble() : null,
      mileage: map['mileage'] != null ? (map['mileage'] as num).toDouble() : null,
      rate: map['rate'] != null ? (map['rate'] as num).toDouble() : null,
      fuelType: map['fuelType'] as String?,
      bunkName: map['bunkName'] as String?,
    );
  }

  FuelEntry copyWith({
    int? id,
    int? vehicleId,
    double? odometer,
    double? litres,
    DateTime? date,
    double? reserveOdometer,
    double? reserveOffset,
    double? distance,
    double? mileage,
    double? rate,
    String? fuelType,
    String? bunkName,
  }) {
    return FuelEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      odometer: odometer ?? this.odometer,
      litres: litres ?? this.litres,
      date: date ?? this.date,
      reserveOdometer: reserveOdometer ?? this.reserveOdometer,
      reserveOffset: reserveOffset ?? this.reserveOffset,
      distance: distance ?? this.distance,
      mileage: mileage ?? this.mileage,
      rate: rate ?? this.rate,
      fuelType: fuelType ?? this.fuelType,
      bunkName: bunkName ?? this.bunkName,
    );
  }
}
