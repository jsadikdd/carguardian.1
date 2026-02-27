class ServiceRecord {
  final String recordId;
  final String vehicleId;
  final String serviceDate;
  final String serviceType;
  final double cost;
  final String notes;
  final int mileageAtService;
  final String createdAt;

  const ServiceRecord({
    required this.recordId,
    required this.vehicleId,
    required this.serviceDate,
    required this.serviceType,
    required this.cost,
    required this.notes,
    required this.mileageAtService,
    required this.createdAt,
  });

  factory ServiceRecord.fromMap(Map<String, dynamic> map) => ServiceRecord(
    recordId: map['record_id'] ?? '',
    vehicleId: map['vehicle_id'] ?? '',
    serviceDate: map['service_date'] ?? '',
    serviceType: map['service_type'] ?? '',
    cost: (map['cost'] ?? 0).toDouble(),
    notes: map['notes'] ?? '',
    mileageAtService: (map['mileage_at_service'] ?? 0).toInt(),
    createdAt: map['created_at'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'record_id': recordId,
    'vehicle_id': vehicleId,
    'service_date': serviceDate,
    'service_type': serviceType,
    'cost': cost,
    'notes': notes,
    'mileage_at_service': mileageAtService,
    'created_at': createdAt,
  };
}
