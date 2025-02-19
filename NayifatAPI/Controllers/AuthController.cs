using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;
using System.Security.Cryptography;
using System.Text;
using BCrypt.Net;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : BaseApiController
    {
        private readonly ILogger<AuthController> _logger;

        public AuthController(
            ApplicationDbContext context,
            ILogger<AuthController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpPost("signin")]
        public async Task<IActionResult> SignIn([FromBody] SignInRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var customer = await _context.Customers
                    .FirstOrDefaultAsync(c => c.NationalId == request.NationalId);

                if (customer == null)
                {
                    return Error(
                        message: "National ID not registered in the system", 
                        statusCode: 401, 
                        details: new { 
                            code = "CUSTOMER_NOT_FOUND",
                            message_ar = "رقم الهوية غير مسجل في النظام"
                        }
                    );
                }

                // Password authentication flow
                if (!string.IsNullOrEmpty(request.Password))
                {
                    _logger.LogInformation("Starting password verification for NationalId: {NationalId}", request.NationalId);
                    
                    if (customer.Password == null)
                    {
                        _logger.LogWarning("No password hash found for NationalId: {NationalId}", request.NationalId);
                        await LogAuthAttempt(request.NationalId, request.DeviceId, "failed", "Password not set");
                        return Error(
                            message: "Password not set for this account", 
                            statusCode: 401, 
                            details: new { 
                                code = "PASSWORD_NOT_SET",
                                message_ar = "كلمة المرور غير معينة لهذا الحساب"
                            }
                        );
                    }

                    var isPasswordValid = VerifyPassword(request.Password, customer.Password);
                    _logger.LogInformation("Password verification result for NationalId {NationalId}: {Result}", 
                        request.NationalId, isPasswordValid ? "Success" : "Failed");

                    if (!isPasswordValid)
                    {
                        await LogAuthAttempt(request.NationalId, request.DeviceId, "failed", "Invalid password");
                        return Error(
                            message: "Invalid password", 
                            statusCode: 401, 
                            details: new { 
                                code = "INVALID_PASSWORD",
                                message_ar = "كلمة المرور غير صحيحة"
                            }
                        );
                    }

                    // Generate token
                    var token = GenerateToken();
                    var refreshToken = GenerateToken();
                    var expiresAt = DateTime.UtcNow.AddHours(24);

                    // Log successful login
                    await LogAuthAttempt(request.NationalId, request.DeviceId, "success", failureReason: null);

                    return Success(new
                    {
                        token,
                        refresh_token = refreshToken,
                        expires_at = expiresAt.ToString("yyyy-MM-dd HH:mm:ss"),
                        user = new
                        {
                            national_id = customer.NationalId,
                            first_name_en = customer.FirstNameEn,
                            first_name_ar = customer.FirstNameAr,
                            family_name_en = customer.FamilyNameEn,
                            family_name_ar = customer.FamilyNameAr,
                            email = customer.Email,
                            phone = customer.Phone,
                            device_id = request.DeviceId,
                            date_of_birth = customer.DateOfBirth?.ToString("yyyy-MM-dd"),
                            id_expiry_date = customer.IdExpiryDate?.ToString("yyyy-MM-dd"),
                            iban = customer.Iban,
                            dependents = customer.Dependents ?? 0
                        }
                    });
                }
                else
                {
                    // OTP authentication flow
                    return Success(new
                    {
                        code = "CUSTOMER_VERIFIED",
                        message = "Customer verified, proceed with OTP",
                        require_otp = true,
                        user = new { phone = customer.Phone }
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during sign in for National ID: {NationalId}", request.NationalId);
                await LogAuthAttempt(request.NationalId, request.DeviceId, "failed", ex.Message);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("refresh")]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            if (!ValidateApiKey() || !ValidateFeatureHeader("auth"))
            {
                return Error("Invalid headers", 401);
            }

            try
            {
                // Validate existing session token
                if (!ValidateSessionToken(request.SessionToken, request.NationalId))
                {
                    await LogAuthAttempt(request.NationalId, "N/A", "failed", "Invalid session token");
                    return Error("Invalid session token", 401);
                }

                var newToken = GenerateSessionToken(request.NationalId);
                await LogAuthAttempt(request.NationalId, "N/A", "success", failureReason: null);

                return Success(new { 
                    session_token = newToken
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error refreshing token for National ID: {NationalId}", request.NationalId);
                await LogAuthAttempt(request.NationalId, "N/A", "failed", ex.Message);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("otp/generate")]
        public async Task<IActionResult> GenerateOtp([FromBody] OtpGenerateRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                // Get customer phone number
                var customer = await _context.Customers
                    .FirstOrDefaultAsync(c => c.NationalId == request.NationalId);

                if (customer == null)
                {
                    return Error("Customer not found", 404, new { code = "USER_NOT_FOUND" });
                }

                // Rate limiting: Check for unexpired OTP
                var hasUnexpiredOtp = await _context.OtpCodes
                    .AnyAsync(o => 
                        o.NationalId == request.NationalId && 
                        !o.IsUsed && 
                        o.ExpiresAt > DateTime.UtcNow &&
                        o.CreatedAt > DateTime.UtcNow.AddMinutes(-2)); // 2-minute rate limit

                if (hasUnexpiredOtp)
                {
                    return Error("Please wait before requesting another OTP", 429);
                }

                // Generate OTP
                var otp = GenerateOtp();
                var hashedOtp = HashOtp(otp);
                var expiresAt = DateTime.UtcNow.AddMinutes(10);

                var otpCode = new OtpCode
                {
                    NationalId = request.NationalId,
                    Code = hashedOtp,
                    ExpiresAt = expiresAt,
                    IsUsed = false,
                    CreatedAt = DateTime.UtcNow,
                    Type = request.Type ?? "auth"
                };

                _context.OtpCodes.Add(otpCode);
                await _context.SaveChangesAsync();

                // TODO: Implement actual OTP sending logic
                return Success(new
                {
                    message = "OTP generated successfully and sent to the user phone",
                    phone = customer.Phone, // 💡 Include phone number in response
                    otp_code = otp // Remove in production
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating OTP for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("otp/verify")]
        public async Task<IActionResult> VerifyOtp([FromBody] OtpVerifyRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var hashedOtp = HashOtp(request.OtpCode);
                var otpRecord = await _context.OtpCodes
                    .FirstOrDefaultAsync(o => 
                        o.NationalId == request.NationalId && 
                        o.Code == hashedOtp &&
                        !o.IsUsed &&
                        o.ExpiresAt > DateTime.UtcNow);

                if (otpRecord == null)
                {
                    return Error("Invalid or expired OTP", 400);
                }

                // Mark OTP as used
                otpRecord.IsUsed = true;
                otpRecord.UsedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Success(new { message = "OTP verified successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verifying OTP for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("password")]
        public async Task<IActionResult> ChangePassword([FromBody] PasswordChangeRequest request)
        {
            if (!ValidateApiKey() || !ValidateFeatureHeader("auth"))
            {
                return Error("Invalid headers", 401);
            }

            try
            {
                var customer = await _context.Customers
                    .FirstOrDefaultAsync(c => c.NationalId == request.NationalId);

                if (customer == null)
                {
                    return Error("Customer not found", 404);
                }

                customer.Password = HashPassword(request.NewPassword);
                await _context.SaveChangesAsync();

                return Success(new { message = "Password updated successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error changing password for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("otp")]
        public async Task<IActionResult> CreateOtp([FromBody] CreateOtpRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                // Rate limiting: Check for unexpired OTP
                var hasUnexpiredOtp = await _context.OtpCodes
                    .AnyAsync(o => 
                        o.NationalId == request.NationalId && 
                        !o.IsUsed && 
                        o.ExpiresAt > DateTime.UtcNow &&
                        o.CreatedAt > DateTime.UtcNow.AddMinutes(-2)); // 2-minute rate limit

                if (hasUnexpiredOtp)
                {
                    return Error("Please wait before requesting another OTP", 429);
                }

                // Create new OTP record
                var otpCode = new OtpCode
                {
                    NationalId = request.NationalId,
                    Code = request.Code,
                    Type = request.Type,
                    IsUsed = false,
                    CreatedAt = DateTime.UtcNow,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(10)
                };

                _context.OtpCodes.Add(otpCode);
                await _context.SaveChangesAsync();

                return Success(new
                {
                    message = "OTP record created successfully",
                    expires_at = otpCode.ExpiresAt
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating OTP for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("validate-otp")]
        public async Task<IActionResult> ValidateOtp([FromBody] ValidateOtpRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Unauthorized", 401);
            }

            try
            {
                var otpRecord = await _context.OtpCodes
                    .FirstOrDefaultAsync(o => 
                        o.NationalId == request.NationalId && 
                        o.Type == request.Type &&
                        !o.IsUsed &&
                        o.ExpiresAt > DateTime.UtcNow);

                if (otpRecord == null)
                {
                    return Error("Invalid or expired OTP", 400, new { code = "INVALID_OTP" });
                }

                if (!VerifyOtp(request.OtpCode, otpRecord.Code))
                {
                    return Error("Invalid OTP code", 400, new { code = "INVALID_OTP" });
                }

                // Mark OTP as used
                otpRecord.IsUsed = true;
                await _context.SaveChangesAsync();

                return Success(new { message = "OTP validated successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error validating OTP for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500, new { code = "SERVER_ERROR" });
            }
        }

        private async Task LogAuthAttempt(string nationalId, string deviceId, string status, string? failureReason)
        {
            var log = new AuthLog
            {
                NationalId = nationalId,
                DeviceId = deviceId,
                Status = status,
                FailureReason = failureReason,
                IpAddress = HttpContext?.Connection?.RemoteIpAddress?.ToString(),
                UserAgent = HttpContext?.Request?.Headers["User-Agent"].ToString(),
                CreatedAt = DateTime.UtcNow,
                AuthType = "password"
            };

            _context.AuthLogs.Add(log);
            await _context.SaveChangesAsync();
        }

        private string GenerateToken()
        {
            var randomBytes = new byte[32];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(randomBytes);
            }
            return Convert.ToHexString(randomBytes).ToLower();
        }

        private string GenerateOtp(int length = 6)
        {
            var random = new Random();
            var min = (int)Math.Pow(10, length - 1);
            var max = (int)Math.Pow(10, length) - 1;
            return random.Next(min, max).ToString();
        }

        private string HashOtp(string otp)
        {
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(otp));
            return Convert.ToBase64String(hashedBytes);
        }

        private bool VerifyPassword(string password, string storedHash)
        {
            try
            {
                // Split the stored hash into its components
                var parts = storedHash.Split(':', 3);
                if (parts.Length != 3)
                {
                    return false;
                }

                var salt = Convert.FromBase64String(parts[0]);
                var iterations = int.Parse(parts[1]);
                var hash = Convert.FromBase64String(parts[2]);

                // Generate hash from the provided password
                using var pbkdf2 = new Rfc2898DeriveBytes(
                    password,
                    salt,
                    iterations,
                    HashAlgorithmName.SHA256);
                var testHash = pbkdf2.GetBytes(32); // 256 bits

                // Compare the hashes
                return hash.SequenceEqual(testHash);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verifying password");
                return false;
            }
        }

        private string HashPassword(string password)
        {
            // Generate a random salt
            byte[] salt = new byte[16];
            using (var rng = new RNGCryptoServiceProvider())
            {
                rng.GetBytes(salt);
            }

            // Set number of iterations (can be increased in the future for better security)
            int iterations = 10000;

            // Generate the hash
            using var pbkdf2 = new Rfc2898DeriveBytes(
                password,
                salt,
                iterations,
                HashAlgorithmName.SHA256);
            var hash = pbkdf2.GetBytes(32); // 256 bits

            // Combine salt, iterations, and hash
            return $"{Convert.ToBase64String(salt)}:{iterations}:{Convert.ToBase64String(hash)}";
        }

        private string GenerateSessionToken(string nationalId)
        {
            var tokenData = $"{nationalId}:{DateTime.UtcNow.Ticks}";
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(tokenData));
            return Convert.ToBase64String(hashedBytes);
        }

        private bool ValidateSessionToken(string token, string nationalId)
        {
            // TODO: Implement proper session token validation
            return !string.IsNullOrEmpty(token);
        }

        private bool VerifyOtp(string providedOtp, string storedOtp)
        {
            return providedOtp == storedOtp;
        }
    }

    public class SignInRequest
    {
        public required string NationalId { get; set; }
        public string? Password { get; set; }
        public required string DeviceId { get; set; }
    }

    public class RefreshTokenRequest
    {
        public required string SessionToken { get; set; }
        public required string NationalId { get; set; }
    }

    public class OtpGenerateRequest
    {
        public required string NationalId { get; set; }
        public required string Type { get; set; }
    }

    public class OtpVerifyRequest
    {
        public required string NationalId { get; set; }
        public required string OtpCode { get; set; }
        public required string Type { get; set; }
    }

    public class PasswordChangeRequest
    {
        public required string NationalId { get; set; }
        public required string NewPassword { get; set; }
    }

    public class CreateOtpRequest
    {
        public required string NationalId { get; set; }
        public required string Code { get; set; }
        public required string Type { get; set; }
    }

    public class ValidateOtpRequest
    {
        public required string NationalId { get; set; }
        public required string Type { get; set; }
        public required string OtpCode { get; set; }
    }
} 