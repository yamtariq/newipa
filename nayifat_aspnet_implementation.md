# Nayifat ASP.NET Core Implementation Guide

## Quick Start

1. Install prerequisites:
   - .NET 8.0 SDK
   - Visual Studio 2022 or VS Code
   - SQL Server 2019+

2. Create project:
   ```bash
   dotnet new webapi -n NayifatAPI
   cd NayifatAPI
   ```

3. Install required packages:
   ```bash
   dotnet add package Microsoft.EntityFrameworkCore.SqlServer
   dotnet add package Microsoft.EntityFrameworkCore.Tools
   dotnet add package BCrypt.Net-Next
   dotnet add package Serilog.AspNetCore
   ```

## Database Configuration

### Connection String
In `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.;Database=NayifatApp;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True"
  }
}
```

### Entity Framework Setup
In `Program.cs`:
```csharp
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
```

## Models

### Customer Model
```csharp
[Table("Customers")]
public class Customer
{
    [Key]
    public required string NationalId { get; set; }

    [Required]
    public required string FirstNameEn { get; set; }
    [Required]
    public required string SecondNameEn { get; set; }
    [Required]
    public required string ThirdNameEn { get; set; }
    [Required]
    public required string FamilyNameEn { get; set; }

    [Required]
    public required string FirstNameAr { get; set; }
    [Required]
    public required string SecondNameAr { get; set; }
    [Required]
    public required string ThirdNameAr { get; set; }
    [Required]
    public required string FamilyNameAr { get; set; }

    public DateTime? DateOfBirth { get; set; }
    public DateTime? IdExpiryDate { get; set; }

    [Required]
    [EmailAddress]
    public required string Email { get; set; }

    [Required]
    [Phone]
    public required string Phone { get; set; }

    // Address Information
    public string? BuildingNo { get; set; }
    public string? Street { get; set; }
    public string? District { get; set; }
    public string? City { get; set; }
    public string? Zipcode { get; set; }
    public string? AddNo { get; set; }

    // Financial Information
    public string? Iban { get; set; }
    public int? Dependents { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal? SalaryDakhli { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal? SalaryCustomer { get; set; }
    
    public int? Los { get; set; }

    // Employment Information
    public string? Sector { get; set; }
    public string? Employer { get; set; }

    // Security
    [Required]
    public required string Password { get; set; }
    public string? Mpin { get; set; }
    public bool MpinEnabled { get; set; }

    // Navigation Properties
    public virtual ICollection<CustomerDevice> Devices { get; set; } = new List<CustomerDevice>();
    public virtual ICollection<UserNotification> Notifications { get; set; } = new List<UserNotification>();
    public virtual ICollection<OtpCode> OtpCodes { get; set; } = new List<OtpCode>();
    public virtual ICollection<AuthLog> AuthLogs { get; set; } = new List<AuthLog>();
}
```

### MasterConfig Model
```csharp
[Table("master_config")]
[Index(nameof(Page), nameof(KeyName), IsUnique = true)]
public class MasterConfig
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public required string Page { get; set; }
    
    [Required]
    public required string KeyName { get; set; }
    
    [Required]
    [Column(TypeName = "nvarchar(max)")]
    public required string Value { get; set; }
    
    public required bool IsActive { get; set; } = true;
    
    public required DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    [NotMapped]
    public bool IsValid => !string.IsNullOrEmpty(Value) && IsActive;
}
```

## API Endpoints

### Config Controller

#### GET /api/config/page/{page}
Retrieves all active configurations for a specific page.

Request:
```http
GET /api/config/page/app
Headers:
  x-api-key: your-api-key
```

Response:
```json
{
  "success": true,
  "data": {
    "version": "1.0.0",
    "maintenance_mode": "false"
  }
}
```

#### POST /api/config
Creates or updates a configuration.

Request:
```http
POST /api/config
Headers:
  x-api-key: your-api-key
Content-Type: application/json
{
  "page": "app",
  "keyName": "version",
  "value": "1.0.0"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "page": "app",
    "keyName": "version",
    "value": "1.0.0",
    "isActive": true,
    "createdAt": "2025-01-29T19:22:24",
    "updatedAt": null
  }
}
```

### Registration Controller

#### POST /api/Registration/register
Registers a new user with device information or checks if an ID is already registered.

Request:
```http
POST /api/Registration/register
Headers:
  x-api-key: your-api-key
Content-Type: application/json
{
  "checkOnly": true,  // Set to true to only check ID availability
  "nationalId": "1234567890",
  "deviceInfo": {
    "deviceId": "test-device-1",
    "platform": "Android",
    "model": "Pixel 6",
    "manufacturer": "Google"
  }
}
```

Response:
```json
{
  "success": true,
  "data": {
    "message": "ID available"
  }
}
```

#### POST /api/Registration/generate-otp
Generates an OTP for the given National ID.

Request:
```http
POST /api/Registration/generate-otp
Headers:
  x-api-key: your-api-key
Content-Type: application/json
{
  "nationalId": "1234567890"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "otpCode": "123456",
    "expiryDate": "2024-03-20T10:30:00Z"
  }
}
```

#### POST /api/Registration/verify-otp
Verifies the OTP for the given National ID.

Request:
```http
POST /api/Registration/verify-otp
Headers:
  x-api-key: your-api-key
Content-Type: application/json
{
  "nationalId": "1234567890",
  "otpCode": "123456"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "message": "OTP verified successfully"
  }
}
```

### User Controller

#### POST /api/user/get_user.php
Retrieves user details including registered devices.

Request:
```http
POST /api/user/get_user.php
Headers:
  x-api-key: your-api-key
Content-Type: application/json
{
  "nationalId": "1234567890"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "user": {
      "national_id": "1234567890",
      "name_en": "John Michael David Smith",
      "name_ar": "جون مايكل ديفيد سميث",
      "email": "john@example.com",
      "phone": "+966501234567",
      "date_of_birth": null,
      "id_expiry_date": null,
      "building_no": null,
      "street": null,
      "district": null,
      "city": null,
      "zipcode": null,
      "add_no": null,
      "iban": null,
      "dependents": null,
      "salary_dakhli": null,
      "salary_customer": null,
      "los": null,
      "sector": null,
      "employer": null,
      "registration_date": "2025-01-29 19:22:24",
      "consent": true,
      "consent_date": "2025-01-29 19:22:24",
      "nafath_status": null,
      "nafath_timestamp": null
    },
    "devices": [
      {
        "device_id": "test-device-1",
        "device_name": "Google Pixel 6",
        "platform": "Android",
        "os_version": null,
        "is_biometric_enabled": true,
        "registered_at": "2025-01-29 19:22:24",
        "last_used_at": "2025-01-29 19:22:24"
      }
    ]
  }
}
```

## Database Schema

### Tables

