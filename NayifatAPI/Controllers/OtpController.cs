using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;
using System.Security.Cryptography;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("[controller]")]
public class OtpController : ControllerBase
{
    private readonly ILogger<OtpController> _logger;
    private readonly DatabaseService _db;
    private readonly AuthService _auth;

    public OtpController(ILogger<OtpController> logger, DatabaseService db, AuthService auth)
    {
        _logger = logger;
        _db = db;
        _auth = auth;
    }

    [HttpPost("generate")]
    public async Task<IActionResult> Generate([FromForm] OtpGenerateRequest request)
    {
        try
        {
            // Set cache control headers
            Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0";
            Response.Headers["Cache-Control"] = "post-check=0, pre-check=0";
            Response.Headers["Pragma"] = "no-cache";

            // Validate API key and feature header
            var apiKeyValidation = await _auth.ValidateApiKeyAsync(HttpContext);
            if (!apiKeyValidation.IsValid)
            {
                return BadRequest(new ApiResponse<object>
                {
                    Status = "error",
                    Message = apiKeyValidation.Message
                });
            }

            // Generate and store OTP
            var result = await _auth.GenerateOtpAsync(request.NationalId);
            
            return Ok(new ApiResponse<OtpGenerateResponse>
            {
                Status = result.Status,
                Message = result.Message,
                Data = new OtpGenerateResponse
                {
                    Status = result.Status,
                    Message = result.Message,
                    OtpCode = result.OtpCode // Remove in production
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating OTP for national ID: {NationalId}", request.NationalId);
            return StatusCode(500, new ApiResponse<object>
            {
                Status = "error",
                Message = "An error occurred while generating OTP"
            });
        }
    }

    [HttpPost("verify")]
    public async Task<IActionResult> VerifyOtp([FromForm] OtpVerificationRequest request)
    {
        try
        {
            var (status, message, debug) = await _auth.VerifyOtpAsync(request.NationalId, request.OtpCode);
            
            var response = new OtpVerificationResponse
            {
                Status = status,
                Message = message,
                Debug = debug // Only included in development
            };

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying OTP");
            return StatusCode(500, new ApiResponse<object>
            {
                Status = "error",
                Message = "Internal server error"
            });
        }
    }
} 
