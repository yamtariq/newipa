# Nayifat ASP.NET 9 Implementation Guide (Core Features)

## Quick Start

1. Install prerequisites:
   - .NET 9 SDK
   - Visual Studio 2022
   - SQL Server 2019+

2. Create project:
   ```bash
   dotnet new webapi -n NayifatAPI --framework net9.0
   cd NayifatAPI
   ```

3. Install packages:
   ```bash
   dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
   dotnet add package Microsoft.EntityFrameworkCore.SqlServer
   dotnet add package Serilog.AspNetCore
   ```

## Project Structure
```
NayifatAPI/
├── Controllers/
│   ├── AuthController.cs        # Authentication & Registration
│   ├── ContentController.cs     # Content management
│   └── NotificationController.cs # Notifications
├── Models/
│   ├── Auth/
│   │   ├── SignInRequest.cs
│   │   ├── RegisterRequest.cs
│   │   ├── UserDetailsRequest.cs
│   │   ├── MpinSetupRequest.cs
│   │   ├── BiometricsRequest.cs
│   │   ├── OtpRequest.cs
│   │   └── DeviceInfo.cs
│   ├── Content/
│   │   └── DynamicContent.cs
│   └── Notifications/
│       ├── Notification.cs
│       └── NotificationTemplate.cs
├── Services/
│   ├── AuthService.cs
│   ├── ContentService.cs
│   └── NotificationService.cs
└── Middleware/
    └── ApiKeyMiddleware.cs
```

## Database Tables Used

### Core Tables
- `Customers` - User registration and auth (including MPIN and biometrics flags)
- `user_notifications` - Notifications
- `master_config` - Dynamic content

### Support Tables
- `auth_logs` - Authentication logs
- `OTP_Codes` - OTP management
- `customer_devices` - Device management (including biometrics status)

## Feature Implementation

### 1. Authentication & Registration
```csharp
// Models/Auth/RegisterRequest.cs
public class RegisterRequest
{
    public string NationalId { get; set; }
    public string Password { get; set; }
    public DeviceInfo DeviceInfo { get; set; }
}

// Models/Auth/UserDetailsRequest.cs
public class UserDetailsRequest
{
    public string NationalId { get; set; }
    public string FirstNameEn { get; set; }
    public string SecondNameEn { get; set; }
    public string ThirdNameEn { get; set; }
    public string FamilyNameEn { get; set; }
    public string FirstNameAr { get; set; }
    public string SecondNameAr { get; set; }
    public string ThirdNameAr { get; set; }
    public string FamilyNameAr { get; set; }
    public DateTime DateOfBirth { get; set; }
    public string Email { get; set; }
    public string Phone { get; set; }
}

// Models/Auth/MpinSetupRequest.cs
public class MpinSetupRequest
{
    public string NationalId { get; set; }
    public string Mpin { get; set; }
    public string CurrentPassword { get; set; }
}

// Models/Auth/BiometricsRequest.cs
public class BiometricsRequest
{
    public string NationalId { get; set; }
    public string DeviceId { get; set; }
    public bool EnableBiometrics { get; set; }
    public string BiometricToken { get; set; }
}

// Controllers/AuthController.cs
[Route("api/auth")]
public class AuthController : ControllerBase
{
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        // Validate national ID
        // Generate OTP
        // Create initial user record
    }

    [HttpPost("user-details")]
    public async Task<IActionResult> SetUserDetails([FromBody] UserDetailsRequest request)
    {
        // Validate user details
        // Update user information
        // Handle Arabic text properly
    }

    [HttpPost("setup-mpin")]
    public async Task<IActionResult> SetupMpin([FromBody] MpinSetupRequest request)
    {
        // Validate current password
        // Hash and store MPIN
        // Update MPIN status
    }

    [HttpPost("biometrics")]
    public async Task<IActionResult> SetupBiometrics([FromBody] BiometricsRequest request)
    {
        // Validate device registration
        // Store biometric token
        // Update biometrics status
    }

    [HttpPost("signin")]
    public async Task<IActionResult> SignIn([FromBody] SignInRequest request)
    {
        // Support multiple auth methods:
        // 1. Password
        // 2. MPIN
        // 3. Biometrics
        // Generate JWT token
        // Log sign-in
    }

    [HttpPost("otp/verify")]
    public async Task<IActionResult> VerifyOTP([FromBody] OtpRequest request)
    {
        // Verify OTP code
        // Update verification status
    }
}

// Services/AuthService.cs
public interface IAuthService
{
    Task<bool> RegisterUser(RegisterRequest request);
    Task<bool> SetUserDetails(UserDetailsRequest request);
    Task<bool> SetupMpin(string nationalId, string mpin);
    Task<bool> SetupBiometrics(BiometricsRequest request);
    Task<AuthResult> SignIn(SignInRequest request);
    Task<bool> VerifyOTP(string nationalId, string otp);
}

// Services/AuthService Implementation
public class AuthService : IAuthService
{
    private readonly NayifatDbContext _context;
    private readonly IConfiguration _configuration;

    public async Task<bool> SetupMpin(string nationalId, string mpin)
    {
        // Hash MPIN before storing
        var hashedMpin = HashMpin(mpin);
        
        var user = await _context.Customers
            .FirstOrDefaultAsync(c => c.NationalId == nationalId);
        
        if (user == null) return false;
        
        user.Mpin = hashedMpin;
        user.MpinEnabled = true;
        
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SetupBiometrics(BiometricsRequest request)
    {
        var device = await _context.CustomerDevices
            .FirstOrDefaultAsync(d => 
                d.NationalId == request.NationalId && 
                d.DeviceId == request.DeviceId);
        
        if (device == null) return false;
        
        device.BiometricEnabled = request.EnableBiometrics;
        device.BiometricToken = request.BiometricToken;
        
        await _context.SaveChangesAsync();
        return true;
    }
}
```

