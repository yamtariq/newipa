using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using NayifatAPI.Models;
using System.Security.Cryptography;
using System.Text;

namespace NayifatAPI.Controllers
{
    public class AuthController : ApiBaseController
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<AuthController> _logger;

        public AuthController(ApplicationDbContext context, ILogger<AuthController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpPost("signin.php")]
        public async Task<IActionResult> SignIn([FromBody] SignInRequest request)
        {
            if (!ValidateApiKey() || !ValidateFeatureHeader("auth"))
            {
                return Error("Invalid headers", 401);
            }

            try
            {
                var customer = await _context.Customers
                    .FirstOrDefaultAsync(c => c.NationalId == request.NationalId);

                if (customer == null || !VerifyPassword(request.Password, customer.Password))
                {
                    return Error("Invalid credentials", 401);
                }

                var authLog = new AuthLog
                {
                    NationalId = customer.NationalId,
                    DeviceId = request.DeviceId,
                    AuthType = "SIGNIN",
                    IsSuccessful = true,
                    CreatedAt = DateTime.UtcNow,
                    IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                    UserAgent = HttpContext.Request.Headers["User-Agent"].ToString()
                };

                _context.AuthLogs.Add(authLog);
                await _context.SaveChangesAsync();

                return Success(new { 
                    session_token = GenerateSessionToken(customer.NationalId),
                    user = new {
                        national_id = customer.NationalId,
                        name = $"{customer.FirstNameEn} {customer.FamilyNameEn}",
                        email = customer.Email,
                        phone = customer.Phone
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during signin for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("refresh_token.php")]
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
                    return Error("Invalid session token", 401);
                }

                return Success(new { 
                    session_token = GenerateSessionToken(request.NationalId)
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error refreshing token for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("otp_generate.php")]
        public async Task<IActionResult> GenerateOtp([FromBody] OtpGenerateRequest request)
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

                var otp = GenerateOtp();
                var otpCode = new OtpCode
                {
                    NationalId = customer.NationalId,
                    Code = otp,
                    Purpose = request.Purpose,
                    CreatedAt = DateTime.UtcNow,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(5),
                    Channel = request.Channel ?? "SMS"
                };

                _context.OtpCodes.Add(otpCode);
                await _context.SaveChangesAsync();

                // TODO: Implement actual OTP sending logic
                _logger.LogInformation("OTP {Otp} generated for {NationalId}", otp, request.NationalId);

                return Success(new { reference_id = otpCode.Id });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating OTP for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("otp_verification.php")]
        public async Task<IActionResult> VerifyOtp([FromBody] OtpVerifyRequest request)
        {
            if (!ValidateApiKey() || !ValidateFeatureHeader("auth"))
            {
                return Error("Invalid headers", 401);
            }

            try
            {
                var otpCode = await _context.OtpCodes
                    .FirstOrDefaultAsync(o => o.Id == request.ReferenceId && 
                                            o.NationalId == request.NationalId &&
                                            !o.IsUsed &&
                                            o.ExpiresAt > DateTime.UtcNow);

                if (otpCode == null || otpCode.Code != request.Code)
                {
                    return Error("Invalid or expired OTP", 400);
                }

                otpCode.IsUsed = true;
                otpCode.UsedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Success(new { verified = true });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verifying OTP for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("password_change.php")]
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

        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
        }

        private bool VerifyPassword(string password, string hashedPassword)
        {
            return HashPassword(password) == hashedPassword;
        }

        private string GenerateOtp()
        {
            return Random.Shared.Next(100000, 999999).ToString();
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
        public string NationalId { get; set; }
        public string Password { get; set; }
        public string DeviceId { get; set; }
    }

    public class RefreshTokenRequest
    {
        public string SessionToken { get; set; }
        public string NationalId { get; set; }
    }

    public class OtpGenerateRequest
    {
        public string NationalId { get; set; }
        public string Purpose { get; set; }
        public string Channel { get; set; }
    }

    public class OtpVerifyRequest
    {
        public string NationalId { get; set; }
        public int ReferenceId { get; set; }
        public string Code { get; set; }
    }

    public class PasswordChangeRequest
    {
        public string NationalId { get; set; }
        public string NewPassword { get; set; }
    }
} 