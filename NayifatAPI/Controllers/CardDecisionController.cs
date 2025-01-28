using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Models.CardDecision;
using NayifatAPI.Services;
using NayifatAPI.Middleware;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("[controller]")]
[FeatureHeader("user")]
public class CardDecisionController : ControllerBase
{
    private readonly ICardDecisionService _cardService;

    public CardDecisionController(ICardDecisionService cardService)
    {
        _cardService = cardService;
    }

    [HttpPost("cards_decision")]
    [ProducesResponseType(typeof(CardDecisionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(CardDecisionErrorResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCardDecision([FromBody] CardDecisionRequest request)
    {
        SetNoCacheHeaders();
        try
        {
            var result = await _cardService.ProcessCardDecision(request);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new ApiResponse<object>
            {
                status = "error",
                code = "SYSTEM_ERROR",
                message = ex.Message
            });
        }
    }

    [HttpPost("update_cards_application")]
    public async Task<IActionResult> UpdateCardApplication([FromBody] CardApplicationUpdateRequest request)
    {
        SetNoCacheHeaders();
        try
        {
            var result = await _cardService.UpdateCardApplication(request);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new ApiResponse<object>
            {
                status = "error",
                code = "SYSTEM_ERROR",
                message = ex.Message
            });
        }
    }

    private void SetNoCacheHeaders()
    {
        Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0";
        Response.Headers["Pragma"] = "no-cache";
    }
} 