1. `Customers`
   - Primary key: `NationalId` (nvarchar(450))
   - Indexes:
     - None required as NationalId is the primary key

2. `master_config`
   - Primary key: `Id` (int)
   - Indexes:
     - `IX_master_config_Page` (Page)
     - `IX_master_config_Page_KeyName` (Page, KeyName) UNIQUE

3. `Customer_Devices`
   - Primary key: `Id` (int)
   - Indexes:
     - `IX_Customer_Devices_DeviceId` (DeviceId)
     - `IX_Customer_Devices_NationalId_DeviceId` (NationalId, DeviceId) UNIQUE

4. `User_Notifications`
   - Primary key: `Id` (int)
   - Indexes:
     - `IX_User_Notifications_NotificationId` (NotificationId)
     - `IX_User_Notifications_NationalId_IsRead` (NationalId, IsRead)

5. `OTP_Codes`
   - Primary key: `Id` (int)
   - Indexes:
     - `IX_OTP_Codes_national_id_type_is_used` (national_id, type, is_used)
     - `IX_OTP_Codes_expires_at` (expires_at)

6. `AuthLogs`
   - Primary key: `Id` (int)
   - Indexes:
     - `IX_AuthLogs_NationalId_CreatedAt` (NationalId, CreatedAt)

## Security Considerations

1. API Key Validation
   - All endpoints require valid x-api-key header
   - API keys should be stored securely and rotated regularly

2. Password Security
   - Passwords are hashed using BCrypt
   - Minimum password requirements should be enforced

3. Device Management
   - Each device ID must be unique per user
   - Biometric authentication is supported
   - Device status tracking for security

4. Data Protection
   - Sensitive data is properly encrypted
   - HTTPS is required for all endpoints
   - Input validation on all endpoints

## Error Handling

All endpoints follow a consistent error response format:

```json
{
  "success": false,
  "error": {
    "code": 400,
    "message": "Detailed error message"
  }
}
```

Common error codes:
- 400: Bad Request (invalid input)
- 401: Unauthorized (invalid API key)
- 404: Not Found
- 500: Internal Server Error

## Best Practices

1. Always use UTC for timestamps
2. Implement proper null checking
3. Use transactions for multi-table operations
4. Log all authentication attempts
5. Validate API keys for all requests
6. Format dates consistently (yyyy-MM-dd HH:mm:ss)
7. Handle device management properly
8. Implement proper error responses
9. Use proper indexing for performance
10. Follow REST API conventions

### AuthLog Model
```csharp
public class AuthLog
{
    public required string NationalId { get; set; }
    
    public string? DeviceId { get; set; }
    
    public required string AuthType { get; set; }
    
    public required string Status { get; set; }
    
    public string? FailureReason { get; set; }
    
    public string? IpAddress { get; set; }
    
    public string? UserAgent { get; set; }
    
    public required DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

### OtpCode Model
```csharp
public class OtpCode
{
    public required string NationalId { get; set; }
    
    public required string Code { get; set; }
    
    public required string Type { get; set; } = "auth";
    
    public required bool IsUsed { get; set; }
    
    public required DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public required DateTime ExpiresAt { get; set; }
    
    public DateTime? UsedAt { get; set; }
}
```

### CustomerDevice Model
```csharp
public class CustomerDevice
{
    [Key]
    public int Id { get; set; }
    
    public required string NationalId { get; set; }
    
    public required string DeviceId { get; set; }
    
    public required string Platform { get; set; }
    
    public required string Model { get; set; }
    
    public required string Manufacturer { get; set; }
    
    public string? OsVersion { get; set; }
    
    public required bool BiometricEnabled { get; set; }
    
    public required string Status { get; set; } = "active";
    
    public required DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? LastUsedAt { get; set; }
    
    public string? BiometricToken { get; set; }
    
    public bool IsActive => Status == "active";
    
    public string DeviceName => $"{Manufacturer} {Model}";
    
    public bool IsBiometricEnabled => BiometricEnabled;
    
    public DateTime RegisteredAt => CreatedAt;
}
```

## Controller Implementations

### NotificationsController
Handles user notifications with features:
- Pagination support
- Read/unread filtering
- Automatic read status updates
- Push notification capability

### UserController
Manages user profile with features:
- Detailed user information retrieval
- Active device listing
- Proper null handling for dates
- Formatted name concatenation

### RegistrationController
Handles user registration with:
- ID availability checking
- Full profile creation
- Device registration
- Transaction support
- Audit logging

## Key Features
- Null safety with required properties
- Default values for timestamps
- Computed properties for derived data
- Proper date formatting
- Transaction support for complex operations
- Comprehensive error logging
- API key validation
- Feature-based access control

## Recent Updates
1. Improved null safety across all models using required modifier
2. Enhanced date handling and formatting
3. Added computed properties for better encapsulation
4. Implemented proper error handling and logging
5. Added transaction support for registration
6. Enhanced device management
7. Improved notification system with proper state management

## Best Practices
1. Use UTC for all timestamps
2. Implement proper null checking
3. Use transactions for multi-table operations
4. Log all authentication attempts
5. Validate API keys for all requests
6. Format dates consistently
7. Handle device management properly
8. Implement proper error responses

## Database Tables Used

### Core Tables
- `Customers` - User registration and auth (including MPIN and biometrics flags)
  - Primary key: national_id
  - Includes user details in both English and Arabic
  - Timestamps using datetime2 for registration and consent

- `user_notifications` - Notifications
  - Uses nvarchar(max) for JSON data storage
  - Foreign key to Customers table
  - Indexed notification_id for fast retrieval

- `master_config` - Dynamic content
  - JSON storage using nvarchar(max)
  - Unique constraint on page and key_name combination
  - Performance index on page column

### Support Tables
- `auth_logs` - Authentication logs
  - Tracks all authentication attempts
  - Indexed on created_at for performance
  - No primary key, optimized for write operations

- `OTP_Codes` - OTP management
  - Foreign key to Customers table
  - Tracks OTP status and expiry
  - Default values for is_used flag

- `customer_devices` - Device management
  - Foreign key to Customers table
  - Tracks biometric status
  - Indexed on deviceId for fast lookups

### SQL Server Specific Implementation
```sql
-- Database Creation
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'NayifatApp')
BEGIN
    CREATE DATABASE NayifatApp;
END
GO

USE NayifatApp;
GO

