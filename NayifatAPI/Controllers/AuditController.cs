using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;
using NayifatAPI.Middleware;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("audit_log")]
[RequireFeatureHeader("user")]
public class AuditController : ControllerBase
{
    private readonly IAuditService _auditService;
    private readonly ILogger<AuditController> _logger;

    public AuditController(
        IAuditService auditService,
        ILogger<AuditController> logger)
    {
        _auditService = auditService;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> LogAudit([FromBody] AuditRequest request)
    {
        try
        {
            await _auditService.LogAuditAsync(
                request.UserId,
                request.ActionDescription,
                request.Details);

            return Ok(new { success = true, message = "Audit log created successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in audit logging");
            return StatusCode(500, new { success = false, message = "Failed to create audit log" });
        }
    }
} 
