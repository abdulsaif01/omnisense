import '../../core/constants/app_constants.dart';
import 'local_intent_classifier.dart';

enum ConfidenceLevel { high, medium, low }

class RoutingDecision {
  final IntentPrediction prediction;
  final ConfidenceLevel confidenceLevel;
  final bool requiresClarification;
  final String actionDescription;
  final List<String> clarificationOptions;

  const RoutingDecision({
    required this.prediction,
    required this.confidenceLevel,
    required this.requiresClarification,
    required this.actionDescription,
    this.clarificationOptions = const [],
  });
}

class ConfidenceAwareRouter {
  static RoutingDecision route(IntentPrediction prediction) {
    final prob = prediction.probability;
    ConfidenceLevel level;

    if (prob >= AppConstants.highConfidenceThreshold) {
      level = ConfidenceLevel.high;
    } else if (prob >= AppConstants.mediumConfidenceThreshold) {
      level = ConfidenceLevel.medium;
    } else {
      level = ConfidenceLevel.low;
    }

    if (level == ConfidenceLevel.low) {
      return RoutingDecision(
        prediction: prediction,
        confidenceLevel: ConfidenceLevel.low,
        requiresClarification: true,
        actionDescription: 'Low confidence detected. Requesting active perception / clarification.',
        clarificationOptions: [
          'Identify Object in View',
          'Read Document Text',
          'Search Visual Memory'
        ],
      );
    }

    if (level == ConfidenceLevel.medium) {
      return RoutingDecision(
        prediction: prediction,
        confidenceLevel: ConfidenceLevel.medium,
        requiresClarification: false,
        actionDescription: 'Medium confidence (${(prob * 100).toStringAsFixed(1)}%). Proceeding with specialized module verification.',
      );
    }

    return RoutingDecision(
      prediction: prediction,
      confidenceLevel: ConfidenceLevel.high,
      requiresClarification: false,
      actionDescription: 'High confidence (${(prob * 100).toStringAsFixed(1)}%). Routing directly to specialized ${prediction.intent} module.',
    );
  }
}
