import '../vision/local_object_detector.dart';

enum HazardRiskCategory { low, medium, high }

class HazardEvaluation {
  final HazardRiskCategory riskCategory;
  final double riskScore;
  final String description;
  final String spokenWarning;

  const HazardEvaluation({
    required this.riskCategory,
    required this.riskScore,
    required this.description,
    required this.spokenWarning,
  });
}

class IndoorHazardDetector {
  /// Evaluates indoor hazards and computes risk score f(confidence, position, category)
  static HazardEvaluation evaluateHazards(List<DetectedObject> detections) {
    double maxRiskScore = 0.0;
    String hazardItem = '';
    String spatialLoc = '';

    for (final det in detections) {
      final region = det.spatialRegion;
      double positionMultiplier = 0.5;

      // Lower center / lower floor carries higher obstruction risk
      if (region == 'lower-center' || region == 'lower-left' || region == 'lower-right') {
        positionMultiplier = 1.0;
      } else if (region == 'center') {
        positionMultiplier = 0.8;
      }

      double categoryRisk = 0.3;
      if (['backpack', 'bag', 'keys', 'bottle', 'cup'].contains(det.label)) {
        categoryRisk = 0.8; // Low-lying trip hazard
      }

      final score = det.confidence * positionMultiplier * categoryRisk;
      if (score > maxRiskScore) {
        maxRiskScore = score;
        hazardItem = det.label;
        spatialLoc = det.spatialDescription;
      }
    }

    HazardRiskCategory category;
    if (maxRiskScore >= 0.60) {
      category = HazardRiskCategory.high;
    } else if (maxRiskScore >= 0.35) {
      category = HazardRiskCategory.medium;
    } else {
      category = HazardRiskCategory.low;
    }

    if (category == HazardRiskCategory.high) {
      return HazardEvaluation(
        riskCategory: category,
        riskScore: maxRiskScore,
        description: 'Obstacle detected directly on floor path: $hazardItem',
        spokenWarning: 'Caution: There appears to be a $hazardItem $spatialLoc. Please tread carefully.',
      );
    } else if (category == HazardRiskCategory.medium) {
      return HazardEvaluation(
        riskCategory: category,
        riskScore: maxRiskScore,
        description: 'Potential low-lying item detected near walking area',
        spokenWarning: 'Notice: A $hazardItem is visible $spatialLoc. Path is mostly clear.',
      );
    } else {
      return const HazardEvaluation(
        riskCategory: HazardRiskCategory.low,
        riskScore: 0.15,
        description: 'Floor area scan clear',
        spokenWarning: 'The floor area ahead appears clear of immediate tripping hazards.',
      );
    }
  }
}
