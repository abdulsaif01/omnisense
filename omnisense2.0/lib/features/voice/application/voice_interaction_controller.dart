import 'package:flutter/foundation.dart';

import '../../../core/network/api_service.dart';
import 'speech_to_text_service.dart';
import 'text_to_speech_service.dart';

class VoiceInteractionController extends ChangeNotifier {
  VoiceInteractionController({
    required SpeechToTextService speechToTextService,
    required TextToSpeechService textToSpeechService,
    ApiService? apiService,
    Future<List<int>?> Function()? captureImage,
  })  : _speechToTextService = speechToTextService,
        _textToSpeechService = textToSpeechService,
        _apiService = apiService,
        _captureImage = captureImage;

  final SpeechToTextService _speechToTextService;
  final TextToSpeechService _textToSpeechService;
  final ApiService? _apiService;
  final Future<List<int>?> Function()? _captureImage;

  VoiceInteractionState _state = VoiceInteractionState.idle;
  String _lastTranscript = '';
  String _lastResponse = '';
  bool _isWakeWordActive = false;

  VoiceInteractionState get state => _state;

  String get lastTranscript => _lastTranscript;

  String get lastResponse => _lastResponse;

  bool get isWakeWordActive => _isWakeWordActive;

  Future<void> initialize() async {
    await _textToSpeechService.configure();
    await _speechToTextService.initialize();
  }

  void toggleWakeWordMode() {
    _isWakeWordActive = !_isWakeWordActive;
    notifyListeners();
    if (_isWakeWordActive) {
      _textToSpeechService.speak('Hands free mode active. Say Hey OmniSense to ask questions.');
      _startWakeWordLoop();
    } else {
      _textToSpeechService.speak('Hands free mode disabled.');
      _speechToTextService.stop();
    }
  }

  Future<void> _startWakeWordLoop() async {
    if (!_isWakeWordActive || _state != VoiceInteractionState.idle) return;

    await _speechToTextService.startWakeWordListening(
      onWakeWordDetected: () async {
        if (!_isWakeWordActive) return;
        await startPushToTalk();
        if (_isWakeWordActive) {
          _startWakeWordLoop();
        }
      },
    );
  }

  Future<void> speakStatus(String message) async {
    await _textToSpeechService.speak(message);
  }

  Future<void> startPushToTalk() async {
    if (_state == VoiceInteractionState.listening ||
        _state == VoiceInteractionState.processing) {
      return;
    }

    _setState(VoiceInteractionState.listening);
    _textToSpeechService.speak('Listening.');

    try {
      final transcript = await _speechToTextService.listenOnce();
      if (transcript == null || transcript.trim().isEmpty) {
        _lastResponse = 'I did not hear a clear question. Please try again.';
        _setState(VoiceInteractionState.idle);
        await _textToSpeechService.speak(_lastResponse);
        return;
      }

      await submitQuery(transcript);
    } catch (error) {
      _lastResponse = error.toString();
      _setState(VoiceInteractionState.error);
      await _textToSpeechService.speak(_lastResponse);
      _setState(VoiceInteractionState.idle);
    }
  }

  Future<void> submitQuery(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return;
    }

    _lastTranscript = cleanQuery;
    _setState(VoiceInteractionState.processing);
    await _textToSpeechService.speak('Processing.');

    try {
      _lastResponse = await _processQuery(_lastTranscript);
      _setState(VoiceInteractionState.responding);
      await _textToSpeechService.speak(_lastResponse);
      _setState(VoiceInteractionState.idle);
    } catch (error) {
      _lastResponse = error.toString();
      _setState(VoiceInteractionState.error);
      await _textToSpeechService.speak(_lastResponse);
      _setState(VoiceInteractionState.idle);
    }
  }

  Future<String> _processQuery(String query) async {
    final apiService = _apiService;
    if (apiService == null) {
      return 'I heard: $query. Assistant backend is not configured. '
          'Run the app with OMNISENSE_API_BASE_URL set to your backend URL.';
    }

    final captureImage = _captureImage;
    if (captureImage == null) {
      final response = await apiService.submitTextQuery(query);
      return _readAssistantResponse(response);
    }

    final imageBytes = await captureImage();
    if (imageBytes == null || imageBytes.isEmpty) {
      return 'I could not capture a camera image. Please try again.';
    }

    final response = await apiService.submitVisionQuery(
      query: query,
      imageBytes: imageBytes,
    );
    return _readAssistantResponse(response);
  }

  String _readAssistantResponse(Map<String, dynamic> response) {
    final value = response['answer'] ??
        response['response'] ??
        response['message'] ??
        response['text'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return 'The assistant service replied, but no spoken answer was provided.';
  }

  Future<void> stop() async {
    await _speechToTextService.stop();
    await _textToSpeechService.stop();
    _setState(VoiceInteractionState.idle);
  }

  void _setState(VoiceInteractionState value) {
    _state = value;
    notifyListeners();
  }
}

enum VoiceInteractionState {
  idle,
  listening,
  processing,
  responding,
  error,
}
