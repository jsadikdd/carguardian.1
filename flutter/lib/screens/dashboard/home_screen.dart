import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fleet_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/health_gauge.dart';
import '../../widgets/alert_banner.dart';
import '../fleet/fleet_list_screen.dart';
import '../damage/damage_scan_screen.dart';
import '../voice/voice_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardPage(),
    FleetListScreen(),
    DamageScanScreen(),
    VoiceScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
      context.read<FleetProvider>().loadFleet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Fleet',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Voice AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final fleet = context.watch<FleetProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.displayName?.split(' ').first ?? 'Driver'} 👋',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Text(
              'Fleet Overview',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => dashboard.loadDashboard(),
          ),
        ],
      ),
      body: dashboard.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await dashboard.loadDashboard();
                await fleet.loadFleet();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alerts
                    if (dashboard.alerts.isNotEmpty)
                      ...dashboard.alerts.map(
                        (alert) => AlertBanner(
                          title: alert['type'] == 'insurance'
                              ? 'Insurance Alert'
                              : 'Service Due',
                          message: alert['message'] ?? '',
                          severity: alert['severity'] ?? 'medium',
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        StatCard(
                          title: 'Total Vehicles',
                          value: '${dashboard.totalVehicles}',
                          icon: Icons.directions_car,
                          color: AppTheme.primaryBlue,
                        ),
                        StatCard(
                          title: 'Damage Reports',
                          value: '${dashboard.totalDamageReports}',
                          icon: Icons.warning_amber_rounded,
                          color: AppTheme.dangerRed,
                        ),
                        StatCard(
                          title: 'Repair Cost',
                          value: '\$${dashboard.totalMaintenanceCost.toStringAsFixed(0)}',
                          icon: Icons.build_outlined,
                          color: AppTheme.accentOrange,
                        ),
                        StatCard(
                          title: 'Fleet Health',
                          value: '${dashboard.averageHealthScore.toStringAsFixed(0)}%',
                          icon: Icons.favorite_outlined,
                          color: AppTheme.healthColor(
                              dashboard.averageHealthScore.toInt()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Health gauge
                    const Text(
                      'Fleet Health Score',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    HealthGauge(score: dashboard.averageHealthScore.toInt()),

                    const SizedBox(height: 24),

                    // Vehicle list preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Vehicles',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (fleet.vehicles.isEmpty)
                      _EmptyFleetCard()
                    else
                      ...fleet.vehicles.take(3).map(
                            (v) => _VehiclePreviewTile(vehicle: v),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EmptyFleetCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No vehicles added yet',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Add your first vehicle to get started',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehiclePreviewTile extends StatelessWidget {
  final dynamic vehicle;
  const _VehiclePreviewTile({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final score = vehicle.healthScore as int;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.directions_car,
              color: AppTheme.primaryBlue, size: 26),
        ),
        title: Text(vehicle.vehicleName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${vehicle.brand} ${vehicle.model}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.healthColor(score).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$score%',
            style: TextStyle(
              color: AppTheme.healthColor(score),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
