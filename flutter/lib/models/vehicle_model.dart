class Vehicle {
  final String id;
  final String name;
  final String brand;
  final String model;
  final String registrationNumber;
  final String fuelType;
  final int mileage;
  final String insuranceExpiryDate;
  final String lastServiceDate;
  final double totalRepairCost;
  final int vehicleHealthScore;
  final String createdAt;

  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.registrationNumber,
    required this.fuelType,
    required this.mileage,
    required this.insuranceExpiryDate,
    required this.lastServiceDate,
    required this.totalRepairCost,
    required this.vehicleHealthScore,
    required this.createdAt,
  });

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) => Vehicle(
    id: id,
    name: map['name'] ?? '',
    brand: map['brand'] ?? '',
    model: map['model'] ?? '',
    registrationNumber: map['registration_number'] ?? '',
    fuelType: map['fuel_type'] ?? 'Petrol',
    mileage: (map['mileage'] ?? 0).toInt(),
    insuranceExpiryDate: map['insurance_expiry_date'] ?? '',
    lastServiceDate: map['last_service_date'] ?? '',
    totalRepairCost: (map['total_repair_cost'] ?? 0).toDouble(),
    vehicleHealthScore: (map['vehicle_health_score'] ?? 100).toInt(),
    createdAt: map['created_at'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'brand': brand,
    'model': model,
    'registration_number': registrationNumber,
    'fuel_type': fuelType,
    'mileage': mileage,
    'insurance_expiry_date': insuranceExpiryDate,
    'last_service_date': lastServiceDate,
    'total_repair_cost': totalRepairCost,
    'vehicle_health_score': vehicleHealthScore,
    'created_at': createdAt,
  };

  Vehicle copyWith({
    String? name, String? brand, String? model,
    String? registrationNumber, String? fuelType, int? mileage,
    String? insuranceExpiryDate, String? lastServiceDate,
    double? totalRepairCost, int? vehicleHealthScore,
  }) => Vehicle(
    id: id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    registrationNumber: registrationNumber ?? this.registrationNumber,
    fuelType: fuelType ?? this.fuelType,
    mileage: mileage ?? this.mileage,
    insuranceExpiryDate: insuranceExpiryDate ?? this.insuranceExpiryDate,
    lastServiceDate: lastServiceDate ?? this.lastServiceDate,
    totalRepairCost: totalRepairCost ?? this.totalRepairCost,
    vehicleHealthScore: vehicleHealthScore ?? this.vehicleHealthScore,
    createdAt: createdAt,
  );
}
