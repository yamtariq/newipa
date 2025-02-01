namespace NayifatAPI.Services
{
    public interface IAuditLogService
    {
        Task LogAsync(string? nationalId, string action, object details);
    }
} 