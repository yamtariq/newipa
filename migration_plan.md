# Nayifat App - PHP to ASP.NET Migration Plan

## Environment Details
- **ASP.NET API Server**: `localhost:5264`
- **Database**: MSSQL (localhost)
- **Current PHP Base URL**: `https://icreditdept.com/api`
- **New ASP.NET Base URL**: `http://localhost:5264/api`

## Phase 1: Core Features Migration

### 1. Initial Setup ✅
- [x] Verify ASP.NET API is running on localhost:5264
- [x] Test database connectivity
- [x] Run basic health check endpoint
```powershell
curl http://localhost:5264/api/health
```

### 2. Constants Update ✅
- [x] Backup current constants.dart
```powershell
copy lib/utils/constants.dart lib/utils/constants.dart.bak
```

- [x] Add feature flag to constants.dart
```dart
static const bool useNewApi = true;
static String get currentApiBaseUrl => 
    useNewApi ? 'http://localhost:5264/api' : 'https://icreditdept.com/api';
```

- [x] Update core endpoints in constants.dart
```dart
// Authentication
static const String endpointSignIn = '/auth/signin';
static const String endpointRefreshToken = '/auth/refresh';
static const String endpointOTPGenerate = '/auth/otp/generate';
static const String endpointOTPVerification = '/auth/otp/verify';
static const String endpointPasswordChange = '/auth/password';

// Device Management
static const String endpointRegisterDevice = '/device';

// Content Management
static const String masterFetchUrl = '/content/fetch';
```

### 3. Authentication Testing ✅
- [x] Test signin endpoint
  - [x] Test with valid credentials
  - [x] Test with invalid credentials
  - [x] Verify error handling

- [x] Test OTP flow
  - [x] Generate OTP
    - [x] Verified successful OTP generation with proper JSON response
    - [x] Tested with required headers (Authorization, X-APP-ID, X-API-KEY, X-Organization-No)
    - [x] Confirmed response includes nationalId, OTP code, and expiryDate
    - [x] Implemented rotating logo loading overlay during OTP generation
    - [x] Added proper loading state management for OTP resend
    - [x] Fixed phone number format to include 966 prefix
    - [x] Updated to use proxy endpoint for testing
    - [x] Centralized OTP endpoints in constants.dart
    - [x] Implemented standardized request/response format
  - [x] Verify OTP
    - [x] Successfully verified valid OTP codes
    - [x] Tested invalid OTP handling
    - [x] Confirmed proper response format for both success and failure cases
    - [x] Added loading states for verification process
    - [x] Centralized OTP verification in constants.dart
  - [x] Test expiry scenarios

Implementation Details:
```json
// OTP Generation Request Format (Centralized in Constants)
static Map<String, dynamic> otpGenerateRequestBody(String nationalId, String mobileNo) => {
    "nationalId": nationalId,
    "mobileNo": mobileNo,
    "purpose": "REGISTRATION",
    "userId": 1
}

// OTP Verification Request Format (Centralized in Constants)
static Map<String, dynamic> otpVerifyRequestBody(String nationalId, String otp) => {
    "nationalId": nationalId.trim(),
    "otp": otp.trim(),
    "userId": 1
}

// OTP Generation Response
{
    "success": true,
    "errors": [],
    "result": {
        "nationalId": "1064448614",
        "otp": 296460,
        "expiryDate": "2025-02-01 18:04:09",
        "successMsg": "Success",
        "errCode": 0,
        "errMsg": null
    },
    "type": "N"
}
```

Headers (Centralized in Constants):
```dart
static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'x-api-key': apiKey
}
```

Endpoints (Centralized in Constants):
```dart
static const String proxyBaseUrl = 'https://icreditdept.com/api/testasp';
static String get proxyOtpGenerateUrl => '$proxyBaseUrl/test_local_generate_otp.php';
static String get proxyOtpVerifyUrl => '$proxyBaseUrl/test_local_verify_otp.php';
```

