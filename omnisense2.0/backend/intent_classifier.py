import json
import os
import math
import re

# Load trained intent model weights from experiments directory or local path
MODEL_WEIGHTS_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "experiments", "models", "intent_model_weights.json")

class LocalMLIntentClassifier:
    def __init__(self):
        self.is_loaded = False
        if os.path.exists(MODEL_WEIGHTS_PATH):
            try:
                with open(MODEL_WEIGHTS_PATH, "r", encoding="utf-8") as f:
                    data = json.load(f)
                self.vocab = data["vocabulary"]
                self.idf = data["idf"]
                self.classes = data["classes"]
                self.coefs = data["coefficients"]
                self.intercepts = data["intercepts"]
                self.is_loaded = True
            except Exception as e:
                print(f"Warning: Could not load intent_model_weights.json ({e}). Falling back to rule-based.")

    def tokenize_ngrams(self, text):
        clean = re.sub(r"[^\w\s]", "", text.lower()).strip()
        words = clean.split()
        ngrams = list(words)
        for i in range(len(words) - 1):
            ngrams.append(f"{words[i]} {words[i+1]}")
        return ngrams

    def predict(self, text):
        if not self.is_loaded:
            return self._rule_based_fallback(text)

        ngrams = self.tokenize_ngrams(text)
        tfidf_vec = [0.0] * len(self.vocab)
        
        # Calculate TF-IDF
        counts = {}
        for ng in ngrams:
            if ng in self.vocab:
                counts[ng] = counts.get(ng, 0) + 1
        
        for ng, count in counts.items():
            idx = self.vocab[ng]
            tf = 1.0 + math.log(count) if count > 0 else 0.0
            tfidf_vec[idx] = tf * self.idf[idx]

        # Normalize L2
        norm = math.sqrt(sum(v*v for v in tfidf_vec))
        if norm > 0:
            tfidf_vec = [v / norm for v in tfidf_vec]

        # Compute logit per class
        logits = []
        for i in range(len(self.classes)):
            logit = self.intercepts[i] + sum(tfidf_vec[j] * self.coefs[i][j] for j in range(len(tfidf_vec)))
            logits.append(logit)

        # Softmax
        max_l = max(logits)
        exps = [math.exp(l - max_l) for l in logits]
        sum_exp = sum(exps)
        probs = [e / sum_exp for e in exps]

        max_idx = max(range(len(probs)), key=lambda k: probs[k])
        predicted_intent = self.classes[max_idx]
        confidence_prob = probs[max_idx]

        return predicted_intent, confidence_prob

    def _rule_based_fallback(self, text):
        lower = text.lower()
        if "where" in lower or "locate" in lower or "find my" in lower:
            return "MEMORY_RETRIEVE", 0.75
        if "remember" in lower or "store" in lower:
            return "MEMORY_STORE", 0.80
        if "read" in lower or "text" in lower:
            return "DOCUMENT_READING", 0.70
        if "expire" in lower or "expiration" in lower:
            return "EXPIRY_QUERY", 0.85
        if "hazard" in lower or "obstacle" in lower or "floor" in lower:
            return "HAZARD_QUERY", 0.75
        if "changed" in lower or "moved" in lower:
            return "CHANGE_DETECTION", 0.80
        return "SCENE_DESCRIPTION", 0.60

classifier_instance = LocalMLIntentClassifier()

def classify_and_process_query(query: str):
    intent, prob = classifier_instance.predict(query)
    
    # Confidence Calibration & Adaptive Routing logic
    if prob >= 0.70:
        confidence_level = "HIGH"
    elif prob >= 0.45:
        confidence_level = "MEDIUM"
    else:
        confidence_level = "LOW"

    # Handle LOW confidence via Active Perception / Clarification
    if confidence_level == "LOW":
        return {
            "handled": True,
            "intent": intent,
            "probability": round(prob, 4),
            "confidence_level": "LOW",
            "requires_clarification": True,
            "answer": "I am not completely certain about your request. Would you like me to inspect objects in the room or read text from a document?",
            "suggested_actions": ["Inspect Objects", "Read Document Text"]
        }

    return {
        "handled": False,
        "intent": intent,
        "probability": round(prob, 4),
        "confidence_level": confidence_level,
        "requires_clarification": False,
        "answer": ""
    }
