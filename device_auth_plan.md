# Device Authentication and Registration Plan

## Overview
This document outlines the implementation plan for device-based authentication and registration in the Nayifat app.

## Core Principles ✅
1. One device can only be registered to one user (National ID)
2. One user can only have one device registered
3. Device registration persists until explicitly replaced
4. Biometric setup can be skipped and enabled later
5. Session management controls UI state

## Frontend Implementation

### 1. Auth Service Changes (`lib/services/auth_service.dart`) ✅

#### New Methods ✅
- `signOff()`
  ```dart
  - Clear current session token only
  - Keep device registration intact
  - Keep MPIN and biometric settings intact
  ```

- `getFirstName(String fullName)`
  ```dart
  - Extract first name from full name (before first space)
  - Handle both English and Arabic names
  ```

#### Modified Methods ✅
- Session State Methods
  ```dart
  - isSessionActive()
  - isDeviceRegistered()
  - getRegisteredUserName()
  ```

### 2. Device Management (`lib/services/auth_service.dart`) ✅
- Device Registration Check Methods
  ```dart
  - checkDeviceRegistration()
  - isDeviceRegisteredToUser()
  - replaceDevice()
  ```

### 3. Sign In Screen Updates (`lib/screens/auth/sign_in_screen.dart`) ✅
- Authentication Flow Updates
  ```dart
  1. Password Authentication:
     - Check device registration status
     - Handle device mismatch scenarios
     - Manage device replacement flow
  
  2. Biometric Authentication:
     - Verify device registration to user
     - Handle session activation
     - Update storage with registration data
  
  3. MPIN Authentication:
     - Verify device registration to user
     - Handle session activation
     - Update storage with registration data
  ```

### 4. UI Changes ✅

#### Main Page (`lib/screens/main_page.dart`) ✅
1. Device Registered with Active Session:
   ```dart
   - Show first name instead of "Guest"
   - Show only "Sign Off" button
   ```
2. Device Registered with Inactive Session:
   ```dart
   - Show first name instead of "Guest" (device still registered to this user)
   - Show "Sign In" button (quick access via bio/MPIN)
   - Show "Sign Out Device" button (completely unregister device)
   ```
3. Unregistered Device (Initial/After Device Sign Out):
   ```dart
   - Show "Guest"
   - Show "Sign In" button (full authentication required)
   - Show "Register" button
   ```

### 5. Storage Implementation ✅
```dart
- 'auth_token': Session token
- 'user_data': User information including name
- 'device_id': Current device ID
- 'device_registered': Boolean flag
- 'device_user_id': National ID of registered user
- 'biometrics_enabled': Boolean flag
- 'mpin_set': Boolean flag
- 'session_active': Boolean flag
```

### 6. Session Management ✅
1. Active Session (Device Registered)
2. Inactive Session (Device Registered)
3. Unregistered Device

## Implementation Phases

### Phase 1: Core Authentication ✅
1. Implement session management
2. Add device sign out functionality
3. Update storage implementation
4. Modify sign-in flows

### Phase 2: Device Management ✅
1. Implement device registration checks
2. Add device replacement flow
3. Update sign-in screen with registration checks
4. Update navigation flows

### Phase 3: UI Updates ✅
1. Update MainPage UI states ✅
2. Implement new dialogs ✅
3. Fix navigation flows ✅

### Phase 4: Testing (Current Phase) 🔄
1. Test device registration scenarios
2. Test session management
3. Test UI state changes
4. Test navigation flows 