# OmniSense Architecture Specification

## Overview
OmniSense is designed around a modular, local-first architecture for Android. It eliminates external cloud dependency on proprietary vision-language models (e.g. Gemini, OpenAI) by combining on-device machine-learning intent classification, confidence calibration, adaptive routing, classical computer vision bounding-box spatial coordinates, local document parsing, and local SQLite data storage.

```text
User Input (Voice / Touch)
        ↓
Speech-to-Text (Device Native)
        ↓
Local Intent Classifier (TF-IDF + Logistic Regression / SVM)
        ↓
Confidence Calibration (Probability Thresholding)
        ↓
Adaptive Multimodal Router
  ├── HIGH (≥0.70)   ──> Direct Execution (Vision / OCR / Memory / Hazard / Tasks)
  ├── MEDIUM (≥0.45) ──> Execution + Verification Notice
  └── LOW (<0.45)    ──> Active Perception / Clarification Prompt
        ↓
Specialized AI Processing Engine
        ↓
Response Formatter & Spatial Reasoner
        ↓
Text-to-Speech (Native Android) + Haptic Feedback
```

---

## Key Components

### 1. `LocalIntentClassifier` (`lib/ml/intent_classifier/`)
- Runs 100% locally on-device in Dart.
- Loads pre-trained model weights exported from scikit-learn (`assets/models/intent_model_weights.json`).
- Calculates n-grams (1, 2), applies L2-normalized TF-IDF vectorization, computes matrix product with trained coefficients, and applies Softmax activation.
- Predicts one of 16 supported intent classes with probability.

### 2. `ConfidenceAwareRouter` (`lib/ml/intent_classifier/`)
- Categorizes intent probability into `HIGH`, `MEDIUM`, or `LOW`.
- Handles low-confidence intent ambiguity by triggering active perception / user clarification without making false assumptions.

### 3. `SpatialReasoner` (`lib/core/utilities/`)
- Maps 2D normalized bounding box coordinates $[ymin, xmin, ymax, xmax]$ into 9 spatial sectors: `upper-left`, `upper-center`, `upper-right`, `center-left`, `center`, `center-right`, `lower-left`, `lower-center`, `lower-right`.
- Generates precise, non-hallucinated spatial descriptions for visually impaired users.

### 4. `AppDatabase` (`lib/data/database/`)
- SQLite storage for visual personal object memories, expiry dates, and snapshot observations for temporal change detection.