- [ ] Test token refresh
  - [x] Verify token refresh endpoint is properly configured (/auth/refresh)
  - [x] Test successful token refresh flow
    - [x] Sign in to get initial tokens
    - [x] Wait for access token to expire
    - [x] Attempt refresh with valid refresh token
    - [x] Verify new tokens are received and stored
  - [x] Test error scenarios
    - [x] Invalid refresh token
    - [x] Expired refresh token
    - [x] Missing refresh token
  - [x] Test automatic refresh mechanism
    - [x] Verify app automatically refreshes token on 401 responses
    - [x] Check proper token storage in secure storage
  - [x] Cross-platform verification
    - [x] Test on Android
    - [x] Test on iOS

  Implementation Details:
  ```
  Endpoint: POST http://localhost:5264/api/auth/refresh
  Headers:
    Content-Type: application/json
    X-APP-ID: NAYIFAT_APP
    X-API-KEY: 7ca7427b418bdbd0b3b23d7debf69bf7
    X-Organization-No: 1
    X-Feature: auth
  
  Request Body:
  {
      "sessionToken": "<current_session_token>",
      "nationalId": "<user_national_id>"
  }
  
  Response Format:
  {
      "success": true,
      "data": {
          "session_token": "<new_session_token>"
      }
  }
  ```
### 4. Device Management Testing ✅
- [x] Test device registration
  - [x] Register new device
  - [x] Verify previous devices are disabled
  - [x] Test error scenarios

### 5. Content Management Testing ✅
- [x] Test content fetch
  - [x] Fetch slides
  - [x] Fetch contact details
  - [x] Test both Arabic and English content

### 6. Notifications System Testing ✅
- [x] Test notification sending
  - [x] Verify Arabic text handling
  - [x] Test table-based filtering (e.g. Customers.City)
  - [x] Test BETWEEN operator for numeric ranges
  - [x] Verify proper character encoding
  Implementation Details:
  ```
  Endpoint: POST http://localhost:5264/api/notifications/send
  Headers:
    Content-Type: application/json
    X-APP-ID: NAYIFAT_APP
    X-API-KEY: 7ca7427b418bdbd0b3b23d7debf69bf7
    X-Organization-No: 1
  
  Request Body:
  {
      "title_ar": "عنوان الإشعار",
      "title_en": "Notification Title",
      "body_ar": "محتوى الإشعار",
      "body_en": "Notification Content",
      "type": "general",
      "filters": [
          {
              "key": "Customers.City",
              "operator": "=",
              "value": "Riyadh"
          },
          {
              "key": "Customers.SalaryDakhli",
              "operator": "BETWEEN",
              "value": [5000, 10000]
          }
      ]
  }
  ```

- [x] Test notification retrieval
  - [x] Verify pagination
  - [x] Test read status tracking
  - [x] Verify Arabic content display
  Implementation Details:
  ```
  Endpoint: POST http://localhost:5264/api/notifications/list
  Headers:
    Content-Type: application/json
    X-APP-ID: NAYIFAT_APP
    X-API-KEY: 7ca7427b418bdbd0b3b23d7debf69bf7
    X-Organization-No: 1
  
  Request Body:
  {
      "nationalId": "1234567890",
      "markAsRead": true
  }

  Response Format:
  {
      "success": true,
      "data": {
          "notifications": [
              {
                  "id": 123,
                  "title": "Notification Title",
                  "body": "Notification Content",
                  "title_en": "Notification Title",
                  "body_en": "Notification Content",
                  "title_ar": "عنوان الإشعار",
                  "body_ar": "محتوى الإشعار",
                  "route": "home",
                  "additional_data": {},
                  "created_at": "2024-03-20T10:00:00Z",
                  "expires_at": "2024-04-19T10:00:00Z",
                  "status": "unread"
              }
          ]
      }
  }
  ```

Features:
- Automatic expiry handling
- Multi-language support (Arabic/English)
- Read status tracking
- Additional data support
- Route specification for deep linking
- Audit logging for all operations
- Automatic cleanup of old notifications (max 50 per user)
- Transaction support for updates

### 7. Database Schema Updates ✅
- [x] Update notification_templates table
  - [x] Change body_ar to nvarchar(max)
  - [x] Verify Arabic text storage
  - [x] Test long content handling

