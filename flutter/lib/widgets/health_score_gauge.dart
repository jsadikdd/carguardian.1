import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class HealthScoreGauge extends StatelessWidget {
  final int score;
  final double size;
  const HealthScoreGauge({super.key, required this.score, this.size = 56});

  Color get _color {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey.shade200,
            color: _color,
            strokeWidth: size < 60 ? 5 : 7,
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: size / 3.5,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
