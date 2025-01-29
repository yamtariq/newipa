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

#### POST /api/registration/register
Registers a new user with device information.

Request:
```http
POST /api/registration/register
Headers:
  x-api-key: your-api-key
Content-Type: application/json
{
  "nationalId": "1234567890",
  "firstNameEn": "John",
  "secondNameEn": "Michael",
  "thirdNameEn": "David",
  "familyNameEn": "Smith",
  "firstNameAr": "جون",
  "secondNameAr": "مايكل",
  "thirdNameAr": "ديفيد",
  "familyNameAr": "سميث",
  "email": "john@example.com",
  "password": "Test123!@#",
  "phone": "+966501234567",
  "consent": true,
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
    "status": "success",
    "message": "Registration successful",
    "government_data": {
      "national_id": "1234567890",
      "first_name_en": "John",
      "family_name_en": "Smith",
      "email": "john@example.com",
      "phone": "+966501234567",
      "date_of_birth": null,
      "id_expiry_date": null
    },
    "device_registered": true,
    "biometric_enabled": true
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