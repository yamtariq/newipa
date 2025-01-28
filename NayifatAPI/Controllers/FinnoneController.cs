using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FinnoneController : ControllerBase
{
    private readonly IFinnoneService _finnoneService;
    private readonly IAuditService _auditService;

    public FinnoneController(
        IFinnoneService finnoneService,
        IAuditService auditService)
    {
        _finnoneService = finnoneService;
        _auditService = auditService;
    }

    [HttpPost("create_customer")]
    public async Task<IActionResult> CreateCustomer([FromQuery] string applicationNo)
    {
        if (string.IsNullOrEmpty(applicationNo))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Application number is required",
                Data = null
            });
        }

        var response = await _finnoneService.CreateCustomerAsync(applicationNo);
        return response.Success ? Ok(response) : BadRequest(response);
    }

    [HttpGet("check_status")]
    public async Task<IActionResult> CheckStatus([FromQuery] string applicationNo)
    {
        if (string.IsNullOrEmpty(applicationNo))
        {
            return BadRequest(new ApiResponse<object>
            {
                Success = false,
                Message = "Application number is required",
                Data = null
            });
        }

        var response = await _finnoneService.CheckStatusAsync(applicationNo);
        return response.Success ? Ok(response) : BadRequest(response);
    }
} 