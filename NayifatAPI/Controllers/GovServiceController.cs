using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using NayifatAPI.Models;
using NayifatAPI.Services;
using Microsoft.AspNetCore.Authorization;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api")]
    public class GovServiceController : ControllerBase
    {
        private readonly IGovService _govService;
        private readonly AuditService _audit;

        public GovServiceController(IGovService govService, AuditService audit)
        {
            _govService = govService;
            _audit = audit;
        }

        [HttpGet("get_gov_services")]
        public async Task<IActionResult> GetGovernmentData([FromQuery] string national_id)
        {
            // Add cache control headers
            Response.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
            Response.Headers.Add("Pragma", "no-cache");
            Response.Headers.Add("Expires", "0");

            if (string.IsNullOrEmpty(national_id))
            {
                await _audit.LogAsync(null, "Get Government Data Failed", "National ID parameter is required");
                return BadRequest(new { status = "error", message = "National ID parameter is required" });
            }

            try
            {
                var response = await _govService.GetGovernmentData(national_id);
                return Ok(response);
            }
            catch (System.Exception ex)
            {
                await _audit.LogAsync(null, "Get Government Data Failed", "An unexpected error occurred");
                return StatusCode(500, new { status = "error", message = "An unexpected error occurred", error = ex.Message });
            }
        }
    }
} 