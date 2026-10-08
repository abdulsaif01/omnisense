abstract class SpeechToTextService {
  Future<bool> initialize();

  Future<String?> listenOnce();

  Future<void> startWakeWordListening({
    required void Function() onWakeWordDetected,
  });

  Future<void> stop();
}
