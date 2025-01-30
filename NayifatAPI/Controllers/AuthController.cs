using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using NayifatAPI.Models;
using System.Security.Cryptography;
using System.Text;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ApiBaseController
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<AuthController> _logger;

        public AuthController(ApplicationDbContext context, ILogger<AuthController> logger)
        {
            _context = context;
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
                    await LogAuthAttempt(request.NationalId, request.DeviceId, "failed", "Customer not found");
                    return Error("Invalid credentials", 401, new { code = "CUSTOMER_NOT_FOUND" });
                }

                // Password authentication flow
                if (!string.IsNullOrEmpty(request.Password))
                {
                    if (customer.Password == null || !VerifyPassword(request.Password, customer.Password))
                    {
                        await LogAuthAttempt(request.NationalId, request.DeviceId, "failed", "Invalid password");
                        return Error("Invalid credentials", 401, new { code = "INVALID_PASSWORD" });
                    }

                    // Check device registration if deviceId provided
                    if (!string.IsNullOrEmpty(request.DeviceId))
                    {
                        var device = await _context.CustomerDevices
                            .FirstOrDefaultAsync(d => 
                                d.NationalId == request.NationalId && 
                                d.DeviceId == request.DeviceId &&
                                d.Status == "active");

                        if (device == null)
                        {
                            await LogAuthAttempt(request.NationalId, request.DeviceId, "failed", "Device not registered");
                            return Error("Device not registered", 401, new { code = "DEVICE_NOT_REGISTERED" });
                        }
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
                            name = $"{customer.FirstNameEn} {customer.FamilyNameEn}".Trim(),
                            email = customer.Email,
                            phone = customer.Phone
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
                        require_otp = true
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

        [HttpPost("refresh-token")]
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

        [HttpPost("password/change")]
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

        private bool VerifyPassword(string password, string hashedPassword)
        {
            // TODO: Implement proper password verification
            return password == hashedPassword;
        }

        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
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
    }

    public class SignInRequest
    {
        public required string NationalId { get; set; }
        public required string Password { get; set; }
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
} 