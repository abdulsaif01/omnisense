import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_to_text_service.dart';

class DeviceSpeechToTextService implements SpeechToTextService {
  DeviceSpeechToTextService({SpeechToText? speechToText})
      : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;
  bool _initialized = false;

  @override
  Future<bool> initialize() async {
    if (!kIsWeb) {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        return false;
      }
    }

    try {
      _initialized = await _speechToText.initialize(
        onError: _handleError,
        debugLogging: false,
      );
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<String?> listenOnce() async {
    if (!_initialized) {
      final ready = await initialize();
      if (!ready) {
        throw const SpeechRecognitionException(
          'Microphone permission is required to listen.',
        );
      }
    }

    final completer = Completer<String?>();
    var lastRecognizedWords = '';

    try {
      await _speechToText.listen(
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(seconds: 15),
        onResult: (SpeechRecognitionResult result) {
          if (result.recognizedWords.trim().isNotEmpty) {
            lastRecognizedWords = result.recognizedWords.trim();
          }
          if (result.finalResult && !completer.isCompleted) {
            completer.complete(lastRecognizedWords);
          }
        },
      );
    } catch (_) {
      if (!completer.isCompleted) {
        completer.complete(lastRecognizedWords.isEmpty ? null : lastRecognizedWords);
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () async {
        await stop();
        return lastRecognizedWords.isEmpty ? null : lastRecognizedWords;
      },
    );
  }

  Future<void> startWakeWordListening({
    required void Function() onWakeWordDetected,
  }) async {
    if (!_initialized) {
      final ready = await initialize();
      if (!ready) return;
    }

    try {
      await _speechToText.listen(
        listenMode: ListenMode.dictation,
        partialResults: true,
        pauseFor: const Duration(seconds: 10),
        listenFor: const Duration(seconds: 30),
        onResult: (SpeechRecognitionResult result) {
          final words = result.recognizedWords.toLowerCase();
          if (words.contains('omnisense') ||
              words.contains('hey omnisense') ||
              words.contains('ok omnisense') ||
              words.contains('hey omni') ||
              words.contains('omni')) {
            stop();
            onWakeWordDetected();
          }
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _speechToText.stop();
    } catch (_) {}
  }

  void _handleError(SpeechRecognitionError error) {
    if (error.permanent) {
      _initialized = false;
    }
  }
}

class SpeechRecognitionException implements Exception {
  const SpeechRecognitionException(this.message);

  final String message;

  @override
  String toString() => message;
}
