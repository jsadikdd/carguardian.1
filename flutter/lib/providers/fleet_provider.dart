import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../services/firestore_service.dart';
import '../utils/notification_service.dart';

class FleetProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<Vehicle> _vehicles = [];
  bool _loading = false;
  String? _error;

  List<Vehicle> get vehicles => _vehicles;
  bool          get loading  => _loading;
  String?       get error    => _error;
  int           get totalVehicles => _vehicles.length;

  double get totalRepairCost =>
      _vehicles.fold(0, (sum, v) => sum + v.totalRepairCost);

  double get avgHealthScore => _vehicles.isEmpty
      ? 100
      : _vehicles.fold(0, (s, v) => s + v.vehicleHealthScore) / _vehicles.length;

  void startListening() {
    _service.streamVehicles().listen((list) {
      _vehicles = list;
      _scheduleAllReminders();
      notifyListeners();
    });
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    _loading = true; notifyListeners();
    try {
      await _service.addVehicle(vehicle);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    _loading = true; notifyListeners();
    try {
      await _service.updateVehicle(vehicle);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    _loading = true; notifyListeners();
    try {
      await _service.deleteVehicle(vehicleId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  void _scheduleAllReminders() {
    for (int i = 0; i < _vehicles.length; i++) {
      final v = _vehicles[i];
      if (v.insuranceExpiryDate.isNotEmpty) {
        try {
          final expiry = DateTime.parse(v.insuranceExpiryDate);
          NotificationService.scheduleInsuranceReminder(
            id: 100 + i,
            vehicleName: v.name,
            expiryDate: expiry,
          );
        } catch (_) {}
      }
      if (v.lastServiceDate.isNotEmpty) {
        try {
          final last    = DateTime.parse(v.lastServiceDate);
          final nextSvc = last.add(const Duration(days: 365));
          NotificationService.scheduleServiceReminder(
            id: 200 + i,
            vehicleName: v.name,
            serviceDate: nextSvc,
          );
        } catch (_) {}
      }
    }
  }
}