-- Core Tables Creation Example
CREATE TABLE Customers (
    national_id varchar(20) PRIMARY KEY,
    first_name_en varchar(50),
    second_name_en varchar(50),
    third_name_en varchar(50),
    family_name_en varchar(50),
    first_name_ar varchar(50),
    second_name_ar varchar(50),
    third_name_ar varchar(50),
    family_name_ar varchar(50),
    date_of_birth date,
    id_expiry_date date,
    email varchar(100),
    phone varchar(20),
    building_no varchar(20),
    street varchar(100),
    district varchar(100),
    city varchar(100),
    zipcode varchar(10),
    add_no varchar(20),
    iban varchar(50),
    dependents int,
    salary_dakhli decimal(18,2),
    salary_customer decimal(18,2),
    los int,
    sector varchar(100),
    employer varchar(200),
    password varchar(255),
    registration_date datetime2 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    consent tinyint NOT NULL DEFAULT 0,
    consent_date datetime2,
    nafath_status varchar(50),
    nafath_timestamp datetime2
);

-- Performance Indexes
CREATE INDEX IX_auth_logs_created_at ON auth_logs(created_at);
CREATE INDEX IX_customer_devices_deviceId ON customer_devices(deviceId);
CREATE INDEX IX_loan_application_status ON loan_application_details(status);
CREATE INDEX IX_card_application_status ON card_application_details(status);
CREATE INDEX IX_notification_templates_expiry ON notification_templates(expiry_at);

### Key Features
- All timestamp fields use datetime2 type
- JSON data stored in nvarchar(max) fields
- Foreign key relationships maintained for data integrity
- Performance indexes on frequently queried columns
- Default values set using CURRENT_TIMESTAMP and 0 for flags

### Connection String Format
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=NayifatApp;User Id=sa;Password=your_password;TrustServerCertificate=True;"
  }
}
```

## Feature Implementation

### 1. Authentication & Registration

Example Sign In Request:
```http
POST /api/auth/signin
Headers:
  x-api-key: your-api-key
  Content-Type: application/json
  X-Feature: auth

Body:
{
    "nationalId": "1012345678",
    "password": "pass123",
    "deviceId": "test_device_123",
    "request": {
        "platform": "Android",
        "model": "Test Model",
        "manufacturer": "Test Manufacturer"
    }
}
```

#### Registration Endpoint (`user_registration.php`)
The registration process is handled through a single endpoint that supports both ID availability checks and full user registration with device management.

```csharp
// Models/Auth/UserRegistrationRequest.cs
public class UserRegistrationRequest
{
    public bool CheckOnly { get; set; }                // For ID availability check
    public string NationalId { get; set; }
    public string FirstNameEn { get; set; }
    public string SecondNameEn { get; set; }
    public string ThirdNameEn { get; set; }
    public string FamilyNameEn { get; set; }
    public string FirstNameAr { get; set; }
    public string SecondNameAr { get; set; }
    public string ThirdNameAr { get; set; }
    public string FamilyNameAr { get; set; }
    public string Email { get; set; }
    public string Password { get; set; }
    public string Phone { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public DateTime? IdExpiryDate { get; set; }
    // Address Information
    public string BuildingNo { get; set; }
    public string Street { get; set; }
    public string District { get; set; }
    public string City { get; set; }
    public string Zipcode { get; set; }
    public string AddNo { get; set; }
    // Financial Information
    public string Iban { get; set; }
    public int? Dependents { get; set; }
    public decimal? SalaryDakhli { get; set; }
    public decimal? SalaryCustomer { get; set; }
    public int? Los { get; set; }
    // Employment Information
    public string Sector { get; set; }
    public string Employer { get; set; }
    // Additional Information
    public bool Consent { get; set; }
    public string NafathStatus { get; set; }
    public DeviceInfo DeviceInfo { get; set; }
}

public class DeviceInfo
{
    public string DeviceId { get; set; }
    public string Platform { get; set; }
    public string Model { get; set; }
    public string Manufacturer { get; set; }
}

// Controllers/RegistrationController.cs
[Route("api")]
public class RegistrationController : ApiBaseController
{
    [HttpPost("user_registration.php")]
    public async Task<IActionResult> Register([FromBody] UserRegistrationRequest request)
    {
        // Key Features:
        // 1. ID Availability Check
        // 2. Full User Registration
        // 3. Device Registration
        // 4. Transaction Support
        // 5. Audit Logging
    }
}
```

#### Registration Flow
1. **ID Availability Check**
   - Endpoint accepts `CheckOnly` flag
   - Returns immediate response for ID availability
   - No data modification during check

2. **Full Registration**
   - Transactional processing
   - Comprehensive user data collection
   - Automatic timestamps for registration and consent
   - Nafath status tracking

3. **Device Management**
   - Automatic deactivation of existing devices
   - New device registration with biometric capability
   - Device audit logging
   - Platform and manufacturer tracking

4. **Response Format**
```json
{
    "status": "success",
    "message": "Registration successful",
    "government_data": {
        "national_id": "1234567890",
        "first_name_en": "John",
        "family_name_en": "Smith",
        "email": "john@example.com",
        "phone": "+966501234567",
        "date_of_birth": "1990-01-01",
        "id_expiry_date": "2025-01-01"
    },
    "device_registered": true,
    "biometric_enabled": true
}
```

5. **Security Features**
   - API key validation
   - Password hashing using BCrypt
   - Transaction rollback on failures
   - Comprehensive error logging
   - Device registration audit trail

6. **Error Handling**
   - Duplicate ID detection
   - Transaction management
   - Device registration failures
   - Detailed error logging with context

### 2. Notifications System

#### Models
```csharp
// Models/Notifications/NotificationTemplate.cs
public class NotificationTemplate
{
    public int Id { get; set; }
    public string? Title { get; set; }
    public string? Body { get; set; }
    public string? TitleEn { get; set; }
    public string? BodyEn { get; set; }
    public string? TitleAr { get; set; }
    public string? BodyAr { get; set; }
    public string? Route { get; set; }
    public string? AdditionalData { get; set; }
    public string? TargetCriteria { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ExpiryAt { get; set; }
}

// Models/Notifications/UserNotification.cs
public class UserNotification
{
    public required string NationalId { get; set; }
    public string? Notifications { get; set; }
    public DateTime LastUpdated { get; set; }
}

// Models/Notifications/GetNotificationsRequest.cs
public class GetNotificationsRequest
{
    public required string NationalId { get; set; }
    public bool MarkAsRead { get; set; }
}

// Models/Notifications/SendNotificationRequest.cs
public class SendNotificationRequest
{
    // Single language
    public string? Title { get; set; }
    public string? Body { get; set; }

    // Multi-language
    [JsonPropertyName("title_en")]
    public string? TitleEn { get; set; }
    
    [JsonPropertyName("body_en")]
    public string? BodyEn { get; set; }
    
    [JsonPropertyName("title_ar")]
    public string? TitleAr { get; set; }
    
    [JsonPropertyName("body_ar")]
    public string? BodyAr { get; set; }

    // Target users (one will be used)
    [JsonPropertyName("national_id")]
    public string? NationalId { get; set; }
    
    [JsonPropertyName("national_ids")]
    public List<string>? NationalIds { get; set; }
    
