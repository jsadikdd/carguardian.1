class Vehicle {
  final String id;
  final String vehicleName;
  final String brand;
  final String model;
  final String registrationNumber;
  final String fuelType;
  final double mileage;
  final String? insuranceExpiryDate;
  final String? lastServiceDate;
  final double totalRepairCost;
  final int healthScore;
  final String? imageUrl;
  final DateTime? createdAt;

  Vehicle({
    required this.id,
    required this.vehicleName,
    required this.brand,
    required this.model,
    required this.registrationNumber,
    this.fuelType = 'Petrol',
    this.mileage = 0,
    this.insuranceExpiryDate,
    this.lastServiceDate,
    this.totalRepairCost = 0,
    this.healthScore = 100,
    this.imageUrl,
    this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      vehicleName: json['vehicleName'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      fuelType: json['fuelType'] ?? 'Petrol',
      mileage: (json['mileage'] ?? 0).toDouble(),
      insuranceExpiryDate: json['insuranceExpiryDate'],
      lastServiceDate: json['lastServiceDate'],
      totalRepairCost: (json['totalRepairCost'] ?? 0).toDouble(),
      healthScore: (json['healthScore'] ?? 100).toInt(),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicleName': vehicleName,
        'brand': brand,
        'model': model,
        'registrationNumber': registrationNumber,
        'fuelType': fuelType,
        'mileage': mileage,
        'insuranceExpiryDate': insuranceExpiryDate,
        'lastServiceDate': lastServiceDate,
        'totalRepairCost': totalRepairCost,
        'healthScore': healthScore,
      };

  Vehicle copyWith({
    String? vehicleName,
    String? brand,
    String? model,
    String? registrationNumber,
    String? fuelType,
    double? mileage,
    String? insuranceExpiryDate,
    String? lastServiceDate,
    double? totalRepairCost,
    int? healthScore,
  }) {
    return Vehicle(
      id: id,
      vehicleName: vehicleName ?? this.vehicleName,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      fuelType: fuelType ?? this.fuelType,
      mileage: mileage ?? this.mileage,
      insuranceExpiryDate: insuranceExpiryDate ?? this.insuranceExpiryDate,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      totalRepairCost: totalRepairCost ?? this.totalRepairCost,
      healthScore: healthScore ?? this.healthScore,
    );
  }

  // Helper: days until insurance expiry
  int? get daysUntilInsuranceExpiry {
    if (insuranceExpiryDate == null) return null;
    try {
      final expiry = DateTime.parse(insuranceExpiryDate!);
      return expiry.difference(DateTime.now()).inDays;
    } catch (_) {
      return null;
    }
  }

  bool get isInsuranceExpiringSoon {
    final days = daysUntilInsuranceExpiry;
    return days != null && days <= 30 && days >= 0;
  }

  bool get isInsuranceExpired {
    final days = daysUntilInsuranceExpiry;
    return days != null && days < 0;
  }

  String get healthLabel {
    if (healthScore >= 80) return 'Excellent';
    if (healthScore >= 60) return 'Good';
    if (healthScore >= 40) return 'Fair';
    return 'Poor';
  }
}
