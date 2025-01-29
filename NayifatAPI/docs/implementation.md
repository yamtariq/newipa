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
The main user model with personal, financial, and security information.
Key features:
- National ID as primary key
- Bilingual name support (Arabic/English)
- Optional address and employment details
- Financial information with proper decimal handling
- Device and notification relationships
- MPIN support for mobile authentication

### MasterConfig Model
Dynamic configuration storage with:
- Unique page/key combinations
- Active/inactive state tracking
- Automatic timestamp management
- Value validation

### CustomerDevice Model
Device management with:
- Unique device IDs per user
- Platform and model tracking
- Biometric authentication support
- Device status management

### UserNotification Model
Notification handling with:
- Read/unread status
- Timestamp tracking
- Type categorization
- JSON data support

## API Endpoints

### Config Controller

#### GET /api/config/page/{page}
Retrieves all active configurations for a specific page.

#### POST /api/config
Creates or updates a configuration.

#### DELETE /api/config/{page}/{keyName}
Deactivates a configuration.

### Registration Controller

#### POST /api/registration/register
Registers a new user with device information.

### User Controller

#### POST /api/user/get_user.php
Retrieves user details including registered devices.

## Database Schema

### Tables

1. `Customers`
   - Primary key: `NationalId`
   - Contains all user information
   - Relationships to devices, notifications, and logs

2. `master_config`
   - Dynamic configuration storage
   - Unique constraints on page/key combinations
   - Soft delete support via IsActive

3. `Customer_Devices`
   - Device management
   - Unique device IDs per user
   - Biometric capability tracking

4. `User_Notifications`
   - Notification storage
   - Read status tracking
   - Performance optimized indexes

5. `OTP_Codes`
   - OTP management
   - Expiration tracking
   - Usage status

6. `AuthLogs`
   - Authentication attempt tracking
   - Device association
   - IP and user agent storage

## Security Considerations

1. API Key Validation
2. Password Hashing (BCrypt)
3. Device Authentication
4. Data Protection
5. Input Validation

## Error Handling

Consistent error response format with proper status codes and messages.

## Best Practices

1. UTC Timestamps
2. Null Safety
3. Transaction Management
4. Comprehensive Logging
5. API Key Validation
6. Date Formatting
7. Device Management
8. Error Handling
9. Database Indexing
10. REST Conventions 