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
        }

        [HttpGet("db-connection")]
        public async Task<IActionResult> TestConnection()
        {
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

                    return Ok(new { 
                        status = "success", 
                        message = "Successfully connected to database",
                        databaseName = connection.Database,
                        serverVersion = version,
                        serverName = connection.DataSource
                    });
                }
                else
                {
                    return BadRequest(new { 
                        status = "error", 
                        message = "Could not connect to database",
                        details = "Database connection test failed"
                    });
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

        [HttpGet("db-tables")]
        public async Task<IActionResult> TestTables()
        {
            try
            {
                var tables = await _context.Database
                    .SqlQuery<string>($@"
                        SELECT TABLE_NAME 
                        FROM INFORMATION_SCHEMA.TABLES 
                        WHERE TABLE_TYPE = 'BASE TABLE'")
                    .ToListAsync();

                return Ok(new
                {
                    status = "success",
                    message = "Successfully retrieved tables",
                    tables = tables
                });
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