# Google Maps Navigation Implementation Plan

## Overview
This document outlines the plan for implementing navigation features in the Nayifat App's branch locator functionality. The implementation will allow users to navigate to branches using various navigation apps based on their platform and preferences.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Dependencies](#dependencies)
3. [Implementation Steps](#implementation-steps)
4. [Platform-Specific Configurations](#platform-specific-configurations)
5. [Testing Plan](#testing-plan)
6. [Assets Required](#assets-required)
7. [Error Handling](#error-handling)

## Prerequisites

### Current Implementation Review
- Existing Google Maps integration
- Branch location display functionality
- Location permission handling
- Marker placement for branches

### Required Access
- Google Maps API key
- Access to the app's iOS and Android configurations
- Permission to add new dependencies

## Dependencies

### New Package Requirements
```yaml
dependencies:
  url_launcher: ^6.1.14    # For launching external apps
  geolocator: ^10.1.0      # For getting current location
```

### Existing Required Packages
```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  permission_handler: ^10.4.3
  device_info_plus: ^9.0.3
```

## Implementation Steps

### 1. Navigation Service Setup
1. Create new service class `navigation_service.dart`:
   - Implement methods for different navigation apps
   - Handle URL scheme generation
   - Implement platform-specific logic

### 2. UI Implementation
1. Modify Marker Interaction:
   - Add tap handlers to markers
   - Show navigation options bottom sheet
   - Implement custom info windows

2. Add Navigation Bottom Sheet:
   - Design responsive layout
   - Include app icons and labels
   - Support RTL layout for Arabic

3. Add List View Navigation:
   - Add navigation buttons to list items
   - Implement consistent UI with map markers

### 3. Core Navigation Features
1. Current Location Handling:
   ```dart
   Future<Position> getCurrentLocation() async {
     return await Geolocator.getCurrentPosition(
       desiredAccuracy: LocationAccuracy.high
     );
   }
   ```

2. Navigation URL Generation:
   ```dart
   String generateGoogleMapsUrl(LatLng origin, LatLng destination) {
     return 'https://www.google.com/maps/dir/?api=1'
            '&origin=${origin.latitude},${origin.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&travelmode=driving';
   }
   ```

3. App Launch Handling:
   ```dart
   Future<void> launchNavigationApp(String url) async {
     final uri = Uri.parse(url);
     if (await canLaunchUrl(uri)) {
       await launchUrl(uri, mode: LaunchMode.externalApplication);
     }
   }
   ```

## Platform-Specific Configurations

### iOS Configuration
1. Update Info.plist:
   ```xml
   <key>LSApplicationQueriesSchemes</key>
   <array>
       <string>comgooglemaps</string>
       <string>waze</string>
   </array>
   ```

2. Add Apple Maps Support:
   ```dart
   String generateAppleMapsUrl(LatLng origin, LatLng destination) {
     return 'http://maps.apple.com/?'
            'saddr=${origin.latitude},${origin.longitude}'
            'daddr=${destination.latitude},${destination.longitude}'
            '&dirflg=d';
   }
   ```

### Android Configuration
1. Update AndroidManifest.xml:
   ```xml
   <queries>
       <package android:name="com.google.android.apps.maps" />
       <package android:name="com.waze" />
   </queries>
   ```

2. Add Waze Support:
   ```dart
   String generateWazeUrl(LatLng destination) {
     return 'waze://?ll=${destination.latitude},${destination.longitude}'
            '&navigate=yes';
   }
   ```

## Testing Plan

### Unit Tests
1. URL Generation Tests:
   - Test URL format for each navigation app
   - Test parameter encoding
   - Test edge cases (null coordinates)

2. Navigation Service Tests:
   - Test app availability checks
   - Test launch methods
   - Test error handling

### Integration Tests
1. Location Permission Tests:
   - Test permission request flow
   - Test permission denial handling
   - Test location service status

2. Navigation Flow Tests:
   - Test marker tap to navigation
   - Test list item navigation
   - Test app switching behavior

### Manual Testing Checklist
- [ ] Test on iOS devices
- [ ] Test on Android devices
- [ ] Test with Google Maps installed/not installed
- [ ] Test with Waze installed/not installed
- [ ] Test with different permission scenarios
- [ ] Test in Arabic and English
- [ ] Test RTL layout
- [ ] Test offline behavior
- [ ] Test error scenarios

## Assets Required

### Images
1. Navigation App Icons:
   ```
   assets/
   ├── images/
   │   ├── google_maps_icon.png
   │   ├── apple_maps_icon.png
   │   └── waze_icon.png
   ```

### Localization
1. Add new strings to localization files:
   ```json
   {
     "navigation_title": "Navigate to Branch",
     "navigation_error": "Error starting navigation",
     "app_not_installed": "Navigation app not installed",
     "select_navigation_app": "Select Navigation App"
   }
   ```

## Error Handling

### Types of Errors to Handle
1. Location Errors:
   - Location services disabled
   - Permission denied
   - Timeout getting location

2. Navigation App Errors:
   - App not installed
   - Unable to launch app
   - Invalid coordinates

3. Network Errors:
   - Offline state
   - Failed to load map
   - Failed to get directions

### Error Messages
Implement user-friendly error messages in both Arabic and English:
```dart
Map<String, String> errorMessages = {
  'location_disabled': {
    'en': 'Please enable location services',
    'ar': 'يرجى تفعيل خدمة الموقع'
  },
  'app_not_installed': {
    'en': 'Navigation app not installed',
    'ar': 'تطبيق الملاحة غير مثبت'
  },
  // Add more error messages
};
```

### Recovery Strategies
1. Location Issues:
   - Prompt to enable location services
   - Offer manual address entry
   - Cache last known location

2. App Launch Issues:
   - Offer alternative navigation apps
   - Provide manual coordinates
   - Show directions in-app

3. Network Issues:
   - Cache offline map data
   - Store branch coordinates locally
   - Show offline warning

## Implementation Timeline

### Phase 1: Basic Navigation
- Setup dependencies
- Implement basic URL launching
- Add marker tap handling
- Duration: 1-2 days

### Phase 2: Enhanced Features
- Add bottom sheet UI
- Implement multiple navigation apps
- Add error handling
- Duration: 2-3 days

### Phase 3: Polish & Testing
- Add animations
- Implement caching
- Comprehensive testing
- Duration: 2-3 days

## Maintenance Considerations

### Version Updates
- Monitor dependency updates
- Test with new iOS/Android versions
- Update API keys and certificates

### Performance Monitoring
- Track navigation success rate
- Monitor error frequencies
- Measure user engagement

### Security
- Secure API keys
- Handle user location data safely
- Implement proper URL sanitization

## Documentation

### Code Documentation
- Add detailed comments
- Create API documentation
- Document error codes

### User Documentation
- Create user guides
- Document troubleshooting steps
- Provide FAQ for common issues 