using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("[controller]")]
public class PasswordController : ControllerBase
{
    private readonly ILogger<PasswordController> _logger;
    private readonly IAuthService _authService;

    public PasswordController(ILogger<PasswordController> logger, IAuthService authService)
    {
        _logger = logger;
        _authService = authService;
    }

    [HttpPost("change")]
    [Consumes("application/x-www-form-urlencoded")]
    public async Task<IActionResult> ChangePassword([FromForm] PasswordChangeRequest request)
    {
        try
        {
            // Set cache control headers
            Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0";
            Response.Headers["Cache-Control"] = "post-check=0, pre-check=0";
            Response.Headers["Pragma"] = "no-cache";
            Response.Headers["Accept"] = "application/x-www-form-urlencoded";
            Response.Headers["Content-Type"] = "application/json; charset=utf-8";

            var (status, code, message, messageAr) = await _authService.ChangePasswordAsync(
                request.NationalId,
                request.NewPassword,
                request.Type
            );

            if (status == "success")
            {
                return Ok(new PasswordChangeResponse
                {
                    Status = status,
                    Message = message,
                    MessageAr = messageAr
                });
            }
            else
            {
                return BadRequest(new PasswordChangeErrorResponse
                {
                    Status = status,
                    Code = code,
                    Message = message,
                    MessageAr = messageAr
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error changing password for national ID: {NationalId}", request.NationalId);
            return StatusCode(500, new PasswordChangeErrorResponse
            {
                Status = "error",
                Code = "UNKNOWN_ERROR",
                Message = "An unexpected error occurred",
                MessageAr = "حدث خطأ غير متوقع"
            });
        }
    }
} 