### 8. Remaining Core Endpoints Testing ✅
- [x] Test validate identity endpoint
  - [x] Updated to use /Registration/register endpoint
  - [x] Added deviceInfo requirement
  - [x] Implemented checkOnly parameter for ID availability
  - [x] Enhanced error handling and logging
  - [x] Fixed 404 and 415 errors
- [x] Test set password endpoint
  - [x] Password change functionality implemented
  - [x] Proper password hashing in place
- [x] Test user registration flow
  - [x] Full registration process implemented
  - [x] Supports both English and Arabic names
  - [x] Includes device registration
  - [x] Proper validation and error handling
  - [x] Fixed request body format issues
  - [x] Added detailed logging for troubleshooting

### 9. Cross-Platform Verification (Priority)
- [ ] Test on Android
  - [ ] Emulator testing
    - [ ] Test all authentication flows
    - [ ] Test registration process
    - [ ] Test device management
    - [ ] Test notifications
  - [ ] Physical device testing
    - [ ] Test on at least 2 different Android versions
    - [ ] Verify biometric functionality
    - [ ] Test push notifications
- [ ] Test on iOS
  - [ ] Simulator testing
    - [ ] Test all authentication flows
    - [ ] Test registration process
    - [ ] Test device management
    - [ ] Test notifications
  - [ ] Physical device testing
    - [ ] Test on latest iOS version
    - [ ] Verify biometric functionality
    - [ ] Test push notifications

## Phase 2: Business Features (Future)

### 1. Loan Application (Planned)
- [ ] Update loan endpoints
- [ ] Test loan application flow
- [ ] Verify loan status updates

### 2. Card Application (Planned)
- [ ] Update card endpoints
- [ ] Test card application flow
- [ ] Verify card status updates

## Monitoring & Validation

### 1. Error Monitoring
- [ ] Set up error logging
- [ ] Monitor API response times
- [ ] Track error rates

### 2. Performance Validation
- [ ] Compare response times with old API
- [ ] Verify memory usage
- [ ] Check database performance

## Rollback Procedures

### Quick Rollback ✅
- [x] Prepare rollback script
```powershell
copy lib/utils/constants.dart.bak lib/utils/constants.dart
```

### Feature Flag Rollback ✅
- [x] Test feature flag switching
```dart
// In constants.dart
static const bool useNewApi = false;
```

## Final Verification

### 1. Security Checks
- [x] Verify API key implementation
- [ ] Check token security
- [x] Validate headers
  - [x] Authorization header working correctly
  - [x] X-APP-ID header validated
  - [x] X-API-KEY header validated
  - [x] X-Organization-No header validated

### 2. User Experience
- [ ] Verify app responsiveness
- [ ] Check error messages
- [ ] Test offline behavior

### 3. Documentation
- [ ] Update API documentation
- [ ] Document new endpoints
- [ ] Update testing procedures

## Notes
- Keep PHP endpoints as backup until migration is fully tested
- Test each endpoint thoroughly before moving to the next
- Document any issues or deviations from the plan
- Maintain communication with the backend team for any adjustments needed

## Notification System Time Zone Migration Plan

### Overview
Migration of the notification system from UTC to Saudi Arabia Time (Arab Standard Time / UTC+3)

### Changes Implemented
1. **NotificationsController.cs Updates**
   - Modified all `DateTime.UtcNow` instances to use Saudi Arabia time
   - Implemented using `TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time"))`

### Modified Timestamps
- Current time calculations
- Notification delivery timestamps
- Read status timestamps
- Database update timestamps
- Template creation and expiry dates
- Notification reference creation times

### Affected Operations
- Getting notifications list
- Marking notifications as read
- Sending new notifications
- Creating notification templates
- Updating user notification records

### Testing Points
- [x] Verify correct time display in notifications list
- [x] Confirm expiry calculations work with Saudi time
- [x] Test notification delivery timestamps
- [x] Validate read status time tracking
- [x] Check template creation times

### Notes
- All timestamps are now consistently in Saudi Arabia time (UTC+3)
- No database schema changes required
- Existing UTC timestamps will be displayed in Saudi time when retrieved 