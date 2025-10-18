import 'package:latlong2/latlong.dart';

class RoadGraph {
  static final nodes = {
    'A': LatLng(18.5089, 73.8077), // Karvenagar Chowk
    'B': LatLng(18.5095, 73.8140), // Cummins College
    'C': LatLng(18.5075, 73.8182), // Karve Road Junction
    'D': LatLng(18.5048, 73.8125), // Alankar Police Chowky
    'E': LatLng(18.5020, 73.8085), // Vitthal Mandir
  };

  static final edges = {
    'A': {'B': 0.5, 'D': 0.6, 'E': 0.8},
    'B': {'A': 0.5, 'C': 0.7},
    'C': {'B': 0.7, 'D': 0.5},
    'D': {'A': 0.6, 'C': 0.5, 'E': 0.4},
    'E': {'A': 0.8, 'D': 0.4},
  };
}
