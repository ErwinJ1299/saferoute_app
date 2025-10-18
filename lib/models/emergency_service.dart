import 'package:latlong2/latlong.dart';

enum EmergencyServiceType {
  hospital,
  police,
  fireStation,
  pharmacy,
}

class EmergencyService {
  final String id;
  final String name;
  final EmergencyServiceType type;
  final LatLng location;
  final String address;
  final String phoneNumber;
  double? distance; // in kilometers, nullable and mutable
  final bool isOpen24Hours;

  EmergencyService({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.address,
    required this.phoneNumber,
    this.distance,
    this.isOpen24Hours = false,
  });

  /// Calculate distance from user location
  void calculateDistance(LatLng userLocation) {
    const distance = Distance();
    this.distance = distance.as(LengthUnit.Kilometer, userLocation, location);
  }

  // Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'address': address,
      'phoneNumber': phoneNumber,
      'distance': distance,
      'isOpen24Hours': isOpen24Hours ? 1 : 0,
    };
  }

  // Create from JSON
  factory EmergencyService.fromJson(Map<String, dynamic> json) {
    return EmergencyService(
      id: json['id'],
      name: json['name'],
      type: EmergencyServiceType.values.firstWhere((e) => e.name == json['type']),
      location: LatLng(json['latitude'], json['longitude']),
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      distance: json['distance'],
      isOpen24Hours: (json['isOpen24Hours'] ?? 0) == 1,
    );
  }

  // Format distance for display
  String get formattedDistance {
    if (distance == null) return 'Unknown';
    if (distance! < 1) {
      return '${(distance! * 1000).toInt()} m';
    } else {
      return '${distance!.toStringAsFixed(1)} km';
    }
  }
}

// Extension for emergency service type display
extension EmergencyServiceTypeExtension on EmergencyServiceType {
  String get displayName {
    switch (this) {
      case EmergencyServiceType.hospital:
        return 'Hospital';
      case EmergencyServiceType.police:
        return 'Police Station';
      case EmergencyServiceType.fireStation:
        return 'Fire Station';
      case EmergencyServiceType.pharmacy:
        return 'Pharmacy';
    }
  }

  String get icon {
    switch (this) {
      case EmergencyServiceType.hospital:
        return '🏥';
      case EmergencyServiceType.police:
        return '👮';
      case EmergencyServiceType.fireStation:
        return '🚒';
      case EmergencyServiceType.pharmacy:
        return '💊';
    }
  }

  String get emergencyNumber {
    switch (this) {
      case EmergencyServiceType.hospital:
        return '102'; // Ambulance (India)
      case EmergencyServiceType.police:
        return '100'; // Police (India)
      case EmergencyServiceType.fireStation:
        return '101'; // Fire (India)
      case EmergencyServiceType.pharmacy:
        return '108'; // Emergency Medical Services
    }
  }

  // Color for UI display
  String get colorHex {
    switch (this) {
      case EmergencyServiceType.hospital:
        return '#EF5350'; // Red
      case EmergencyServiceType.police:
        return '#1976D2'; // Blue
      case EmergencyServiceType.fireStation:
        return '#FF6F00'; // Orange
      case EmergencyServiceType.pharmacy:
        return '#43A047'; // Green
    }
  }
}
