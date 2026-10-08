import json
import os
import joblib
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, f1_score, accuracy_score

def train_logreg():
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

    # TF-IDF Vectorizer
    vectorizer = TfidfVectorizer(ngram_range=(1, 2), min_df=1, lowercase=True)
    X_train_tfidf = vectorizer.fit_transform(X_train)
    X_val_tfidf = vectorizer.transform(X_val)
    X_test_tfidf = vectorizer.transform(X_test)

    clf = LogisticRegression(C=10.0, max_iter=1000, random_state=42)
    clf.fit(X_train_tfidf, y_train)

    val_preds = clf.predict(X_val_tfidf)
    val_probs = clf.predict_proba(X_val_tfidf)

    test_preds = clf.predict(X_test_tfidf)
    test_probs = np.max(clf.predict_proba(X_test_tfidf), axis=1)

    print("=== MODEL A: TF-IDF + LOGISTIC REGRESSION ===")
    print("Validation Accuracy:", accuracy_score(y_val, val_preds))
    print("Test Accuracy:", accuracy_score(y_test, test_preds))
    print("Test Macro F1:", f1_score(y_test, test_preds, average="macro"))

    # Save model artifacts
    out_model_dir = os.path.join("experiments", "models")
    os.makedirs(out_model_dir, exist_ok=True)
    joblib.dump(clf, os.path.join(out_model_dir, "logreg_model.pkl"))
    joblib.dump(vectorizer, os.path.join(out_model_dir, "tfidf_vectorizer.pkl"))

    # Export json model for Flutter Dart offline local execution!
    vocab = vectorizer.vocabulary_
    idf = vectorizer.idf_.tolist()
    classes = list(clf.classes_)
    coefs = clf.coef_.tolist()
    intercepts = clf.intercept_.tolist()

    export_payload = {
        "vocabulary": vocab,
        "idf": idf,
        "classes": classes,
        "coefficients": coefs,
        "intercepts": intercepts,
        "ngram_range": [1, 2]
    }

    with open(os.path.join(out_model_dir, "intent_model_weights.json"), "w", encoding="utf-8") as f:
        json.dump(export_payload, f, indent=2)

    print(f"Exported JSON model weights for Dart & Python local inference to {out_model_dir}/intent_model_weights.json")

if __name__ == "__main__":
    train_logreg()
