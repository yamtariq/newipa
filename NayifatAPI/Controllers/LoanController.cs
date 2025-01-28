using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("api")]
public class LoanController : ControllerBase
{
    private readonly ILoanService _loanService;
    private readonly ILogger<LoanController> _logger;

    public LoanController(
        ILoanService loanService,
        ILogger<LoanController> logger)
    {
        _loanService = loanService;
        _logger = logger;
    }

    [HttpPost("loan_decision")]
    [ProducesResponseType(typeof(LoanDecisionResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetLoanDecision([FromBody] LoanDecisionRequest request)
    {
        try
        {
            // Add cache control headers to match PHP implementation
            Response.Headers.CacheControl = "no-store, no-cache, must-revalidate, max-age=0";
            Response.Headers.Pragma = "no-cache";

            var result = await _loanService.GetLoanDecisionAsync(request);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing loan decision request");
            return Ok(LoanDecisionResponse.Error(
                "SYSTEM_ERROR",
                "An unexpected error occurred"
            ));
        }
    }
} 