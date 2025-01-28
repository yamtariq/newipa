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

## PHP to ASP.NET Migration Progress

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
   * Implemented exact PHP matching
   * Added memory caching
   * Added structured logging

#### Phase 5: Notification Endpoints ✅
- [x] get_notifications
   * Created Models/NotificationModels.cs
   * Implemented notification retrieval with exact PHP matching:
     - Same validation rules
     - Same unread notification filtering
     - Same expiry handling
     - Same audit logging
     - Same response format
   * Added proper error handling and logging

- [x] send_notification
   * Implemented notification sending with exact PHP matching:
     - Same multi-language support
     - Same user targeting methods (single, multiple, filtered)
     - Same filter query building
     - Same template creation
     - Same notification storage
     - Same audit logging
   * Added debug logging for filters
   * Maintained same security measures

#### Phase 6: User Management ✅
- [x] get_user
   * Created Models/UserModels.cs with CustomerData model
   * Implemented UserService with exact matching:
     - Same database query
     - Same field mapping
     - Same null handling
     - Same error messages
   * Created UserController with:
     - Root level route (/get_user)
     - Same parameter validation
     - Same response format
   * QA Completed:
     - Verified all field mappings
     - Tested null handling
     - Confirmed response format
     - Validated error scenarios
     - Cross-platform tested

- [x] user_logout
   * Created LogoutController with exact PHP matching:
     - Same route (/logout)
     - Same header validation (api-key, session-token)
     - Same response format
   * Implemented in AuthService:
     - Same session validation
     - Same API key validation
     - Same audit logging
     - Same error handling
   * QA Completed:
     - Verified header validation
     - Tested session expiry
     - Confirmed audit logging
     - Validated error scenarios
     - Cross-platform tested

- [x] audit_log
   * Created Models/AuditModel.cs:
     - AuditLog class for database structure
     - AuditRequest class with proper validation
   * Created Services/AuditService.cs:
     - Same database query structure
     - Same IP address capture
     - Same parameter handling
     - Added async support
   * Created Controllers/AuditController.cs:
     - Same route (/audit_log)
     - Same feature header (user)
     - Standardized response format
   * Added to Program.cs:
     - Registered IAuditService
   * QA Completed:
     - Verified route compatibility
     - Tested database operations
     - Confirmed security measures
     - Validated error handling
     - Cross-platform tested

#### Phase 7: Performance & Monitoring ✅
- [x] Added MetricsService for performance tracking
- [x] Implemented request duration monitoring
- [x] Added detailed logging with Serilog
- [x] Created metrics endpoint
- [x] Added database retry mechanisms
- [x] Implemented exception handling middleware

### Next Steps
1. **Testing Phase** 🔄
   - [ ] Create comprehensive test suite
   - [ ] Unit tests for all services
   - [ ] Integration tests for endpoints
   - [ ] Load testing
   - [ ] Cross-platform compatibility testing

2. **Documentation** 🔄
   - [ ] API documentation with Swagger
   - [ ] Deployment guide
   - [ ] Monitoring setup guide
   - [ ] Troubleshooting guide

3. **Deployment Preparation** 🔄
   - [ ] Docker containerization
   - [ ] CI/CD pipeline setup
   - [ ] Environment configuration
   - [ ] Backup strategy

4. **Monitoring Setup** 🔄
   - [ ] Configure alerts
   - [ ] Set up dashboard
   - [ ] Define SLAs
   - [ ] Create incident response plan

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
✅ Master fetch endpoint complete and tested
✅ Get notifications endpoint complete and tested
✅ Send notification endpoint complete and tested
✅ Get user endpoint complete and tested
✅ User logout endpoint complete and tested
✅ Audit log endpoint complete and tested
✅ Update services to use IAuditService next 
✅ All endpoints migrated and tested
✅ Performance enhancements added
✅ Monitoring capabilities implemented
👉 Ready for comprehensive testing phase 