    public Dictionary<string, object>? Filters { get; set; }

    // Optional data
    public string? Route { get; set; }
    
    [JsonPropertyName("additional_data")]
    public object? AdditionalData { get; set; }
    
    [JsonPropertyName("expiry_at")]
    public DateTime? ExpiryAt { get; set; }
}
```

#### Database Schema
```sql
CREATE TABLE notification_templates (
    id int IDENTITY(1,1) PRIMARY KEY,
    title nvarchar(255),
    body nvarchar(max),
    title_en nvarchar(255),
    body_en nvarchar(max),
    title_ar nvarchar(255),
    body_ar nvarchar(max),
    route nvarchar(255),
    additional_data nvarchar(max),
    target_criteria nvarchar(max),
    created_at datetime2 NOT NULL DEFAULT GETDATE(),
    expiry_at datetime2
);

CREATE TABLE user_notifications (
    national_id nvarchar(20) PRIMARY KEY,
    notifications nvarchar(max),
    last_updated datetime2 NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (national_id) REFERENCES Customers(national_id)
);

CREATE INDEX IX_notification_templates_expiry ON notification_templates(expiry_at);
CREATE INDEX IX_user_notifications_last_updated ON user_notifications(last_updated);
```

#### Features
1. **Multi-language Support**
   - Arabic and English content
   - Proper nvarchar storage for Arabic text
   - Language-specific title and body

2. **Notification Management**
   - Automatic expiry handling
   - Read status tracking
   - Maximum 50 notifications per user
   - Automatic cleanup of old notifications

3. **Targeting Options**
   - Single user by National ID
   - Multiple users by National IDs list
   - Advanced filtering:
     - Table-based filtering (e.g. Customers.City)
     - BETWEEN operator for ranges
     - Multiple filter conditions
     - AND/OR operations

4. **Additional Features**
   - Deep linking via route parameter
   - Additional data support (JSON)
   - Audit logging
   - Transaction support
   - Error handling

#### Implementation Details

1. **Get Notifications**
```http
POST /api/notifications/list
Headers:
  Content-Type: application/json
  X-APP-ID: NAYIFAT_APP
  X-API-KEY: 7ca7427b418bdbd0b3b23d7debf69bf7
  X-Organization-No: 1

Request:
{
    "nationalId": "1234567890",
    "markAsRead": true
}

Response:
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

2. **Send Notification**
```http
POST /api/notifications/send
Headers:
  Content-Type: application/json
  X-APP-ID: NAYIFAT_APP
  X-API-KEY: 7ca7427b418bdbd0b3b23d7debf69bf7
  X-Organization-No: 1

Request:
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
    ],
    "route": "home",
    "additional_data": {
        "key": "value"
    },
    "expiry_at": "2024-04-19T10:00:00Z"
}

Response:
{
    "success": true,
    "data": {
        "status": "success",
        "message": "Successfully sent notifications to 100 users",
        "total_recipients": 100,
        "successful_sends": 100
    }
}
```

#### Error Handling
```json
{
    "success": false,
    "error": {
        "code": "ERROR_CODE",
        "message": "Error description"
    }
}
```

Common error codes:
- `INVALID_API_KEY`: Invalid or missing API key
- `INVALID_REQUEST`: Missing required fields
- `NO_RECIPIENTS`: No users match the filter criteria
- `INTERNAL_ERROR`: Server error during processing

### 3. Nafath Integration (`NafathController`)
Handles Nafath authentication and verification requests.

```csharp
[Route("api")]
public class NafathController : ApiBaseController
{
    [HttpPost("create_request.php")]
    public async Task<IActionResult> CreateRequest([FromBody] NafathCreateRequest request)
    {
        // Features:
        // 1. Creates Nafath authentication request
        // 2. Validates customer existence
        // 3. Handles API communication
        // 4. Status tracking
    }

    [HttpPost("get_request_status.php")]
    public async Task<IActionResult> GetRequestStatus([FromBody] NafathStatusRequest request)
    {
        // Features:
        // 1. Checks Nafath request status
        // 2. Updates customer verification status
        // 3. Handles timeouts and errors
    }
}
```

#### Nafath Flow
1. **Request Creation**
   - Generate Nafath request
   - Store request details
   - Handle API communication

2. **Status Checking**
   - Poll Nafath status
   - Update customer verification
   - Handle timeout scenarios

3. **Response Format**
```json
{
    "status": "success",
    "nafath_status": "COMPLETED",
    "transaction_id": "123456",
    "random_number": "12345",
    "timestamp": "2024-03-20T10:00:00Z"
}
```

### 4. User Management (`UserController`)
Handles user information retrieval and management.

```csharp
[Route("api")]
public class UserController : ApiBaseController
{
    [HttpPost("get_user.php")]
    public async Task<IActionResult> GetUser([FromBody] GetUserRequest request)
    {
        // Features:
        // 1. Retrieves user details
        // 2. Includes active devices
        // 3. Handles security validation
    }
}
```

#### Features
- Comprehensive user data retrieval
- Active device tracking
- Security validation
- Error handling with detailed messages

#### Response Format
```json
{
    "status": "success",
    "user": {
        "national_id": "1234567890",
        "name": {
            "first_name_en": "John",
            "family_name_en": "Doe",
            "first_name_ar": "جون",
            "family_name_ar": "دو"
        },
        "contact": {
            "email": "john@example.com",
            "phone": "+966501234567"
        },
        "active_devices": [
            {
                "device_id": "device123",
                "platform": "iOS",
                "last_used": "2024-03-20T10:00:00Z",
                "biometric_enabled": true
            }
        ]
    }
}
```

### Security Implementation
All controllers implement:
1. **API Key Validation**
   - Required for all endpoints
   - Configurable key validation
   - Rate limiting support

2. **Error Handling**
   - Standardized error responses
   - Detailed logging
   - Transaction management

3. **Audit Logging**
   - Authentication attempts
   - Device registration
   - Notification reads
   - Nafath requests

4. **Data Protection**
   - Password hashing with BCrypt
   - Secure device tracking
   - Transaction integrity
   - Input validation

### Common Response Format
All endpoints follow a standardized response format:
```json
{
    "status": "success|error",
    "message": "Operation result message",
    "data": {
        // Endpoint-specific data
    },
    "error_code": "ERROR_CODE",  // Only in error responses
    "timestamp": "2024-03-20T10:00:00Z"
}
```

## Response Format
```csharp
public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string Message { get; set; }
    public T Data { get; set; }
    public string ErrorCode { get; set; }
}
```

## Deployment

1. Build:
   ```bash
   dotnet publish -c Release
   ```

2. Deploy to IIS:
   - Copy published files to IIS folder
   - Configure application pool
   - Set up SSL

## Performance Tips

1. Use existing indexes
2. Enable response compression
3. Implement caching
4. Use async/await consistently

## Registration Flow Implementation

### 1. Initial Registration
```csharp
// Models/Auth/InitialRegistrationRequest.cs
public class InitialRegistrationRequest
{
    public string NationalId { get; set; }
    public string DateOfBirth { get; set; }
    public string IdExpiryDate { get; set; }
    public string Email { get; set; }
    public string Phone { get; set; }
}

// Models/Auth/NafathVerificationRequest.cs
public class NafathVerificationRequest
{
    public string NationalId { get; set; }
}

public class NafathVerificationResponse
{
    public bool Success { get; set; }
    public NafathResult Result { get; set; }
}

public class NafathResult
{
    public string Random { get; set; }
    public string TransId { get; set; }
    public string Status { get; set; }
}

// Models/Auth/CustomerDetailsResponse.cs
public class CustomerDetailsResponse
{
    public string DateOfBirth { get; set; }
    public string EnglishFirstName { get; set; }
    public string EnglishLastName { get; set; }
    public string EnglishSecondName { get; set; }
    public string EnglishThirdName { get; set; }
    public string FamilyName { get; set; }
    public string FatherName { get; set; }
    public string FirstName { get; set; }
    public int Gender { get; set; }
    public string GrandFatherName { get; set; }
    public string IdExpiryDate { get; set; }
    public string IdIssueDate { get; set; }
    public string IdIssuePlace { get; set; }
}

// Controllers/AuthController.cs
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly INafathService _nafathService;
    private readonly ICustomerService _customerService;

    [HttpPost("register/init")]
    public async Task<IActionResult> InitiateRegistration([FromBody] InitialRegistrationRequest request)
    {
        // 1. Validate basic fields
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // 2. Create temporary registration record
        var registrationResult = await _authService.CreateTemporaryRegistration(request);
        if (!registrationResult.Success)
            return BadRequest(registrationResult);

        // 3. Initiate Nafath verification
        var nafathResult = await _nafathService.CreateRequest(request.NationalId);
        
        return Ok(new ApiResponse<NafathVerificationResponse>
        {
            Success = true,
            Data = nafathResult
        });
    }

    [HttpPost("register/nafath/status")]
    public async Task<IActionResult> CheckNafathStatus([FromBody] NafathStatusRequest request)
    {
        var status = await _nafathService.CheckRequestStatus(
            request.NationalId,
            request.TransId,
            request.Random
        );

        if (status.Result.Status == "COMPLETED")
        {
            // Fetch customer details from Yakeen
            var customerDetails = await _customerService.GetCustomerDetails(
                request.NationalId,
                request.DateOfBirth,
                request.IdExpiryDate
            );

            // Store customer details
            await _authService.StoreCustomerDetails(request.NationalId, customerDetails);
        }

        return Ok(new ApiResponse<NafathStatusResponse>
        {
            Success = true,
            Data = status
        });
    }

    [HttpPost("register/security-setup")]
    public async Task<IActionResult> SetupSecurity([FromBody] SecuritySetupRequest request)
    {
        // Setup password, MPIN, and biometrics in one call
        var result = await _authService.SetupSecurityCredentials(request);
        return Ok(result);
    }
}

// Services/NafathService.cs
public interface INafathService
{
    Task<NafathVerificationResponse> CreateRequest(string nationalId);
    Task<NafathStatusResponse> CheckRequestStatus(string nationalId, string transId, string random);
}

public class NafathService : INafathService
{
    private readonly HttpClient _httpClient;
    private const string BaseUrl = "https://api.nayifat.com/nafath/api/Nafath";

    public NafathService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<NafathVerificationResponse> CreateRequest(string nationalId)
    {
        var response = await _httpClient.PostAsJsonAsync($"{BaseUrl}/CreateRequest", 
            new { nationalId });
        
        return await response.Content.ReadFromJsonAsync<NafathVerificationResponse>();
    }

    public async Task<NafathStatusResponse> CheckRequestStatus(
        string nationalId, 
        string transId, 
        string random)
    {
        var response = await _httpClient.PostAsJsonAsync($"{BaseUrl}/RequestStatus", 
            new { nationalId, transId, random });
        
        return await response.Content.ReadFromJsonAsync<NafathStatusResponse>();
    }
}

// Services/CustomerService.cs
public interface ICustomerService
{
    Task<CustomerDetailsResponse> GetCustomerDetails(
        string nationalId, 
        string dateOfBirth, 
        string idExpiryDate);
}

public class CustomerService : ICustomerService
{
    private readonly HttpClient _httpClient;
    private const string YakeenUrl = "https://172.22.226.203:663/api/Yakeen/getCitizenInfo/json";

    public async Task<CustomerDetailsResponse> GetCustomerDetails(
        string nationalId, 
        string dateOfBirth, 
        string idExpiryDate)
    {
        var request = new
        {
            iqamaNumber = nationalId,
            dateOfBirthHijri = dateOfBirth,
            idExpiryDate = idExpiryDate
        };

        var response = await _httpClient.PostAsJsonAsync(YakeenUrl, request);
        return await response.Content.ReadFromJsonAsync<CustomerDetailsResponse>();
    }
}

// Registration Flow Sequence
/*
1. User submits initial registration:
   POST /api/auth/register/init
   - Validates basic fields
   - Creates temporary registration
   - Initiates Nafath verification

2. Frontend polls Nafath status:
   POST /api/auth/register/nafath/status
   - Checks Nafath verification status
   - When completed, fetches customer details
   - Stores complete customer profile

3. User sets up security:
   POST /api/auth/register/security-setup
   - Sets password
   - Sets MPIN
   - Configures biometrics (optional)
*/

## Sign-in Implementation

### Models
```csharp
public class SignInRequest
{
    public string NationalId { get; set; }
    public string? Password { get; set; }
    public string? Mpin { get; set; }
    public BiometricData? BiometricData { get; set; }
    public string AuthMethod { get; set; } // "password", "mpin", "biometric"
    public DeviceInfo DeviceInfo { get; set; }
}

public class BiometricData
{
    public string DeviceId { get; set; }
    public string BiometricToken { get; set; }
}

public class SignInResponse
{
    public bool Success { get; set; }
    public string AccessToken { get; set; }
    public string RefreshToken { get; set; }
    public UserProfile UserProfile { get; set; }
    public DeviceStatus DeviceStatus { get; set; }
}

public class DeviceStatus
{
    public bool IsRegistered { get; set; }
    public bool BiometricsEnabled { get; set; }
    public bool MpinEnabled { get; set; }
}
```

### Controller Implementation
```csharp
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ITokenService _tokenService;
    private readonly IAuditService _auditService;

