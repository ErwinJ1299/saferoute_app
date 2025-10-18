import 'package:latlong2/latlong.dart';

enum HazardType {
  accident,
  roadblock,
  pothole,
  flooding,
  construction,
  other,
}

enum HazardSeverity {
  low,
  medium,
  high,
  critical,
}

class Hazard {
  final String id;
  final HazardType type;
  final LatLng location;
  final HazardSeverity severity;
  final String description;
  final DateTime timestamp;
  final DateTime expiryTime;
  final int upvotes;
  final int downvotes;

  Hazard({
    required this.id,
    required this.type,
    required this.location,
    required this.severity,
    required this.description,
    required this.timestamp,
    required this.expiryTime,
    this.upvotes = 0,
    this.downvotes = 0,
  });

  // Check if hazard is still valid
  bool isValid() {
    return DateTime.now().isBefore(expiryTime);
  }

  // Calculate hazard weight for routing (higher = more dangerous)
  double getRoutingWeight() {
    switch (severity) {
      case HazardSeverity.low:
        return 1.5;
      case HazardSeverity.medium:
        return 3.0;
      case HazardSeverity.high:
        return 5.0;
      case HazardSeverity.critical:
        return 100.0; // Effectively blocks the route
    }
  }

  // Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'severity': severity.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'expiryTime': expiryTime.toIso8601String(),
      'upvotes': upvotes,
      'downvotes': downvotes,
    };
  }

  // Create from JSON
  factory Hazard.fromJson(Map<String, dynamic> json) {
    return Hazard(
      id: json['id'],
      type: HazardType.values.firstWhere((e) => e.name == json['type']),
      location: LatLng(json['latitude'], json['longitude']),
      severity: HazardSeverity.values.firstWhere((e) => e.name == json['severity']),
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      expiryTime: DateTime.parse(json['expiryTime']),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
    );
  }

  // Copy with method for updates
  Hazard copyWith({
    String? id,
    HazardType? type,
    LatLng? location,
    HazardSeverity? severity,
    String? description,
    DateTime? timestamp,
    DateTime? expiryTime,
    int? upvotes,
    int? downvotes,
  }) {
    return Hazard(
      id: id ?? this.id,
      type: type ?? this.type,
      location: location ?? this.location,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      expiryTime: expiryTime ?? this.expiryTime,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
    );
  }
}

// Helper extension for hazard type display
extension HazardTypeExtension on HazardType {
  String get displayName {
    switch (this) {
      case HazardType.accident:
        return 'Accident';
      case HazardType.roadblock:
        return 'Road Block';
      case HazardType.pothole:
        return 'Pothole';
      case HazardType.flooding:
        return 'Flooding';
      case HazardType.construction:
        return 'Construction';
      case HazardType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case HazardType.accident:
        return '🚗';
      case HazardType.roadblock:
        return '🚧';
      case HazardType.pothole:
        return '🕳️';
      case HazardType.flooding:
        return '🌊';
      case HazardType.construction:
        return '🏗️';
      case HazardType.other:
        return '⚠️';
    }
  }
}

// Helper extension for severity display
extension HazardSeverityExtension on HazardSeverity {
  String get displayName {
    switch (this) {
      case HazardSeverity.low:
        return 'Low';
      case HazardSeverity.medium:
        return 'Medium';
      case HazardSeverity.high:
        return 'High';
      case HazardSeverity.critical:
        return 'Critical';
    }
  }

  // Color for UI display
  String get colorHex {
    switch (this) {
      case HazardSeverity.low:
        return '#FFA726'; // Orange
      case HazardSeverity.medium:
        return '#FF6F00'; // Dark Orange
      case HazardSeverity.high:
        return '#EF5350'; // Red
      case HazardSeverity.critical:
        return '#C62828'; // Dark Red
    }
  }
}
