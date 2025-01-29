using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using System;
using System.Threading.Tasks;
using System.Collections.Generic;

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
            _logger.LogInformation("TestController constructed with route pattern: [controller]");
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

        [HttpGet("db-connection")]
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

        [HttpGet("db-tables")]
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

        [HttpGet("sql-info")]
        public async Task<IActionResult> GetSqlServerInfo()
        {
            _logger.LogInformation("Getting SQL Server information");
            try
            {
                var connection = _context.Database.GetDbConnection();
                var info = new List<object>();

                // Basic Connection Info
                info.Add(new
                {
                    section = "Connection Details",
                    details = new
                    {
                        serverName = connection.DataSource,
                        databaseName = connection.Database,
                        connectionState = connection.State.ToString(),
                        serverVersion = await _context.Database.SqlQuery<string>($"SELECT @@VERSION").FirstOrDefaultAsync()
                    }
                });

                if (await _context.Database.CanConnectAsync())
                {
                    // Server Configuration
                    var config = await _context.Database
                        .SqlQuery<dynamic>(@"
                            SELECT 
                                SERVERPROPERTY('Edition') as Edition,
                                SERVERPROPERTY('ProductVersion') as ProductVersion,
                                SERVERPROPERTY('ProductLevel') as ProductLevel,
                                SERVERPROPERTY('MachineName') as MachineName,
                                SERVERPROPERTY('InstanceName') as InstanceName,
                                SERVERPROPERTY('Collation') as Collation,
                                SERVERPROPERTY('IsIntegratedSecurityOnly') as IsIntegratedSecurityOnly
                        ").FirstOrDefaultAsync();
                    info.Add(new { section = "Server Configuration", details = config });

                    // Database Information
                    var dbInfo = await _context.Database
                        .SqlQuery<dynamic>(@"
                            SELECT 
                                d.name as DatabaseName,
                                d.state_desc as State,
                                d.recovery_model_desc as RecoveryModel,
                                d.compatibility_level as CompatibilityLevel,
                                d.collation_name as Collation,
                                CONVERT(VARCHAR, d.create_date, 120) as CreateDate,
                                CONVERT(DECIMAL(10,2), SUM(CAST(mf.size AS BIGINT)) * 8.0 / 1024) as SizeMB
                            FROM sys.databases d
                            JOIN sys.master_files mf ON d.database_id = mf.database_id
                            WHERE d.name = DB_NAME()
                            GROUP BY d.name, d.state_desc, d.recovery_model_desc, 
                                     d.compatibility_level, d.collation_name, d.create_date
                        ").FirstOrDefaultAsync();
                    info.Add(new { section = "Database Information", details = dbInfo });

                    // Table Count
                    var tableCount = await _context.Database
                        .SqlQuery<int>(@"
                            SELECT COUNT(*) 
                            FROM INFORMATION_SCHEMA.TABLES 
                            WHERE TABLE_TYPE = 'BASE TABLE'
                        ").FirstOrDefaultAsync();
                    info.Add(new { section = "Schema Information", details = new { totalTables = tableCount } });

                    return Ok(new
                    {
                        status = "success",
                        message = "SQL Server information retrieved successfully",
                        timestamp = DateTime.UtcNow,
                        information = info
                    });
                }
                else
                {
                    return BadRequest(new
                    {
                        status = "error",
                        message = "Could not connect to database",
                        timestamp = DateTime.UtcNow
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting SQL Server information");
                return StatusCode(500, new
                {
                    status = "error",
                    message = "Error retrieving SQL Server information",
                    details = ex.Message,
                    timestamp = DateTime.UtcNow
                });
            }
        }
    }
} 