    [HttpPost("signin")]
    public async Task<IActionResult> SignIn([FromBody] SignInRequest request)
    {
        try
        {
            // 1. Validate device registration
            var deviceStatus = await _authService.ValidateDevice(
                request.NationalId, 
                request.DeviceInfo.DeviceId
            );

            if (!deviceStatus.IsRegistered)
            {
                return BadRequest(new ApiResponse<object>
                {
                    Success = false,
                    ErrorCode = "DEVICE_NOT_REGISTERED",
                    Message = "Device is not registered"
                });
            }

            // 2. Authenticate based on method
            var authResult = await _authService.Authenticate(request);
            if (!authResult.Success)
            {
                await _auditService.LogAuthFailure(
                    request.NationalId,
                    request.AuthMethod,
                    authResult.ErrorCode
                );
                return BadRequest(new ApiResponse<object>
                {
                    Success = false,
                    ErrorCode = authResult.ErrorCode,
                    Message = authResult.Message
                });
            }

            // 3. Generate tokens
            var tokens = await _tokenService.GenerateTokens(
                request.NationalId,
                request.DeviceInfo.DeviceId
            );

            // 4. Get user profile
            var userProfile = await _authService.GetUserProfile(request.NationalId);

            // 5. Log successful sign-in
            await _auditService.LogAuthSuccess(
                request.NationalId,
                request.AuthMethod,
                request.DeviceInfo
            );

            return Ok(new ApiResponse<SignInResponse>
            {
                Success = true,
                Data = new SignInResponse
                {
                    Success = true,
                    AccessToken = tokens.AccessToken,
                    RefreshToken = tokens.RefreshToken,
                    UserProfile = userProfile,
                    DeviceStatus = deviceStatus
                }
            });
        }
        catch (Exception ex)
        {
            // Log exception
            return StatusCode(500, new ApiResponse<object>
            {
                Success = false,
                ErrorCode = "INTERNAL_ERROR",
                Message = "An internal error occurred"
            });
        }
    }
}
```

### Service Implementation
```csharp
public interface IAuthService
{
    Task<AuthResult> Authenticate(SignInRequest request);
    Task<DeviceStatus> ValidateDevice(string nationalId, string deviceId);
    Task<UserProfile> GetUserProfile(string nationalId);
}

public class AuthService : IAuthService
{
    private readonly NayifatDbContext _context;
    private readonly IConfiguration _configuration;

