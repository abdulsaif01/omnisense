import 'package:flutter_tts/flutter_tts.dart';

import 'text_to_speech_service.dart';

class DeviceTextToSpeechService implements TextToSpeechService {
  DeviceTextToSpeechService({FlutterTts? flutterTts})
      : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;

  @override
  Future<void> configure({
    double speechRate = 0.48,
    String language = 'en-US',
    double volume = 1.0,
  }) async {
    await _flutterTts.setLanguage(language);
    await _flutterTts.setSpeechRate(speechRate);
    await _flutterTts.setVolume(volume);
  }

  @override
  Future<void> speak(String text) async {
    await stop();
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
