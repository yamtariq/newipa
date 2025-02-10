using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;
using System.Text.Json;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RegistrationController : ApiBaseController
    {
        private readonly ILogger<RegistrationController> _logger;

        public RegistrationController(
            ApplicationDbContext context,
            ILogger<RegistrationController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpGet("health")]
        public IActionResult Health()
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            return Success(new { status = "healthy" }, "API is working");
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] UserRegistrationRequest registrationRequest)
        {
            _logger.LogInformation("🚀 Starting registration process for NationalId: {NationalId}", registrationRequest.NationalId);

            // Validate API key
            if (!ValidateApiKey())
            {
                _logger.LogWarning("❌ Invalid API key");
                return Error("Invalid API key", 401);
            }

            // Validate request
            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage)
                    .ToList();
                _logger.LogWarning("❌ Invalid registration request: {@Errors}", errors);
                return BadRequest(new { error = "Invalid registration data", details = errors });
            }

            // Check if user already exists
            var existingUser = await _context.Customers.FirstOrDefaultAsync(c => c.NationalId == registrationRequest.NationalId);
            if (existingUser != null)
            {
                _logger.LogWarning("❌ User with NationalId {NationalId} already exists", registrationRequest.NationalId);
                return BadRequest(new { error = "User already registered" });
            }

            _logger.LogInformation("✅ User validation passed. Creating new customer record");
            _logger.LogDebug("📝 Registration Request Data: {@RegistrationRequest}", registrationRequest);

            // Start transaction
            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                _logger.LogInformation("🔒 Hashing password");
                var hashedPassword = HashPassword(registrationRequest.Password);

                // Create customer record
                _logger.LogInformation("👤 Creating new customer record");
                var customer = new Customer
                {
                    NationalId = registrationRequest.NationalId,
                    FirstNameEn = registrationRequest.FirstNameEn,
                    SecondNameEn = registrationRequest.SecondNameEn ?? string.Empty,
                    ThirdNameEn = registrationRequest.ThirdNameEn ?? string.Empty,
                    FamilyNameEn = registrationRequest.FamilyNameEn,
                    FirstNameAr = registrationRequest.FirstNameAr,
                    SecondNameAr = registrationRequest.SecondNameAr ?? string.Empty,
                    ThirdNameAr = registrationRequest.ThirdNameAr ?? string.Empty,
                    FamilyNameAr = registrationRequest.FamilyNameAr,
                    Email = registrationRequest.Email,
                    Phone = registrationRequest.Phone,
                    Password = hashedPassword,
                    DateOfBirth = registrationRequest.DateOfBirth,
                    IdExpiryDate = registrationRequest.IdExpiryDate,
                    BuildingNo = registrationRequest.BuildingNo,
                    Street = registrationRequest.Street,
                    District = registrationRequest.District,
                    City = registrationRequest.City,
                    Zipcode = registrationRequest.Zipcode,
                    AddNo = registrationRequest.AddNo,
                    Iban = registrationRequest.Iban,
                    Dependents = registrationRequest.Dependents,
                    SalaryDakhli = registrationRequest.SalaryDakhli,
                    SalaryCustomer = registrationRequest.SalaryCustomer,
                    Los = registrationRequest.Los,
                    Sector = registrationRequest.Sector,
                    Employer = registrationRequest.Employer,
                    RegistrationDate = DateTime.UtcNow,
                    Consent = registrationRequest.Consent,
                    ConsentDate = DateTime.UtcNow,
                    NafathStatus = registrationRequest.NafathStatus ?? "pending",
                    NafathTimestamp = DateTime.UtcNow
                };

                _logger.LogDebug("📝 New Customer Data: {@Customer}", new 
                {
                    customer.NationalId,
                    customer.FirstNameEn,
                    customer.FamilyNameEn,
                    customer.Email,
                    customer.Phone,
                    customer.DateOfBirth,
                    customer.IdExpiryDate,
                    customer.Dependents,
                    customer.RegistrationDate
                });

                _context.Customers.Add(customer);
                await _context.SaveChangesAsync();
                _logger.LogInformation("✅ Customer record created successfully");

                // Create device record if device info is provided
                if (registrationRequest.DeviceInfo != null)
                {
                    _logger.LogInformation("📱 Adding device information");
                    _logger.LogDebug("📱 Device Info: {@DeviceInfo}", registrationRequest.DeviceInfo);

                    var device = new CustomerDevice
                    {
                        NationalId = customer.NationalId,
                        DeviceId = registrationRequest.DeviceInfo.DeviceId,
                        Platform = registrationRequest.DeviceInfo.Platform,
                        Model = registrationRequest.DeviceInfo.Model,
                        Manufacturer = registrationRequest.DeviceInfo.Manufacturer,
                        BiometricEnabled = true,
                        Status = "active",
                        CreatedAt = DateTime.UtcNow,
                        LastUsedAt = DateTime.UtcNow
                    };

                    _context.CustomerDevices.Add(device);
                    await _context.SaveChangesAsync();
                    _logger.LogInformation("✅ Device information added successfully");
                }

                await transaction.CommitAsync();
                _logger.LogInformation("✅ Registration completed successfully");

                // Return success response with user data
                var response = new
                {
                    success = true,
                    data = new
                    {
                        national_id = customer.NationalId,
                        first_name_en = customer.FirstNameEn,
                        family_name_en = customer.FamilyNameEn,
                        email = customer.Email,
                        phone = customer.Phone,
                        date_of_birth = customer.DateOfBirth?.ToString("yyyy-MM-dd"),
                        id_expiry_date = customer.IdExpiryDate?.ToString("yyyy-MM-dd"),
                        dependents = customer.Dependents
                    }
                };

                _logger.LogDebug("📤 Response Data: {@Response}", response);
                return Ok(response);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "❌ Error during registration for NationalId: {NationalId}", registrationRequest.NationalId);
                return BadRequest(new { error = "Registration failed", details = ex.Message });
            }
        }

        private string HashPassword(string password)
        {
            return BCrypt.Net.BCrypt.HashPassword(password);
        }
    }

    public class UserRegistrationRequest
    {
        public required string NationalId { get; set; }
        public required string FirstNameEn { get; set; }
        public required string SecondNameEn { get; set; }
        public string? ThirdNameEn { get; set; }
        public required string FamilyNameEn { get; set; }
        public required string FirstNameAr { get; set; }
        public required string SecondNameAr { get; set; }
        public string? ThirdNameAr { get; set; }
        public required string FamilyNameAr { get; set; }
        public required string Email { get; set; }
        public required string Phone { get; set; }
        public required string Password { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public DateTime? IdExpiryDate { get; set; }
        public string? BuildingNo { get; set; }
        public string? Street { get; set; }
        public string? District { get; set; }
        public string? City { get; set; }
        public string? Zipcode { get; set; }
        public string? AddNo { get; set; }
        public string? Iban { get; set; }
        public decimal? SalaryDakhli { get; set; }
        public decimal? SalaryCustomer { get; set; }
        public int? Los { get; set; }
        public string? Sector { get; set; }
        public string? Employer { get; set; }
        public bool Consent { get; set; }
        public string? NafathStatus { get; set; }
        public int? Dependents { get; set; }
        public required DeviceInfo DeviceInfo { get; set; }
    }

    public class DeviceInfo
    {
        public required string DeviceId { get; set; }
        public required string Platform { get; set; }
        public required string Model { get; set; }
        public required string Manufacturer { get; set; }
    }
}