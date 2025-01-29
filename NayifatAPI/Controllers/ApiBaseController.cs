using Microsoft.AspNetCore.Mvc;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]  // This will use the controller name as the route
    public abstract class ApiBaseController : ControllerBase
    {
        protected IActionResult ApiResponse(bool success, object? data = null, string? message = null, int statusCode = 200)
        {
            var response = new
            {
                status = success ? "success" : "error",
                message = message,
                data = data
            };

            return StatusCode(statusCode, response);
        }

        protected IActionResult Success(object? data = null, string? message = null)
        {
            return Ok(new
            {
                status = "success",
                message,
                data
            });
        }

        protected IActionResult Error(string message, int statusCode = 400, object? data = null)
        {
            return StatusCode(statusCode, new
            {
                status = "error",
                message,
                data
            });
        }

        protected IActionResult ValidationError(string message, object? errors = null)
        {
            return BadRequest(new
            {
                status = "error",
                message,
                errors
            });
        }

        protected bool ValidateApiKey()
        {
            var apiKey = Request.Headers["api-key"].ToString();
            return apiKey == "7ca7427b418bdbd0b3b23d7debf69bf7";
        }

        protected bool ValidateFeatureHeader(string expectedFeature)
        {
            var feature = Request.Headers["X-Feature"].ToString();
            return feature == expectedFeature;
        }
    }
} 