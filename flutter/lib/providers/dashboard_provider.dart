import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic> _data = {};
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalVehicles => _data['totalVehicles'] ?? 0;
  double get totalMaintenanceCost => (_data['totalMaintenanceCost'] ?? 0).toDouble();
  int get totalDamageReports => _data['totalDamageReports'] ?? 0;
  double get averageHealthScore => (_data['averageHealthScore'] ?? 100).toDouble();
  List<dynamic> get alerts => _data['alerts'] ?? [];

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _api.getDashboard();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
