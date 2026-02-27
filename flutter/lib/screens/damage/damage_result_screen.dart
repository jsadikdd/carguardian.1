import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/damage_report_model.dart';
import '../../utils/app_theme.dart';

class DamageResultScreen extends StatelessWidget {
  final DamageReport report;
  const DamageResultScreen({super.key, required this.report});

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'minor':    return AppTheme.successColor;
      case 'moderate': return AppTheme.warningColor;
      case 'severe':   return AppTheme.errorColor;
      default:         return Colors.grey;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'minor':    return Icons.check_circle;
      case 'moderate': return Icons.warning_amber;
      case 'severe':   return Icons.dangerous;
      default:         return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = report.analysis;
    final sevColor = _severityColor(a.severityLevel);

    return Scaffold(
      appBar: AppBar(title: const Text('Damage Analysis Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            if (report.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: report.imageUrl,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      height: 220,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator())),
                  errorWidget: (_, __, ___) =>
                      Container(height: 220, color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 64)),
                ),
              ),
            const SizedBox(height: 16),

            // Severity banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sevColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sevColor.withOpacity(0.4)),
              ),
              child: Row(children: [
                Icon(_severityIcon(a.severityLevel), color: sevColor, size: 36),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.severityLevel.toUpperCase(),
                      style: TextStyle(color: sevColor, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(a.damageType, style: TextStyle(color: sevColor.withOpacity(0.8))),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('AI Confidence', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text('${a.confidenceScore}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Affected part
            _infoCard('Affected Area', a.affectedPart, Icons.location_on_outlined),
            const SizedBox(height: 12),

            // Cost estimate
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.currency_rupee, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Estimated Repair Cost',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _costBox('Minimum',
                          '₹${a.estimatedRepairCost.min.toStringAsFixed(0)}', Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _costBox('Maximum',
                          '₹${a.estimatedRepairCost.max.toStringAsFixed(0)}', AppTheme.errorColor)),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Parts required
            if (a.partsRequired.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.build_outlined, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('Parts Required',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: a.partsRequired.map((p) => Chip(
                          label: Text(p, style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Repair suggestion
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.lightbulb_outline, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Repair Recommendation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                    const SizedBox(height: 8),
                    Text(a.repairSuggestion, style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Additional notes
            if (a.additionalNotes.isNotEmpty)
              _infoCard('Additional Notes', a.additionalNotes, Icons.notes),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String content, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(height: 1.5)),
            ],
          )),
        ],
      ),
    ),
  );

  Widget _costBox(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
