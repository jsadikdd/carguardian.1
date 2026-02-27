import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_severityIcon(severity), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            severity,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return Icons.warning_rounded;
      case 'moderate':
        return Icons.warning_amber_rounded;
      case 'minor':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }
}

class AlertBanner extends StatelessWidget {
  final String title;
  final String message;
  final String severity; // 'high', 'medium', 'low'

  const AlertBanner({
    super.key,
    required this.title,
    required this.message,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    final color = severity == 'high'
        ? AppTheme.dangerRed
        : severity == 'medium'
            ? AppTheme.warningAmber
            : AppTheme.successGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            severity == 'high' ? Icons.warning : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(color: color.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