### 2. Content Management
```csharp
// Controllers/ContentController.cs
[Route("api/content")]
public class ContentController : ControllerBase
{
    [HttpGet("master-fetch")]
    public async Task<IActionResult> GetContent(
        [FromQuery] string page,
        [FromQuery] string keyName)
    {
        // Fetch dynamic content
        // Handle localization
        // Return formatted content
    }
}

// Services/ContentService.cs
public interface IContentService
{
    Task<dynamic> GetContent(string page, string keyName);
}
```

### 3. Notification System
```csharp
// Controllers/NotificationController.cs
[Route("api/notifications")]
public class NotificationController : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetNotifications(
        [FromQuery] string nationalId)
    {
        // Get user notifications
        // Filter by status
        // Handle pagination
    }

    [HttpPost("send")]
    public async Task<IActionResult> SendNotification(
        [FromBody] NotificationRequest request)
    {
        // Validate request
        // Send notification
        // Store in database
    }
}

// Services/NotificationService.cs
public interface INotificationService
{
    Task<List<Notification>> GetUserNotifications(string nationalId);
    Task<bool> SendNotification(NotificationRequest request);
}
```

## Security Implementation

```csharp
// Middleware/ApiKeyMiddleware.cs
public class ApiKeyMiddleware
{
    private const string API_KEY_HEADER = "api-key";
    private const string EXPECTED_API_KEY = "7ca7427b418bdbd0b3b23d7debf69bf7";

    public async Task InvokeAsync(HttpContext context, RequestDelegate next)
    {
        if (!context.Request.Headers.TryGetValue(API_KEY_HEADER, out var apiKey) || 
            apiKey != EXPECTED_API_KEY)
        {
            context.Response.StatusCode = 401;
            return;
        }
        await next(context);
    }
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
    private readonly IPasswordHasher _passwordHasher;
    
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