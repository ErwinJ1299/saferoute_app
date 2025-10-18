# Expandable Emergency Menu - Updated Design

## 🎯 Overview
The emergency services have been redesigned into a **single expandable FAB (Floating Action Button)** that expands to show all emergency options when tapped.

## 🔴 Main Emergency Button (Always Visible)

Located on the **bottom-left** of the screen:
- **Red circular button** with **+ icon**
- Label below: **"Emergency"**
- **Tap** to expand/collapse the menu
- **Long press** (hold for 1 second) to trigger SOS alert directly

### Visual States:
1. **Collapsed** (Default):
   ```
   ┌──────┐
   │  +   │  Red button with plus icon
   └──────┘
   Emergency  (Label below)
   ```

2. **Expanded** (After tap):
   ```
   ┌────────────────┐
   │ 🏥 Facilities  │  Toggle nearby facilities
   ├────────────────┤
   │ 🚒 Fire 101    │  Call fire department
   ├────────────────┤
   │ 🚑 Ambulance102│  Call ambulance
   ├────────────────┤
   │ 👮 Police 100  │  Call police
   ├────────────────┤
   │       ×        │  Close button (rotated +)
   └────────────────┘
   ```

## 🚀 Features

### 1. **Space-Efficient Design**
- Only **one button** visible by default
- Expands upward when needed
- Doesn't clutter the map interface
- Easy to access with thumb

### 2. **Smooth Animations**
- Button rotates 45° when opening (+ becomes ×)
- Menu items slide in from bottom
- Material Design elevation effects
- Instant visual feedback

### 3. **Quick Access Options**

When expanded, you get 4 options:

#### 🏥 **Facilities** (Blue/White toggle)
- Shows/hides emergency facilities on map
- Blue when active, white when inactive
- Displays hospitals, police stations, fire stations, pharmacies

#### 🚒 **Fire 101** (Orange)
- Direct call to fire department
- Emergency number: 101 (India)

#### 🚑 **Ambulance 102** (Red)
- Direct call to ambulance services
- Emergency number: 102 (India)

#### 👮 **Police 100** (Dark Blue)
- Direct call to police
- Emergency number: 100 (India)

### 4. **Long Press for SOS**
- Hold the main red button for ~1 second
- Instantly triggers SOS location sharing
- No need to open menu for emergencies
- Shares location via SMS/WhatsApp

## 📱 How to Use

### Opening the Menu
1. Tap the red **Emergency** button on bottom-left
2. Menu expands upward showing 4 options
3. Icon changes from **+** to **×**

### Making Emergency Call
1. Open the menu (tap Emergency button)
2. Tap the service you need:
   - 👮 Police 100
   - 🚑 Ambulance 102
   - 🚒 Fire 101
3. Phone dialer opens automatically

### Showing Nearby Facilities
1. Open the menu
2. Tap **🏥 Facilities**
3. Map shows markers for:
   - Hospitals (red)
   - Police stations (blue)
   - Fire stations (orange)
   - Pharmacies (green)
4. Tap any marker for details

### Quick SOS (Emergency)
1. **Long press** (hold) the red Emergency button
2. Location is captured
3. Share menu opens
4. Send to emergency contacts

### Closing the Menu
1. Tap the **×** button (was + when closed)
2. Menu collapses smoothly

## 🎨 Visual Design

### Button Styles
- **Main Button**: Large red FAB (56x56 dp)
- **Menu Items**: Rounded rectangles with labels
- **Colors**: Material Design emergency colors
- **Elevation**: 4-6dp shadows for depth
- **Typography**: Bold, readable fonts

### Layout
```
Map Area
│
├─ Left Side (Bottom)
│  │
│  ├─ [Expanded Menu Items] ← When open
│  │   ├─ 🏥 Facilities
│  │   ├─ 🚒 Fire 101
│  │   ├─ 🚑 Ambulance 102
│  │   └─ 👮 Police 100
│  │
│  └─ [+ Emergency] ← Main button (always visible)
│
└─ Right Side (Bottom)
    ├─ ⚠️ Hazard Report
    ├─ 📍 My Location
    └─ ☁️ Download Maps
```

## 🔧 Technical Implementation

### State Management
- `_isEmergencyMenuExpanded`: Boolean to track menu state
- Updates on tap to toggle open/closed
- Smooth animations with Flutter's built-in widgets

### Gestures
- **onPressed**: Toggle menu expand/collapse
- **onLongPress**: Trigger SOS alert (≥1 second hold)

### Widget Composition
- `FloatingActionButton` for main button
- `GestureDetector` for long-press detection
- `_buildExpandedMenuItem()` helper for menu items
- `AnimatedRotation` for icon transformation

### Responsive Positioning
- Adjusts based on `_showDirections` state
- Bottom offset changes when directions panel is visible
- Always accessible regardless of map state

## ✨ Benefits

1. **Cleaner Interface**: 5 buttons → 1 button
2. **Less Clutter**: Map area remains clear
3. **Easy Access**: Still quick (1 tap + 1 tap)
4. **Emergency Ready**: Long press for instant SOS
5. **Professional Look**: Matches modern app design
6. **Intuitive**: Familiar FAB pattern
7. **Scalable**: Easy to add more emergency options

## 🆚 Before vs After

### Before:
```
5 separate buttons stacked vertically
Taking up significant screen space
Always visible even when not needed
```

### After:
```
1 main button (collapsed state)
Expands on demand
Clean, professional appearance
More map space available
```

## 💡 Tips

- **In a real emergency**: Long press for instant SOS
- **For planned needs**: Tap to open menu, choose service
- **To see facilities**: Open menu → tap Facilities
- **To close quickly**: Tap × or tap anywhere on map
- **One-handed use**: Positioned for easy thumb reach

## 🔮 Future Enhancements

Possible additions to the menu:
- 📞 Emergency contacts list
- 🏥 Medical info (blood type, allergies)
- 🆘 Panic mode with siren
- 📸 Quick photo for evidence
- 🎙️ Voice recording
- 📡 Live location sharing toggle

---

**Version**: Emergency Menu v2.0 - Expandable Design  
**Date**: October 18, 2025  
**SafeRoute App** 🚀
