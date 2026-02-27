import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/damage_provider.dart';
import '../../providers/fleet_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_theme.dart';
import 'damage_result_screen.dart';

class DamageDetectionScreen extends StatefulWidget {
  final Vehicle? preselectedVehicle;
  const DamageDetectionScreen({super.key, this.preselectedVehicle});
  @override
  State<DamageDetectionScreen> createState() => _DamageDetectionScreenState();
}

class _DamageDetectionScreenState extends State<DamageDetectionScreen> {
  File? _imageFile;
  Vehicle? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.preselectedVehicle;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _analyze() async {
    if (_imageFile == null) {
      _snack('Please select an image first');
      return;
    }
    if (_selectedVehicle == null) {
      _snack('Please select a vehicle');
      return;
    }

    final lang = context.read<LanguageProvider>().languageCode;
    await context.read<DamageProvider>().analyzeImage(
          imageFile: _imageFile!,
          vehicleId: _selectedVehicle!.id,
          language: lang,
        );

    if (mounted) {
      final damage = context.read<DamageProvider>();
      if (damage.status == AnalysisStatus.done && damage.latestReport != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DamageResultScreen(report: damage.latestReport!),
          ),
        );
      }
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final damage = context.watch<DamageProvider>();
    final fleet = context.watch<FleetProvider>();
    final isLoading = damage.status == AnalysisStatus.uploading ||
        damage.status == AnalysisStatus.analyzing;

    return Scaffold(
      appBar: AppBar(title: const Text('Damage Detection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Vehicle',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (fleet.vehicles.isEmpty)
                      const Text('No vehicles available. Add a vehicle first.',
                          style: TextStyle(color: Colors.grey))
                    else
                      DropdownButtonFormField<Vehicle>(
                        initialValue: _selectedVehicle,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.directions_car_outlined)),
                        hint: const Text('Select vehicle'),
                        items: fleet.vehicles
                            .map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                      '${v.name} - ${v.registrationNumber}'),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedVehicle = v),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image area
            GestureDetector(
              onTap: () => _showPickerOptions(),
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Tap to add vehicle photo',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Camera or gallery',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Pick buttons
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Status
            if (isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                damage.status == AnalysisStatus.uploading
                    ? 'Uploading image...'
                    : 'AI analysing damage...',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
            ],

            if (damage.status == AnalysisStatus.error)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(damage.error ?? 'Analysis failed',
                    style: const TextStyle(color: AppTheme.errorColor)),
              ),

            ElevatedButton.icon(
              onPressed: isLoading ? null : _analyze,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Analyse Damage with AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const _TipsCard(),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();
  @override
  Widget build(BuildContext context) => Card(
        color: AppTheme.primaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.lightbulb_outline,
                    color: AppTheme.primaryColor, size: 18),
                SizedBox(width: 6),
                Text('Tips for best results',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
              ]),
              const SizedBox(height: 8),
              ...[
                'Take photo in good lighting',
                'Ensure damage is clearly visible',
                'Capture the entire affected area',
                'Avoid blurry or dark images',
              ].map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(t, style: const TextStyle(fontSize: 13)),
                    ]),
                  )),
            ],
          ),
        ),
      );
}
