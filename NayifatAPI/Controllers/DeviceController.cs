using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api")]
    public class DeviceController : ControllerBase
    {
        private readonly IAuthService _authService;

        public DeviceController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("register_device")]
        [ProducesResponseType(typeof(DeviceRegistrationResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> RegisterDevice([FromBody] DeviceRegistrationRequest request)
        {
            // Get IP and User Agent
            var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
            var userAgent = HttpContext.Request.Headers.UserAgent.ToString();

            // Register device
            var response = await _authService.RegisterDevice(request, ipAddress, userAgent);

            // Return response with 200 status code regardless of success/error
            // This matches the PHP implementation's behavior
            return Ok(response);
        }
    }
} 