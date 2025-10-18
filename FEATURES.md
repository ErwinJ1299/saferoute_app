# 🛡️ SafeRoute - Smart Hazard-Aware Navigation App

## 🎯 Overview
SafeRoute is a Flutter-based navigation app that prioritizes user safety by intelligently routing around reported hazards. Unlike traditional navigation apps that only focus on speed, SafeRoute gives users the power to choose between the fastest route or the safest route.

---

## ✨ Key Features

### 1. 🗺️ **Google Maps-Style UI**
- Modern, clean interface with floating search bar
- Bottom sheet for route directions
- Smooth animations and transitions
- Professional color scheme (Google blue, green, red)
- Responsive design for all screen sizes

### 2. 📍 **Smart Location Tracking**
- **Smooth Position Updates**: Animated transitions (800ms) with easing curves
- **Pulsing Blue Dot**: Continuous 1.5s pulse animation for visual feedback
- **GPS Jitter Filtering**: 
  - 20-meter distance filter to prevent unnecessary updates
  - Accuracy filtering (>50m readings ignored)
  - Stable positioning when stationary indoors
- **Auto-Follow Mode**: Toggle to automatically center map on user location
- **Battery Optimized**: Efficient location updates only when needed

### 3. 🚨 **Hazard Reporting System**

#### **Hazard Types**:
- 🚗 Accident
- 🚧 Road Block
- 🕳️ Pothole
- 🌊 Flooding
- 🏗️ Construction
- ⚠️ Other

#### **Severity Levels**:
- **Low** (Orange) - Minor inconvenience, 1.5x route weight
- **Medium** (Dark Orange) - Moderate danger, 3x route weight
- **High** (Red) - Serious hazard, 5x route weight
- **Critical** (Dark Red) - Extreme danger, 100x route weight (effectively blocks route)

#### **Hazard Features**:
- Quick report via red warning button (FAB)
- Beautiful bottom sheet with emoji-based type selection
- Color-coded severity chips
- Optional description field
- Automatic 24-hour expiry
- SQLite local storage for offline access
- Community-ready (upvote/downvote support built-in)

### 4. 🛣️ **Smart Route Recalculation with Hazard Avoidance**

#### **Dijkstra Algorithm Enhanced**:
```dart
// Hazard proximity detection (100m threshold)
// Dynamic weight adjustment based on severity
// Real-time route recalculation
```

#### **Routing Features**:
- **Safest Route** 🛡️ (Green):
  - Automatically avoids all reported hazards
  - Shows count of hazards avoided
  - Visual badge: "X avoided"
  - Minimizes risk even if route is longer
  
- **Fastest Route** ⚡ (Blue):
  - Shortest path regardless of hazards
  - Shows warning if hazards detected on route
  - Quick toggle to switch to safest route

#### **Real-Time Intelligence**:
- **Automatic Rerouting**: When new hazard reported on current route
- **Smart Notifications**: 
  - "Route updated to avoid new hazard!" (red alert)
  - "✓ Avoiding X hazard(s) on safest route" (green success)
  - "⚠️ Warning: X hazard(s) on this route" (orange warning)
- **Proximity Detection**: 100m radius around road segments
- **Area Analysis**: 500m radius for nearby hazard detection

### 5. 🎨 **Visual Hazard Markers**

#### **On Map**:
- Circular markers with hazard emoji icons
- Color-coded by severity
- White border and shadow for visibility
- Tap to view full details:
  - Hazard type and severity
  - Description
  - Time reported ("5 min ago", "2 hr ago")
  
#### **In Route Info**:
- Hazard counter in bottom sheet
- Avoided hazards badge
- Toggle switch with visual feedback

### 6. 💾 **Offline Capabilities**
- **FMTC Tile Caching**: Download maps for offline use
- **SQLite Database**: Local hazard storage
- **Automatic Sync**: Updates when connection restored
- **Desktop Support**: Network tiles for development

### 7. 📊 **Route Information Display**
- Distance in kilometers
- Estimated duration (3 min per km approximation)
- Real-time hazard count
- Avoided hazards counter
- Visual route polyline with Google blue color
- Start (green) and end (red) markers

---

## 🏗️ Technical Architecture

### **Frontend (Flutter)**
- **State Management**: StatefulWidget with setState
- **Animations**: 
  - AnimationController for smooth transitions
  - Tween animations for position and pulse
  - TickerProviderStateMixin for multiple controllers
- **Maps**: flutter_map with OpenStreetMap tiles
- **Location**: Geolocator with StreamSubscription

### **Data Layer**
- **Models**: 
  - `Hazard` class with JSON serialization
  - Enum-based type and severity system
- **Database**: SQLite with sqflite package
- **Caching**: FMTC for offline tile storage

### **Algorithms**
- **Dijkstra's Algorithm**: Custom implementation with hazard weighting
- **Distance Calculations**: Haversine formula via latlong2
- **Proximity Detection**: Geospatial calculations for hazard-route intersection

