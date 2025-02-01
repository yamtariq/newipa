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
        public async Task<IActionResult> Register([FromBody] object request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            UserRegistrationRequest? registrationRequest = null;
            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };

                // Deserialize as IdCheckRequest first to check if it's an ID check
                var idCheckRequest = JsonSerializer.Deserialize<IdCheckRequest>(request.ToString()!, options);
                
                if (idCheckRequest?.CheckOnly == true)
                {
                    var exists = await _context.Customers
                        .AnyAsync(c => c.NationalId == idCheckRequest.NationalId);

                    if (exists)
                    {
                        return Error("This ID already registered", 400);
                    }
                    
                    return Success(new { message = "ID available" });
                }

                // If not an ID check, process as full registration
                registrationRequest = JsonSerializer.Deserialize<UserRegistrationRequest>(request.ToString()!, options);
                if (registrationRequest == null)
                {
                    return Error("Invalid request data", 400);
                }

                // Regular registration flow
                var customerExists = await _context.Customers
                    .AnyAsync(c => c.NationalId == registrationRequest.NationalId);

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
                        NationalId = registrationRequest.NationalId,
                        FirstNameEn = registrationRequest.FirstNameEn,
                        SecondNameEn = registrationRequest.SecondNameEn,
                        ThirdNameEn = registrationRequest.ThirdNameEn ?? string.Empty,
                        FamilyNameEn = registrationRequest.FamilyNameEn,
                        FirstNameAr = registrationRequest.FirstNameAr,
                        SecondNameAr = registrationRequest.SecondNameAr,
                        ThirdNameAr = registrationRequest.ThirdNameAr ?? string.Empty,
                        FamilyNameAr = registrationRequest.FamilyNameAr,
                        Email = registrationRequest.Email,
                        Password = HashPassword(registrationRequest.Password),
                        Phone = registrationRequest.Phone,
                        DateOfBirth = registrationRequest.DateOfBirth,
                        IdExpiryDate = registrationRequest.IdExpiryDate,
                        BuildingNo = registrationRequest.BuildingNo,
                        Street = registrationRequest.Street,
                        District = registrationRequest.District ?? string.Empty,
                        City = registrationRequest.City ?? string.Empty,
                        Zipcode = registrationRequest.Zipcode ?? string.Empty,
                        AddNo = registrationRequest.AddNo ?? string.Empty,
                        Iban = registrationRequest.Iban ?? string.Empty,
                        Dependents = registrationRequest.Dependents,
                        SalaryDakhli = registrationRequest.SalaryDakhli,
                        SalaryCustomer = registrationRequest.SalaryCustomer,
                        Los = registrationRequest.Los,
                        Sector = registrationRequest.Sector ?? string.Empty,
                        Employer = registrationRequest.Employer ?? string.Empty,
                        RegistrationDate = DateTime.UtcNow,
                        Consent = registrationRequest.Consent,
                        ConsentDate = registrationRequest.Consent ? DateTime.UtcNow : null,
                        NafathStatus = registrationRequest.NafathStatus ?? string.Empty,
                        NafathTimestamp = registrationRequest.NafathStatus != null ? DateTime.UtcNow : null
                    };

                    _context.Customers.Add(customer);

                    // Handle device registration if provided
                    if (registrationRequest.DeviceInfo != null)
                    {
                        // Disable any existing devices
                        await _context.CustomerDevices
                            .Where(d => d.NationalId == registrationRequest.NationalId)
                            .ExecuteUpdateAsync(s => s
                                .SetProperty(d => d.Status, "disabled")
                                .SetProperty(d => d.LastUsedAt, DateTime.UtcNow));

                        // Register new device
                        var device = new CustomerDevice
                        {
                            NationalId = registrationRequest.NationalId,
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

                        // Log device registration
                        var authLog = new AuthLog
                        {
                            NationalId = registrationRequest.NationalId,
                            DeviceId = registrationRequest.DeviceInfo.DeviceId,
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

                    if (registrationRequest.DeviceInfo != null)
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
                _logger.LogError(ex, "Error during registration for National ID: {NationalId}", registrationRequest?.NationalId);

                // Log registration failure if device info was provided
                if (registrationRequest?.DeviceInfo != null)
                {
                    var authLog = new AuthLog
                    {
                        NationalId = registrationRequest.NationalId,
                        DeviceId = registrationRequest.DeviceInfo.DeviceId,
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

    public class IdCheckRequest
    {
        public bool CheckOnly { get; set; }
        public required string NationalId { get; set; }
        public required DeviceInfo DeviceInfo { get; set; }
    }
} 