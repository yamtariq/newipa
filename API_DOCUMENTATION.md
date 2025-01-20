# API Documentation

## API Standards and Guidelines

### 1. Centralized Configuration
All API-related configurations are centralized in `lib/utils/constants.dart`. This includes:
- Base URLs
- API Endpoints
- Headers
- API Keys

### 2. Endpoint Management
- All endpoints must be defined in `constants.dart` as static constants
- Each endpoint must include a comment documenting:
  - Which service uses it
  - Which file it's located in
  - Which methods/functions use it
- Example:
  ```dart
  static const String masterFetchUrl = '$apiBaseUrl/master_fetch.php';
  // Used in: ContentUpdateService (content_update_service.dart) - For fetching all dynamic content:
  // - Loan ads: page=loans&key_name=loan_ad
  // - Card ads: page=cards&key_name=card_ad
  // - Slides: page=home&key_name=slideshow_content
  // - Contact details: page=home&key_name=contact_details
  ```

### 3. Header Management
- All headers are defined in `constants.dart`
- Base headers are defined in `defaultHeaders`
- Feature-specific headers extend `defaultHeaders`
- Current header types:
  ```dart
  defaultHeaders  // Base headers for general API calls
  authHeaders    // Authentication-related endpoints
  deviceHeaders  // Device management endpoints
  userHeaders    // User data endpoints
  ```
- If a new header type is needed, it must be added to `constants.dart`

### 4. Implementation Rules
1. **No Hardcoded URLs**: All API calls must use endpoints defined in `constants.dart`
2. **Appropriate Headers**: Use the correct feature-specific headers for each endpoint
3. **Documentation**: When adding new endpoints or services, update the comments in `constants.dart`
4. **Consistency**: Follow the established naming patterns for new endpoints

## Current Implementation

### Base URLs
```dart
apiBaseUrl = 'https://icreditdept.com/api'
authBaseUrl = '$apiBaseUrl/auth'
masterFetchUrl = '$apiBaseUrl/master_fetch.php'  // Used for all dynamic content
```

### Native Code Constants
**TODO Before Production**: The following API constants are currently hardcoded in native code and need to be synchronized with `constants.dart`:
- `NotificationWorker.kt`:
  ```kotlin
  private const val BASE_URL = "https://icreditdept.com/api"
  private const val API_KEY = "7ca7427b418bdbd0b3b23d7debf69bf7"
  ```
Consider implementing a build-time solution or using platform channels to maintain these values in a single source.

### TODO: Branch Service Configuration
The branch service (`lib/services/branch_service.dart`) currently uses mock data for development. Before production:
- Configure proper branch API endpoint in `constants.dart`
- Update `BranchService` to use the configured endpoint
- Implement proper error handling and data validation

### Authentication Endpoints
- `/signin.php` - User sign-in and authentication
  - Uses: `authHeaders`
- `/refresh_token.php` - Token refresh
  - Uses: `authHeaders`
- `/verify_credentials.php` - Credential verification
  - Uses: `authHeaders`
- `/otp_generate.php` - OTP generation
  - Uses: `authFormHeaders` (form data)
- `/otp_verification.php` - OTP verification
  - Uses: `authFormHeaders` (form data)
- `/password_change.php` - Password change
  - Uses: `authHeaders`

### Device Management Endpoints
- `/check_device_registration.php` - Check device registration status
  - Uses: `deviceHeaders`
- `/register_device.php` - Register new device
  - Uses: `deviceHeaders`
- `/unregister_device.php` - Unregister device
  - Uses: `deviceHeaders`
- `/replace_device.php` - Replace existing device
  - Uses: `deviceHeaders`

### User Management Endpoints
- `/user_registration.php` - User registration
  - Uses: `userHeaders`
- `/get_gov_services.php` - Get government data
  - Uses: `userHeaders`

### Loan Management Endpoints
- `/loan_decision.php` - Get loan decision based on user financial data
  - Uses: `defaultHeaders`
  - Accepts: salary, liabilities, expenses, requested_tenure
  - Returns: loan decision with approved amount and terms
- `/update_loan_application.php` - Update loan application status and details
  - Uses: `defaultHeaders`
  - Accepts: loan application data
  - Returns: updated application status

### Card Management Endpoints
- `/cards_decision.php` - Get credit card decision based on user financial data
  - Uses: `defaultHeaders`
  - Accepts: salary, liabilities, expenses
  - Returns: card decision with credit limit and card type (GOLD/REWARD)
