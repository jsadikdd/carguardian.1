import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fleet_provider.dart';
import '../../models/vehicle_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/health_score_gauge.dart';
import 'add_edit_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';

class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fleet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditVehicleScreen()),
            ),
          )
        ],
      ),
      body: fleet.loading
          ? const Center(child: CircularProgressIndicator())
          : fleet.vehicles.isEmpty
              ? _emptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: fleet.vehicles.length,
                  itemBuilder: (ctx, i) =>
                      _VehicleCard(vehicle: fleet.vehicles[i]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditVehicleScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.directions_car, size: 96, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No vehicles in your fleet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Text('Tap + to add your first vehicle',
            style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddEditVehicleScreen())),
          icon: const Icon(Icons.add),
          label: const Text('Add Vehicle'),
        ),
      ],
    ),
  );
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  Color _healthColor(int score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car,
                      color: AppTheme.primaryColor, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text('${vehicle.brand} ${vehicle.model}',
                        style: TextStyle(color: Colors.grey.shade600)),
                    Text(vehicle.registrationNumber,
                        style: const TextStyle(
                            color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                  ],
                )),
                HealthScoreGauge(score: vehicle.vehicleHealthScore),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                    icon: Icons.local_gas_station,
                    label: vehicle.fuelType,
                  ),
                  _InfoChip(
                    icon: Icons.speed,
                    label: '${vehicle.mileage} km',
                  ),
                  _InfoChip(
                    icon: Icons.currency_rupee,
                    label: '₹${vehicle.totalRepairCost.toStringAsFixed(0)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddEditVehicleScreen(vehicle: vehicle)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Remove ${vehicle.name} from your fleet?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              context.read<FleetProvider>().deleteVehicle(vehicle.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey.shade600),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
    ],
  );
}
