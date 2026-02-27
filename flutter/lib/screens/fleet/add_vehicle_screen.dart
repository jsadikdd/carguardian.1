import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fleet_provider.dart';
import '../../models/vehicle.dart';
import '../../utils/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? existingVehicle;
  const AddVehicleScreen({super.key, this.existingVehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  String _fuelType = 'Petrol';
  DateTime? _insuranceExpiry;
  DateTime? _lastService;

  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'CNG'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingVehicle != null) {
      final v = widget.existingVehicle!;
      _nameCtrl.text = v.vehicleName;
      _brandCtrl.text = v.brand;
      _modelCtrl.text = v.model;
      _regCtrl.text = v.registrationNumber;
      _mileageCtrl.text = v.mileage.toString();
      _fuelType = v.fuelType;
      if (v.insuranceExpiryDate != null) {
        _insuranceExpiry = DateTime.tryParse(v.insuranceExpiryDate!);
      }
      if (v.lastServiceDate != null) {
        _lastService = DateTime.tryParse(v.lastServiceDate!);
      }
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isInsurance) {
          _insuranceExpiry = picked;
        } else {
          _lastService = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final vehicle = Vehicle(
      id: widget.existingVehicle?.id ?? const Uuid().v4(),
      vehicleName: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      registrationNumber: _regCtrl.text.trim().toUpperCase(),
      fuelType: _fuelType,
      mileage: double.tryParse(_mileageCtrl.text) ?? 0,
      insuranceExpiryDate: _insuranceExpiry?.toIso8601String(),
      lastServiceDate: _lastService?.toIso8601String(),
    );

    final fleet = context.read<FleetProvider>();
    bool success;

    if (widget.existingVehicle != null) {
      success = await fleet.updateVehicle(vehicle.id, vehicle.toJson());
    } else {
      success = await fleet.addVehicle(vehicle);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.existingVehicle != null
            ? 'Vehicle updated successfully!'
            : 'Vehicle added successfully!'),
        backgroundColor: AppTheme.successGreen,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingVehicle != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Vehicle' : 'Add Vehicle')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Info Section
              _SectionHeader('Basic Information'),
              const SizedBox(height: 12),

              _buildField(
                controller: _nameCtrl,
                label: 'Vehicle Name',
                hint: 'e.g. My Honda City',
                icon: Icons.badge_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _brandCtrl,
                      label: 'Brand',
                      hint: 'Honda, Toyota...',
                      icon: Icons.branding_watermark_outlined,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _modelCtrl,
                      label: 'Model',
                      hint: 'City, Corolla...',
                      icon: Icons.directions_car_outlined,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _regCtrl,
                label: 'Registration Number',
                hint: 'e.g. MH01AB1234',
                icon: Icons.confirmation_number_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              _SectionHeader('Vehicle Details'),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _fuelType,
                decoration: InputDecoration(
                  labelText: 'Fuel Type',
                  prefixIcon: const Icon(Icons.local_gas_station_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _fuelTypes
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _fuelType = v!),
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _mileageCtrl,
                label: 'Current Mileage (km)',
                hint: '0',
                icon: Icons.speed_outlined,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),
              _SectionHeader('Important Dates'),
              const SizedBox(height: 12),

              _DatePicker(
                label: 'Insurance Expiry Date',
                icon: Icons.security_outlined,
                date: _insuranceExpiry,
                onTap: () => _pickDate(true),
              ),
              const SizedBox(height: 12),
              _DatePicker(
                label: 'Last Service Date',
                icon: Icons.build_outlined,
                date: _lastService,
                onTap: () => _pickDate(false),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isEdit ? 'Update Vehicle' : 'Add Vehicle',
                        style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePicker(
      {required this.label,
      required this.icon,
      required this.date,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date!)
                        : 'Tap to select date',
                    style: TextStyle(
                      color:
                          date != null ? Colors.black87 : Colors.grey.shade400,
                      fontWeight:
                          date != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_outlined,
                color: AppTheme.primaryBlue),
          ],
        ),
      ),
    );
  }
}
