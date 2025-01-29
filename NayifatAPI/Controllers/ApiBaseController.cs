using Microsoft.AspNetCore.Mvc;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("/")]  // Root level routing to match PHP endpoints
    public abstract class ApiBaseController : ControllerBase
    {
        protected IActionResult ApiResponse(bool success, object data = null, string message = null, int statusCode = 200)
        {
            var response = new
            {
                status = success ? "success" : "error",
                message = message,
                data = data
            };

            return StatusCode(statusCode, response);
        }

        protected IActionResult Success(object data = null, string message = null)
        {
            return ApiResponse(true, data, message);
        }

        protected IActionResult Error(string message, int statusCode = 400, object data = null)
        {
            return ApiResponse(false, data, message, statusCode);
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