import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/accessibility/accessibility_feedback_service.dart';
import '../../../services/speech_service/speech_to_text_service.dart';
import '../../../services/inference_service/orchestrator_service.dart';
import '../../../ml/intent_classifier/confidence_aware_router.dart';

class CameraHomeScreen extends StatefulWidget {
  const CameraHomeScreen({super.key});

  @override
  State<CameraHomeScreen> createState() => _CameraHomeScreenState();
}

class _CameraHomeScreenState extends State<CameraHomeScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  final SpeechToTextService _sttService = SpeechToTextService();
  final OrchestratorService _orchestrator = OrchestratorService();
  final AccessibilityFeedbackService _feedback = AccessibilityFeedbackService();

  bool _isListening = false;
  bool _isProcessing = false;
  bool _isResponseExpanded = true;
  String _recognizedText = 'Press Mic or say "Hey OmniSense"';

  PipelineResult? _latestResult;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initServices();
  }

  Future<void> _initServices() async {
    await _sttService.initialize();
    await _orchestrator.initialize();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Select rear camera automatically
        final rearCamera = _cameras!.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          rearCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
          await _feedback.speak('OmniSense camera ready.');
          await _feedback.triggerSuccessHaptic();
        }
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  void _toggleListening() async {
    await _feedback.triggerHapticFeedback(durationMs: 40);

    if (_isListening) {
      await _sttService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      await _feedback.speak('Listening');
      setState(() {
        _isListening = true;
        _recognizedText = 'Listening... Speak now.';
      });

      await _sttService.startListening(
        onResult: (text) {
          setState(() {
            _recognizedText = text;
          });
        },
        onListeningComplete: () {
          setState(() {
            _isListening = false;
          });
          if (_recognizedText.isNotEmpty && _recognizedText != 'Listening... Speak now.') {
            _handleQuery(_recognizedText);
          }
        },
      );
    }
  }

  Future<void> _handleQuery(String query) async {
    setState(() {
      _isProcessing = true;
    });

    final result = await _orchestrator.processQuery(query);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _latestResult = result;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _feedback.stop();
    super.dispose();
  }

  Color _getConfidenceColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return Colors.green.shade600;
      case ConfidenceLevel.medium:
        return Colors.orange.shade700;
      case ConfidenceLevel.low:
        return Colors.red.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'OmniSense AI Assistant',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
            tooltip: 'Clear Privacy History',
            onPressed: () async {
              await _orchestrator.processQuery('delete all stored visual memories');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Rear Camera Live Preview
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),

          // 2. Top Info Overlay & Status Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Semantics(
              label: 'System Status Indicator',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isListening
                          ? Icons.mic
                          : _isProcessing
                              ? Icons.memory
                              : Icons.center_focus_strong,
                      color: _isListening ? Colors.redAccent : Colors.lightBlueAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isProcessing ? 'Processing local AI query...' : _recognizedText,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Response Dropdown Card & Microphone Control
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Response Header Dropdown Toggle
                  if (_latestResult != null) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isResponseExpanded = !_isResponseExpanded;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getConfidenceColor(_latestResult!.confidenceLevel),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _latestResult!.confidenceLevel.name.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _latestResult!.intent,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          Icon(
                            _isResponseExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Expandable Details View
                    if (_isResponseExpanded) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _latestResult!.responseText,
                              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.3),
                            ),
                            const Divider(color: Colors.white24, height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Model: ${_latestResult!.modelUsed}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                Text(
                                  'Lat: ${_latestResult!.latencyMs.toStringAsFixed(1)} ms',
                                  style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // 4. Large Accessible Microphone Button
                  Semantics(
                    button: true,
                    label: _isListening ? 'Stop listening' : 'Start voice query',
                    hint: 'Double tap to activate microphone and speak to OmniSense assistant',
                    child: ElevatedButton(
                      onPressed: _toggleListening,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                        backgroundColor: _isListening ? Colors.redAccent : Colors.blueAccent,
                        elevation: 8,
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isListening ? 'TAP TO STOP' : 'TAP MIC TO SPEAK',
                    style: TextStyle(
                      color: _isListening ? Colors.redAccent : Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
