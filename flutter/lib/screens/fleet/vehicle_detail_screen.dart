import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/health_score_gauge.dart';
import '../damage/damage_detection_screen.dart';
import '../maintenance/service_history_screen.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Vehicle vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(vehicle.name),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Damage'),
              Tab(text: 'Service'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _OverviewTab(vehicle: vehicle),
          ServiceHistoryScreen(vehicle: vehicle, showDamage: true),
          ServiceHistoryScreen(vehicle: vehicle, showDamage: false),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DamageDetectionScreen(preselectedVehicle: vehicle),
            ),
          ),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Scan Damage'),
          backgroundColor: AppTheme.accentColor,
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Vehicle vehicle;
  const _OverviewTab({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Health Score Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              HealthScoreGauge(score: vehicle.vehicleHealthScore, size: 80),
              const SizedBox(width: 20),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Vehicle Health',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  vehicle.vehicleHealthScore >= 80
                      ? 'Excellent Condition'
                      : vehicle.vehicleHealthScore >= 50
                          ? 'Fair Condition'
                          : 'Needs Attention',
                  style: TextStyle(
                    color: vehicle.vehicleHealthScore >= 80
                        ? AppTheme.successColor
                        : vehicle.vehicleHealthScore >= 50
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                  ),
                ),
                Text(
                    'Total spent: ₹${vehicle.totalRepairCost.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.grey)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        // Details grid
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _detailRow('Brand', vehicle.brand),
              _detailRow('Model', vehicle.model),
              _detailRow('Registration', vehicle.registrationNumber),
              _detailRow('Fuel Type', vehicle.fuelType),
              _detailRow('Mileage', '${vehicle.mileage} km'),
              _detailRow(
                  'Insurance Expiry',
                  vehicle.insuranceExpiryDate.isNotEmpty
                      ? vehicle.insuranceExpiryDate.substring(0, 10)
                      : 'Not set'),
              _detailRow(
                  'Last Service',
                  vehicle.lastServiceDate.isNotEmpty
                      ? vehicle.lastServiceDate.substring(0, 10)
                      : 'Not set'),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
