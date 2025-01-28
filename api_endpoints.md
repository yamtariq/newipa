# API Endpoints Documentation

## Base URLs
- Main API: `https://icreditdept.com/api`
- Auth API: `${apiBaseUrl}/auth`
- Nafath API: `https://api.nayifat.com/nafath/api/Nafath`

## Authentication & User Management
| Endpoint | Usage Location |
|----------|---------------|
| `/signin.php` | `auth_service.dart` |
| `/refresh_token.php` | `auth_service.dart` |
| `/otp_generate.php` | - `auth_service.dart`<br>- `registration_service.dart`<br>- `forget_password_screen.dart`<br>- `forget_mpin_screen.dart` |
| `/otp_verification.php` | - `auth_service.dart`<br>- `registration_service.dart`<br>- `forget_password_screen.dart`<br>- `forget_mpin_screen.dart` |
| `/password_change.php` | `forget_password_screen.dart` |

## Device Management
| Endpoint | Usage Location |
|----------|---------------|
| `/register_device.php` | - `auth_service.dart`<br>- `notification_service.dart` |

## Applications
| Endpoint | Usage Location |
|----------|---------------|
| `/user_registration.php` | `registration_service.dart` |
| `/get_gov_services.php` | `registration_service.dart` |
| `/loan_decision.php` | `loan_service.dart` |
| `/update_loan_application.php` | - `loan_service.dart`<br>- `application_landing_screen.dart` |
| `/cards_decision.php` | `card_service.dart` |
| `/update_cards_application.php` | - `card_service.dart`<br>- `application_landing_screen.dart` |

## Notifications
| Endpoint | Usage Location |
|----------|---------------|
| `/get_notifications.php` | `notification_service.dart` |
| `/send_notification.php` | `notification_service.dart` |

## Content Management
### Master Fetch Endpoint
- Base endpoint: `/master_fetch.php` (Used in `content_update_service.dart`)
  
Query Parameters:
- Loan ads: `page=loans&key_name=loan_ad`
- Card ads: `page=cards&key_name=card_ad`
- Slides: `page=home&key_name=slideshow_content`
- Arabic slides: `page=home&key_name=slideshow_content_ar`
- Contact details: `page=home&key_name=contact_details`
- Arabic contact details: `page=home&key_name=contact_details_ar`

## Nafath Service
| Endpoint | Usage Location |
|----------|---------------|
| `/CreateRequest` | `nafath_service.dart` |
| `/RequestStatus` | `nafath_service.dart` |

## Headers
All endpoints require appropriate headers:
```dart
{
  'Accept': 'application/json',
  'api-key': '7ca7427b418bdbd0b3b23d7debf69bf7',
  'Content-Type': 'application/json'
}
```

Additional headers based on endpoint type:
- Auth endpoints: `'X-Feature': 'auth'`
- Device endpoints: `'X-Feature': 'device'`
- User endpoints: `'X-Feature': 'user'` 

## PHP to ASP.NET Migration Plan

### Project Setup ✅
1. Created new ASP.NET 9 Web API project
   - Simple, minimal API approach
   - Single project structure
   - MySQL.Data NuGet package for database connectivity
   - JWT Bearer authentication package

### Core Components ✅
1. Database
   - Created DatabaseService for MySQL connections
   - Implemented timezone handling (Asia/Riyadh)
   - Added connection string configuration

2. Authentication & Headers
   - Implemented ApiKeyMiddleware for API key validation
   - Implemented FeatureHeaderMiddleware for X-Feature headers
   - Added CORS configuration

3. Response Format
   - Created ApiResponse<T> model
   - Standardized error responses
   - Matched PHP response structure

### Migration Progress

#### Phase 1: Foundation ✅
- [x] Project creation
- [x] MySQL connection setup
- [x] Header middleware
- [x] Base response models
- [x] Error handling

#### Phase 2: Auth Endpoints ✅
- [x] signin
- [x] refresh_token
- [x] otp_generate
- [x] otp_verification
- [x] password_change
- [x] register_device
- [x] user_registration

#### Phase 3: Application Endpoints ✅
- [x] loan_decision
- [x] update_loan_application
- [x] cards_decision
- [x] update_cards_application
- [x] get_gov_services

#### Phase 4: Content Management ✅
- [x] master_fetch
   * Created Models/MasterFetchModels.cs
   * Created Services/ContentService.cs
   * Created Controllers/ContentController.cs
   * Implemented exact PHP matching:
     - Same route (master_fetch)
     - Same query parameters (action=checkupdate|fetchdata)
     - Same database queries
     - Same response format
     - Same error handling
   * Added improvements:
     - Memory caching (5-minute duration)
     - Structured logging
     - JSON validation
     - Strong typing
     - Async operations
   * Tested all scenarios:
     - checkupdate action
     - fetchdata action
     - Error cases
     - Cache behavior
     - Cross-platform compatibility

#### Phase 5: Notification Endpoints (Next Up 👉)
- [ ] get_notifications
   * Plan:
     - Create notification models
     - Implement notification service
     - Add notification controller
     - Match PHP validation and error handling
     - Add proper logging and caching

- [ ] send_notification
   * Plan:
     - Create notification sending models
     - Add FCM integration
     - Implement notification sending service
     - Add proper error handling and retries
     - Match PHP functionality exactly

### Testing Checklist
- [x] Headers validation
- [x] Base response format
- [x] Auth flow
- [x] Database operations
- [x] File operations
- [x] Content management
- [ ] Notification handling

### Next Steps
1. Create Models for get_notifications endpoint
2. Implement notification fetching functionality
3. Add FCM integration for send_notification
4. Test against PHP version responses
5. Get verification before proceeding

### Current Status
✅ Signin endpoint complete and tested
✅ Refresh token endpoint complete and tested
✅ OTP generate endpoint complete and tested
✅ OTP verification endpoint complete and tested
✅ Password change endpoint complete and tested
✅ User registration endpoint complete and tested
✅ Device registration endpoint complete and tested
✅ Loan decision endpoint complete and tested
✅ Update loan application endpoint complete and tested
✅ Card decision endpoint complete and tested
✅ Update cards application endpoint complete and tested
✅ Get government services endpoint complete and tested
👉 Master fetch endpoint next 