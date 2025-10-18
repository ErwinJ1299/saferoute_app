import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/hazard.dart';
import '../utils/hazard_database.dart';
import '../services/routing_service.dart';
import '../models/emergency_service.dart';
import '../utils/emergency_service_manager.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  final _tileProvider = Platform.isWindows || Platform.isLinux || Platform.isMacOS
      ? NetworkTileProvider()
      : FMTCTileProvider(
          stores: const {'SafeRouteCache': BrowseStoreStrategy.readUpdateCreate},
        );
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  bool _isOffline = false;
  List<LatLng> _routePoints = [];
  bool _showDirections = false;
  String _routeDistance = '';
  String _routeDuration = '';
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _followUserLocation = true; // Auto-follow user location
  bool _useSafestRoute = true; // Toggle between safest and fastest route
  int _hazardsAvoided = 0; // Count of hazards avoided on safest route
  LatLng? _startLocation; // Geocoded start location
  LatLng? _endLocation; // Geocoded end location
  bool _isSearching = false; // Loading state for geocoding
  
  // Animation variables for smooth location transitions
  late AnimationController _animationController;
  Animation<double>? _latAnimation;
  Animation<double>? _lngAnimation;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Hazard management
  List<Hazard> _hazards = [];
  final _uuid = const Uuid();
  
  // Emergency services
  final _emergencyManager = EmergencyServiceManager();
  List<EmergencyService> _nearbyEmergencyServices = [];
  bool _showEmergencyServices = false;
  EmergencyServiceType? _selectedEmergencyType;
  bool _isEmergencyMenuExpanded = false; // For expandable FAB menu

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for smooth location transitions
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _animationController.addListener(() {
      if (_latAnimation != null && _lngAnimation != null) {
        setState(() {
          _currentPosition = LatLng(
            _latAnimation!.value,
            _lngAnimation!.value,
          );
        });
        
        // Auto-center map during animation if follow mode is enabled
        if (_followUserLocation && _currentPosition != null) {
          _mapController.move(_currentPosition!, _mapController.camera.zoom);
        }
      }
    });
    
    // Initialize pulse animation for the blue dot
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _checkConnectivity();
    _determinePosition();
    _loadHazards();
    _loadEmergencyServices();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _positionStreamSubscription?.cancel();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  // Smoothly animate location changes
  void _animateToNewPosition(LatLng newPosition) {
    if (_currentPosition == null) {
      // First position, no animation needed
      setState(() {
        _currentPosition = newPosition;
      });
      return;
    }

    // Create animations for latitude and longitude
    _latAnimation = Tween<double>(
      begin: _currentPosition!.latitude,
      end: newPosition.latitude,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _lngAnimation = Tween<double>(
      begin: _currentPosition!.longitude,
      end: newPosition.longitude,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0.0);
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied')),
      );
      return;
    }

    // Get initial position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    // Start continuous location tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // Update only after moving 20 meters (reduces GPS jitter)
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // Filter out low-accuracy readings (GPS jitter)
      if (position.accuracy > 50) {
        debugPrint('Skipping low accuracy reading: ${position.accuracy}m');
        return;
      }
      
      final newPosition = LatLng(position.latitude, position.longitude);
      
      // Animate to new position smoothly
      _animateToNewPosition(newPosition);
      
      // Optional: Show a small indicator when location updates
      debugPrint('Location updated: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
    });
  }

  // Function to find route using real geocoding
  Future<void> _findRoute() async {
    final startText = _startController.text.trim();
    final endText = _endController.text.trim();

    if (startText.isEmpty || endText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both start and end locations')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Geocode start location (or use current if selected)
      if (startText == 'Current Location' && _currentPosition != null) {
        _startLocation = _currentPosition;
      } else {
        List<Location> startLocations = await locationFromAddress(startText);
        if (startLocations.isEmpty) {
          throw Exception('Start location not found');
        }
        _startLocation = LatLng(startLocations.first.latitude, startLocations.first.longitude);
      }

      // Geocode end location
      List<Location> endLocations = await locationFromAddress(endText);
      if (endLocations.isEmpty) {
        throw Exception('Destination not found');
      }
      _endLocation = LatLng(endLocations.first.latitude, endLocations.first.longitude);

      // Get real road-based route from OSRM
      final routeData = await RoutingService.getDetailedRoute(_startLocation!, _endLocation!);
      
      List<LatLng> routePoints = routeData['points'] as List<LatLng>;
      
      // Apply hazard avoidance if safest route is enabled
      if (_useSafestRoute && _hazards.isNotEmpty) {
        routePoints = _applyHazardAvoidance(routePoints);
      }
      
      setState(() {
        _routePoints = routePoints;
        _showDirections = _routePoints.isNotEmpty;
        _isSearching = false;
        
        // Use accurate distance and duration from OSRM
        if (_routePoints.isNotEmpty) {
          _routeDistance = '${routeData['distance'].toStringAsFixed(1)} km';
          _routeDuration = '${routeData['duration'].toInt()} min';
          
          // Count hazards on route and nearby
          final hazardsOnRoute = _hazards.where((hazard) {
            return _routePoints.any((point) {
              const Distance distance = Distance();
              return distance.as(LengthUnit.Meter, hazard.location, point) < 100;
            });
          }).toList();
          
          // Count all hazards in the general area (within 500m of any route point)
          final hazardsNearRoute = _hazards.where((hazard) {
            return _routePoints.any((point) {
              const Distance distance = Distance();
              return distance.as(LengthUnit.Meter, hazard.location, point) < 500;
            });
          }).length;
          
          // Calculate hazards avoided (nearby but not on route when using safest)
          _hazardsAvoided = _useSafestRoute ? hazardsNearRoute - hazardsOnRoute.length : 0;
          
          if (hazardsOnRoute.isNotEmpty && !_useSafestRoute) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Warning: ${hazardsOnRoute.length} hazard(s) on this route'),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'Use Safest Route',
                  onPressed: () {
                    setState(() {
                      _useSafestRoute = true;
                    });
                    _findRoute();
                  },
                ),
              ),
            );
          } else if (_hazardsAvoided > 0 && _useSafestRoute) {
            // Show success message for avoided hazards
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.shield, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('✓ Avoiding $_hazardsAvoided hazard(s) on safest route'),
                  ],
                ),
                backgroundColor: const Color(0xFF34A853),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      });

      if (_routePoints.isNotEmpty) {
        // Center map on route with better zoom for road visibility
        // Calculate bounds to fit entire route
        final bounds = LatLngBounds.fromPoints(_routePoints);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Create a simple route with waypoints (avoiding hazards if safest mode)
  // Apply hazard avoidance to OSRM route
  List<LatLng> _applyHazardAvoidance(List<LatLng> routePoints) {
    if (_hazards.isEmpty) return routePoints;
    
    List<LatLng> adjustedRoute = [];
    const double hazardRadius = 100.0; // meters
    
    for (int i = 0; i < routePoints.length; i++) {
      LatLng currentPoint = routePoints[i];
      bool shouldSkip = false;
      
      // Check if current point is near any hazard
      for (final hazard in _hazards) {
        const Distance distance = Distance();
        final distanceToHazard = distance.as(LengthUnit.Meter, currentPoint, hazard.location);
        
        if (distanceToHazard < hazardRadius) {
          // For critical/high hazards, try to skip nearby points
          if (hazard.severity == HazardSeverity.critical || hazard.severity == HazardSeverity.high) {
            // Skip points very close to critical hazards
            if (distanceToHazard < 50.0) {
              shouldSkip = true;
              break;
            }
          }
        }
      }
      
      if (!shouldSkip) {
        adjustedRoute.add(currentPoint);
      }
    }
    
    return adjustedRoute.isEmpty ? routePoints : adjustedRoute;
  }

  // Optional pre-cache region (Karvenagar area)
  Future<void> _downloadMapRegion() async {
    if (!mounted) return;
    
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline maps not supported on desktop'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create and initialize offline store
      final store = FMTCStore('SafeRouteCache');
      await store.manage.create();
      
      // Download region for offline use
      final region = RectangleRegion(
        LatLngBounds(
          LatLng(18.5020, 73.8080), // SW corner
          LatLng(18.5100, 73.8200), // NE corner
        ),
      );
      
      final downloadable = region.toDownloadable(
        minZoom: 12,
        maxZoom: 17,
        options: TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.saferoute_app',
        ),
      );
      
      await store.download.startForeground(region: downloadable);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline map downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading map: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load hazards from database
  Future<void> _loadHazards() async {
    final hazards = await HazardDatabase.instance.readValidHazards();
    
    // Check if new hazards affect current route
    bool routeAffected = false;
    if (_routePoints.isNotEmpty && _useSafestRoute) {
      for (final hazard in hazards) {
        if (!_hazards.any((h) => h.id == hazard.id)) {
          // This is a new hazard
          for (final point in _routePoints) {
            const Distance distance = Distance();
            if (distance.as(LengthUnit.Meter, hazard.location, point) < 100) {
              routeAffected = true;
              break;
            }
          }
        }
        if (routeAffected) break;
      }
    }
    
    setState(() {
      _hazards = hazards;
    });
    
    // Auto-recalculate route if new hazard affects current route
    if (routeAffected && _showDirections) {
      _findRoute();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Text('Route updated to avoid new hazard!'),
              ],
            ),
            backgroundColor: Color(0xFFEA4335),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
    
    // Clean up expired hazards
    await HazardDatabase.instance.deleteExpiredHazards();
  }

  // Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Show hazard reporting bottom sheet
  void _showReportHazardSheet() {
    if (_currentPosition == null) return;

    HazardType selectedType = HazardType.accident;
    HazardSeverity selectedSeverity = HazardSeverity.medium;
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Color(0xFFEA4335), size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Report Hazard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Hazard Type Selection
                  const Text(
                    'Hazard Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: HazardType.values.map((type) {
                      return ChoiceChip(
                        label: Text('${type.icon} ${type.displayName}'),
                        selected: selectedType == type,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedType = type;
                          });
                        },
                        selectedColor: const Color(0xFF4285F4),
                        labelStyle: TextStyle(
                          color: selectedType == type ? Colors.white : Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Severity Selection
                  const Text(
                    'Severity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: HazardSeverity.values.map((severity) {
                      return ChoiceChip(
                        label: Text(severity.displayName),
                        selected: selectedSeverity == severity,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedSeverity = severity;
                          });
                        },
                        selectedColor: Color(int.parse(severity.colorHex.replaceFirst('#', '0xFF'))),
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add more details...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final hazard = Hazard(
                          id: _uuid.v4(),
                          type: selectedType,
                          location: _currentPosition!,
                          severity: selectedSeverity,
                          description: descriptionController.text.isEmpty 
                              ? '${selectedType.displayName} reported' 
                              : descriptionController.text,
                          timestamp: DateTime.now(),
                          expiryTime: DateTime.now().add(const Duration(hours: 24)),
                        );

                        await HazardDatabase.instance.create(hazard);
                        await _loadHazards();

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${selectedType.displayName} reported successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Report Hazard',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // === EMERGENCY SERVICES METHODS ===

  /// Load emergency services from JSON
  Future<void> _loadEmergencyServices() async {
    try {
      await _emergencyManager.loadServices();
      _updateNearbyEmergencyServices();
      print('Emergency services loaded successfully');
    } catch (e) {
      print('Error loading emergency services: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading emergency services: $e'),
            backgroundColor: const Color(0xFFEA4335),
          ),
        );
      }
    }
  }

  /// Update nearby emergency services based on current location
  void _updateNearbyEmergencyServices() {
    if (_currentPosition == null) {
      print('Cannot update emergency services: location not available');
      return;
    }

    try {
      final services = _emergencyManager.getNearestServices(
        userLocation: _currentPosition!,
        type: _selectedEmergencyType,
        limit: 10,
        maxDistanceKm: 15.0,
      );
      
      setState(() {
        _nearbyEmergencyServices = services;
      });
      
      print('Found ${services.length} nearby emergency services');
      if (mounted && _showEmergencyServices) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${services.length} emergency facilities nearby'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating emergency services: $e');
    }
  }

  /// Make emergency call
  Future<void> _makeEmergencyCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make call'),
            backgroundColor: Color(0xFFEA4335),
          ),
        );
      }
    }
  }

  /// Send SOS with location
  Future<void> _sendSOS() async {
    if (_currentPosition == null) return;

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final message = '🆘 EMERGENCY! I need help. My location: https://www.google.com/maps?q=$lat,$lng';

    try {
      await Share.share(
        message,
        subject: 'Emergency Location Share',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share location'),
            backgroundColor: Color(0xFFEA4335),
          ),
        );
      }
    }
  }

  /// Show emergency service details
  void _showServiceDetails(EmergencyService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Service type icon
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${service.type.colorHex.replaceFirst('#', '')}')),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        service.type.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          service.type.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Distance
              if (service.distance != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Color(0xFF4285F4)),
                    const SizedBox(width: 8),
                    Text(
                      '${service.formattedDistance} away',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    if (service.isOpen24Hours)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '24 Hours',
                          style: TextStyle(
                            color: Color(0xFF34A853),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      service.address,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() {
                          _endLocation = service.location;
                          _endController.text = service.name;
                        });
                        await _findRoute();
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4285F4),
                        side: const BorderSide(color: Color(0xFF4285F4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _makeEmergencyCall(service.phoneNumber);
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Map Layer
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 16, // Higher zoom for more detail
                    minZoom: 3,
                    maxZoom: 19, // Allow closer zoom to see small roads
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all, // Enable all interactions
                    ),
                  ),
                  children: [
                    // Using OpenStreetMap with high detail
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.saferoute_app',
                      tileProvider: _tileProvider,
                      // Increased tile size for better quality
                      tileSize: 512,
                      zoomOffset: -1,
                      maxZoom: 19,
                      minZoom: 3,
                      // Enable retina display for sharper tiles
                      retinaMode: true,
                    ),
                    // Route Polyline
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: const Color(0xFF4285F4), // Google blue
                            strokeWidth: 6.0,
                            borderColor: Colors.white,
                            borderStrokeWidth: 2.0,
                          ),
                        ],
                      ),
                    // Markers
                    MarkerLayer(
                      markers: [
                        // Route markers - draw these first
                        if (_routePoints.isNotEmpty)
                          // Start marker
                          Marker(
                            point: _routePoints.first,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF34A853), // Google green
                              size: 40,
                            ),
                          ),
                        if (_routePoints.length > 1)
                          // End marker
                          Marker(
                            point: _routePoints.last,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFEA4335), // Google red
                              size: 40,
                            ),
                          ),
                        // Hazard markers
                        ..._hazards.map((hazard) => Marker(
                          point: hazard.location,
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Row(
                                    children: [
                                      Text(hazard.type.icon, style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 8),
                                      Text(hazard.type.displayName),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('Severity: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Color(int.parse(hazard.severity.colorHex.replaceFirst('#', '0xFF'))),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              hazard.severity.displayName,
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Description: ${hazard.description}'),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Reported: ${_formatTimestamp(hazard.timestamp)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(int.parse(hazard.severity.colorHex.replaceFirst('#', '0xFF'))),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  hazard.type.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          ),
                        )).toList(),
                        // Emergency service markers
                        if (_showEmergencyServices)
                          ..._nearbyEmergencyServices.map((service) => Marker(
                            point: service.location,
                            width: 45,
                            height: 45,
                            child: GestureDetector(
                              onTap: () => _showServiceDetails(service),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(int.parse('0xFF${service.type.colorHex.replaceFirst('#', '')}')),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    service.type.icon,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                            ),
                          )).toList(),
                        // Current location marker with pulse animation - ALWAYS DRAW LAST so it's on top
                        Marker(
                          point: _currentPosition!,
                          width: 50,
                          height: 50,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pulsing outer circle
                                  Container(
                                    width: 50 * _pulseAnimation.value,
                                    height: 50 * _pulseAnimation.value,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4285F4).withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  // Inner blue dot
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4285F4),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.circle,
                                      color: Color(0xFF4285F4),
                                      size: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Top Search Bar (Google Maps style)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Start Location
                          Row(
                            children: [
                              const Icon(Icons.my_location, color: Color(0xFF34A853), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _startController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter start location (e.g., Nashik)',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (_currentPosition != null) {
                                    _startController.text = 'Current Location';
                                    _startLocation = _currentPosition;
                                  }
                                },
                                child: const Text(
                                  'Current',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 1),
                          // End Location
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFEA4335), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _endController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter destination (e.g., Mumbai)',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: _isSearching 
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.search, color: Color(0xFF4285F4)),
                                onPressed: _isSearching ? null : _findRoute,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Emergency Quick Access Menu (Left side) - Expandable FAB
                Positioned(
                  left: 16,
                  bottom: _showDirections ? 220 : 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expanded menu items (shown when menu is open)
                      if (_isEmergencyMenuExpanded) ...[
                        // Share Location (SOS)
                        _buildExpandedMenuItem(
                          icon: Icons.share_location,
                          label: 'Share Location',
                          color: const Color(0xFFEA4335),
                          textColor: Colors.white,
                          onPressed: () {
                            _sendSOS();
                            setState(() {
                              _isEmergencyMenuExpanded = false;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        // Toggle Emergency Services on Map
                        _buildExpandedMenuItem(
                          icon: Icons.local_hospital,
                          label: 'Facilities',
                          color: _showEmergencyServices 
                              ? const Color(0xFF4285F4) 
                              : Colors.white,
                          textColor: _showEmergencyServices 
                              ? Colors.white 
                              : Colors.black87,
                          onPressed: () {
                            setState(() {
                              _showEmergencyServices = !_showEmergencyServices;
                              if (_showEmergencyServices) {
                                _updateNearbyEmergencyServices();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        // Fire (101)
                        _buildExpandedMenuItem(
                          emoji: '🚒',
                          label: 'Fire 101',
                          color: Colors.deepOrange,
                          onPressed: () => _makeEmergencyCall('101'),
                        ),
                        const SizedBox(height: 8),
                        // Ambulance (102)
                        _buildExpandedMenuItem(
                          emoji: '🚑',
                          label: 'Ambulance 102',
                          color: const Color(0xFFEA4335),
                          onPressed: () => _makeEmergencyCall('102'),
                        ),
                        const SizedBox(height: 8),
                        // Police (100)
                        _buildExpandedMenuItem(
                          emoji: '👮',
                          label: 'Police 100',
                          color: Colors.blue[900]!,
                          onPressed: () => _makeEmergencyCall('100'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Main Emergency Button (Always visible)
                      GestureDetector(
                        onLongPress: _sendSOS, // Long press for SOS
                        child: FloatingActionButton(
                          heroTag: 'emergency_main',
                          backgroundColor: const Color(0xFFEA4335),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          onPressed: () {
                            setState(() {
                              _isEmergencyMenuExpanded = !_isEmergencyMenuExpanded;
                            });
                          },
                          child: AnimatedRotation(
                            turns: _isEmergencyMenuExpanded ? 0.125 : 0, // 45 degree rotation when open
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _isEmergencyMenuExpanded ? Icons.close : Icons.add,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      // SOS label below main button
                      if (!_isEmergencyMenuExpanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA4335),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Emergency',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Floating Action Buttons (Right side)
                Positioned(
                  right: 16,
                  bottom: _showDirections ? 220 : 120,
                  child: Column(
                    children: [
                      // Report Hazard Button
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: const Color(0xFFEA4335),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        onPressed: _showReportHazardSheet,
                        child: const Icon(Icons.warning),
                      ),
                      const SizedBox(height: 12),
                      // My Location Button
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: _followUserLocation ? const Color(0xFF4285F4) : Colors.white,
                        foregroundColor: _followUserLocation ? Colors.white : Colors.black87,
                        elevation: 4,
                        onPressed: () {
                          setState(() {
                            _followUserLocation = !_followUserLocation;
                          });
                          
                          if (_currentPosition != null) {
                            _mapController.move(_currentPosition!, _mapController.camera.zoom);
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _followUserLocation 
                                    ? 'Following your location' 
                                    : 'Location follow disabled',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Icon(
                          _followUserLocation ? Icons.my_location : Icons.location_searching,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Offline Download Button
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        foregroundColor: _isOffline ? Colors.orange : Colors.black87,
                        elevation: 4,
                        onPressed: _downloadMapRegion,
                        child: Icon(_isOffline ? Icons.cloud_off : Icons.cloud_download),
                      ),
                    ],
                  ),
                ),

                // Bottom Sheet with Directions
                if (_showDirections)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                      elevation: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle bar
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Route Info
                            Row(
                              children: [
                                const Icon(Icons.directions, color: Color(0xFF4285F4), size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _routeDuration,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF202124),
                                        ),
                                      ),
                                      Text(
                                        _routeDistance,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    // Start navigation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Navigation started!'),
                                        backgroundColor: Color(0xFF34A853),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4285F4),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Start', style: TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Safest/Fastest Route Toggle
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _useSafestRoute ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _useSafestRoute ? const Color(0xFF34A853) : const Color(0xFF4285F4),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _useSafestRoute ? Icons.shield : Icons.speed,
                                    color: _useSafestRoute ? const Color(0xFF34A853) : const Color(0xFF4285F4),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _useSafestRoute ? 'Safest Route' : 'Fastest Route',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _useSafestRoute ? const Color(0xFF34A853) : const Color(0xFF4285F4),
                                              ),
                                            ),
                                            if (_useSafestRoute && _hazardsAvoided > 0) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF34A853),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '$_hazardsAvoided avoided',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          _useSafestRoute 
                                              ? 'Avoiding hazards' 
                                              : 'Shortest path',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _useSafestRoute,
                                    onChanged: (value) {
                                      setState(() {
                                        _useSafestRoute = value;
                                      });
                                      _findRoute(); // Recalculate route
                                    },
                                    activeColor: const Color(0xFF34A853),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Hazard count on route
                            if (_hazards.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 18,
                                    color: Colors.orange[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_hazards.length} hazard(s) reported nearby',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Route calculated using Dijkstra algorithm',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Offline Indicator
                if (_isOffline)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 80,
                    left: 16,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Offline',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // Build expanded menu item with label
  Widget _buildExpandedMenuItem({
    String? emoji,
    IconData? icon,
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                )
              else if (icon != null)
                Icon(
                  icon,
                  color: textColor ?? Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
