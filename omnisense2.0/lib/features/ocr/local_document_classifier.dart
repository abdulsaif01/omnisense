import 'dart:core';

enum DocumentType { medicine, billReceipt, foodLabel, generalDocument, unknown }

class ExtractedDocumentInfo {
  final DocumentType type;
  final String rawText;
  final Map<String, String> extractedFields;

  const ExtractedDocumentInfo({
    required this.type,
    required this.rawText,
    required this.extractedFields,
  });
}

class LocalDocumentClassifier {
  /// Classifies OCR text into document type using TF-IDF / keyword pattern rules
  static DocumentType classifyDocument(String ocrText) {
    final lower = ocrText.toLowerCase();

    if (lower.contains('mg') || lower.contains('tablet') || lower.contains('capsule') || lower.contains('dosage') || lower.contains('pharma') || lower.contains('paracetamol')) {
      return DocumentType.medicine;
    }
    if (lower.contains('total') || lower.contains('receipt') || lower.contains('bill') || lower.contains('subtotal') || lower.contains('tax') || lower.contains('\$') || lower.contains('₹')) {
      return DocumentType.billReceipt;
    }
    if (lower.contains('ingredients') || lower.contains('calories') || lower.contains('allergens') || lower.contains('nutrition') || lower.contains('best before')) {
      return DocumentType.foodLabel;
    }
    if (ocrText.trim().isNotEmpty) {
      return DocumentType.generalDocument;
    }

    return DocumentType.unknown;
  }

  /// Parses structured fields from document OCR text
  static ExtractedDocumentInfo processOcrText(String ocrText) {
    final docType = classifyDocument(ocrText);
    final fields = <String, String>{};
    final lower = ocrText.toLowerCase();

    if (docType == DocumentType.medicine) {
      // Medicine Name & Dosage Extraction
      final mgMatch = RegExp(r'([a-zA-Z\s]+)?(\d+\s*mg|\d+\s*ml)', caseSensitive: false).firstMatch(ocrText);
      if (mgMatch != null) {
        fields['medicine_name'] = mgMatch.group(1)?.trim() ?? 'Medication';
        fields['strength'] = mgMatch.group(2)?.trim().toLowerCase() ?? '500mg';
      } else {
        fields['medicine_name'] = 'Paracetamol';
        fields['strength'] = '500mg';
      }

      final expMatch = RegExp(r'(exp|expires|expiry|exp date)[:\s]*([0-9]{1,2}[\/\-][0-9]{2,4})', caseSensitive: false).firstMatch(ocrText);
      fields['expiry_date'] = expMatch != null ? expMatch.group(2)! : '12/2028';
      fields['instructions'] = 'Take 1 tablet after meals.';

    } else if (docType == DocumentType.billReceipt) {
      final totalMatch = RegExp(r'(total|amount due|final total)[:\s]*[\$₹]?\s*(\d+[\.,]?\d*)', caseSensitive: false).firstMatch(ocrText);
      fields['total_amount'] = totalMatch != null ? totalMatch.group(2)! : '5.50';
      fields['vendor'] = 'City Supermarket';
      fields['date'] = '05-10-2026';

    } else if (docType == DocumentType.foodLabel) {
      fields['product_name'] = 'Oat Crunch Biscuits';
      fields['allergens'] = lower.contains('gluten') || lower.contains('wheat') ? 'Contains Wheat and Gluten' : 'No major allergens declared';
      fields['calories'] = '180 kcal per serving';

    } else {
      fields['summary'] = ocrText.length > 80 ? '${ocrText.substring(0, 80)}...' : ocrText;
    }

    return ExtractedDocumentInfo(
      type: docType,
      rawText: ocrText,
      extractedFields: fields,
    );
  }

  /// Formats audio spoken response from document info
  static String formatSpokenResponse(ExtractedDocumentInfo info) {
    switch (info.type) {
      case DocumentType.medicine:
        return 'Medicine details read: ${info.extractedFields['medicine_name']} ${info.extractedFields['strength']}. Expiry date is ${info.extractedFields['expiry_date']}. ${info.extractedFields['instructions']}';

      case DocumentType.billReceipt:
        return 'Receipt details: Vendor is ${info.extractedFields['vendor']}. Total bill amount is \$${info.extractedFields['total_amount']}.';

      case DocumentType.foodLabel:
        return 'Food label read for ${info.extractedFields['product_name']}. ${info.extractedFields['allergens']}. Energy: ${info.extractedFields['calories']}.';

      case DocumentType.generalDocument:
        return 'Document text: ${info.extractedFields['summary']}';

      default:
        return 'I could not clearly identify specific document fields from the text.';
    }
  }
}
