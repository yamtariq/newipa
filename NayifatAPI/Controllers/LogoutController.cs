using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Services;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("[controller]")]
public class LogoutController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<LogoutController> _logger;

    public LogoutController(IAuthService authService, ILogger<LogoutController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> Logout()
    {
        try
        {
            // Check for both API key and session token in the request headers
            if (!Request.Headers.TryGetValue("api-key", out var apiKey) || 
                !Request.Headers.TryGetValue("session-token", out var sessionToken))
            {
                return BadRequest(new { status = "error", message = "API key or session token is missing" });
            }

            // First validate the API key
            if (!await _authService.ValidateApiKeyAsync(apiKey!))
            {
                return BadRequest(new { status = "error", message = "Invalid or expired API key" });
            }

            var result = await _authService.LogoutAsync(sessionToken!);
            return Ok(new { status = result.Status, message = result.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during logout");
            return StatusCode(500, new { status = "error", message = "An error occurred during logout" });
        }
    }
} 