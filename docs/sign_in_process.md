# Sign-In Process Documentation

## Normal Flow
1. User enters National ID
2. System checks if quick sign-in is available:
   - If yes: Proceeds to biometric/MPIN verification
   - If no: Requires password entry

3. After successful authentication:
   - If password mode and (device not registered or MPIN not set): Redirects to MPIN setup screen
   - Otherwise: Redirects to main page

## API Response Codes

### Success Responses

#### Normal Sign-in Success
```json
{
  "status": "success",
  "code": "SUCCESS",
  "user": {
    // User data object
  },
  "requires_mpin_setup": boolean,
  "is_device_registered": boolean
}
```

#### Quick Sign-in Success (MPIN/Biometric)
```json
{
  "status": "success",
  "code": "SUCCESS",
  "user": {
    // User data object
  }
}
```

### Error Codes
1. `DEVICE_REGISTERED_TO_OTHER`
   - Meaning: Current device is registered to another user
   - Response includes: `existing_device` information
   - Action: Shows device replacement dialog

2. `DEVICE_NOT_REGISTERED`
   - Meaning: Device not registered for this user
   - Response includes: `existing_device` if user has another device
   - Actions:
     - If `existing_device` exists: Shows device replacement dialog
     - If no `existing_device`: Shows device registration dialog

3. `REQUIRES_DEVICE_REPLACEMENT`
   - Meaning: Device needs to be replaced
   - Action: Shows device mismatch dialog

4. `USER_NOT_FOUND`
   - Meaning: National ID not registered in system
   - Action: Shows error snackbar in Arabic/English

5. `INVALID_PASSWORD`
   - Meaning: Incorrect password entered
   - Action: Shows error snackbar in Arabic/English

6. `INVALID_MPIN`
   - Meaning: Incorrect MPIN entered
   - Action: Shows error snackbar in Arabic/English

7. `BIOMETRIC_VERIFICATION_FAILED`
   - Meaning: Biometric verification failed
   - Action: Shows error snackbar and falls back to MPIN entry

## Device Registration States

1. **New Device Registration**
   - Triggered when: No existing device for user
   - Flow: Sign-in → Device registration dialog → MPIN setup

2. **Device Replacement**
   - Triggered when: User has existing device
   - Flow: Sign-in → Device replacement confirmation → MPIN setup

3. **Registered Device**
   - Allows quick sign-in with MPIN/biometrics
   - Stores device information securely

## Error Handling
- All API calls wrapped in try-catch blocks
- Network errors show generic error message
- Language-aware error messages (Arabic/English)
- Proper state management with `mounted` checks

## Navigation Flows

1. **New User Flow**
   ```
   Sign-in with password → Device Registration → MPIN Setup → Main Page
   ```

2. **Existing User (New Device)**
   ```
   Sign-in with password → Device Replacement → MPIN Setup → Main Page
   ```

3. **Quick Sign-in Flow**
   ```
   Sign-in → Biometric/MPIN Verification → Main Page
   ```

## Security Considerations
- Device information stored securely
- MPIN/Biometric data handled securely
- Session management
- Proper error handling for security-related responses

## Implementation Details

### Key Files
- `lib/screens/auth/sign_in_screen.dart`: Main sign-in screen implementation
- `lib/screens/auth/mpin_setup_screen.dart`: MPIN setup implementation
- `lib/screens/registration/biometric_setup_screen.dart`: Biometric setup implementation
- `lib/services/auth_service.dart`: Authentication service implementation

### Important Methods
- `_handleSignInResponse`: Handles the sign-in API response and navigation
- `_handleDeviceMismatch`: Handles device replacement scenarios
- `_showDeviceRegistrationDialog`: Handles new device registration
- `_handleMPINSetup`: Manages MPIN setup process

### State Management
- Uses Flutter's built-in state management
- Maintains proper lifecycle management
- Handles configuration changes appropriately

## Debugging Tips
1. Check API response codes for specific error scenarios
2. Verify device registration status in secure storage
3. Monitor biometric availability and status
4. Check MPIN setup state before navigation
5. Verify proper error message localization 