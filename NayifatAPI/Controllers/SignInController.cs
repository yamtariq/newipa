using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;
using System.Security.Cryptography;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("/signin")]  // Match PHP endpoint exactly
[Produces("application/json")]
public class SignInController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<SignInController> _logger;

    public SignInController(IAuthService authService, ILogger<SignInController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> SignIn([FromBody] SignInRequest? request)
    {
        // Add PHP-like headers
        Response.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        Response.Headers.Add("Cache-Control", "post-check=0, pre-check=0", false);
        Response.Headers.Add("Pragma", "no-cache");
        Response.ContentType = "application/json";

        try
        {
            // Check for null request (invalid JSON)
            if (request == null)
            {
                return Ok(new SignInResponse
                {
                    status = "error",
                    code = "INVALID_JSON",
                    message = "Invalid JSON input"
                });
            }

            if (string.IsNullOrEmpty(request.national_id))
            {
                return Ok(new SignInResponse
                {
                    status = "error",
                    code = "MISSING_FIELD",
                    message = "Missing required field: national_id"
                });
            }

            var customer = await _authService.GetCustomerByNationalId(request.national_id);
            
            if (customer == null)
            {
                await _authService.LogAuthAttempt(request.national_id, request.deviceId, "failed", "Customer not found");
                return Ok(new SignInResponse
                {
                    status = "error",
                    code = "CUSTOMER_NOT_FOUND",
                    message = "Invalid credentials"
                });
            }

            bool isPasswordAuth = !string.IsNullOrEmpty(request.password);
            
            if (isPasswordAuth)
            {
                var storedPassword = customer["password"]?.ToString();
                if (storedPassword != null)
                {
                    if (!BCrypt.Net.BCrypt.Verify(request.password, storedPassword))
                    {
                        await _authService.LogAuthAttempt(request.national_id, request.deviceId, "failed", "Invalid password");
                        return Ok(new SignInResponse
                        {
                            status = "error",
                            code = "INVALID_PASSWORD",
                            message = "Invalid credentials"
                        });
                    }
                }
            }
            else
            {
                return Ok(new SignInResponse
                {
                    status = "success",
                    code = "CUSTOMER_VERIFIED",
                    message = "Customer verified, proceed with OTP",
                    require_otp = true
                });
            }

            // Generate token
            var token = Convert.ToHexString(RandomNumberGenerator.GetBytes(32)).ToLower();

            // Update device last used if deviceId provided
            if (!string.IsNullOrEmpty(request.deviceId))
            {
                await _authService.UpdateDeviceLastUsed(request.national_id, request.deviceId);
            }

            // Log successful login
            await _authService.LogAuthAttempt(request.national_id, request.deviceId, "success");

            return Ok(new SignInResponse
            {
                status = "success",
                token = token,
                user = customer
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during signin");
            return Ok(new SignInResponse
            {
                status = "error",
                code = "SYSTEM_ERROR",
                message = ex.Message
            });
        }
    }
} 