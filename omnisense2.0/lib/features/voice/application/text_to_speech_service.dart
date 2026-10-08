abstract class TextToSpeechService {
  Future<void> configure({
    double speechRate,
    String language,
    double volume,
  });

  Future<void> speak(String text);

  Future<void> stop();
}
