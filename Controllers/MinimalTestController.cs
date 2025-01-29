using Microsoft.AspNetCore.Mvc;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class MinimalTestController : ControllerBase
    {
        [HttpGet]
        public IActionResult Get()
        {
            return Ok(new { message = "MinimalTest controller working!" });
        }

        [HttpGet("ping")]
        public IActionResult Ping()
        {
            return Ok(new { message = "pong" });
        }
    }
} 