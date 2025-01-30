using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using Microsoft.Extensions.Logging;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HealthController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<HealthController> _logger;

        public HealthController(ApplicationDbContext context, ILogger<HealthController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpGet("database")]
        public async Task<IActionResult> CheckDatabase()
        {
            try
            {
                // Test database connection
                bool canConnect = await _context.Database.CanConnectAsync();
                
                if (!canConnect)
                {
                    _logger.LogError("Cannot connect to database");
                    return StatusCode(500, new { 
                        status = "error", 
                        message = "Cannot connect to database"
                    });
                }

                // Get database name
                string databaseName = _context.Database.GetDbConnection().Database;

                // Try to query a table
                var customerCount = await _context.Customers.CountAsync();

                return Ok(new { 
                    status = "healthy", 
                    database = databaseName,
                    customerCount = customerCount,
                    message = "Successfully connected to database"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Database health check failed");
                return StatusCode(500, new { 
                    status = "error", 
                    message = ex.Message
                });
            }
        }

        [HttpGet]
        public IActionResult Get()
        {
            return Ok(new { status = "healthy" });
        }
    }
} 