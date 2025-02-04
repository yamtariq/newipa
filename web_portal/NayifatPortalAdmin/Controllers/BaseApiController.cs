using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using NayifatPortalAdmin.Data;

namespace NayifatPortalAdmin.Controllers;

[ApiController]
[Route("api/[controller]")]
public abstract class BaseApiController : ControllerBase
{
    protected readonly ApplicationDbContext Context;

    protected BaseApiController(ApplicationDbContext context)
    {
        Context = context;
    }

    protected int GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null)
            throw new UnauthorizedAccessException("User is not authenticated");

        return int.Parse(userIdClaim.Value);
    }

    protected async Task LogActivityAsync(string action, string? details = null)
    {
        var activity = new Models.ActivityLog
        {
            EmployeeId = GetCurrentUserId(),
            Action = action,
            Details = details,
            IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
            CreatedAt = DateTime.UtcNow
        };

        Context.ActivityLogs.Add(activity);
        await Context.SaveChangesAsync();
    }
}
