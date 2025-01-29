using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    public class DeviceController : ApiBaseController
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<DeviceController> _logger;

        public DeviceController(ApplicationDbContext context, ILogger<DeviceController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpPost("register")]
        public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var customer = await _context.Customers.FindAsync(request.NationalId);
                if (customer == null)
                {
                    return Error("Customer not found", 404);
                }

                // Disable all existing devices for this user if deviceId is provided
                if (!string.IsNullOrEmpty(request.DeviceId))
                {
                    await _context.CustomerDevices
                        .Where(d => d.NationalId == request.NationalId)
                        .ExecuteUpdateAsync(s => s
                            .SetProperty(d => d.Status, "disabled")
                            .SetProperty(d => d.LastUsedAt, DateTime.UtcNow));
                }

                // Register new device
                var device = new CustomerDevice
                {
                    NationalId = request.NationalId,
                    DeviceId = request.DeviceId,
                    Platform = request.Platform,
                    Model = request.Model,
                    Manufacturer = request.Manufacturer,
                    BiometricEnabled = false, // Default to false, can be enabled later
                    Status = "active",
                    CreatedAt = DateTime.UtcNow,
                    LastUsedAt = DateTime.UtcNow
                };

                _context.CustomerDevices.Add(device);

                // Log the device registration
                var authLog = new AuthLog
                {
                    NationalId = request.NationalId,
                    DeviceId = request.DeviceId,
                    AuthType = "device_registration",
                    Status = "success",
                    IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = HttpContext.Request.Headers["User-Agent"].ToString(),
                    CreatedAt = DateTime.UtcNow
                };

                _context.AuthLogs.Add(authLog);
                await _context.SaveChangesAsync();

                return Success(new
                {
                    status = "success",
                    message = "Device registered successfully",
                    device_id = device.DeviceId
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error registering device for National ID: {NationalId}", request.NationalId);

                // Log failed attempt
                var authLog = new AuthLog
                {
                    NationalId = request.NationalId,
                    DeviceId = request.DeviceId,
                    AuthType = "device_registration",
                    Status = "failed",
                    IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = HttpContext.Request.Headers["User-Agent"].ToString(),
                    FailureReason = ex.Message,
                    CreatedAt = DateTime.UtcNow
                };

                _context.AuthLogs.Add(authLog);
                await _context.SaveChangesAsync();

                return Error("Internal server error", 500);
            }
        }
    }

    public class RegisterDeviceRequest
    {
        public required string NationalId { get; set; }
        public required string DeviceId { get; set; }
        public required string Platform { get; set; }
        public required string Model { get; set; }
        public required string Manufacturer { get; set; }
        public string? OsVersion { get; set; }
        public bool BiometricEnabled { get; set; }
    }
} 