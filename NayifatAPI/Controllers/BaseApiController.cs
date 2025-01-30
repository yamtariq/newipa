using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using System.Security.Cryptography;
using System.Text;

namespace NayifatAPI.Controllers
{
    public class ApiKey
    {
        public required string Key { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastUsedAt { get; set; }
    }

    [ApiController]
    [Route("api/[controller]")]
    public abstract class BaseApiController : ControllerBase
    {
        protected readonly ApplicationDbContext _context;
        protected readonly IConfiguration _configuration;

        protected BaseApiController(ApplicationDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        protected bool ValidateApiKey()
        {
            try
            {
                var providedApiKey = Request.Headers["x-api-key"].ToString();
                if (string.IsNullOrEmpty(providedApiKey))
                {
                    return false;
                }

                var apiKey = _context.ApiKeys
                    .FirstOrDefault(k => k.Key == providedApiKey && k.IsActive);

                if (apiKey == null)
                {
                    return false;
                }

                if (apiKey.ExpiresAt.HasValue && apiKey.ExpiresAt.Value < DateTime.UtcNow)
                {
                    return false;
                }

                return true;
            }
            catch
            {
                return false;
            }
        }

        protected bool ValidateFeatureHeader(string feature)
        {
            try
            {
                var featureHeader = Request.Headers["x-feature"].ToString();
                if (string.IsNullOrEmpty(featureHeader))
                {
                    return false;
                }

                return featureHeader.Equals(feature, StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return false;
            }
        }

        protected IActionResult HandleException(Exception ex)
        {
            return StatusCode(500, new { error = "An internal server error occurred.", details = ex.Message });
        }

        protected IActionResult Success(object? data = null)
        {
            return Ok(new { success = true, data });
        }

        protected IActionResult Success(object data, object metadata)
        {
            return Ok(new { success = true, data, metadata });
        }

        protected IActionResult Failure(string message, int statusCode = 400)
        {
            return StatusCode(statusCode, new { success = false, error = message });
        }

        protected IActionResult Error(string message, int statusCode = 400)
        {
            return Failure(message, statusCode);
        }

        protected IActionResult Error(string message, int statusCode, object details)
        {
            return StatusCode(statusCode, new { success = false, error = message, details });
        }
    }

    // Alias for backward compatibility
    public abstract class ApiBaseController : BaseApiController
    {
        protected ApiBaseController(ApplicationDbContext context, IConfiguration configuration) : base(context, configuration) { }
    }
} 