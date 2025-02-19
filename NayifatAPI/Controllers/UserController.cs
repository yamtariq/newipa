using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ApiBaseController
    {
        private readonly ILogger<UserController> _logger;

        public UserController(
            ApplicationDbContext context,
            ILogger<UserController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpGet("profile")]
        public async Task<IActionResult> GetUser([FromBody] GetUserRequest request)
        {
            if (!ValidateApiKey() || !ValidateFeatureHeader("user"))
            {
                return Error("Invalid headers", 401);
            }

            try
            {
                var customer = await _context.Customers
                    .FirstOrDefaultAsync(c => c.NationalId == request.NationalId);

                if (customer == null)
                {
                    return Error("User not found", 404);
                }

                var devices = await _context.CustomerDevices
                    .Where(d => d.NationalId == request.NationalId && d.IsActive)
                    .ToListAsync();

                var deviceList = devices.Select(d => new
                {
                    device_id = d.DeviceId,
                    device_name = d.DeviceName,
                    platform = d.Platform,
                    os_version = d.OsVersion,
                    is_biometric_enabled = d.IsBiometricEnabled,
                    registered_at = d.RegisteredAt.ToString("yyyy-MM-dd HH:mm:ss"),
                    last_used_at = d.LastUsedAt?.ToString("yyyy-MM-dd HH:mm:ss")
                }).ToList();

                return Success(new
                {
                    user = new
                    {
                        national_id = customer.NationalId,
                        first_name_en = customer.FirstNameEn,
                        last_name_en = customer.FamilyNameEn,
                        email = customer.Email,
                        phone = customer.Phone,
                        date_of_birth = customer.DateOfBirth?.ToString("yyyy-MM-dd"),
                        id_expiry_date = customer.IdExpiryDate?.ToString("yyyy-MM-dd"),
                        mpin_enabled = customer.MpinEnabled,
                        registration_date = customer.RegistrationDate.ToString("yyyy-MM-dd HH:mm:ss")
                    },
                    devices = deviceList
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user details for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }
    }

    public class GetUserRequest
    {
        public required string NationalId { get; set; }
    }
} 