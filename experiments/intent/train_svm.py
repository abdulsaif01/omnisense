import json
import os
import joblib
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.calibration import CalibratedClassifierCV
from sklearn.metrics import accuracy_score, f1_score

def train_svm():
    data_dir = os.path.join("experiments", "datasets")
    with open(os.path.join(data_dir, "intent_train.json"), "r", encoding="utf-8") as f:
        train_data = json.load(f)
    with open(os.path.join(data_dir, "intent_val.json"), "r", encoding="utf-8") as f:
        val_data = json.load(f)
    with open(os.path.join(data_dir, "intent_test.json"), "r", encoding="utf-8") as f:
        test_data = json.load(f)

    X_train = [d["text"] for d in train_data]
    y_train = [d["intent"] for d in train_data]
    X_val = [d["text"] for d in val_data]
    y_val = [d["intent"] for d in val_data]
    X_test = [d["text"] for d in test_data]
    y_test = [d["intent"] for d in test_data]

    vectorizer = TfidfVectorizer(ngram_range=(1, 2), min_df=1, lowercase=True)
    X_train_tfidf = vectorizer.fit_transform(X_train)
    X_val_tfidf = vectorizer.transform(X_val)
    X_test_tfidf = vectorizer.transform(X_test)

    base_svm = LinearSVC(C=1.0, random_state=42)
    clf = CalibratedClassifierCV(estimator=base_svm, cv=3)
    clf.fit(X_train_tfidf, y_train)

    val_preds = clf.predict(X_val_tfidf)
    test_preds = clf.predict(X_test_tfidf)

    print("=== MODEL B: TF-IDF + LINEAR SVM ===")
    print("Validation Accuracy:", accuracy_score(y_val, val_preds))
    print("Test Accuracy:", accuracy_score(y_test, test_preds))
    print("Test Macro F1:", f1_score(y_test, test_preds, average="macro"))

    out_model_dir = os.path.join("experiments", "models")
    os.makedirs(out_model_dir, exist_ok=True)
    joblib.dump(clf, os.path.join(out_model_dir, "svm_model.pkl"))

if __name__ == "__main__":
    train_svm()
