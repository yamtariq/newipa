using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("user_registration")]
    public class UserRegistrationController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<UserRegistrationController> _logger;

        public UserRegistrationController(
            IAuthService authService,
            ILogger<UserRegistrationController> logger)
        {
            _authService = authService;
            _logger = logger;
        }

        [HttpPost]
        public async Task<IActionResult> Register([FromBody] UserRegistrationRequest request)
        {
            try
            {
                // Set cache control headers to match PHP implementation exactly
                Response.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
                Response.Headers.Add("Cache-Control", "post-check=0, pre-check=0");
                Response.Headers.Add("Pragma", "no-cache");

                // Validate request
                if (request == null || string.IsNullOrEmpty(request.NationalId))
                {
                    return BadRequest(new ApiResponse<object>
                    {
                        Status = "error",
                        Message = "Missing required field: national_id"
                    });
                }

                // Validate device info if provided
                if (request.DeviceInfo != null)
                {
                    if (string.IsNullOrEmpty(request.DeviceInfo.DeviceId) ||
                        string.IsNullOrEmpty(request.DeviceInfo.Platform) ||
                        string.IsNullOrEmpty(request.DeviceInfo.Model) ||
                        string.IsNullOrEmpty(request.DeviceInfo.Manufacturer))
                    {
                        return BadRequest(new ApiResponse<object>
                        {
                            Status = "error",
                            Message = "Missing required device info fields"
                        });
                    }
                }

                // Handle check_only request
                if (request.CheckOnly == true)
                {
                    var exists = await _authService.CheckNationalIdExists(request.NationalId);
                    return Ok(new ApiResponse<object>
                    {
                        Status = exists ? "error" : "success",
                        Message = exists ? "This ID already registered" : "ID available"
                    });
                }

                // Regular registration flow
                var (success, message) = await _authService.RegisterUser(request);
                
                if (!success)
                {
                    return BadRequest(new ApiResponse<object>
                    {
                        Status = "error",
                        Message = message
                    });
                }

                // Get government data for response
                var govData = _authService.GetGovernmentData(request);

                return Ok(new ApiResponse<object>
                {
                    Status = "success",
                    Message = message,
                    Data = new { gov_data = govData }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during user registration for national ID: {NationalId}", 
                    request?.NationalId ?? "unknown");
                
                return StatusCode(500, new ApiResponse<object>
                {
                    Status = "error",
                    Message = "An error occurred during registration"
                });
            }
        }
    }
} 
