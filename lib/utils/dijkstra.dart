import 'package:latlong2/latlong.dart';
import '../models/hazard.dart';

class Edge {
  final String destination;
  final double weight;

  Edge(this.destination, this.weight);
}

class Graph {
  final Map<String, Map<String, double>> adjacencyList;
  final Map<String, LatLng> nodeLocations; // Node ID to coordinates mapping

  Graph(this.adjacencyList, {Map<String, LatLng>? nodeLocations})
      : nodeLocations = nodeLocations ?? {};

  // Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  // Check if a road segment is affected by hazards
  double _getHazardWeight(String node1, String node2, List<Hazard> hazards) {
    if (!nodeLocations.containsKey(node1) || !nodeLocations.containsKey(node2)) {
      return 1.0; // No hazard penalty if location data missing
    }

    final point1 = nodeLocations[node1]!;
    final point2 = nodeLocations[node2]!;
    double hazardMultiplier = 1.0;

    for (final hazard in hazards) {
      // Check if hazard is near the road segment
      final distanceToStart = _calculateDistance(hazard.location, point1);
      final distanceToEnd = _calculateDistance(hazard.location, point2);
      
      // If hazard is within 100 meters of either endpoint, apply penalty
      const double proximityThreshold = 100.0;
      if (distanceToStart < proximityThreshold || distanceToEnd < proximityThreshold) {
        hazardMultiplier *= hazard.getRoutingWeight();
      }
    }

    return hazardMultiplier;
  }

  List<String> dijkstra(String start, String goal, {List<Hazard>? hazards, bool avoidHazards = true}) {
    final activeHazards = hazards ?? [];
    final shouldAvoidHazards = avoidHazards && activeHazards.isNotEmpty;
    final distances = <String, double>{};
    final previous = <String, String?>{};
    final unvisited = <String>{};

    // Initialize
    for (final node in adjacencyList.keys) {
      distances[node] = double.infinity;
      previous[node] = null;
      unvisited.add(node);
    }
    distances[start] = 0;

    while (unvisited.isNotEmpty) {
      // Pick node with smallest tentative distance
      final current = unvisited.reduce((a, b) =>
          (distances[a] ?? double.infinity) < (distances[b] ?? double.infinity)
              ? a
              : b);

      if (current == goal) break;
      unvisited.remove(current);

      final neighbors = adjacencyList[current];
      if (neighbors == null) continue;

      for (final entry in neighbors.entries) {
        final neighbor = entry.key;
        var weight = entry.value;
        
        // Apply hazard penalty if hazard avoidance is enabled
        if (shouldAvoidHazards) {
          final hazardMultiplier = _getHazardWeight(current, neighbor, activeHazards);
          weight *= hazardMultiplier;
        }
        
        final alt = (distances[current] ?? double.infinity) + weight;
        if (alt < (distances[neighbor] ?? double.infinity)) {
          distances[neighbor] = alt;
          previous[neighbor] = current;
        }
      }
    }

    // Reconstruct path
    final path = <String>[];
    String? currentNode = goal;
    
    if (!distances.containsKey(goal) || distances[goal] == double.infinity) {
      return []; // No path found
    }
    
    while (currentNode != null) {
      path.insert(0, currentNode);
      if (currentNode == start) break;
      currentNode = previous[currentNode];
    }

    return path;
  }
}