### **Code Structure**
```
lib/
├── main.dart
├── models/
│   └── hazard.dart              # Hazard data model with enums
├── screens/
│   └── map_screen.dart          # Main UI with all features
├── utils/
│   ├── dijkstra.dart            # Enhanced pathfinding algorithm
│   ├── hazard_database.dart     # SQLite database helper
│   ├── map_matching.dart        # Future: snap to road
│   └── offline_storage.dart     # Cache management
├── data/
│   └── sample_graph.dart        # Road network with coordinates
└── assets/
    ├── hazards.json             # Sample hazard data
    ├── roads.json               # Road network JSON
    └── shelters.json            # Emergency shelters
```

---

## 🎮 User Flow

### **Reporting a Hazard**:
1. Tap red warning button (⚠️)
2. Select hazard type (🚗 🚧 🕳️ 🌊 🏗️ ⚠️)
3. Choose severity (Low/Medium/High/Critical)
4. Add optional description
5. Submit → Appears immediately on map

### **Planning a Route**:
1. Tap floating search bar
2. Enter start location (e.g., "A")
3. Enter destination (e.g., "C")
4. Tap "Get Directions"
5. View route on map with distance/time
6. Toggle Safest/Fastest as needed
7. Tap "Start" to begin navigation

### **Switching Route Mode**:
1. Open directions bottom sheet
2. Toggle switch between shield (🛡️) and speed (⚡)
3. Route instantly recalculates
4. See hazards avoided or warnings displayed

---

## 🔧 Configuration

### **Location Settings**:
```dart
LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 20,  // Update every 20 meters
)
```

### **Animation Settings**:
```dart
// Position transition
Duration: 800ms
Curve: Curves.easeInOut

// Pulse animation
Duration: 1500ms
Scale: 1.0x to 1.3x
Repeat: Reverse
```

### **Hazard Thresholds**:
```dart
proximityThreshold: 100m   // On-route detection
areaThreshold: 500m        // Nearby detection
expiryDuration: 24 hours   // Auto-cleanup
accuracyFilter: 50m        // GPS quality threshold
```

---

## 📱 Sample Data

### **Road Network (Pune, India)**:
- **Node A**: Karvenagar Chowk (18.5089, 73.8077)
- **Node B**: Cummins College (18.5095, 73.8140)
- **Node C**: Karve Road Junction (18.5075, 73.8182)
- **Node D**: Alankar Police Chowky (18.5048, 73.8125)
- **Node E**: Vitthal Mandir (18.5020, 73.8085)

### **Edge Weights**:
```dart
A ↔ B: 0.5 km
A ↔ D: 0.6 km
A ↔ E: 0.8 km
B ↔ C: 0.7 km
C ↔ D: 0.5 km
D ↔ E: 0.4 km
```

---

## 🚀 Future Enhancements

### **Planned Features**:
1. **Turn-by-Turn Voice Navigation** 🗣️
2. **Emergency Services Integration** 🚑
   - Quick-dial buttons
   - Nearest hospital/police
   - SOS with location sharing
3. **Community Verification** 👥
   - Upvote/downvote hazards
   - User reputation system
   - Hazard heatmap
4. **Advanced Routing** 🎯
   - Multiple route alternatives
   - Time-based routing (avoid rush hour)
   - Elevation-aware routing
5. **Analytics Dashboard** 📊
   - Personal safety score
   - Hazards avoided stats
   - Route history
6. **Social Features** 💬
   - Share routes with friends
   - Group navigation
   - Real-time location sharing

---

## 🎯 What Makes SafeRoute Unique

### **vs Traditional Navigation Apps**:
| Feature | Google Maps | Waze | **SafeRoute** |
|---------|-------------|------|---------------|
| Fastest Route | ✅ | ✅ | ✅ |
| Safest Route | ❌ | ❌ | ✅ |
| Hazard Reporting | Limited | ✅ | ✅ |
| Offline First | Limited | ❌ | ✅ |
| Safety Priority | ❌ | ❌ | ✅ |
| Route Comparison | Limited | ❌ | ✅ (Safe vs Fast) |
| Auto-Rerouting | ✅ | ✅ | ✅ (Hazard-aware) |
| Local Database | ❌ | ❌ | ✅ |

### **Core Philosophy**:
> "Get there **safely**, not just quickly."

SafeRoute is built on the principle that the shortest path isn't always the best path. By giving users transparent control over safety vs. speed trade-offs, we empower informed decision-making.

---

## 📝 License
This project is private and for educational purposes.

---

## 👨‍💻 Developer Notes

### **Performance Optimizations**:
- Lazy loading of hazard markers
- Debounced location updates
- Efficient SQLite queries with indexing
- Widget rebuild optimization
- Memory-efficient tile caching

### **Error Handling**:
- GPS accuracy filtering
- Network connectivity checks
- Graceful offline degradation
- User-friendly error messages
- Automatic retry mechanisms

### **Best Practices**:
- SOLID principles
- Clean code architecture
- Comprehensive error handling
- Efficient state management
- Optimized animations

---

**SafeRoute** - *Navigate with Confidence* 🛡️
