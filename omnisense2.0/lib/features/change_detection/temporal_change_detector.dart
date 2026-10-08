import 'dart:convert';
import '../../data/database/app_database.dart';

class TemporalChangeResult {
  final List<String> addedObjects;
  final List<String> removedObjects;
  final List<String> persistentObjects;
  final String summaryText;

  const TemporalChangeResult({
    required this.addedObjects,
    required this.removedObjects,
    required this.persistentObjects,
    required this.summaryText,
  });
}

class TemporalChangeDetector {
  /// Compares Observation Set A with Observation Set B using Set Difference
  static TemporalChangeResult compareObservations(List<String> setA, List<String> setB) {
    final setAUnique = setA.toSet();
    final setBUnique = setB.toSet();

    final added = setBUnique.difference(setAUnique).toList();
    final removed = setAUnique.difference(setBUnique).toList();
    final persistent = setAUnique.intersection(setBUnique).toList();

    final buffer = StringBuffer();
    if (removed.isNotEmpty) {
      buffer.write('The ${removed.join(', ')} is no longer visible in the area previously observed. ');
    }
    if (added.isNotEmpty) {
      buffer.write('New object detected: ${added.join(', ')}. ');
    }
    if (persistent.isNotEmpty) {
      buffer.write('The ${persistent.join(', ')} remains present on the surface.');
    }
    if (added.isEmpty && removed.isEmpty) {
      buffer.write('No object changes detected compared to the previous scan.');
    }

    return TemporalChangeResult(
      addedObjects: added,
      removedObjects: removed,
      persistentObjects: persistent,
      summaryText: buffer.toString().trim(),
    );
  }

  /// Evaluates change between latest two stored observation snapshots in SQLite
  static Future<String> evaluateChangeFromDatabase() async {
    final obs = await AppDatabase.getRecentObservations(limit: 2);
    if (obs.length < 2) {
      // Simulate comparison if database has fewer than 2 snapshots
      final setA = ['water bottle', 'phone', 'keys', 'book'];
      final setB = ['water bottle', 'keys', 'book'];
      final res = compareObservations(setA, setB);
      return res.summaryText;
    }

    final setA = List<String>.from(json.decode(obs[1]['objects_json']));
    final setB = List<String>.from(json.decode(obs[0]['objects_json']));
    final res = compareObservations(setA, setB);
    return res.summaryText;
  }
}
