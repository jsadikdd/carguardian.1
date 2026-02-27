import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fleet_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/health_score_gauge.dart';
import '../../widgets/stat_card.dart';
import '../fleet/fleet_screen.dart';
import '../damage/damage_detection_screen.dart';
import '../damage/voice_assistant_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().startListening();
    });
  }

  final List<Widget> _pages = [
    const _HomeTab(),
    const FleetScreen(),
    const DamageDetectionScreen(),
    const VoiceAssistantScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.directions_car_outlined),
              selectedIcon: Icon(Icons.directions_car),
              label: 'Fleet'),
          NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined),
              selectedIcon: Icon(Icons.camera_alt),
              label: 'Scan'),
          NavigationDestination(
              icon: Icon(Icons.mic_outlined),
              selectedIcon: Icon(Icons.mic),
              label: 'Assistant'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetProvider>();
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.displayName?.split(' ').first ?? 'Driver';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF00B4D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Hello, $name!',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text('Fleet Overview',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {},
              )
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                Row(children: [
                  Expanded(
                      child: StatCard(
                    label: 'Vehicles',
                    value: '${fleet.totalVehicles}',
                    icon: Icons.directions_car,
                    color: AppTheme.secondaryColor,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                    label: 'Total Cost',
                    value: '₹${fleet.totalRepairCost.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee,
                    color: AppTheme.accentColor,
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: StatCard(
                    label: 'Avg Health',
                    value: '${fleet.avgHealthScore.toStringAsFixed(0)}%',
                    icon: Icons.health_and_safety,
                    color: AppTheme.successColor,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                    label: 'Repairs',
                    value: fleet.vehicles
                        .fold<int>(0,
                            (s, v) => s + (v.vehicleHealthScore < 80 ? 1 : 0))
                        .toString(),
                    icon: Icons.build_circle,
                    color: AppTheme.warningColor,
                  )),
                ]),
                const SizedBox(height: 24),
                // Health score widget
                const Text('Fleet Health',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (fleet.vehicles.isEmpty)
                  const _EmptyState()
                else
                  ...fleet.vehicles.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              const Icon(Icons.directions_car,
                                  color: AppTheme.primaryColor, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text('${v.brand} ${v.model}',
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                ],
                              )),
                              HealthScoreGauge(score: v.vehicleHealthScore),
                            ]),
                          ),
                        ),
                      )),
                const SizedBox(height: 24),
                // Quick Actions
                const Text('Quick Actions',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(children: [
                  _QuickAction(
                    icon: Icons.camera_alt,
                    label: 'Scan Damage',
                    color: AppTheme.accentColor,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.add_circle,
                    label: 'Add Vehicle',
                    color: AppTheme.primaryColor,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.mic,
                    label: 'Ask AI',
                    color: AppTheme.secondaryColor,
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16)),
        child: const Column(children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No vehicles yet',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Add your first vehicle to get started',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
        ]),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3))),
            child: Column(children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}