    public async Task<AuthResult> Authenticate(SignInRequest request)
    {
        var user = await _context.Customers
            .FirstOrDefaultAsync(c => c.NationalId == request.NationalId);

        if (user == null)
            return AuthResult.Failed("INVALID_CREDENTIALS");

        switch (request.AuthMethod.ToLower())
        {
            case "password":
                return await ValidatePassword(user, request.Password);
                
            case "mpin":
                if (!user.MpinEnabled)
                    return AuthResult.Failed("MPIN_NOT_ENABLED");
                return await ValidateMpin(user, request.Mpin);
                
            case "biometric":
                if (!await IsBiometricsEnabled(user.NationalId, request.BiometricData.DeviceId))
                    return AuthResult.Failed("BIOMETRICS_NOT_ENABLED");
                return await ValidateBiometrics(user, request.BiometricData);
                
            default:
                return AuthResult.Failed("INVALID_AUTH_METHOD");
        }
    }

    private async Task<AuthResult> ValidatePassword(Customer user, string password)
    {
        if (!_passwordHasher.Verify(user.Password, password))
            return AuthResult.Failed("INVALID_CREDENTIALS");

        return AuthResult.Success();
    }

    private async Task<AuthResult> ValidateMpin(Customer user, string mpin)
    {
        if (!_passwordHasher.Verify(user.Mpin, mpin))
            return AuthResult.Failed("INVALID_MPIN");

        return AuthResult.Success();
    }

    private async Task<AuthResult> ValidateBiometrics(
        Customer user, 
        BiometricData biometricData)
    {
        var device = await _context.CustomerDevices
            .FirstOrDefaultAsync(d => 
                d.NationalId == user.NationalId && 
                d.DeviceId == biometricData.DeviceId);

        if (device == null || !device.BiometricEnabled)
            return AuthResult.Failed("BIOMETRICS_NOT_ENABLED");

        if (device.BiometricToken != biometricData.BiometricToken)
            return AuthResult.Failed("INVALID_BIOMETRIC_TOKEN");

        return AuthResult.Success();
    }
}
```

### Token Service
```csharp
public interface ITokenService
{
    Task<TokenResult> GenerateTokens(string nationalId, string deviceId);
    Task<TokenResult> RefreshToken(string refreshToken);
}

public class TokenResult
{
    public string AccessToken { get; set; }
    public string RefreshToken { get; set; }
    public DateTime AccessTokenExpiry { get; set; }
    public DateTime RefreshTokenExpiry { get; set; }
}
```

### Sign-in Flow
1. Client sends sign-in request with:
   - National ID
   - Auth method (password/MPIN/biometric)
   - Corresponding credentials
   - Device information

2. Server validates:
   - Device registration
   - Credentials based on auth method
   - User status

3. On successful validation:
   - Generates JWT access token
   - Generates refresh token
   - Returns user profile
   - Returns device status

4. Error scenarios:
   - DEVICE_NOT_REGISTERED
   - INVALID_CREDENTIALS
   - MPIN_NOT_ENABLED
   - BIOMETRICS_NOT_ENABLED
   - INVALID_BIOMETRIC_TOKEN
   - ACCOUNT_LOCKED
   - INTERNAL_ERROR
```

### Device Registration
```csharp
// Models/Auth/RegisterDeviceRequest.cs
public class RegisterDeviceRequest
{
    public string NationalId { get; set; }
    public string DeviceId { get; set; }
    public string Platform { get; set; }
    public string Model { get; set; }
    public string Manufacturer { get; set; }
    public string OsVersion { get; set; }
}

// Controllers/DeviceController.cs
public class DeviceController : ApiBaseController
{
    [HttpPost("register_device.php")]
    public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceRequest request)
    {
        // 1. Validate API key
        // 2. Check if customer exists
        // 3. Disable existing devices for the user
        // 4. Register new device with:
        //    - Device identification (ID, name, platform)
        //    - Hardware details (manufacturer, model, OS)
        //    - Biometric settings
        //    - Timestamps
        // 5. Log registration attempt
        // 6. Return success with device ID or error
    }
}
```

Key Features:
- Automatic deactivation of existing devices
- Device information tracking
- Biometric capability flags
- Audit logging for all registration attempts
- Error handling with detailed logging
- Standardized API responses

Database Operations:
- Updates to `customer_devices` table
- Logging to `auth_logs` table
- Transaction handling for data consistency

Security:
- API key validation
- Customer existence verification
- Device status tracking
- Audit trail maintenance
```

## SQL Server Connection Management

### Connection String Best Practices
```json
{
    "ConnectionStrings": {
        "DefaultConnection": "Server=.;Database=NayifatApp;User Id=nayifat_app;Password=your_password;TrustServerCertificate=True;MultipleActiveResultSets=true"
    }
}
```

### Connection Handling Implementation
```csharp
[ApiController]
[Route("[controller]")]
public class TestController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<TestController> _logger;

