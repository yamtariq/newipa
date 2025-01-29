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

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] UserRegistrationRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                // Check if this is just an ID check
                if (request.CheckOnly)
                {
                    var exists = await _context.Customers
                        .AnyAsync(c => c.NationalId == request.NationalId);

                    if (exists)
                    {
                        return Error("This ID already registered", 400);
                    }
                    
                    return Success(new { message = "ID available" });
                }

                // Regular registration flow
                var customerExists = await _context.Customers
                    .AnyAsync(c => c.NationalId == request.NationalId);

                if (customerExists)
                {
                    return Error("This ID already registered", 400);
                }

                // Start transaction
                using var transaction = await _context.Database.BeginTransactionAsync();

                try
                {
                    // Create customer record
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
                        Email = request.Email,
                        Password = request.Password != null ? HashPassword(request.Password) : null,
                        Phone = request.Phone,
                        DateOfBirth = request.DateOfBirth ?? DateTime.MinValue,
                        IdExpiryDate = request.IdExpiryDate ?? DateTime.MinValue,
                        BuildingNo = request.BuildingNo ?? string.Empty,
                        Street = request.Street ?? string.Empty,
                        District = request.District ?? string.Empty,
                        City = request.City ?? string.Empty,
                        Zipcode = request.Zipcode ?? string.Empty,
                        AddNo = request.AddNo ?? string.Empty,
                        Iban = request.Iban ?? string.Empty,
                        Dependents = request.Dependents,
                        SalaryDakhli = request.SalaryDakhli,
                        SalaryCustomer = request.SalaryCustomer,
                        Los = request.Los,
                        Sector = request.Sector ?? string.Empty,
                        Employer = request.Employer ?? string.Empty,
                        RegistrationDate = DateTime.UtcNow,
                        Consent = request.Consent,
                        ConsentDate = request.Consent ? DateTime.UtcNow : null,
                        NafathStatus = request.NafathStatus ?? string.Empty,
                        NafathTimestamp = request.NafathStatus != null ? DateTime.UtcNow : null
                    };

                    _context.Customers.Add(customer);

                    // Handle device registration if provided
                    if (request.DeviceInfo != null)
                    {
                        // Disable any existing devices
                        await _context.CustomerDevices
                            .Where(d => d.NationalId == request.NationalId)
                            .ExecuteUpdateAsync(s => s
                                .SetProperty(d => d.Status, "disabled")
                                .SetProperty(d => d.LastUsedAt, DateTime.UtcNow));

                        // Register new device
                        var device = new CustomerDevice
                        {
                            NationalId = request.NationalId,
                            DeviceId = request.DeviceInfo.DeviceId,
                            Platform = request.DeviceInfo.Platform,
                            Model = request.DeviceInfo.Model,
                            Manufacturer = request.DeviceInfo.Manufacturer,
                            BiometricEnabled = true,
                            Status = "active",
                            CreatedAt = DateTime.UtcNow,
                            LastUsedAt = DateTime.UtcNow
                        };

                        _context.CustomerDevices.Add(device);

                        // Log device registration
                        var authLog = new AuthLog
                        {
                            NationalId = request.NationalId,
                            DeviceId = request.DeviceInfo.DeviceId,
                            AuthType = "device_registration",
                            Status = "success",
                            IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                            UserAgent = HttpContext.Request.Headers["User-Agent"].ToString(),
                            CreatedAt = DateTime.UtcNow
                        };

                        _context.AuthLogs.Add(authLog);
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // Prepare response
                    var response = new
                    {
                        status = "success",
                        message = "Registration successful",
                        government_data = new
                        {
                            national_id = customer.NationalId,
                            first_name_en = customer.FirstNameEn,
                            family_name_en = customer.FamilyNameEn,
                            email = customer.Email,
                            phone = customer.Phone,
                            date_of_birth = customer.DateOfBirth?.ToString("yyyy-MM-dd"),
                            id_expiry_date = customer.IdExpiryDate?.ToString("yyyy-MM-dd")
                        }
                    };

                    if (request.DeviceInfo != null)
                    {
                        return Success(new
                        {
                            response.status,
                            response.message,
                            response.government_data,
                            device_registered = true,
                            biometric_enabled = true
                        });
                    }

                    return Success(response);
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during registration for National ID: {NationalId}", request.NationalId);

                // Log registration failure if device info was provided
                if (request.DeviceInfo != null)
                {
                    var authLog = new AuthLog
                    {
                        NationalId = request.NationalId,
                        DeviceId = request.DeviceInfo.DeviceId,
                        AuthType = "device_registration",
                        Status = "failed",
                        IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                        UserAgent = HttpContext.Request.Headers["User-Agent"].ToString(),
                        FailureReason = ex.Message,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.AuthLogs.Add(authLog);
                    await _context.SaveChangesAsync();
                }

                return Error("Internal server error", 500);
            }
        }

        private string HashPassword(string password)
        {
            return BCrypt.Net.BCrypt.HashPassword(password);
        }
    }

    public class UserRegistrationRequest
    {
        public bool CheckOnly { get; set; }
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
        public required string Password { get; set; }
        public required string Phone { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public DateTime? IdExpiryDate { get; set; }
        public string? BuildingNo { get; set; }
        public string? Street { get; set; }
        public string? District { get; set; }
        public string? City { get; set; }
        public string? Zipcode { get; set; }
        public string? AddNo { get; set; }
        public string? Iban { get; set; }
        public int? Dependents { get; set; }
        public decimal? SalaryDakhli { get; set; }
        public decimal? SalaryCustomer { get; set; }
        public int? Los { get; set; }
        public string? Sector { get; set; }
        public string? Employer { get; set; }
        public bool Consent { get; set; }
        public string? NafathStatus { get; set; }
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