class BoundingBox {
  final double ymin;
  final double xmin;
  final double ymax;
  final double xmax;

  const BoundingBox({
    required this.ymin,
    required this.xmin,
    required this.ymax,
    required this.xmax,
  });

  double get centerX => (xmin + xmax) / 2.0;
  double get centerY => (ymin + ymax) / 2.0;
  double get width => xmax - xmin;
  double get height => ymax - ymin;
  double get area => width * height;
}

class SpatialReasoner {
  /// Converts normalized bounding box [0.0 - 1.0] to spatial sector
  static String calculateSpatialRegion(BoundingBox bbox) {
    final cx = bbox.centerX;
    final cy = bbox.centerY;

    String vertical;
    if (cy < 0.35) {
      vertical = 'upper';
    } else if (cy > 0.65) {
      vertical = 'lower';
    } else {
      vertical = 'center';
    }

    String horizontal;
    if (cx < 0.35) {
      horizontal = 'left';
    } else if (cx > 0.65) {
      horizontal = 'right';
    } else {
      horizontal = 'center';
    }

    if (vertical == 'center' && horizontal == 'center') {
      return 'center';
    }
    if (vertical == 'center') {
      return 'center-$horizontal';
    }
    if (horizontal == 'center') {
      return '$vertical-center';
    }

    return '$vertical-$horizontal';
  }

  /// Expresses object location relative to user
  static String formatSpatialDescription(String label, BoundingBox bbox) {
    final region = calculateSpatialRegion(bbox);
    switch (region) {
      case 'center':
        return '$label directly in front of you';
      case 'center-left':
        return '$label to your left';
      case 'center-right':
        return '$label to your right';
      case 'upper-left':
        return '$label on your upper-left';
      case 'upper-center':
        return '$label above center';
      case 'upper-right':
        return '$label on your upper-right';
      case 'lower-left':
        return '$label on the lower-left floor';
      case 'lower-center':
        return '$label on the floor directly ahead';
      case 'lower-right':
        return '$label on the lower-right floor';
      default:
        return '$label near $region';
    }
  }
}
