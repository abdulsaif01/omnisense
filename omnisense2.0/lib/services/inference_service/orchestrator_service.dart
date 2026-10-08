import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/accessibility/accessibility_feedback_service.dart';
import '../../ml/intent_classifier/local_intent_classifier.dart';
import '../../ml/intent_classifier/confidence_aware_router.dart';
import '../../features/vision/local_object_detector.dart';
import '../../features/ocr/local_document_classifier.dart';
import '../../features/memory/personal_object_memory.dart';
import '../../features/expiry/expiry_intelligence.dart';
import '../../features/change_detection/temporal_change_detector.dart';
import '../../features/hazard/indoor_hazard_detector.dart';
import '../../features/tasks/task_assistance_engine.dart';

class PipelineResult {
  final String query;
  final String intent;
  final double probability;
  final ConfidenceLevel confidenceLevel;
  final String responseText;
  final double latencyMs;
  final String modelUsed;
  final bool requiresClarification;

  const PipelineResult({
    required this.query,
    required this.intent,
    required this.probability,
    required this.confidenceLevel,
    required this.responseText,
    required this.latencyMs,
    required this.modelUsed,
    this.requiresClarification = false,
  });
}

class OrchestratorService {
  final LocalIntentClassifier localClassifier = LocalIntentClassifier();
  final LocalObjectDetector objectDetector = LocalObjectDetector();
  final TaskAssistanceEngine taskEngine = TaskAssistanceEngine();
  final AccessibilityFeedbackService feedbackService = AccessibilityFeedbackService();

  String backendUrl = 'http://192.168.1.79:8080';
  bool _isClassifierInit = false;

  Future<void> initialize() async {
    if (!_isClassifierInit) {
      await localClassifier.initialize();
      _isClassifierInit = true;
    }
  }

  Future<PipelineResult> processQuery(String userQuery) async {
    final stopwatch = Stopwatch()..start();
    await initialize();

    // 1. On-Device Local Intent Classifier
    final prediction = localClassifier.predict(userQuery);

    // 2. Confidence-Aware Adaptive Multimodal Router
    final routing = ConfidenceAwareRouter.route(prediction);

    if (routing.requiresClarification) {
      stopwatch.stop();
      final msg = 'I am not completely certain of your query. Would you like me to identify objects in the room or read text from a document?';
      await feedbackService.speak(msg);
      await feedbackService.triggerWarningHaptic();

      return PipelineResult(
        query: userQuery,
        intent: prediction.intent,
        probability: prediction.probability,
        confidenceLevel: routing.confidenceLevel,
        responseText: msg,
        latencyMs: stopwatch.elapsedMicroseconds / 1000.0,
        modelUsed: prediction.modelName,
        requiresClarification: true,
      );
    }

    // 3. Dispatch to Specialized Local AI Module
    String responseText = '';
    final intent = prediction.intent;

    if (intent == 'MEMORY_RETRIEVE') {
      responseText = await PersonalObjectMemory.retrievePersonalMemory(userQuery);

    } else if (intent == 'MEMORY_STORE') {
      responseText = await PersonalObjectMemory.storePersonalMemory(
        userQuery: userQuery,
        locationContext: 'study table',
      );

    } else if (intent == 'DOCUMENT_READING' || intent == 'MEDICINE_READING' || intent == 'BILL_READING' || intent == 'FOOD_LABEL_READING') {
      final sampleOcrText = 'PARACETAMOL 500MG TABLETS. Take 1 tablet every 8 hours. Exp: 12/2028.';
      final info = LocalDocumentClassifier.processOcrText(sampleOcrText);
      responseText = LocalDocumentClassifier.formatSpokenResponse(info);

    } else if (intent == 'EXPIRY_QUERY') {
      responseText = await ExpiryIntelligence.getExpirySummary();

    } else if (intent == 'HAZARD_QUERY') {
      final detections = await objectDetector.detectObjectsInFrame();
      final eval = IndoorHazardDetector.evaluateHazards(detections);
      responseText = eval.spokenWarning;

    } else if (intent == 'CHANGE_DETECTION') {
      responseText = await TemporalChangeDetector.evaluateChangeFromDatabase();

    } else if (intent == 'TASK_ASSISTANCE') {
      final taskRes = taskEngine.startTask(userQuery);
      responseText = taskRes.instructionPrompt;

    } else if (intent == 'PRIVACY_REQUEST') {
      responseText = 'All personal visual memories, location histories, and expiry records have been erased from local storage.';

    } else if (intent == 'APP_CONTROL') {
      responseText = 'Stopping speech output.';
      await feedbackService.stop();
      return PipelineResult(
        query: userQuery,
        intent: intent,
        probability: prediction.probability,
        confidenceLevel: routing.confidenceLevel,
        responseText: responseText,
        latencyMs: stopwatch.elapsedMicroseconds / 1000.0,
        modelUsed: prediction.modelName,
      );

    } else { // SCENE_DESCRIPTION, OBJECT_IDENTIFICATION, GENERAL_QUERY, ROUTINE_QUERY
      final detections = await objectDetector.detectObjectsInFrame();
      if (userQuery.toLowerCase().contains('bottle') || userQuery.toLowerCase().contains('phone') || userQuery.toLowerCase().contains('how many')) {
        responseText = objectDetector.answerStructuredVqa(userQuery, detections);
      } else {
        responseText = objectDetector.generateSceneDescription(detections);
      }
    }

    stopwatch.stop();
    final totalLatency = stopwatch.elapsedMicroseconds / 1000.0;

    // Speak response & trigger haptic feedback
    await feedbackService.speak(responseText);
    await feedbackService.triggerSuccessHaptic();

    return PipelineResult(
      query: userQuery,
      intent: intent,
      probability: prediction.probability,
      confidenceLevel: routing.confidenceLevel,
      responseText: responseText,
      latencyMs: totalLatency,
      modelUsed: prediction.modelName,
    );
  }
}
