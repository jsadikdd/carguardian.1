import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../providers/fleet_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../models/vehicle.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final ApiService _api = ApiService();

  bool _isListening = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String _aiResponse = '';
  Vehicle? _contextVehicle;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _startListening() async {
    if (!await _speech.initialize()) return;
    setState(() {
      _isListening = true;
      _recognizedText = '';
    });
    await _speech.listen(
      onResult: (result) {
        setState(() => _recognizedText = result.recognizedWords);
        if (result.finalResult) {
          _stopListening();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (_recognizedText.isNotEmpty) {
      await _processQuery(_recognizedText);
    }
  }

  Future<void> _processQuery(String query) async {
    setState(() {
      _isProcessing = true;
      _chatHistory.add({'role': 'user', 'text': query});
    });

    try {
      final response = await _api.voiceQuery(
        query,
        vehicleId: _contextVehicle?.id,
        language: 'en',
      );
      setState(() {
        _aiResponse = response;
        _isProcessing = false;
        _chatHistory.add({'role': 'assistant', 'text': response});
      });
      await _tts.speak(response);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _aiResponse = 'Sorry, I could not process that. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice AI Assistant'),
        actions: [
          if (_chatHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() {
                _chatHistory.clear();
                _recognizedText = '';
                _aiResponse = '';
              }),
            ),
        ],
      ),
      body: Column(
        children: [
          // Vehicle context picker
          Container(
            color: AppTheme.primaryBlue.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.directions_car,
                    size: 18, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<Vehicle>(
                    value: _contextVehicle,
                    hint: const Text('Ask about all vehicles',
                        style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem<Vehicle>(
                        value: null,
                        child: Text('All Vehicles'),
                      ),
                      ...fleet.vehicles.map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v.vehicleName),
                          )),
                    ],
                    onChanged: (v) => setState(() => _contextVehicle = v),
                  ),
                ),
              ],
            ),
          ),

          // Chat history
          Expanded(
            child: _chatHistory.isEmpty
                ? _EmptyVoiceState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatHistory.length,
                    itemBuilder: (_, i) {
                      final msg = _chatHistory[i];
                      final isUser = msg['role'] == 'user';
                      return _ChatBubble(
                          text: msg['text']!, isUser: isUser);
                    },
                  ),
          ),

          if (_isProcessing) ...[
            const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('AI is thinking...',
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
          ],

          // Quick suggestions
          if (_chatHistory.isEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  'What\'s wrong with my car?',
                  'When is my next service?',
                  'Check insurance status',
                  'How is my fleet health?',
                ].map((q) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(q, style: const TextStyle(fontSize: 11)),
                        onPressed: () => _processQuery(q),
                        backgroundColor:
                            AppTheme.primaryBlue.withOpacity(0.1),
                        side: BorderSide(
                            color: AppTheme.primaryBlue.withOpacity(0.3)),
                      ),
                    )).toList(),
              ),
            ),

          // Mic button
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      _isListening
                          ? _recognizedText.isEmpty
                              ? 'Listening...'
                              : _recognizedText
                          : 'Tap mic to ask a question',
                      style: TextStyle(
                        color: _isListening
                            ? Colors.black87
                            : Colors.grey.shade500,
                        fontStyle: _recognizedText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, child) => Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: child,
                  ),
                  child: GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: _isListening
                            ? AppTheme.dangerGradient
                            : AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening
                                    ? AppTheme.dangerRed
                                    : AppTheme.primaryBlue)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
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

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryBlue
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                children: [
                  const Icon(Icons.shield,
                      size: 14, color: AppTheme.primaryBlue),
                  const SizedBox(width: 4),
                  Text('CarGuardian AI',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                ],
              ),
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyVoiceState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('Ask Me Anything',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Tap the microphone and ask\nabout your vehicles, service, or damage.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }
}
