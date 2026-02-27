import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../providers/damage_provider.dart';
import '../../providers/fleet_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/vehicle_model.dart';
import '../../utils/app_theme.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});
  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _textCtrl = TextEditingController();
  bool _isListening = false;
  bool _speechAvailable = false;
  Vehicle? _selectedVehicle;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      await _speech.listen(
        onResult: (r) {
          setState(() {
            _textCtrl.text = r.recognizedWords;
            if (r.finalResult) _isListening = false;
          });
        },
        localeId: context.read<LanguageProvider>().languageCode == 'hi'
            ? 'hi_IN'
            : context.read<LanguageProvider>().languageCode == 'ta'
                ? 'ta_IN'
                : 'en_US',
      );
      setState(() => _isListening = true);
    }
  }

  Future<void> _sendQuery() async {
    final q = _textCtrl.text.trim();
    if (q.isEmpty) return;
    final lang = context.read<LanguageProvider>().languageCode;
    await context.read<DamageProvider>().askAssistant(
          question: q,
          vehicleId: _selectedVehicle?.id,
          language: lang,
        );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final damage = context.watch<DamageProvider>();
    final fleet = context.watch<FleetProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Vehicle selector
            if (fleet.vehicles.isNotEmpty)
              DropdownButtonFormField<Vehicle>(
                initialValue: _selectedVehicle,
                decoration: const InputDecoration(
                    labelText: 'Vehicle context (optional)',
                    prefixIcon: Icon(Icons.directions_car_outlined)),
                hint: const Text('All vehicles'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All vehicles')),
                  ...fleet.vehicles.map(
                      (v) => DropdownMenuItem(value: v, child: Text(v.name))),
                ],
                onChanged: (v) => setState(() => _selectedVehicle = v),
              ),
            const SizedBox(height: 24),

            // Mic button
            GestureDetector(
              onTap: _speechAvailable ? _toggleListening : null,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? AppTheme.accentColor
                        : AppTheme.primaryColor,
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: AppTheme.accentColor
                                  .withOpacity(0.3 + 0.3 * _pulseCtrl.value),
                              blurRadius: 20 + 20 * _pulseCtrl.value,
                              spreadRadius: 5 + 5 * _pulseCtrl.value,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none,
                      size: 48, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isListening ? 'Listening...' : 'Tap mic to speak',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Text input
            TextField(
              controller: _textCtrl,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Or type your question',
                hintText: 'e.g. When is my next service due?',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                  onPressed: _sendQuery,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Suggestions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'What is wrong with my car?',
                  'When is my next service due?',
                  'My insurance expiry?',
                  'How healthy is my car?',
                ]
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label:
                                Text(s, style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              _textCtrl.text = s;
                              _sendQuery();
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Answer
            if (damage.assistantLoading)
              const Center(child: CircularProgressIndicator())
            else if (damage.assistantAnswer.isNotEmpty)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.smart_toy,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          const Text('CarGuardian AI',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor)),
                        ]),
                        const SizedBox(height: 12),
                        Text(damage.assistantAnswer,
                            style: const TextStyle(height: 1.6)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
