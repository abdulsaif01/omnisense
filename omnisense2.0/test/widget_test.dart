import 'package:flutter_test/flutter_test.dart';
import 'package:omnisense/core/utilities/spatial_reasoner.dart';
import 'package:omnisense/ml/intent_classifier/local_intent_classifier.dart';
import 'package:omnisense/ml/intent_classifier/confidence_aware_router.dart';
import 'package:omnisense/features/vision/local_object_detector.dart';
import 'package:omnisense/features/ocr/local_document_classifier.dart';
import 'package:omnisense/features/change_detection/temporal_change_detector.dart';
import 'package:omnisense/features/hazard/indoor_hazard_detector.dart';
import 'package:omnisense/features/tasks/task_assistance_engine.dart';

void main() {
  group('OmniSense Local AI & Spatial Reasoning Tests', () {
    test('Spatial Reasoner maps bounding box coordinates correctly', () {
      const bboxUpperLeft = BoundingBox(ymin: 0.1, xmin: 0.1, ymax: 0.3, xmax: 0.3);
      expect(SpatialReasoner.calculateSpatialRegion(bboxUpperLeft), equals('upper-left'));

      const bboxCenter = BoundingBox(ymin: 0.4, xmin: 0.4, ymax: 0.6, xmax: 0.6);
      expect(SpatialReasoner.calculateSpatialRegion(bboxCenter), equals('center'));

      const bboxLowerCenter = BoundingBox(ymin: 0.7, xmin: 0.4, ymax: 0.9, xmax: 0.6);
      expect(SpatialReasoner.calculateSpatialRegion(bboxLowerCenter), equals('lower-center'));
    });

    test('Local Baseline Rule-Based Intent Classifier predicts intents accurately', () {
      final classifier = LocalIntentClassifier();

      final pred1 = classifier.predictBaselineRuleBased('Where did I leave my keys?');
      expect(pred1.intent, equals('MEMORY_RETRIEVE'));
      expect(pred1.probability, greaterThanOrEqualTo(0.70));

      final pred2 = classifier.predictBaselineRuleBased('Remember that my watch is on the table');
      expect(pred2.intent, equals('MEMORY_STORE'));

      final pred3 = classifier.predictBaselineRuleBased('Read medicine bottle dosage');
      expect(pred3.intent, equals('MEDICINE_READING'));

      final pred4 = classifier.predictBaselineRuleBased('Are there any hazards on the floor?');
      expect(pred4.intent, equals('HAZARD_QUERY'));
    });

    test('Confidence-Aware Adaptive Router categorizes confidence correctly', () {
      const highPred = IntentPrediction(
        intent: 'MEDICINE_READING',
        probability: 0.85,
        modelName: 'TestModel',
        latencyMs: 1.0,
      );
      final highRoute = ConfidenceAwareRouter.route(highPred);
      expect(highRoute.confidenceLevel, equals(ConfidenceLevel.high));
      expect(highRoute.requiresClarification, isFalse);

      const lowPred = IntentPrediction(
        intent: 'UNKNOWN',
        probability: 0.35,
        modelName: 'TestModel',
        latencyMs: 1.0,
      );
      final lowRoute = ConfidenceAwareRouter.route(lowPred);
      expect(lowRoute.confidenceLevel, equals(ConfidenceLevel.low));
      expect(lowRoute.requiresClarification, isTrue);
    });

    test('Local Document Classifier parses Medicine & Bill fields', () {
      const sampleMed = 'PARACETAMOL 500MG TABLETS. Take 1 tablet every 8 hours. Exp: 12/2028.';
      final medInfo = LocalDocumentClassifier.processOcrText(sampleMed);
      expect(medInfo.type, equals(DocumentType.medicine));
      expect(medInfo.extractedFields['strength'], equals('500mg'));

      const sampleBill = 'SUPERMARKET RECEIPT. TOTAL: \$15.50. Date: 05-10-2026.';
      final billInfo = LocalDocumentClassifier.processOcrText(sampleBill);
      expect(billInfo.type, equals(DocumentType.billReceipt));
      expect(billInfo.extractedFields['total_amount'], equals('15.50'));
    });

    test('Temporal Change Detector compares observation sets', () {
      final setA = ['bottle', 'phone', 'keys', 'book'];
      final setB = ['bottle', 'keys', 'book'];

      final result = TemporalChangeDetector.compareObservations(setA, setB);
      expect(result.removedObjects, contains('phone'));
      expect(result.persistentObjects, contains('bottle'));
      expect(result.summaryText, contains('phone is no longer visible'));
    });

    test('Indoor Hazard Detector calculates floor obstruction risk', () {
      const objFloor = DetectedObject(
        label: 'backpack',
        confidence: 0.95,
        boundingBox: BoundingBox(ymin: 0.7, xmin: 0.4, ymax: 0.9, xmax: 0.6),
      );

      final eval = IndoorHazardDetector.evaluateHazards([objFloor]);
      expect(eval.riskCategory, equals(HazardRiskCategory.high));
      expect(eval.spokenWarning, contains('Caution: There appears to be a backpack'));
    });

    test('Task Assistance Engine transitions states correctly', () {
      final engine = TaskAssistanceEngine();
      final start = engine.startTask('Help me find my keys step by step');
      expect(start.state, equals(TaskState.searching));
      expect(start.targetItem, equals('keys'));

      final step2 = engine.processFrameObservations(true, 'on your right table');
      expect(step2.state, equals(TaskState.found));

      final step3 = engine.processFrameObservations(true, 'on your right table');
      expect(step3.state, equals(TaskState.completed));
    });
  });
}
