# SafeRoute App - Emergency Services UI Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SafeRoute App                                │
├─────────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  🔍 [Start Location      ] → [Destination         ] [Search]  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  LEFT SIDE                    MAP AREA                  RIGHT SIDE  │
│  Emergency Buttons                                      Map Controls│
│                                                                      │
│  ┌──────┐                                                ┌──────┐   │
│  │ 🆘   │  ← SOS Alert (Large Red Button)              │  ⚠️  │   │
│  │ SOS  │                                                │Hazard│   │
│  └──────┘                                                └──────┘   │
│                                                                      │
│  ┌────┐              📍 Your Location                   ┌──────┐   │
│  │ 👮 │  ← Police 100    (Blue Dot)                     │  📍  │   │
│  └────┘                                                  │ GPS  │   │
│  ┌────┐              🏥 Hospital (Red)                  └──────┘   │
│  │ 🚑 │  ← Ambulance 102                                           │
│  └────┘              👮 Police Station (Blue)           ┌──────┐   │
│  ┌────┐                                                  │  ☁️  │   │
│  │ 🚒 │  ← Fire 101      🚒 Fire Station (Orange)       │ DL   │   │
│  └────┘                                                  └──────┘   │
│                        💊 Pharmacy (Green)                          │
│  ┌────┐                                                             │
│  │ 🏥 │  ← Toggle Emergency Services                                │
│  └────┘                                                             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
│                                                                      │
│  ┌─────────────────── Directions Panel ──────────────────────┐     │
│  │  📊 Route Info: 5.2 km • 12 min                           │     │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━               │     │
│  │  [⚡ Fastest] / [🛡️ Safest]                                │     │
│  │  Turn-by-turn directions...                               │     │
│  └────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────┘
```

## Button Functions

### Left Side (Emergency Access)
1. **🆘 SOS** (Large, Red, Always Visible)
   - Share location via SMS/WhatsApp
   - Sends emergency message with GPS link
   
2. **👮 Police** (Mini, Dark Blue)
   - Instant call to 100
   
3. **🚑 Ambulance** (Mini, Red)
   - Instant call to 102
   
4. **🚒 Fire** (Mini, Orange)
   - Instant call to 101
   
5. **🏥 Services** (Mini, Blue/White Toggle)
   - Show/hide emergency facilities on map

### Right Side (Navigation Controls)
1. **⚠️ Hazard** (Mini, Red)
   - Report road hazards
   
2. **📍 GPS** (Mini, Blue/White)
   - Toggle location following
   
3. **☁️ DL** (Mini, White)
   - Download offline maps

## Emergency Service Marker Tap Actions

When you tap a facility marker (🏥, 👮, 🚒, 💊):

```
┌──────────────────────────────────┐
│  🏥  Wockhardt Hospital          │
│      Hospital                    │
├──────────────────────────────────┤
│  📍 2.5 km away    [24 Hours]    │
│  📍 Mumbai Naka, Nashik          │
├──────────────────────────────────┤
│  [🧭 Directions]  [📞 Call]      │
└──────────────────────────────────┘
```

## Color Scheme

### Emergency Services
- **🆘 SOS Button**: #EA4335 (Google Red)
- **👮 Police**: #0D47A1 (Dark Blue)
- **🚑 Ambulance**: #EA4335 (Red)
- **🚒 Fire**: #FF5722 (Deep Orange)
- **🏥 Services Toggle**: #4285F4 (Google Blue) when ON

### Map Markers
- **Hospital**: Red (#EA4335)
- **Police Station**: Blue (#0D47A1)
- **Fire Station**: Orange (#FF5722)
- **Pharmacy**: Green (#34A853)
- **Your Location**: Blue with pulse animation (#4285F4)
- **Route**: Google Blue (#4285F4)

## Interaction Flow

### Emergency Call Flow
```
User taps emoji button (👮/🚑/🚒)
         ↓
System opens phone dialer
         ↓
User confirms call
         ↓
Call connected to emergency service
```

### Find Facility Flow
```
User taps 🏥 button
         ↓
Map shows all nearby facilities (colored markers)
         ↓
User taps a facility marker
         ↓
Details sheet appears
         ↓
User taps "Directions" → Route calculated
   OR
User taps "Call" → Phone dialer opens
```

### SOS Alert Flow
```
User taps 🆘 button
         ↓
Location captured with GPS coordinates
         ↓
Share menu opens (SMS/WhatsApp/etc.)
         ↓
User selects contact(s)
         ↓
Message sent: "🆘 EMERGENCY! My location: [link]"
```

## Distance Display
- < 1 km: Shows in meters (e.g., "450 m away")
- ≥ 1 km: Shows in kilometers (e.g., "2.5 km away")

## Smart Features
- **Auto-update**: Distances recalculate as you move
- **Filter range**: Only shows facilities within 15km
- **Limit results**: Maximum 10 facilities per type
- **Sort by distance**: Nearest facilities shown first
- **Marker layering**: Your blue dot always on top
