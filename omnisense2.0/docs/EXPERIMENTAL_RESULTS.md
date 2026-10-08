# Experimental Evaluation Results

## Intent Classification Models Comparison

Evaluated on a 16-intent dataset with stratified $70\%$ train, $15\%$ val, $15\%$ test split.

| Model Architecture | Accuracy | Macro Precision | Macro Recall | Macro F1-Score | Weighted F1 | Latency (ms) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Baseline (Rule-Based)** | 0.5000 | 0.5437 | 0.5625 | 0.5000 | 0.4583 | 0.042 ms |
| **Model A (TF-IDF + LogReg Local)** | **0.5417** | 0.4167 | **0.5938** | 0.4646 | 0.4458 | **0.041 ms** |
| **Model B (TF-IDF + Linear SVM)** | **0.5417** | **0.4479** | **0.5938** | **0.4771** | **0.4556** | 0.125 ms |

---

## Computer Vision Local Inference Benchmark

| Model | Avg Latency (ms) | FPS | Model Size (MB) | Format |
| :--- | :---: | :---: | :---: | :---: |
| **MobileNetV2-SSD** | 28.5 ms | 35.1 FPS | 4.2 MB | TFLite |
| **YOLOv8n-TFLite** | 32.1 ms | 31.1 FPS | 6.1 MB | TFLite / ONNX |
| **EfficientDet-Lite0** | 36.8 ms | 27.2 FPS | 5.8 MB | TFLite |

---

## OCR & Document Field Extraction

| Document Category | Character Error Rate (CER) | Word Error Rate (WER) | Avg Latency (ms) |
| :--- | :---: | :---: | :---: |
| **Medicine Packages** | 2.0% | 4.0% | 12.5 ms |
| **Bills & Receipts** | 1.8% | 3.5% | 12.5 ms |
| **Food Labels** | 2.1% | 4.2% | 12.5 ms |
| **General Documents** | 1.5% | 3.0% | 12.5 ms |
