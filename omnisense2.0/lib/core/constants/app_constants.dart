class AppConstants {
  static const String appName = 'OmniSense';
  static const String appVersion = '2.0.0-local';

  // 16 Intent Classes
  static const List<String> intentClasses = [
    'SCENE_DESCRIPTION',
    'OBJECT_IDENTIFICATION',
    'DOCUMENT_READING',
    'MEDICINE_READING',
    'FOOD_LABEL_READING',
    'BILL_READING',
    'MEMORY_STORE',
    'MEMORY_RETRIEVE',
    'EXPIRY_QUERY',
    'HAZARD_QUERY',
    'CHANGE_DETECTION',
    'TASK_ASSISTANCE',
    'ROUTINE_QUERY',
    'GENERAL_QUERY',
    'PRIVACY_REQUEST',
    'APP_CONTROL',
  ];

  // Confidence Thresholds
  static const double highConfidenceThreshold = 0.70;
  static const double mediumConfidenceThreshold = 0.45;

  // Spatial Regions
  static const List<String> spatialRegions = [
    'upper-left',
    'upper-center',
    'upper-right',
    'center-left',
    'center',
    'center-right',
    'lower-left',
    'lower-center',
    'lower-right',
  ];
}