    public TestController(ApplicationDbContext context, ILogger<TestController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet("sql-info")]
    public async Task<IActionResult> GetSqlInfo()
    {
        try
        {
            var connection = _context.Database.GetDbConnection();
            
            // Ensure connection is open
            if (connection.State != System.Data.ConnectionState.Open)
            {
                await connection.OpenAsync();
            }
            
            var connectionString = connection.ConnectionString;
            
            // Mask sensitive information by removing password
            var maskedConnectionString = string.Join(";",
                connectionString.Split(';')
                    .Where(part => !part.StartsWith("Password=", StringComparison.OrdinalIgnoreCase))
            );
            
            var serverInfo = new
            {
                DatabaseName = connection.Database,
                ServerVersion = connection is SqlConnection sqlConnection ? sqlConnection.ServerVersion : "Unknown",
                State = connection.State.ToString(),
                ConnectionString = maskedConnectionString,
                CanConnect = await _context.Database.CanConnectAsync()
            };

            return Ok(new { 
                status = "success",
                data = serverInfo,
                message = "SQL Server information retrieved successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting SQL Server information");
            return StatusCode(500, new { 
                status = "error",
                message = ex.Message,
                details = ex.ToString()
            });
        }
        finally
        {
            // Always ensure connection is closed
            if (_context.Database.GetDbConnection().State == System.Data.ConnectionState.Open)
            {
                await _context.Database.GetDbConnection().CloseAsync();
            }
        }
    }
}
```

### Connection Management Best Practices
1. **Explicit Connection Management**
   - Always open connections explicitly when needed
   - Use `async/await` for connection operations
   - Ensure connections are closed in a `finally` block
   - Use `using` statements where appropriate

2. **Security**
   - Never expose connection strings in responses
   - Mask sensitive information like passwords
   - Use minimum required permissions for the database user
   - Enable TLS/SSL with `TrustServerCertificate`

3. **Performance**
   - Use connection pooling (enabled by default)
   - Keep connections open only as long as needed
   - Use `MultipleActiveResultSets` for concurrent operations
   - Monitor connection usage and timeouts

4. **Error Handling**
   - Catch and log specific SQL exceptions
   - Provide meaningful error messages
   - Include proper error context
   - Implement retry logic for transient failures

5. **Monitoring**
   - Log connection states
   - Track connection open/close times
   - Monitor connection pool usage
   - Log connection string changes

### Testing SQL Connection
```csharp
public async Task<bool> TestConnection()
{
    try
    {
        return await _context.Database.CanConnectAsync();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Database connection test failed");
        return false;
    }
}
```

### Connection String Parameters
- `Server=.` - Local SQL Server instance
- `Database=NayifatApp` - Target database
- `User Id=nayifat_app` - SQL authentication username
- `Password=your_password` - SQL authentication password
- `TrustServerCertificate=True` - Trust the SQL Server certificate
- `MultipleActiveResultSets=true` - Allow multiple active result sets
```

## Proxy Controller Implementation

### Overview
The Proxy Controller acts as an intermediary between the app and local endpoints, allowing secure and controlled access to local services.

### Endpoint
```http
POST /api/proxy/forward
Headers:
    api-key: your-api-key
    Content-Type: application/json
```

### Request Format
```json
{
    "endpoint": "your/local/endpoint",
    "method": "POST",              // Optional, defaults to POST
    "data": {                      // Optional, ignored for GET requests
        // Your request data
    },
    "contentType": "application/json",  // Optional, defaults to application/json
    "headers": {                   // Optional, additional headers
        "custom-header": "value"
    }
}
```

### Configuration
In `appsettings.json`:
```json
{
  "LocalEndpoint": {
    "BaseUrl": "http://localhost:5000"  // Your local service base URL
  }
}
```

### Usage Examples

1. **Simple GET Request**
```json
{
    "endpoint": "api/users",
    "method": "GET"
}
```

2. **POST with JSON Data**
```json
{
    "endpoint": "api/users/create",
    "method": "POST",
    "data": {
        "name": "John Doe",
        "email": "john@example.com"
    }
}
```

3. **Form Data Submission**
```json
{
    "endpoint": "api/auth/login",
    "method": "POST",
    "contentType": "application/x-www-form-urlencoded",
    "data": {
        "username": "john",
        "password": "secret"
    }
}
```

4. **Request with Custom Headers**
```json
{
    "endpoint": "api/secure/data",
    "method": "GET",
    "headers": {
        "X-Custom-Auth": "token123",
        "X-Feature": "secure"
    }
}
```

### Response Handling

1. **JSON Response**
```json
{
    "status": "success",
    "data": {
        // Response data
    }
}
```

2. **Error Response**
```json
{
    "status": "error",
    "message": "Error description",
    "errorCode": "ERROR_CODE"
}
```

### Features

1. **HTTP Methods Support**
   - GET
   - POST
   - PUT
   - DELETE
   - PATCH

2. **Content Types**
   - application/json (default)
   - application/x-www-form-urlencoded
   - application/xml
   - text/plain

3. **Security**
   - API key validation
   - Header forwarding
   - Error logging
   - Exception handling

4. **Response Types**
   - Automatic JSON parsing
   - XML support
   - Plain text fallback
   - Status code preservation

### Best Practices

1. **Error Handling**
   ```csharp
   try {
       var response = await client.PostAsync("/api/proxy/forward", content);
       if (response.IsSuccessStatusCode) {
           var result = await response.Content.ReadFromJsonAsync<T>();
           // Process result
       }
   }
   catch (Exception ex) {
       // Handle exception
   }
   ```

2. **Headers Management**
   - Always include required headers:
     - api-key
     - Content-Type
   - Use custom headers for specific features
   - Avoid sensitive information in headers

3. **Request Validation**
   - Validate endpoint paths
   - Ensure proper data format
   - Check content type compatibility
   - Verify required fields

4. **Response Processing**
   - Check status codes
   - Handle different content types
   - Parse responses appropriately
   - Log errors and exceptions

### Common Use Cases

1. **User Authentication**
```json
{
    "endpoint": "api/auth/login",
    "method": "POST",
    "data": {
        "username": "user@example.com",
        "password": "password123"
    }
}
```

2. **Data Retrieval**
```json
{
    "endpoint": "api/data/user-profile",
    "method": "GET",
    "headers": {
        "X-User-Id": "123"
    }
}
```

3. **File Upload**
```json
{
    "endpoint": "api/documents/upload",
    "method": "POST",
    "contentType": "multipart/form-data",
    "data": {
        // File data
    }
}
```

### Troubleshooting

1. **Common Issues**
   - Invalid API key
   - Incorrect endpoint path
   - Malformed request data
   - Network connectivity
   - Content type mismatch

2. **Logging**
   - All requests are logged
   - Error details are captured
   - Response status is tracked
   - Performance metrics are recorded

3. **Error Codes**
   - 401: Invalid API key
   - 404: Endpoint not found
   - 400: Bad request
   - 500: Internal server error
```

## Nayifat ASP.NET Implementation Details

### Time Zone Implementation

#### Overview
Implementation of Saudi Arabia Time (Arab Standard Time) in the Notifications System

#### Technical Details

1. **Time Conversion Method**
```csharp
TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time"))
```

2. **Modified Components in NotificationsController**

- **Current Time Calculation**
  ```csharp
  var currentTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, 
      TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time"));
  ```

- **Notification Status Updates**
  ```csharp
  notif["read_at"] = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, 
      TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time"));
  ```

- **Database Operations**
  ```csharp
  // Update operations
  "UPDATE user_notifications SET notifications = {0}, last_updated = {1} WHERE national_id = {2}"
  
