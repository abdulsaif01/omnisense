import 'dart:math';
import '../../data/database/app_database.dart';

class PersonalObjectMemory {
  /// Computes cosine similarity between two feature vector embeddings
  static double computeCosineSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length || vecA.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Stores a personal object observation into SQLite database
  static Future<String> storePersonalMemory({
    required String userQuery,
    required String locationContext,
  }) async {
    final clean = userQuery.toLowerCase().replaceAll('remember', '').replaceAll('that', '').replaceAll('my', '').trim();
    final parts = clean.split(RegExp(r'\s+is\s+|\s+was\s+|\s+on\s+|\s+at\s+'));
    final concept = parts.isNotEmpty ? parts.first.trim() : 'item';

    final memory = StoredMemory(
      keyConcept: concept,
      content: userQuery,
      locationContext: locationContext.isNotEmpty ? locationContext : 'study table',
      confidence: 0.95,
    );

    await AppDatabase.insertMemory(memory);
    return 'I have recorded that your $concept is located at ${memory.locationContext}.';
  }

  /// Retrieves last known visual location of a personal object
  static Future<String> retrievePersonalMemory(String userQuery) async {
    final clean = userQuery.toLowerCase();
    final words = clean.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

    String searchTerm = '';
    for (final w in words) {
      if (!['where', 'did', 'put', 'leave', 'find', 'last', 'seen', 'located', 'the', 'my'].contains(w)) {
        searchTerm = w;
        break;
      }
    }

    final memories = await AppDatabase.searchMemories(searchTerm);
    if (memories.isNotEmpty) {
      final m = memories.first;
      return 'The last time I saw your ${m.keyConcept}, it was located at ${m.locationContext}.';
    }

    return 'I could not find a stored memory for that item in your database.';
  }
}
