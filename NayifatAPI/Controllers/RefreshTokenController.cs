using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;
using System.Security.Cryptography;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("/refresh_token")]  // Match PHP endpoint exactly
[Produces("application/json")]
public class RefreshTokenController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<RefreshTokenController> _logger;

    public RefreshTokenController(IAuthService authService, ILogger<RefreshTokenController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest? request)
    {
        // Add PHP-like headers
        Response.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        Response.Headers.Add("Cache-Control", "post-check=0, pre-check=0", false);
        Response.Headers.Add("Pragma", "no-cache");
        Response.ContentType = "application/json";

        try
        {
            // Check for null request (invalid JSON)
            if (request == null || string.IsNullOrEmpty(request.refresh_token))
            {
                Response.StatusCode = 401;
                return Ok(new RefreshTokenResponse
                {
                    success = false,
                    error = "invalid_token",
                    message = "Invalid request data"
                });
            }

            // Validate refresh token
            var (userId, nationalId) = await _authService.ValidateRefreshToken(request.refresh_token);
            
            if (userId == null || nationalId == null)
            {
                Response.StatusCode = 401;
                return Ok(new RefreshTokenResponse
                {
                    success = false,
                    error = "invalid_token",
                    message = "Invalid or expired refresh token"
                });
            }

            // Generate new access token
            var accessToken = Convert.ToHexString(RandomNumberGenerator.GetBytes(32)).ToLower();
            var accessExpiry = (int)DateTimeOffset.UtcNow.ToUnixTimeSeconds() + AuthService.TOKEN_EXPIRY;

            // Update access token in database
            await _authService.UpdateAccessToken(userId, accessToken, accessExpiry);

            return Ok(new RefreshTokenResponse
            {
                success = true,
                access_token = accessToken,
                expires_in = AuthService.TOKEN_EXPIRY,
                token_type = "Bearer"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during token refresh");
            Response.StatusCode = 401;
            return Ok(new RefreshTokenResponse
            {
                success = false,
                error = "invalid_token",
                message = ex.Message
            });
        }
    }
} 