- `/update_cards_application.php` - Update card application status and details
  - Uses: `defaultHeaders`
  - Accepts: card application data
  - Returns: updated application status

### Auth-specific Endpoints
- `/validate-identity` - Identity validation
  - Uses: `authHeaders`
- `/set-password` - Password setup
  - Uses: `authHeaders`
- `/set-quick-access-pin` - PIN setup
  - Uses: `authHeaders`
- `/verify-otp` - OTP verification
  - Uses: `authHeaders`
- `/resend-otp` - OTP resend
  - Uses: `authHeaders`

### Headers Structure

#### Content Types
The API supports two content types:
- JSON: `application/json` (default)
- Form Data: `application/x-www-form-urlencoded` (for specific endpoints)

#### Headers Configuration
```dart
defaultHeaders = {
  'Content-Type': 'application/json',  // Changes to 'application/x-www-form-urlencoded' for form data
  'Accept': 'application/json',
  'api-key': apiKey,
}

// JSON Headers (Default)
authHeaders = {
  ...defaultHeaders,
  'X-Feature': 'auth',
}

// Form Data Headers (For specific endpoints like OTP)
authFormHeaders = {
  ...defaultHeaders,
  'Content-Type': 'application/x-www-form-urlencoded',
  'X-Feature': 'auth',
}

deviceHeaders = {
  ...defaultHeaders,
  'X-Feature': 'device',
}

userHeaders = {
  ...defaultHeaders,
  'X-Feature': 'user',
}
```

Note: Some endpoints (like OTP generation) require form data instead of JSON. For these endpoints, use the appropriate form headers version.

## Services Using API
Currently implemented in:
1. `auth_service.dart`
   - Handles authentication, device management, and user registration
   - Header Usage:
     - `authHeaders`: For authentication operations (sign-in, password change)
     - `deviceHeaders`: For device management operations
     - `userHeaders`: For user data operations
     - `authFormHeaders`: For OTP operations (generate, verify)

2. `api_service.dart`
   - Handles general API calls and auth-specific endpoints
   - Header Usage:
     - `defaultHeaders`: For general API calls (slides, contact details)
     - `authHeaders`: For auth-specific operations

3. `registration_service.dart`
   - Handles user registration flow and identity verification
   - Header Usage:
     - `authHeaders`: For identity validation, password setup, MPIN setup
     - `authFormHeaders`: For OTP operations (generate, verify)
     - `userHeaders`: For user registration and government data retrieval

4. `loan_service.dart`
   - Handles loan decisions and application updates
   - Header Usage:
     - `defaultHeaders`: For all loan-related operations (decisions, updates)
   - Key Features:
     - Loan decision calculation based on user financial data
     - Loan application status updates
     - Mock data for development (getUserLoans, getCurrentApplicationStatus)

5. `card_service.dart`
   - Handles credit card decisions and application updates
   - Header Usage:
     - `defaultHeaders`: For all card-related operations (decisions, updates)
   - Key Features:
     - Card decision calculation based on user financial data
     - Card type determination (GOLD/REWARD) based on credit limit
     - Mock data for development (getUserCards, getCurrentApplicationStatus)

### Registration Flow Endpoints
The registration service uses the following endpoints:
- `/validate-identity` - Validate user identity with ID and phone
  - Uses: `authHeaders`
- `/otp_generate.php` - Generate OTP for verification
  - Uses: `authFormHeaders` (form data)
- `/otp_verification.php` - Verify OTP code
  - Uses: `authFormHeaders` (form data)
- `/set-password` - Set user password
  - Uses: `authHeaders`
- `/set-quick-access-pin` - Set user MPIN
  - Uses: `authHeaders`
- `/user_registration.php` - Check registration status and complete registration
  - Uses: `userHeaders`
- `/get_gov_services.php` - Retrieve government data for user
  - Uses: `userHeaders`

Note: Some endpoints (like OTP generation/verification) require form data instead of JSON. For these endpoints, use the appropriate form headers version (`authFormHeaders`).

## Adding New API Functionality
When adding new API functionality:
1. Add the endpoint to `constants.dart`
2. Add appropriate comments documenting usage
3. Use the correct feature-specific headers
4. Update this documentation if adding new types of endpoints or headers