  // Insert operations
  "INSERT INTO user_notifications (national_id, notifications, last_updated) VALUES ({0}, {1}, {2})"
  ```

#### Key Implementation Points

1. **Consistency**
   - All datetime operations now use Saudi Arabia Time
   - Uniform time zone handling across the controller

2. **Database Interactions**
   - Direct SQL queries updated to use Saudi time
   - Notification template timestamps converted
   - User notification records standardized to Saudi time

3. **Notification Processing**
   - Template creation times
   - Expiry calculations
   - Read status tracking
   - Delivery timestamps

4. **Performance Considerations**
   - Time zone conversions handled at application level
   - No additional database overhead
   - Minimal impact on response times

#### Testing Guidelines

1. **Timestamp Verification**
   - Verify all timestamps show in Saudi time (UTC+3)
   - Check expiry calculations
   - Validate notification delivery times

2. **Database Operations**
   - Confirm correct timestamp storage
   - Verify time consistency in queries
   - Check notification template times

3. **User Experience**
   - Ensure correct time display in UI
   - Verify notification sorting
   - Check expiry behavior
```

## OTP System Implementation

### 1. OTP Generation Endpoint
**Endpoint**: `/api/proxy/forward?url=https://icreditdept.com/api/testasp/test_local_generate_otp.php`

#### Request Format
```json
{
    "nationalId": "string",     // Customer's national ID
    "mobileNo": "string",       // Mobile number with 966 prefix
    "purpose": "REGISTRATION",  // Purpose of OTP
    "userId": 1                 // Default user ID for registration
}
```

#### Response Format
```json
{
    "success": true,
    "errors": [],
    "result": {
        "nationalId": "string",
        "otp": number,
        "expiryDate": "datetime",
        "successMsg": "string",
        "errCode": number,
        "errMsg": string | null
    },
    "type": "N"
}
```

#### Implementation Details
- **Headers Required**:
  ```
  Content-Type: application/json
  x-api-key: 7ca7427b418bdbd0b3b23d7debf69bf7
  ```
- **Phone Number Formatting**:
  - Remove any existing '+' or '966' prefix
  - Add '966' prefix to the number
- **Validation**:
  - National ID must be valid format
  - Mobile number must be valid Saudi format
  - Purpose must be "REGISTRATION"
- **Error Handling**:
  - Invalid phone format
  - Invalid national ID
  - System errors
  - Network issues

### 2. OTP Verification Endpoint
**Endpoint**: `/api/proxy/forward?url=https://icreditdept.com/api/testasp/test_local_verify_otp.php`

#### Request Format
```json
{
    "nationalId": "string",  // Customer's national ID (trimmed)
    "otp": "string",        // OTP code (trimmed)
    "userId": 1             // Default user ID for registration
}
```

#### Response Format
```json
{
    "success": true,
    "errors": [],
    "result": {
        "nationalId": "string",
        "verified": boolean,
        "successMsg": "string",
        "errCode": number,
        "errMsg": string | null
    },
    "type": "N"
}
```

#### Implementation Details
- **Headers Required**:
  ```
  Content-Type: application/json
  x-api-key: 7ca7427b418bdbd0b3b23d7debf69bf7
  ```
- **Validation**:
  - OTP code format
  - OTP expiration check
  - National ID match
- **Error Handling**:
  - Invalid OTP
  - Expired OTP
  - System errors
  - Network issues

### 3. Security Considerations
1. **Rate Limiting**:
   - Maximum 3 OTP requests per number per hour
   - Maximum 5 verification attempts per OTP

2. **OTP Expiration**:
   - OTPs expire after 5 minutes
   - Expired OTPs cannot be verified

3. **Data Protection**:
   - All requests must include valid API key
   - National IDs and phone numbers are validated
   - Response data is sanitized

4. **Logging**:
   - All OTP generations are logged
   - Failed verification attempts are logged
   - System errors are logged with stack traces

### 4. Error Codes and Messages
```json
{
    "1001": "Invalid phone number format",
    "1002": "Invalid national ID format",
    "1003": "OTP generation limit exceeded",
    "1004": "Invalid OTP code",
    "1005": "OTP expired",
    "1006": "Verification attempts exceeded",
    "2001": "System error",
    "2002": "Network error"
}
```

### 5. Testing Guidelines
1. **OTP Generation Testing**:
   - Test with valid/invalid phone numbers
   - Test with valid/invalid national IDs
   - Verify rate limiting
   - Check response format
   - Verify OTP format

2. **OTP Verification Testing**:
   - Test with valid/invalid OTPs
   - Test with expired OTPs
   - Test with wrong national ID
   - Verify attempt limiting
   - Check response format

3. **Error Handling Testing**:
   - Test all error scenarios
   - Verify error messages
   - Check error codes
   - Test system errors
   - Test network issues

### 6. Integration Notes
1. **Mobile App Integration**:
   - Use centralized constants
   - Implement proper error handling
   - Show appropriate loading states
   - Format phone numbers correctly
   - Handle network timeouts

2. **Backend Integration**:
   - Validate all inputs
   - Sanitize all outputs
   - Log all operations
   - Handle all errors
   - Maintain security

### 7. Monitoring and Maintenance
1. **Performance Monitoring**:
   - Track response times
   - Monitor error rates
   - Check rate limiting
   - Watch system resources

2. **Security Monitoring**:
   - Track failed attempts
   - Monitor API key usage
   - Check for abuse patterns
   - Review security logs

3. **Maintenance Tasks**:
   - Regular log rotation
   - Database cleanup
   - Performance optimization
   - Security updates