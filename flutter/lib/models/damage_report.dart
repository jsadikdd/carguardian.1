class DamageReport {
  final String id;
  final String vehicleId;
  final bool damageDetected;
  final String damageType;
  final String severityLevel;
  final List<String> affectedParts;
  final String primaryAffectedPart;
  final String repairSuggestion;
  final RepairCostRange estimatedRepairCost;
  final List<String> partsRequired;
  final String urgencyLevel;
  final bool safetyRisk;
  final String additionalNotes;
  final double confidence;
  final String imageUrl;
  final String reportDate;

  DamageReport({
    required this.id,
    required this.vehicleId,
    required this.damageDetected,
    required this.damageType,
    required this.severityLevel,
    required this.affectedParts,
    required this.primaryAffectedPart,
    required this.repairSuggestion,
    required this.estimatedRepairCost,
    required this.partsRequired,
    required this.urgencyLevel,
    required this.safetyRisk,
    required this.additionalNotes,
    required this.confidence,
    required this.imageUrl,
    required this.reportDate,
  });

  factory DamageReport.fromJson(Map<String, dynamic> json) {
    return DamageReport(
      id: json['id'] ?? '',
      vehicleId: json['vehicleId'] ?? '',
      damageDetected: json['damageDetected'] ?? false,
      damageType: json['damageType'] ?? 'Unknown',
      severityLevel: json['severityLevel'] ?? 'None',
      affectedParts: List<String>.from(json['affectedParts'] ?? []),
      primaryAffectedPart: json['primaryAffectedPart'] ?? '',
      repairSuggestion: json['repairSuggestion'] ?? '',
      estimatedRepairCost: RepairCostRange.fromJson(json['estimatedRepairCost'] ?? {}),
      partsRequired: List<String>.from(json['partsRequired'] ?? []),
      urgencyLevel: json['urgencyLevel'] ?? 'None',
      safetyRisk: json['safetyRisk'] ?? false,
      additionalNotes: json['additionalNotes'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      reportDate: json['reportDate'] ?? '',
    );
  }

  String get costRange =>
      '\$${estimatedRepairCost.min.toStringAsFixed(0)} - \$${estimatedRepairCost.max.toStringAsFixed(0)}';
}

class RepairCostRange {
  final double min;
  final double max;
  final String currency;

  RepairCostRange({required this.min, required this.max, this.currency = 'USD'});

  factory RepairCostRange.fromJson(Map<String, dynamic> json) {
    return RepairCostRange(
      min: (json['min'] ?? 0).toDouble(),
      max: (json['max'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }
}

class ServiceRecord {
  final String id;
  final String serviceType;
  final String serviceDate;
  final double mileageAtService;
  final double cost;
  final String serviceCenter;
  final String notes;
  final String? nextServiceDue;

  ServiceRecord({
    required this.id,
    required this.serviceType,
    required this.serviceDate,
    required this.mileageAtService,
    required this.cost,
    required this.serviceCenter,
    required this.notes,
    this.nextServiceDue,
  });

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      id: json['id'] ?? '',
      serviceType: json['serviceType'] ?? '',
      serviceDate: json['serviceDate'] ?? '',
      mileageAtService: (json['mileageAtService'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      serviceCenter: json['serviceCenter'] ?? '',
      notes: json['notes'] ?? '',
      nextServiceDue: json['nextServiceDue'],
    );
  }
}
