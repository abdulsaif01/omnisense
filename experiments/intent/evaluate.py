import json
import os
import joblib
import time
import numpy as np
from sklearn.metrics import classification_report, accuracy_score, precision_recall_fscore_support, confusion_matrix
from train_baseline import KeywordBaselineClassifier

def run_evaluation():
    data_dir = os.path.join("experiments", "datasets")
    model_dir = os.path.join("experiments", "models")
    
    with open(os.path.join(data_dir, "intent_test.json"), "r", encoding="utf-8") as f:
        test_data = json.load(f)

    X_test = [d["text"] for d in test_data]
    y_test = [d["intent"] for d in test_data]

    # Baseline
    baseline = KeywordBaselineClassifier()
    t0 = time.time()
    baseline_preds = [baseline.predict(t)[0] for t in X_test]
    baseline_lat = (time.time() - t0) / len(X_test) * 1000.0

    # Model A: LogReg
    logreg_clf = joblib.load(os.path.join(model_dir, "logreg_model.pkl"))
    vectorizer = joblib.load(os.path.join(model_dir, "tfidf_vectorizer.pkl"))
    
    t0 = time.time()
    X_test_tfidf = vectorizer.transform(X_test)
    logreg_preds = logreg_clf.predict(X_test_tfidf)
    logreg_lat = (time.time() - t0) / len(X_test) * 1000.0

    # Model B: SVM
    svm_clf = joblib.load(os.path.join(model_dir, "svm_model.pkl"))
    t0 = time.time()
    svm_preds = svm_clf.predict(X_test_tfidf)
    svm_lat = (time.time() - t0) / len(X_test) * 1000.0

    models = [
        ("Baseline (Rule-Based)", baseline_preds, baseline_lat),
        ("Model A (TF-IDF + LogReg)", logreg_preds, logreg_lat),
        ("Model B (TF-IDF + SVM)", svm_preds, svm_lat)
    ]

    results = {}
    print("\n=============================================================")
    print("      RESEARCH EVALUATION RESULTS — INTENT CLASSIFICATION    ")
    print("=============================================================\n")

    all_intents = sorted(list(set(y_test)))

    for name, preds, lat in models:
        acc = accuracy_score(y_test, preds)
        p, r, f1, _ = precision_recall_fscore_support(y_test, preds, average="macro", zero_division=0)
        wp, wr, wf1, _ = precision_recall_fscore_support(y_test, preds, average="weighted", zero_division=0)
        cm = confusion_matrix(y_test, preds, labels=all_intents).tolist()

        results[name] = {
            "accuracy": round(acc, 4),
            "macro_precision": round(p, 4),
            "macro_recall": round(r, 4),
            "macro_f1": round(f1, 4),
            "weighted_f1": round(wf1, 4),
            "avg_latency_ms": round(lat, 3),
            "confusion_matrix": cm,
            "labels": all_intents
        }

        print(f"--- {name} ---")
        print(f"  Accuracy:       {acc:.4f}")
        print(f"  Macro Precision:{p:.4f}")
        print(f"  Macro Recall:   {r:.4f}")
        print(f"  Macro F1-Score: {f1:.4f}")
        print(f"  Weighted F1:    {wf1:.4f}")
        print(f"  Inference Lat:  {lat:.3f} ms/query\n")

    res_path = os.path.join("experiments", "results")
    os.makedirs(res_path, exist_ok=True)
    with open(os.path.join(res_path, "intent_evaluation_results.json"), "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print(f"Evaluation report written to {res_path}/intent_evaluation_results.json")

if __name__ == "__main__":
    run_evaluation()
