using System.Text.Json;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Services
{
    public class AuditLogService : IAuditLogService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<AuditLogService> _logger;

        public AuditLogService(
            ApplicationDbContext context,
            ILogger<AuditLogService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task LogAsync(string? nationalId, string action, object details)
        {
            try
            {
                var log = new AuthLog
                {
                    NationalId = nationalId,
                    AuthType = action,
                    Status = "success",
                    FailureReason = null,
                    IpAddress = null,
                    UserAgent = null,
                    CreatedAt = DateTime.UtcNow
                };

                _context.AuthLogs.Add(log);
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error logging audit event. NationalId: {NationalId}, Action: {Action}, Details: {Details}",
                    nationalId, action, JsonSerializer.Serialize(details));
            }
        }
    }
} 