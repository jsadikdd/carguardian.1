class DamageAnalysis {
  final String damageType;
  final String severityLevel;
  final String affectedPart;
  final String repairSuggestion;
  final RepairCost estimatedRepairCost;
  final List<String> partsRequired;
  final String additionalNotes;
  final int confidenceScore;

  const DamageAnalysis({
    required this.damageType,
    required this.severityLevel,
    required this.affectedPart,
    required this.repairSuggestion,
    required this.estimatedRepairCost,
    required this.partsRequired,
    required this.additionalNotes,
    required this.confidenceScore,
  });

  factory DamageAnalysis.fromMap(Map<String, dynamic> map) => DamageAnalysis(
    damageType: map['damage_type'] ?? '',
    severityLevel: map['severity_level'] ?? '',
    affectedPart: map['affected_part'] ?? '',
    repairSuggestion: map['repair_suggestion'] ?? '',
    estimatedRepairCost: RepairCost.fromMap(
        map['estimated_repair_cost'] ?? {}),
    partsRequired: List<String>.from(map['parts_possibly_required'] ?? []),
    additionalNotes: map['additional_notes'] ?? '',
    confidenceScore: (map['confidence_score'] ?? 0).toInt(),
  );
}

class RepairCost {
  final double min;
  final double max;
  final String currency;

  const RepairCost({required this.min, required this.max, required this.currency});

  factory RepairCost.fromMap(Map<String, dynamic> map) => RepairCost(
    min: (map['min'] ?? 0).toDouble(),
    max: (map['max'] ?? 0).toDouble(),
    currency: map['currency'] ?? 'INR',
  );
}

class DamageReport {
  final String reportId;
  final String vehicleId;
  final String imageUrl;
  final DamageAnalysis analysis;
  final String createdAt;

  const DamageReport({
    required this.reportId,
    required this.vehicleId,
    required this.imageUrl,
    required this.analysis,
    required this.createdAt,
  });

  factory DamageReport.fromMap(Map<String, dynamic> map) => DamageReport(
    reportId: map['report_id'] ?? '',
    vehicleId: map['vehicle_id'] ?? '',
    imageUrl: map['image_url'] ?? '',
    analysis: DamageAnalysis.fromMap(map['analysis'] ?? {}),
    createdAt: map['created_at'] ?? '',
  );
}
