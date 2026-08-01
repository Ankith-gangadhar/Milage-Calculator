class Vehicle {
  final int? id;
  final String name;
  final String type; // 'car', 'bike', 'scooter', 'truck'
  final double initialOdometer;
  final bool useReserveOffset;

  Vehicle({
    this.id,
    required this.name,
    required this.type,
    required this.initialOdometer,
    required this.useReserveOffset,
  });

  // Convert a Vehicle into a Map. The keys must correspond to the
  // column names in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'initialOdometer': initialOdometer,
      'useReserveOffset': useReserveOffset ? 1 : 0,
    };
  }

  // Convert a Map into a Vehicle.
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      initialOdometer: (map['initialOdometer'] as num).toDouble(),
      useReserveOffset: (map['useReserveOffset'] as int) == 1,
    );
  }

  // Helper to copy Vehicle with changes
  Vehicle copyWith({
    int? id,
    String? name,
    String? type,
    double? initialOdometer,
    bool? useReserveOffset,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialOdometer: initialOdometer ?? this.initialOdometer,
      useReserveOffset: useReserveOffset ?? this.useReserveOffset,
    );
  }
}
