import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fleet_provider.dart';
import '../../models/vehicle.dart';
import '../../utils/app_theme.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';

class FleetListScreen extends StatefulWidget {
  const FleetListScreen({super.key});

  @override
  State<FleetListScreen> createState() => _FleetListScreenState();
}

class _FleetListScreenState extends State<FleetListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().loadFleet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Fleet (${fleet.vehicleCount})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fleet.loadFleet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
      body: fleet.isLoading
          ? const Center(child: CircularProgressIndicator())
          : fleet.vehicles.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: fleet.loadFleet,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: fleet.vehicles.length,
                    itemBuilder: (_, i) => _VehicleCard(
                      vehicle: fleet.vehicles[i],
                      onTap: () {
                        fleet.selectVehicle(fleet.vehicles[i]);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VehicleDetailScreen(vehicle: fleet.vehicles[i]),
                          ),
                        );
                      },
                      onDelete: () =>
                          _confirmDelete(context, fleet.vehicles[i], fleet),
                    ),
                  ),
                ),
    );
  }

  void _confirmDelete(
      BuildContext context, Vehicle vehicle, FleetProvider fleet) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
            'Remove "${vehicle.vehicleName}" from your fleet? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await fleet.deleteVehicle(vehicle.id);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VehicleCard(
      {required this.vehicle, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final score = vehicle.healthScore;
    final healthColor = AppTheme.healthColor(score);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.directions_car,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle.brand} ${vehicle.model}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        Text(
                          vehicle.registrationNumber,
                          style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: healthColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$score%',
                          style: TextStyle(
                            color: healthColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.healthLabel,
                        style: TextStyle(color: healthColor, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickStat(
                    label: 'Fuel',
                    value: vehicle.fuelType,
                    icon: Icons.local_gas_station_outlined,
                  ),
                  _QuickStat(
                    label: 'Repairs',
                    value: '\$${vehicle.totalRepairCost.toStringAsFixed(0)}',
                    icon: Icons.build_outlined,
                  ),
                  if (vehicle.isInsuranceExpiringSoon ||
                      vehicle.isInsuranceExpired)
                    _InsuranceBadge(vehicle: vehicle)
                  else
                    _QuickStat(
                      label: 'Mileage',
                      value: '${vehicle.mileage.toStringAsFixed(0)} km',
                      icon: Icons.speed_outlined,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _QuickStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
      ],
    );
  }
}

class _InsuranceBadge extends StatelessWidget {
  final Vehicle vehicle;
  const _InsuranceBadge({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.dangerRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        vehicle.isInsuranceExpired ? '🚨 Expired' : '⚠️ Expiring',
        style: const TextStyle(
            color: AppTheme.dangerRed,
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No Vehicles Added',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first vehicle',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
