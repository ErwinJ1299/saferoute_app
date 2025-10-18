# 🧪 SafeRoute Testing Guide

## Quick Test Scenarios

### Test 1: Report a Hazard
**Steps**:
1. Open app and wait for location to load
2. Tap the **red warning button** (top-right FAB)
3. Select hazard type: **🕳️ Pothole**
4. Choose severity: **High** (red)
5. Add description: "Large pothole on main road"
6. Tap **Report Hazard**
7. **Expected**: Red marker appears on map at your location

### Test 2: Plan a Safest Route
**Steps**:
1. Tap the floating search bar
2. Enter **Start**: `A`
3. Enter **Destination**: `C`
4. Tap **Get Directions**
5. **Expected**: 
   - Blue route line appears
   - Bottom sheet shows distance and time
   - "Safest Route" toggle is ON (green)
   - If hazards nearby, see "X avoided" badge

### Test 3: Compare Safe vs Fast Routes
**Steps**:
1. With route active from Test 2
2. First report a hazard near the route:
   - Tap map location near path
   - Report hazard (any type, High severity)
3. Toggle switch to **Fastest Route** (off)
4. **Expected**: 
   - Route may change
   - Orange warning: "⚠️ Warning: X hazard(s) on this route"
5. Toggle back to **Safest Route** (on)
6. **Expected**:
   - Green success: "✓ Avoiding X hazard(s)"
   - Badge shows number avoided

### Test 4: Real-Time Rerouting
**Steps**:
1. Have an active route (Safest mode)
2. Report a NEW hazard ON your current route:
   - Tap along the blue route line
   - Report critical hazard
3. **Expected**:
   - Route automatically recalculates
   - Red alert: "Route updated to avoid new hazard!"
   - New path avoids the hazard

### Test 5: View Hazard Details
**Steps**:
1. Tap any hazard marker on the map
2. **Expected**: Dialog shows:
   - Hazard type with emoji
   - Severity with colored badge
   - Description
   - Time reported ("5 min ago")
3. Tap **Close**

### Test 6: Smooth Location Tracking
**Steps**:
1. Go outside and start walking
2. Observe the blue dot
3. **Expected**:
   - Smooth gliding animation (not jumping)
   - Pulsing outer circle
   - Updates every 20 meters
   - No jitter when stationary

### Test 7: GPS Jitter Fix (Indoor)
**Steps**:
1. Stay inside your house
2. Don't move
3. Wait 2-3 minutes
4. **Expected**:
   - Blue dot stays mostly stable
   - Very few or no updates
   - Console shows: "Skipping low accuracy reading"

### Test 8: Auto-Follow Mode
**Steps**:
1. Tap the **location button** (blue/white FAB)
2. Walk around
3. **Expected**:
   - Map auto-centers on your position
   - Blue button indicates active
4. Manually drag map
5. **Expected**:
   - Auto-follow disables
   - Button turns white

### Test 9: Offline Maps (Mobile Only)
**Steps**:
1. Tap the **cloud download** button
2. Wait for download
3. **Expected**: 
   - Success message
   - Maps cached for offline use
4. Turn on airplane mode
5. Pan/zoom map
6. **Expected**: Map tiles load from cache

### Test 10: Multiple Hazards
**Steps**:
1. Report 3 different hazards:
   - 🚗 Accident (Critical)
   - 🚧 Road Block (High)
   - 🕳️ Pothole (Medium)
2. Plan route from A → E
3. **Expected**:
   - All hazards visible as colored markers
   - Route avoids critical/high hazards
   - Bottom sheet shows total hazard count

---

## Expected Behaviors

### Route Calculation Logic:
- **Safest Route ON**: 
  - Multiplies edge weight by hazard severity
  - Critical (100x) = almost impossible to use
  - High (5x) = very unlikely to use
  - Medium (3x) = avoids if alternative exists
  - Low (1.5x) = slight penalty

- **Fastest Route ON**:
  - Ignores all hazards
  - Pure shortest path
  - Shows warnings only

### Hazard Weight Examples:
```
Normal road A→B: 0.5 km

With Low hazard: 0.5 × 1.5 = 0.75 km weight
With Medium: 0.5 × 3.0 = 1.5 km weight
With High: 0.5 × 5.0 = 2.5 km weight
With Critical: 0.5 × 100 = 50 km weight (effectively blocked)
```

### Animation Timing:
- **Position Animation**: 800ms with easeInOut curve
- **Pulse Animation**: 1500ms repeating
- **Scale Range**: 1.0x to 1.3x

### Distance Thresholds:
- **On-Route Detection**: 100 meters
- **Nearby Area**: 500 meters  
- **Update Trigger**: 20 meters movement
- **Accuracy Filter**: 50 meters

---

## Known Limitations

1. **Sample Data**: Only 5 nodes (A-E) in Pune area
2. **Voice Navigation**: Not yet implemented
3. **Road Snapping**: Points may not align perfectly with roads
4. **Desktop**: Offline maps not available (uses network tiles)
5. **Accuracy**: Approximate duration calculation (3 min/km)

---

## Debug Console Messages

### Good Messages:
```
✅ FMTC tile caching initialized
Location updated: 19.999, 73.706 (accuracy: 15m)
```

### Filtered Messages:
```
Skipping low accuracy reading: 75m
```

### Route Messages:
```
Route recalculated with 2 hazards avoided
```

---

## Performance Benchmarks

- **Route Calculation**: < 100ms
- **Hazard Loading**: < 50ms
- **Animation FPS**: 60 fps
- **Memory Usage**: < 150 MB
- **Battery Impact**: Low (optimized location updates)

---

## Troubleshooting

### Issue: Location not updating
**Solution**: 
- Check location permissions
- Ensure GPS is enabled
- Go outside for better signal
- Restart app

### Issue: Map tiles not loading
**Solution**:
- Check internet connection
- Try offline download
- Clear cache and restart

### Issue: Route not calculating
**Solution**:
- Use valid nodes (A, B, C, D, E)
- Ensure start ≠ destination
- Check for typos (case-sensitive)

### Issue: Hazards not appearing
**Solution**:
- Check database permissions
- Restart app
- Report hazard again
- Check expiry (24 hours)

---

**Happy Testing!** 🧪🚀
