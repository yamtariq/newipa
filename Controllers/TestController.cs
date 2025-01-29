using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using System;
using System.Threading.Tasks;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<TestController> _logger;

        public TestController(ApplicationDbContext context, ILogger<TestController> logger)
        {
            _context = context;
            _logger = logger;
            _logger.LogInformation("TestController constructed");
        }

        [HttpGet]
        public IActionResult Index()
        {
            _logger.LogInformation("Index endpoint called");
            return Ok(new { message = "Test controller is working" });
        }

        [HttpGet("health")]
        public IActionResult HealthCheck()
        {
            _logger.LogInformation("Health check endpoint called at: {Path}", 
                HttpContext?.Request?.Path.Value ?? "unknown");
            return Ok(new { 
                status = "healthy", 
                timestamp = DateTime.UtcNow,
                path = HttpContext?.Request?.Path.Value
            });
        }

        [HttpGet]
        [Route("db-connection")]
        public async Task<IActionResult> TestConnection()
        {
            _logger.LogInformation("TestConnection endpoint called");
            try
            {
                _logger.LogInformation("Testing database connection...");
                
                var connection = _context.Database.GetDbConnection();
                _logger.LogInformation("Connection string: {ConnectionString}", 
                    connection.ConnectionString.Replace("Password=.*?;", "Password=***;"));

                bool canConnect = await _context.Database.CanConnectAsync();
                _logger.LogInformation("Can connect: {CanConnect}", canConnect);
                
                if (canConnect)
                {
                    // Try to get database version
                    var version = await _context.Database
                        .SqlQuery<string>($"SELECT @@VERSION")
                        .FirstOrDefaultAsync();

                    var result = new { 
                        status = "success", 
                        message = "Successfully connected to database",
                        databaseName = connection.Database,
                        serverVersion = version,
                        serverName = connection.DataSource
                    };
                    _logger.LogInformation("Connection successful: {@Result}", result);
                    return Ok(result);
                }
                else
                {
                    var result = new { 
                        status = "error", 
                        message = "Could not connect to database",
                        details = "Database connection test failed"
                    };
                    _logger.LogWarning("Connection failed: {@Result}", result);
                    return BadRequest(result);
                }
            }
            catch (SqlException sqlEx)
            {
                _logger.LogError(sqlEx, "SQL Exception occurred");
                return StatusCode(500, new { 
                    status = "error", 
                    message = "SQL Server error",
                    errorCode = sqlEx.Number,
                    details = sqlEx.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "General exception occurred");
                return StatusCode(500, new { 
                    status = "error", 
                    message = "Database connection error",
                    details = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }

        [HttpGet]
        [Route("db-tables")]
        public async Task<IActionResult> TestTables()
        {
            _logger.LogInformation("TestTables endpoint called");
            try
            {
                var tables = await _context.Database
                    .SqlQuery<string>($@"
                        SELECT TABLE_NAME 
                        FROM INFORMATION_SCHEMA.TABLES 
                        WHERE TABLE_TYPE = 'BASE TABLE'")
                    .ToListAsync();

                var result = new
                {
                    status = "success",
                    message = "Successfully retrieved tables",
                    tables = tables
                };
                _logger.LogInformation("Tables retrieved: {@Result}", result);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving tables");
                return StatusCode(500, new
                {
                    status = "error",
                    message = "Error retrieving tables",
                    details = ex.Message
                });
            }
        }
    }
} 