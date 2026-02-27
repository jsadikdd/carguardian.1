import "package:flutter/material.dart";
import "../../models/vehicle_model.dart";
import "../../models/service_record_model.dart";
import "../../models/damage_report_model.dart";
import "../../services/firestore_service.dart";
import "../../utils/app_theme.dart";

class ServiceHistoryScreen extends StatelessWidget {
  final Vehicle vehicle;
  final bool showDamage;
  const ServiceHistoryScreen({super.key, required this.vehicle, required this.showDamage});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    if (showDamage) {
      return StreamBuilder<List<DamageReport>>(
        stream: service.streamDamageReports(vehicle.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final reports = snap.data ?? [];
          if (reports.isEmpty) return _empty("No damage reports yet");
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (_, i) => _DamageCard(report: reports[i]));
        },
      );
    }
    return StreamBuilder<List<ServiceRecord>>(
      stream: service.streamServiceRecords(vehicle.id),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final records = snap.data ?? [];
        if (records.isEmpty) return _empty("No service records yet");
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (_, i) => _ServiceCard(record: records[i]));
      },
    );
  }

  Widget _empty(String msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.history, size: 72, color: Colors.grey.shade300),
    const SizedBox(height: 12),
    Text(msg, style: TextStyle(color: Colors.grey.shade500)),
  ]));
}

class _DamageCard extends StatelessWidget {
  final DamageReport report;
  const _DamageCard({required this.report});
  @override
  Widget build(BuildContext context) {
    final a = report.analysis;
    Color sev = a.severityLevel.toLowerCase() == "minor" ? AppTheme.successColor
        : a.severityLevel.toLowerCase() == "moderate" ? AppTheme.warningColor : AppTheme.errorColor;
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a.damageType, style: const TextStyle(fontWeight: FontWeight.bold)),
          Chip(label: Text(a.severityLevel, style: TextStyle(color: sev, fontSize: 12)),
            backgroundColor: sev.withOpacity(0.1), side: BorderSide(color: sev.withOpacity(0.3)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ]),
        Text(a.affectedPart, style: TextStyle(color: Colors.grey.shade600)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Rs.${a.estimatedRepairCost.min.toStringAsFixed(0)} - Rs.${a.estimatedRepairCost.max.toStringAsFixed(0)}",
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(report.createdAt.isNotEmpty ? report.createdAt.substring(0, 10) : "",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ]),
      ]),
    ));
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceRecord record;
  const _ServiceCard({required this.record});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      Container(width: 48, height: 48,
        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.build, color: AppTheme.primaryColor)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(record.serviceType, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (record.notes.isNotEmpty)
          Text(record.notes, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text("Rs.${record.cost.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        Text(record.serviceDate.isNotEmpty ? record.serviceDate.substring(0, 10) : "",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      ]),
    ])),
  );
}
