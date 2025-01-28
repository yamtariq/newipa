using MySql.Data.MySqlClient;
using System.Data;
using Microsoft.Extensions.Options;

namespace NayifatAPI.Services;

public class DatabaseService
{
    private readonly string _connectionString;
    private readonly ILogger<DatabaseService> _logger;

    public DatabaseService(IOptions<DatabaseSettings> settings, ILogger<DatabaseService> logger)
    {
        _connectionString = settings.Value.ConnectionString;
        _logger = logger;

        // Clear all connection pools to ensure clean state
        MySqlConnection.ClearAllPools();
    }

    public IDbConnection CreateConnection()
    {
        try
        {
            var connection = new MySqlConnection(_connectionString);
            
            // Set connection properties
            var settings = ((MySqlConnection)connection).Settings;
            settings.AllowZeroDateTime = true;
            settings.ConvertZeroDateTime = true;
            settings.ConnectionTimeout = 30;
            settings.CharacterSet = "utf8mb4";
            
            connection.Open();
            
            // Set session timezone to Riyadh (UTC+3)
            using var command = connection.CreateCommand();
            command.CommandText = "SET time_zone = '+03:00'"; // Riyadh timezone
            command.ExecuteNonQuery();
            
            return connection;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating database connection");
            throw;
        }
    }

    public async Task<IDbConnection> CreateConnectionAsync()
    {
        try
        {
            var connection = new MySqlConnection(_connectionString);
            
            // Set connection properties
            var settings = ((MySqlConnection)connection).Settings;
            settings.AllowZeroDateTime = true;
            settings.ConvertZeroDateTime = true;
            settings.ConnectionTimeout = 30;
            settings.CharacterSet = "utf8mb4";
            
            await connection.OpenAsync();
            
            // Set session timezone to Riyadh (UTC+3)
            using var command = connection.CreateCommand();
            command.CommandText = "SET time_zone = '+03:00'"; // Riyadh timezone
            await command.ExecuteNonQueryAsync();
            
            return connection;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating database connection asynchronously");
            throw;
        }
    }
} 