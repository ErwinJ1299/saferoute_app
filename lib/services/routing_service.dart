import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  // OSRM Demo server (free, public) - for production, use your own server
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  /// Get real road-based route between two points using OSRM
  /// Returns list of LatLng points that follow actual roads
  static Future<List<LatLng>> getRoute(
    LatLng start,
    LatLng end, {
    bool avoidHighways = false,
  }) async {
    try {
      // OSRM route API format: /route/v1/{profile}/{coordinates}
      // Profile: driving (car), walking, cycling
      final String coordinates =
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

      final String url =
          '$_osrmBaseUrl/route/v1/driving/$coordinates?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convert coordinates to LatLng list
          return coordinates.map((coord) {
            return LatLng(
              coord[1].toDouble(), // latitude
              coord[0].toDouble(), // longitude
            );
          }).toList();
        }
      }

      throw Exception('Failed to get route: ${response.statusCode}');
    } catch (e) {
      throw Exception('Routing error: $e');
    }
  }

  /// Get route with detailed information (distance, duration, steps)
  static Future<Map<String, dynamic>> getDetailedRoute(
    LatLng start,
    LatLng end,
  ) async {
    try {
      final String coordinates =
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

      final String url =
          '$_osrmBaseUrl/route/v1/driving/$coordinates?overview=full&geometries=geojson&steps=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convert coordinates to LatLng list
          final List<LatLng> routePoints = coordinates.map((coord) {
            return LatLng(
              coord[1].toDouble(),
              coord[0].toDouble(),
            );
          }).toList();

          // Extract distance and duration
          final double distance =
              (route['distance'] as num).toDouble() / 1000; // meters to km
          final double duration =
              (route['duration'] as num).toDouble() / 60; // seconds to minutes

          return {
            'points': routePoints,
            'distance': distance,
            'duration': duration,
            'steps': route['legs'][0]['steps'] ?? [],
          };
        }
      }

      throw Exception('Failed to get route');
    } catch (e) {
      throw Exception('Routing error: $e');
    }
  }

  /// Calculate distance between two points (in kilometers)
  static double calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, start, end);
  }

  /// Get multiple route alternatives (if available)
  static Future<List<Map<String, dynamic>>> getAlternativeRoutes(
    LatLng start,
    LatLng end,
  ) async {
    try {
      final String coordinates =
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

      final String url =
          '$_osrmBaseUrl/route/v1/driving/$coordinates?overview=full&geometries=geojson&alternatives=3';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null) {
          List<Map<String, dynamic>> routes = [];

          for (var route in data['routes']) {
            final geometry = route['geometry'];
            final coordinates = geometry['coordinates'] as List;

            final List<LatLng> routePoints = coordinates.map((coord) {
              return LatLng(
                coord[1].toDouble(),
                coord[0].toDouble(),
              );
            }).toList();

            routes.add({
              'points': routePoints,
              'distance': (route['distance'] as num).toDouble() / 1000,
              'duration': (route['duration'] as num).toDouble() / 60,
            });
          }

          return routes;
        }
      }

      throw Exception('Failed to get alternative routes');
    } catch (e) {
      throw Exception('Routing error: $e');
    }
  }
}
