using System.Data;
using System.IO.Compression;
using System.Text;
using Microsoft.Extensions.Options;
using MySql.Data.MySqlClient;
using NayifatAPI.Models;

namespace NayifatAPI.Services;

public interface IAuditService
{
    Task LogAuditAsync(int userId, string actionDescription, string? details = null);
}

public class AuditService : IAuditService
{
    private readonly DatabaseService _db;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly ILogger<AuditService> _logger;
    private const int COMPRESSION_THRESHOLD = 1000; // Compress if details are longer than 1KB

    public AuditService(
        DatabaseService db,
        IHttpContextAccessor httpContextAccessor,
        ILogger<AuditService> logger)
    {
        _db = db;
        _httpContextAccessor = httpContextAccessor;
        _logger = logger;
    }

    private (string data, bool isCompressed) CompressIfNeeded(string? input)
    {
        if (string.IsNullOrEmpty(input) || input.Length <= COMPRESSION_THRESHOLD)
        {
            return (input ?? "", false);
        }

        try
        {
            var inputBytes = Encoding.UTF8.GetBytes(input);
            using var memoryStream = new MemoryStream();
            using (var gzipStream = new GZipStream(memoryStream, CompressionMode.Compress))
            {
                gzipStream.Write(inputBytes, 0, inputBytes.Length);
            }
            var compressedData = Convert.ToBase64String(memoryStream.ToArray());
            
            // Only use compression if it actually saves space
            if (compressedData.Length < input.Length)
            {
                return (compressedData, true);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to compress audit details, will store uncompressed");
        }

        return (input, false);
    }

    private string? DecompressIfNeeded(string? input, bool isCompressed)
    {
        if (!isCompressed || string.IsNullOrEmpty(input))
        {
            return input;
        }

        try
        {
            var compressedBytes = Convert.FromBase64String(input);
            using var memoryStream = new MemoryStream(compressedBytes);
            using var gzipStream = new GZipStream(memoryStream, CompressionMode.Decompress);
            using var resultStream = new MemoryStream();
            gzipStream.CopyTo(resultStream);
            return Encoding.UTF8.GetString(resultStream.ToArray());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to decompress audit details");
            return input;
        }
    }

    public async Task LogAuditAsync(int userId, string actionDescription, string? details = null)
    {
        try
        {
            using var connection = await _db.CreateConnectionAsync();
            var ipAddress = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? "unknown";
            var userAgent = _httpContextAccessor.HttpContext?.Request.Headers.UserAgent.ToString() ?? "unknown";

            var (compressedDetails, isCompressed) = CompressIfNeeded(details);

            const string query = @"
                INSERT INTO AuditTrail 
                (user_id, action_description, ip_address, created_at, details, is_compressed, user_agent) 
                VALUES 
                (@UserId, @ActionDescription, @IpAddress, UTC_TIMESTAMP(), @Details, @IsCompressed, @UserAgent)";

            using var command = connection.CreateCommand();
            command.CommandText = query;

            var parameters = new[]
            {
                new MySqlParameter("@UserId", userId),
                new MySqlParameter("@ActionDescription", actionDescription),
                new MySqlParameter("@IpAddress", ipAddress),
                new MySqlParameter("@Details", compressedDetails ?? (object)DBNull.Value),
                new MySqlParameter("@IsCompressed", isCompressed),
                new MySqlParameter("@UserAgent", userAgent)
            };

            foreach (var param in parameters)
            {
                command.Parameters.Add(param);
            }

            await command.ExecuteNonQueryAsync();

            if (isCompressed)
            {
                _logger.LogInformation(
                    "Compressed audit log for action {Action}. Original size: {OriginalSize}, Compressed size: {CompressedSize}", 
                    actionDescription, 
                    details?.Length ?? 0, 
                    compressedDetails?.Length ?? 0
                );
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error logging audit trail for user {UserId}: {Action}", 
                userId, actionDescription);
            throw;
        }
    }
} 