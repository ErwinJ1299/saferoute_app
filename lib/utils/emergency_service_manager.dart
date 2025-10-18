import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/emergency_service.dart';

class EmergencyServiceManager {
  static final EmergencyServiceManager _instance = EmergencyServiceManager._internal();
  factory EmergencyServiceManager() => _instance;
  EmergencyServiceManager._internal();

  List<EmergencyService> _allServices = [];
  bool _isLoaded = false;

  /// Load emergency services from JSON asset
  Future<void> loadServices() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/emergency_services.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      _allServices = jsonData.map((json) => EmergencyService(
        id: json['id'],
        name: json['name'],
        type: _parseServiceType(json['type']),
        location: LatLng(json['latitude'], json['longitude']),
        address: json['address'],
        phoneNumber: json['phoneNumber'],
        isOpen24Hours: json['isOpen24Hours'],
      )).toList();

      _isLoaded = true;
    } catch (e) {
      print('Error loading emergency services: $e');
    }
  }

  /// Parse service type from string
  EmergencyServiceType _parseServiceType(String type) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return EmergencyServiceType.hospital;
      case 'police':
        return EmergencyServiceType.police;
      case 'firestation':
        return EmergencyServiceType.fireStation;
      case 'pharmacy':
        return EmergencyServiceType.pharmacy;
      default:
        return EmergencyServiceType.hospital;
    }
  }

  /// Get all services
  List<EmergencyService> getAllServices() {
    return List.from(_allServices);
  }

  /// Get services by type
  List<EmergencyService> getServicesByType(EmergencyServiceType type) {
    return _allServices.where((service) => service.type == type).toList();
  }

  /// Get nearest services to a location
  List<EmergencyService> getNearestServices({
    required LatLng userLocation,
    EmergencyServiceType? type,
    int limit = 5,
    double maxDistanceKm = 10.0,
  }) {
    List<EmergencyService> services = type != null 
        ? getServicesByType(type) 
        : getAllServices();

    // Calculate distances
    for (var service in services) {
      service.calculateDistance(userLocation);
    }

    // Filter by max distance and sort
    services = services
        .where((s) => s.distance != null && s.distance! <= maxDistanceKm)
        .toList()
      ..sort((a, b) => a.distance!.compareTo(b.distance!));

    return services.take(limit).toList();
  }

  /// Get the single nearest service of a type
  EmergencyService? getNearestService({
    required LatLng userLocation,
    required EmergencyServiceType type,
  }) {
    final services = getNearestServices(
      userLocation: userLocation,
      type: type,
      limit: 1,
    );
    return services.isEmpty ? null : services.first;
  }
}
