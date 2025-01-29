using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    public class RegistrationController : ApiBaseController
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<RegistrationController> _logger;

        public RegistrationController(ApplicationDbContext context, ILogger<RegistrationController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpPost("user_registration.php")]
        public async Task<IActionResult> RegisterUser([FromBody] UserRegistrationRequest request)
        {
            if (!ValidateApiKey() || !ValidateFeatureHeader("user"))
            {
                return Error("Invalid headers", 401);
            }

            try
            {
                // Check if user already exists
                if (await _context.Customers.AnyAsync(c => c.NationalId == request.NationalId))
                {
                    return Error("User already registered", 400);
                }

                // Validate OTP if provided
                if (!string.IsNullOrEmpty(request.OtpCode))
                {
                    var otpValid = await _context.OtpCodes
                        .AnyAsync(o => o.NationalId == request.NationalId &&
                                     o.Code == request.OtpCode &&
                                     !o.IsUsed &&
                                     o.ExpiresAt > DateTime.UtcNow);

                    if (!otpValid)
                    {
                        return Error("Invalid or expired OTP", 400);
                    }
                }

                var customer = new Customer
                {
                    NationalId = request.NationalId,
                    FirstNameEn = request.FirstNameEn,
                    SecondNameEn = request.SecondNameEn,
                    ThirdNameEn = request.ThirdNameEn,
                    FamilyNameEn = request.FamilyNameEn,
                    FirstNameAr = request.FirstNameAr,
                    SecondNameAr = request.SecondNameAr,
                    ThirdNameAr = request.ThirdNameAr,
                    FamilyNameAr = request.FamilyNameAr,
                    DateOfBirth = request.DateOfBirth,
                    IdExpiryDate = request.IdExpiryDate,
                    Email = request.Email,
                    Phone = request.Phone,
                    Password = HashPassword(request.Password),
                    RegistrationDate = DateTime.UtcNow,
                    Consent = request.Consent,
                    ConsentDate = request.Consent ? DateTime.UtcNow : null
                };

                _context.Customers.Add(customer);

                // Mark OTP as used if provided
                if (!string.IsNullOrEmpty(request.OtpCode))
                {
                    var otp = await _context.OtpCodes
                        .FirstOrDefaultAsync(o => o.NationalId == request.NationalId &&
                                               o.Code == request.OtpCode);
                    if (otp != null)
                    {
                        otp.IsUsed = true;
                        otp.UsedAt = DateTime.UtcNow;
                    }
                }

                await _context.SaveChangesAsync();

                return Success(new { 
                    message = "Registration successful",
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
                _logger.LogError(ex, "Error during user registration for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        private string HashPassword(string password)
        {
            using var sha256 = System.Security.Cryptography.SHA256.Create();
            var hashedBytes = sha256.ComputeHash(System.Text.Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
        }
    }

    public class UserRegistrationRequest
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
        public DateTime IdExpiryDate { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public string Password { get; set; }
        public bool Consent { get; set; }
        public string OtpCode { get; set; }
    }
} 