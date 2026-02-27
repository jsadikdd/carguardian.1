import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/fleet_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;
  const AddEditVehicleScreen({super.key, this.vehicle});
  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  String _selectedFuel = 'Petrol';
  DateTime? _insurDate;
  DateTime? _serviceDate;
  bool get isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final v = widget.vehicle!;
      _nameCtrl.text = v.name;
      _brandCtrl.text = v.brand;
      _modelCtrl.text = v.model;
      _regCtrl.text = v.registrationNumber;
      _mileageCtrl.text = v.mileage.toString();
      _selectedFuel = v.fuelType;
      if (v.insuranceExpiryDate.isNotEmpty)
        _insurDate = DateTime.tryParse(v.insuranceExpiryDate);
      if (v.lastServiceDate.isNotEmpty)
        _serviceDate = DateTime.tryParse(v.lastServiceDate);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _regCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isInsurance) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null)
      setState(() {
        if (isInsurance)
          _insurDate = picked;
        else
          _serviceDate = picked;
      });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? '',
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      registrationNumber: _regCtrl.text.trim().toUpperCase(),
      fuelType: _selectedFuel,
      mileage: int.tryParse(_mileageCtrl.text) ?? 0,
      insuranceExpiryDate: _insurDate?.toIso8601String() ?? '',
      lastServiceDate: _serviceDate?.toIso8601String() ?? '',
      totalRepairCost: widget.vehicle?.totalRepairCost ?? 0,
      vehicleHealthScore: widget.vehicle?.vehicleHealthScore ?? 100,
      createdAt: widget.vehicle?.createdAt ?? DateTime.now().toIso8601String(),
    );

    final provider = context.read<FleetProvider>();
    if (isEditing) {
      await provider.updateVehicle(vehicle);
    } else {
      await provider.addVehicle(vehicle);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<FleetProvider>().loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _save,
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Basic Information'),
              _field(_nameCtrl, 'Vehicle Name', Icons.label_outline,
                  required: true),
              const SizedBox(height: 12),
              _field(_brandCtrl, 'Brand', Icons.branding_watermark_outlined,
                  required: true),
              const SizedBox(height: 12),
              _field(_modelCtrl, 'Model', Icons.directions_car_outlined,
                  required: true),
              const SizedBox(height: 12),
              _field(_regCtrl, 'Registration Number', Icons.badge_outlined,
                  required: true),
              const SizedBox(height: 20),
              _section('Vehicle Details'),
              DropdownButtonFormField<String>(
                initialValue: _selectedFuel,
                decoration: const InputDecoration(
                    labelText: 'Fuel Type',
                    prefixIcon: Icon(Icons.local_gas_station_outlined)),
                items: AppConstants.fuelTypes
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFuel = v!),
              ),
              const SizedBox(height: 12),
              _field(_mileageCtrl, 'Current Mileage (km)', Icons.speed_outlined,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _section('Dates'),
              _dateTile(
                label: 'Insurance Expiry Date',
                date: _insurDate,
                icon: Icons.security,
                onTap: () => _pickDate(true),
              ),
              const SizedBox(height: 12),
              _dateTile(
                label: 'Last Service Date',
                date: _serviceDate,
                icon: Icons.build_outlined,
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isEditing ? 'Update Vehicle' : 'Add Vehicle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: 0.5)),
      );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
          {bool required = false, TextInputType? keyboardType}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: required
            ? (v) => v != null && v.trim().isNotEmpty ? null : 'Required'
            : null,
      );

  Widget _dateTile({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              suffixIcon: const Icon(Icons.calendar_today)),
          child: Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select date',
              style: TextStyle(color: date != null ? null : Colors.grey)),
        ),
      );
}
