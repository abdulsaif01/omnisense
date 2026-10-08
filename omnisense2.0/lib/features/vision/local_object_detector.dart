import '../../core/utilities/spatial_reasoner.dart';

class DetectedObject {
  final String label;
  final double confidence;
  final BoundingBox boundingBox;

  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  String get spatialRegion => SpatialReasoner.calculateSpatialRegion(boundingBox);
  String get spatialDescription => SpatialReasoner.formatSpatialDescription(label, boundingBox);
}

class LocalObjectDetector {
  static const List<String> supportedClasses = [
    'person', 'chair', 'table', 'phone', 'laptop', 'book', 'bottle',
    'cup', 'bag', 'keys', 'remote', 'backpack', 'keyboard', 'mouse',
    'door', 'bed', 'sofa', 'medicine bottle', 'box'
  ];

  /// Performs simulated local computer vision inference on image frame
  Future<List<DetectedObject>> detectObjectsInFrame() async {
    // Simulated local TFLite / OpenCV detection output
    await Future.delayed(const Duration(milliseconds: 30));

    return [
      DetectedObject(
        label: 'bottle',
        confidence: 0.94,
        boundingBox: const BoundingBox(ymin: 0.10, xmin: 0.10, ymax: 0.35, xmax: 0.30),
      ),
      DetectedObject(
        label: 'phone',
        confidence: 0.92,
        boundingBox: const BoundingBox(ymin: 0.40, xmin: 0.60, ymax: 0.65, xmax: 0.85),
      ),
      DetectedObject(
        label: 'book',
        confidence: 0.88,
        boundingBox: const BoundingBox(ymin: 0.45, xmin: 0.35, ymax: 0.70, xmax: 0.55),
      ),
      DetectedObject(
        label: 'table',
        confidence: 0.96,
        boundingBox: const BoundingBox(ymin: 0.20, xmin: 0.05, ymax: 0.95, xmax: 0.95),
      ),
    ];
  }

  /// Generates a deterministic scene description based on detected objects and spatial regions
  String generateSceneDescription(List<DetectedObject> detections) {
    if (detections.isEmpty) {
      return 'I do not detect any known objects in the current view.';
    }

    final items = detections.where((d) => d.label != 'table' && d.label != 'chair').toList();
    if (items.isEmpty) {
      return 'I see a ${detections.first.label} in front of you.';
    }

    final descList = items.map((item) => item.spatialDescription).toList();

    if (descList.length == 1) {
      return 'I see a ${descList.first}.';
    } else if (descList.length == 2) {
      return 'I see a ${descList[0]} and a ${descList[1]}.';
    } else {
      final mainPart = descList.sublist(0, descList.length - 1).join(', ');
      return 'I see a $mainPart, and a ${descList.last}.';
    }
  }

  /// Answers structured visual questions without a VLM
  String answerStructuredVqa(String query, List<DetectedObject> detections) {
    final lower = query.toLowerCase();

    if (lower.contains('bottle')) {
      final bottles = detections.where((d) => d.label == 'bottle').toList();
      if (bottles.isNotEmpty) {
        return 'Yes, there is a ${bottles.first.spatialDescription}.';
      }
      return 'I do not see a bottle in the current view.';
    }

    if (lower.contains('phone')) {
      final phones = detections.where((d) => d.label == 'phone').toList();
      if (phones.isNotEmpty) {
        return 'Yes, your phone is ${phones.first.spatialDescription}.';
      }
      return 'I do not see a phone in the current camera view.';
    }

    if (lower.contains('how many')) {
      return 'I can see ${detections.length} distinct objects in front of you.';
    }

    return generateSceneDescription(detections);
  }
}
