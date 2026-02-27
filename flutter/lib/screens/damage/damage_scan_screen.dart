import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/damage_provider.dart';
import '../../providers/fleet_provider.dart';
import '../../models/damage_report.dart';
import '../../models/vehicle.dart';
import '../../utils/app_theme.dart';
import '../../widgets/severity_badge.dart';

class DamageScanScreen extends StatefulWidget {
  const DamageScanScreen({super.key});

  @override
  State<DamageScanScreen> createState() => _DamageScanScreenState();
}

class _DamageScanScreenState extends State<DamageScanScreen> {
  File? _selectedImage;
  Vehicle? _selectedVehicle;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
      context.read<DamageProvider>().resetAnalysis();
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera to capture damage'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: AppTheme.accentOrange),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || _selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle and image first'),
          backgroundColor: AppTheme.warningAmber,
        ),
      );
      return;
    }
    await context.read<DamageProvider>().analyzeDamage(
          _selectedVehicle!.id,
          _selectedImage!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetProvider>();
    final damage = context.watch<DamageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Damage Scan'),
        actions: [
          if (damage.latestReport != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _selectedImage = null);
                damage.resetAnalysis();
              },
            ),
        ],
      ),
      body: damage.isAnalyzing
          ? _AnalyzingView()
          : damage.latestReport != null
              ? _ReportView(report: damage.latestReport!)
              : _ScanInputView(
                  vehicles: fleet.vehicles,
                  selectedVehicle: _selectedVehicle,
                  selectedImage: _selectedImage,
                  onVehicleSelected: (v) =>
                      setState(() => _selectedVehicle = v),
                  onPickImage: _showImageSourceSheet,
                  onAnalyze: _analyzeImage,
                  error: damage.error,
                ),
    );
  }
}

// ─── Input View ──────────────────────────────────────────────────────────────
class _ScanInputView extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final File? selectedImage;
  final Function(Vehicle) onVehicleSelected;
  final VoidCallback onPickImage;
  final VoidCallback onAnalyze;
  final String? error;

  const _ScanInputView({
    required this.vehicles,
    required this.selectedVehicle,
    required this.selectedImage,
    required this.onVehicleSelected,
    required this.onPickImage,
    required this.onAnalyze,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vehicle selection
          const Text('1. Select Vehicle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (vehicles.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No vehicles found. Add a vehicle first.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            DropdownButtonFormField<Vehicle>(
              initialValue: selectedVehicle,
              decoration: InputDecoration(
                hintText: 'Choose a vehicle',
                prefixIcon: const Icon(Icons.directions_car_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: vehicles
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child:
                            Text('${v.vehicleName} (${v.registrationNumber})'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onVehicleSelected(v);
              },
            ),

          const SizedBox(height: 24),

          // Image upload
          const Text('2. Upload Damage Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: onPickImage,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedImage != null
                      ? AppTheme.successGreen
                      : Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload vehicle image',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Camera or Gallery',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(error!,
                  style: const TextStyle(color: AppTheme.dangerRed)),
            ),
          ],

          const SizedBox(height: 28),

          // Analyze button
          ElevatedButton.icon(
            onPressed: (selectedImage != null && selectedVehicle != null)
                ? onAnalyze
                : null,
            icon: const Icon(Icons.search),
            label: const Text('Analyze Damage with AI'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryBlue,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppTheme.primaryBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI analyzes your image using GPT-4 Vision for accurate damage assessment.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Analyzing View ───────────────────────────────────────────────────────────
class _AnalyzingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.psychology, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 28),
            const Text(
              'AI Analyzing Image...',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'GPT-4 Vision is examining the damage.\nThis may take 15-30 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            const LinearProgressIndicator(),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _ProcessingChip('Detecting Damage'),
                _ProcessingChip('Assessing Severity'),
                _ProcessingChip('Estimating Cost'),
                _ProcessingChip('Generating Report'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingChip extends StatelessWidget {
  final String label;
  const _ProcessingChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
      side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
    );
  }
}

// ─── Report View ──────────────────────────────────────────────────────────────
class _ReportView extends StatelessWidget {
  final DamageReport report;
  const _ReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: report.damageDetected
                  ? AppTheme.dangerGradient
                  : AppTheme.successGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  report.damageDetected
                      ? Icons.warning_rounded
                      : Icons.check_circle,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  report.damageDetected ? 'Damage Detected' : 'No Damage Found',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                if (report.damageDetected) ...[
                  const SizedBox(height: 8),
                  SeverityBadge(severity: report.severityLevel),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Report image
          if (report.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                report.imageUrl,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 200, color: Colors.grey.shade100),
              ),
            ),

          const SizedBox(height: 16),

          if (report.damageDetected) ...[
            _InfoCard(
              title: 'Damage Details',
              icon: Icons.car_crash,
              children: [
                _InfoRow('Damage Type', report.damageType),
                _InfoRow('Primary Location', report.primaryAffectedPart),
                _InfoRow('Urgency', report.urgencyLevel),
                _InfoRow('Safety Risk', report.safetyRisk ? '⚠️ Yes' : '✅ No'),
                _InfoRow('AI Confidence',
                    '${report.confidence.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Affected Parts',
              icon: Icons.build_circle_outlined,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: report.affectedParts
                      .map((part) => Chip(
                            label: Text(part,
                                style: const TextStyle(fontSize: 12)),
                            backgroundColor:
                                AppTheme.dangerRed.withOpacity(0.1),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Cost Estimate',
              icon: Icons.attach_money,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CostBox(
                        label: 'Minimum',
                        amount:
                            '\$${report.estimatedRepairCost.min.toStringAsFixed(0)}',
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CostBox(
                        label: 'Maximum',
                        amount:
                            '\$${report.estimatedRepairCost.max.toStringAsFixed(0)}',
                        color: AppTheme.dangerRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Repair Recommendation',
              icon: Icons.lightbulb_outlined,
              children: [
                Text(
                  report.repairSuggestion,
                  style: const TextStyle(height: 1.6, fontSize: 14),
                ),
              ],
            ),
            if (report.partsRequired.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Parts Required',
                icon: Icons.settings_outlined,
                children: report.partsRequired
                    .map((part) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 6, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Text(part),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
            if (report.additionalNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Additional Notes',
                icon: Icons.notes_outlined,
                children: [
                  Text(
                    report.additionalNotes,
                    style: const TextStyle(height: 1.6, fontSize: 14),
                  ),
                ],
              ),
            ],
          ],

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Scan Another Vehicle'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CostBox extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  const _CostBox(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(amount,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
