using Microsoft.AspNetCore.Mvc;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public abstract class BaseApiController : ControllerBase
    {
        protected IActionResult HandleException(Exception ex)
        {
            return StatusCode(500, new { error = "An internal server error occurred.", details = ex.Message });
        }

        protected IActionResult Success(object? data = null)
        {
            return Ok(new { success = true, data });
        }

        protected IActionResult Failure(string message, int statusCode = 400)
        {
            return StatusCode(statusCode, new { success = false, error = message });
        }
    }
} 