import json
import random
import os
from sklearn.model_selection import train_test_split

RANDOM_SEED = 42

def prepare_splits():
    dataset_path = os.path.join("experiments", "datasets", "intent_dataset.json")
    with open(dataset_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    texts = [item["text"] for item in data]
    labels = [item["intent"] for item in data]

    # Stratified split: 70% train, 30% temp (val + test)
    train_texts, temp_texts, train_labels, temp_labels = train_test_split(
        texts, labels, test_size=0.30, random_state=RANDOM_SEED, stratify=labels
    )

    # Split temp into 50% val, 50% test (which equals 15% val, 15% test of total)
    val_texts, test_texts, val_labels, test_labels = train_test_split(
        temp_texts, temp_labels, test_size=0.50, random_state=RANDOM_SEED, stratify=temp_labels
    )

    splits = {
        "train": [{"text": t, "intent": l} for t, l in zip(train_texts, train_labels)],
        "val": [{"text": t, "intent": l} for t, l in zip(val_texts, val_labels)],
        "test": [{"text": t, "intent": l} for t, l in zip(test_texts, test_labels)]
    }

    out_dir = os.path.join("experiments", "datasets")
    for name, items in splits.items():
        with open(os.path.join(out_dir, f"intent_{name}.json"), "w", encoding="utf-8") as f:
            json.dump(items, f, indent=2)

    print(f"Dataset Split Completed successfully (Seed={RANDOM_SEED}):")
    print(f"  Train: {len(train_texts)} samples")
    print(f"  Validation: {len(val_texts)} samples")
    print(f"  Test: {len(test_texts)} samples")

if __name__ == "__main__":
    prepare_splits()
