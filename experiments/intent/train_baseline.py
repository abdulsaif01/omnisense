import json
import re

class KeywordBaselineClassifier:
    def __init__(self):
        self.rules = {
            "SCENE_DESCRIPTION": ["describe", "room", "surroundings", "overview", "what is in front", "summary"],
            "OBJECT_IDENTIFICATION": ["what is this", "identify", "holding", "object", "item", "pointing"],
            "DOCUMENT_READING": ["read paper", "read document", "read text", "page", "letter"],
            "MEDICINE_READING": ["medicine", "dosage", "pill", "tablet", "pharma", "prescription", "paracetamol"],
            "FOOD_LABEL_READING": ["ingredients", "calories", "food", "allergen", "snack", "milk carton"],
            "BILL_READING": ["receipt", "bill", "total amount", "vendor", "due date", "payment"],
            "MEMORY_STORE": ["remember", "save location", "store item", "keep a record"],
            "MEMORY_RETRIEVE": ["where is", "where did", "find my", "locate", "last seen"],
            "EXPIRY_QUERY": ["expire", "expiration", "best before", "past expiry"],
            "HAZARD_QUERY": ["hazard", "obstacle", "spill", "drawer", "safe to walk", "floor"],
            "CHANGE_DETECTION": ["changed", "moved", "disappeared", "difference", "table before"],
            "TASK_ASSISTANCE": ["step by step", "guide me", "task", "find my medicine"],
            "ROUTINE_QUERY": ["what can you do", "features", "how do i use"],
            "GENERAL_QUERY": ["hello", "thank you", "who created", "time"],
            "PRIVACY_REQUEST": ["delete", "clear", "erase", "disable memory retention"],
            "APP_CONTROL": ["stop", "repeat", "pause", "volume"]
        }

    def predict(self, text):
        lower = text.lower()
        for intent, keywords in self.rules.items():
            for kw in keywords:
                if kw in lower:
                    return intent, 0.70 # Default heuristic confidence
        return "GENERAL_QUERY", 0.30

if __name__ == "__main__":
    clf = KeywordBaselineClassifier()
    print("Keyword Baseline Classifier Initialized successfully.")
