# Emergency Services Integration - SafeRoute

## Features Implemented

### 1. Quick Emergency Call Buttons (Left Side of Screen)
Located on the left side of the map for easy access:

- **🆘 SOS Button (Large Red)**: Shares your current location via SMS/WhatsApp with emergency message
- **👮 Police Button (100)**: Direct call to police emergency number
- **🚑 Ambulance Button (102)**: Direct call to ambulance/medical emergency
- **🚒 Fire Button (101)**: Direct call to fire department
- **🏥 Toggle Services**: Shows/hides nearby emergency facilities on map

### 2. Emergency Facilities Database
Pre-loaded facilities in Nashik area (expandable to other cities):
- Hospitals (🏥): Nashik Civil Hospital, Wockhardt Hospital, Ashoka Medicover Hospital
- Police Stations (👮): Nashik Road Police Station, Sarkarwada Police Station
- Fire Stations (🚒): Nashik Fire Station, Satpur Fire Station
- Pharmacies (💊): Apollo Pharmacy, MedPlus Pharmacy

### 3. Map Markers for Emergency Facilities
When emergency services toggle is ON:
- Color-coded circular markers for each service type
- Hospital: Red markers
- Police: Blue markers  
- Fire: Orange markers
- Pharmacy: Green markers
- Tap any marker to view details

### 4. Service Details Sheet
When you tap an emergency service marker:
- **Facility name and type**
- **Distance from your location** (e.g., "2.5 km away")
- **24-hour availability badge** (if applicable)
- **Full address**
- **Action Buttons**:
  - **Directions**: Get route from your location to facility
  - **Call**: Directly call the facility's phone number

### 5. SOS Feature
Tap the large red SOS button to:
- Generate emergency message with your GPS coordinates
- Share via SMS, WhatsApp, or any messaging app
- Message format: "🆘 EMERGENCY! I need help. My location: [Google Maps link]"

### 6. Nearby Services Detection
- Automatically finds nearest emergency facilities within 15km
- Shows up to 10 facilities per type
- Distance calculated in real-time from your current location
- Services sorted by distance (nearest first)

## How to Use

### Making an Emergency Call
1. Tap one of the emoji buttons on the left side:
   - 👮 for Police (100)
   - 🚑 for Ambulance (102)
   - 🚒 for Fire (101)
2. Your phone will prompt to make the call

### Finding Nearby Emergency Facilities
1. Tap the hospital icon (🏥) button at bottom of left panel
2. Map will show markers for all nearby facilities
3. Tap any marker to see facility details
4. Use "Directions" button to navigate to the facility
5. Use "Call" button to phone the facility directly

### Sending SOS Alert
1. Tap the large red SOS button
2. Choose how to share (SMS, WhatsApp, etc.)
3. Select emergency contact
4. Message with your location is sent automatically

## Emergency Numbers (India)
- **100** - Police
- **101** - Fire Department
- **102** - Ambulance
- **108** - Emergency Medical Services

## Technical Details

### Packages Used
- `url_launcher` v6.3.1 - For making phone calls
- `share_plus` v10.1.3 - For SOS location sharing
- `latlong2` - For distance calculations

### Data Source
Emergency services loaded from `assets/emergency_services.json` containing:
- Facility ID, name, type
- GPS coordinates (latitude/longitude)
- Address and phone number
- 24-hour availability status

### Smart Features
- **Distance Filtering**: Only shows facilities within 15km
- **Real-time Calculation**: Distances update as you move
- **Color Coding**: Different colors for different service types
- **Persistent Markers**: Emergency markers stay on top of other map elements
- **One-tap Actions**: Quick access to critical features

## Future Enhancements
- Add more cities across India
- Integration with real-time facility availability APIs
- Show facility current capacity/wait times
- Add more service types (poison control, women helpline, etc.)
- Emergency contact management
- Auto-SOS trigger on crash detection

## Safety Notes
⚠️ **Important**: This app provides emergency service information as a convenience. In a real emergency:
1. **Call emergency services directly** using the quick call buttons
2. **Use SOS feature** to alert your contacts
3. **Navigate to nearest facility** using the directions feature
4. Don't rely solely on the app - always call emergency numbers

---

## Version
Emergency Services Integration v1.0  
SafeRoute App - Built with Flutter 🚀
