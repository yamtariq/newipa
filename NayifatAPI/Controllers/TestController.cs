using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using Microsoft.Data.SqlClient;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TestController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<TestController> _logger;

        public TestController(ApplicationDbContext context, ILogger<TestController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Get()
        {
            return Ok(new { message = "Test endpoint working!" });
        }

        [HttpGet("sql-info")]
        public async Task<IActionResult> GetSqlInfo()
        {
            try
            {
                var connection = _context.Database.GetDbConnection();
                
                // Ensure connection is open
                if (connection.State != System.Data.ConnectionState.Open)
                {
                    await connection.OpenAsync();
                }
                
                var connectionString = connection.ConnectionString;
                
                // Mask sensitive information by removing password
                var maskedConnectionString = string.Join(";",
                    connectionString.Split(';')
                        .Where(part => !part.StartsWith("Password=", StringComparison.OrdinalIgnoreCase))
                );
                
                var serverInfo = new
                {
                    DatabaseName = connection.Database,
                    ServerVersion = connection is SqlConnection sqlConnection ? sqlConnection.ServerVersion : "Unknown",
                    State = connection.State.ToString(),
                    ConnectionString = maskedConnectionString,
                    CanConnect = await _context.Database.CanConnectAsync()
                };

                return Ok(new { 
                    status = "success",
                    data = serverInfo,
                    message = "SQL Server information retrieved successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting SQL Server information");
                return StatusCode(500, new { 
                    status = "error",
                    message = ex.Message,
                    details = ex.ToString() // Adding full exception details for debugging
                });
            }
            finally
            {
                // Always ensure connection is closed
                if (_context.Database.GetDbConnection().State == System.Data.ConnectionState.Open)
                {
                    await _context.Database.GetDbConnection().CloseAsync();
                }
            }
        }
    }
} 