## Error Handling
All API calls should include:
1. Proper error handling with try-catch blocks
2. Meaningful error messages
3. Appropriate status code handling
4. Timeout handling where necessary

## Notification Endpoints

### Get Notifications
- **Endpoint**: `GET /get_notifications.php`
- **Headers**: Uses `Constants.defaultHeaders`
- **Purpose**: Fetches notifications for a specific user
- **Used by**: `NotificationService.fetchNotifications()`
- **Request Body**:
  ```json
  {
    "national_id": "string",
    "mark_as_read": boolean
  }
  ```
- **Response**: List of notifications with titles and bodies in both English and Arabic

### Send Notification
- **Endpoint**: `POST /send_notification.php`
- **Headers**: Uses `Constants.defaultHeaders`
- **Purpose**: Sends notifications to specific users or groups
- **Used by**: `NotificationService.sendNotification()`
- **Request Body**:
  ```json
  {
    "national_id": "string",          // Optional: Send to single user
    "national_ids": ["string"],       // Optional: Send to multiple users
    "filters": {                      // Optional: Send based on filters
      "salary_range": {
        "min": number,
        "max": number
      },
      "employment_status": "string",
      "employer_name": "string",
      "language": "string"
    },
    "title": "string",
    "body": "string",
    "route": "string",               // Optional: Navigation route
    "isArabic": boolean,            // Optional: Language flag
    "additionalData": object        // Optional: Extra data
  }
  ```

### Register Device
- **Endpoint**: `POST /register-device`
- **Headers**: Uses `Constants.defaultHeaders`
- **Purpose**: Registers a device for push notifications
- **Used by**: `NotificationService.registerDevice()`
- **Request Body**:
  ```json
  {
    "user_id": "string",
    "device_token": "string",
    "platform": "string"  // "android" or "ios"
  }
  ```

## Services Using API

### NotificationService (`notification_service.dart`)
- Uses `Constants.defaultHeaders` for all API calls
- Endpoints used:
  - `endpointGetNotifications`: For fetching user notifications
  - `endpointSendNotification`: For sending notifications to users
  - `endpointRegisterDevice`: For registering devices for push notifications
- Features:
  - Background notification fetching
  - Multi-language support (Arabic/English)
  - Push notification handling
  - Device registration management

### Content Update System
The content update system uses `master_fetch.php` for all dynamic content:

#### Master Fetch Endpoint
- **Endpoint**: `GET /master_fetch.php`
- **Headers**: Uses `Constants.defaultHeaders`
- **Purpose**: Fetches dynamic content based on page and key parameters
- **Used by**: `ContentUpdateService.checkAndUpdateContent()`
- **Query Parameters**:
  ```
  page: string      // The page/section identifier
  key_name: string  // The specific content key to fetch
  ```
- **Response Format**:
  ```json
  {
    "success": boolean,
    "data": {
      // Content specific to the requested key
    },
    "message": "string"  // Optional status message
  }
  ```

#### Content Types and Keys
1. **Loan Advertisements**
   - Query: `page=loans&key_name=loan_ad`
   - Response data format:
     ```json
     {
       "image_url": "string",
       "title": "string",
       "description": "string"
     }
     ```

2. **Card Advertisements**
   - Query: `page=cards&key_name=card_ad`
   - Response data format:
     ```json
     {
       "image_url": "string",
       "title": "string",
       "description": "string",
       "card_type": "string",
       "benefits": ["string"]
     }
     ```

3. **Slideshow Content**
   - English: `page=home&key_name=slideshow_content`
   - Arabic: `page=home&key_name=slideshow_content_ar`
   - Response data format:
     ```json
     [{
       "id": "string",
       "imageUrl": "string",
       "leftTitle": "string",
       "rightTitle": "string",
       "link": "string"
     }]
     ```

4. **Contact Details**
   - English: `page=home&key_name=contact_details`
   - Arabic: `page=home&key_name=contact_details_ar`
   - Response data format:
     ```json
     {
       "phone": "string",
       "email": "string",
       "workHours": "string",
       "socialLinks": {
         "facebook": "string",
         "twitter": "string",
         "instagram": "string"
       }
     }
     ```

### Content Update Service
The `ContentUpdateService` (`lib/services/content_update_service.dart`) manages all dynamic content:
- Checks for updates periodically (every 3 hours by default)
- Caches content locally
- Provides fallback to static content
- Supports both English and Arabic content
- Handles binary content (images, animations)