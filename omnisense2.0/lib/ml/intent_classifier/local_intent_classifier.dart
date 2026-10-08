import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class IntentPrediction {
  final String intent;
  final double probability;
  final String modelName;
  final double latencyMs;

  const IntentPrediction({
    required this.intent,
    required this.probability,
    required this.modelName,
    required this.latencyMs,
  });
}

class LocalIntentClassifier {
  Map<String, dynamic>? _modelWeights;
  Map<String, int> _vocab = {};
  List<double> _idf = [];
  List<String> _classes = [];
  List<List<double>> _coefs = [];
  List<double> _intercepts = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> initialize() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/models/intent_model_weights.json');
      _modelWeights = json.decode(jsonStr);

      _vocab = Map<String, int>.from(_modelWeights!['vocabulary']);
      _idf = List<double>.from((_modelWeights!['idf'] as List).map((x) => (x as num).toDouble()));
      _classes = List<String>.from(_modelWeights!['classes']);
      _intercepts = List<double>.from((_modelWeights!['intercepts'] as List).map((x) => (x as num).toDouble()));

      final rawCoefs = _modelWeights!['coefficients'] as List;
      _coefs = rawCoefs.map((row) => List<double>.from((row as List).map((x) => (x as num).toDouble()))).toList();

      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
    }
  }

  List<String> _tokenizeNgrams(String text) {
    final clean = text.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase().trim();
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final ngrams = <String>[...words];

    for (int i = 0; i < words.length - 1; i++) {
      ngrams.add('${words[i]} ${words[i + 1]}');
    }
    return ngrams;
  }

  /// Predicts intent using On-Device Local TF-IDF + Logistic Regression Model
  IntentPrediction predict(String text) {
    final stopwatch = Stopwatch()..start();

    if (!_isLoaded || _vocab.isEmpty) {
      return predictBaselineRuleBased(text);
    }

    final ngrams = _tokenizeNgrams(text);
    final tfidfVec = List<double>.filled(_vocab.length, 0.0);

    final counts = <String, int>{};
    for (final ng in ngrams) {
      if (_vocab.containsKey(ng)) {
        counts[ng] = (counts[ng] ?? 0) + 1;
      }
    }

    counts.forEach((ng, count) {
      final idx = _vocab[ng]!;
      final tf = count > 0 ? 1.0 + log(count) : 0.0;
      tfidfVec[idx] = tf * _idf[idx];
    });

    // L2 Normalization
    double sumSq = 0.0;
    for (final v in tfidfVec) {
      sumSq += v * v;
    }
    final norm = sqrt(sumSq);
    if (norm > 0) {
      for (int i = 0; i < tfidfVec.length; i++) {
        tfidfVec[i] /= norm;
      }
    }

    // Linear Logits
    final logits = List<double>.filled(_classes.length, 0.0);
    for (int i = 0; i < _classes.length; i++) {
      double sum = _intercepts[i];
      for (int j = 0; j < tfidfVec.length; j++) {
        sum += tfidfVec[j] * _coefs[i][j];
      }
      logits[i] = sum;
    }

    // Softmax Probability
    final maxLogit = logits.reduce(max);
    final exps = logits.map((l) => exp(l - maxLogit)).toList();
    final sumExp = exps.reduce((a, b) => a + b);
    final probs = exps.map((e) => e / sumExp).toList();

    int maxIdx = 0;
    double maxProb = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIdx = i;
      }
    }

    stopwatch.stop();
    final lat = stopwatch.elapsedMicroseconds / 1000.0;

    return IntentPrediction(
      intent: _classes[maxIdx],
      probability: maxProb,
      modelName: 'Model A (TF-IDF + LogReg Local)',
      latencyMs: lat,
    );
  }

  /// Baseline Rule-Based Keyword Classifier for comparative ablation research
  IntentPrediction predictBaselineRuleBased(String text) {
    final stopwatch = Stopwatch()..start();
    final lower = text.toLowerCase();

    String intent = 'SCENE_DESCRIPTION';
    double confidence = 0.60;

    if (lower.contains('where') || lower.contains('locate') || lower.contains('find my') || lower.contains('last seen')) {
      intent = 'MEMORY_RETRIEVE';
      confidence = 0.85;
    } else if (lower.contains('remember') || lower.contains('save location') || lower.contains('store')) {
      intent = 'MEMORY_STORE';
      confidence = 0.80;
    } else if (lower.contains('medicine') || lower.contains('dosage') || lower.contains('pill') || lower.contains('tablet')) {
      intent = 'MEDICINE_READING';
      confidence = 0.80;
    } else if (lower.contains('read') || lower.contains('document') || lower.contains('paper') || lower.contains('text')) {
      intent = 'DOCUMENT_READING';
      confidence = 0.75;
    } else if (lower.contains('expire') || lower.contains('expiration') || lower.contains('best before')) {
      intent = 'EXPIRY_QUERY';
      confidence = 0.85;
    } else if (lower.contains('hazard') || lower.contains('obstacle') || lower.contains('spill') || lower.contains('floor')) {
      intent = 'HAZARD_QUERY';
      confidence = 0.75;
    } else if (lower.contains('changed') || lower.contains('moved') || lower.contains('disappeared')) {
      intent = 'CHANGE_DETECTION';
      confidence = 0.80;
    } else if (lower.contains('receipt') || lower.contains('bill') || lower.contains('total amount')) {
      intent = 'BILL_READING';
      confidence = 0.80;
    } else if (lower.contains('ingredient') || lower.contains('food') || lower.contains('calories')) {
      intent = 'FOOD_LABEL_READING';
      confidence = 0.80;
    } else if (lower.contains('step by step') || lower.contains('guide me') || lower.contains('task')) {
      intent = 'TASK_ASSISTANCE';
      confidence = 0.75;
    }

    stopwatch.stop();
    final lat = stopwatch.elapsedMicroseconds / 1000.0;

    return IntentPrediction(
      intent: intent,
      probability: confidence,
      modelName: 'Baseline (Rule-Based)',
      latencyMs: lat,
    );
  }
}
