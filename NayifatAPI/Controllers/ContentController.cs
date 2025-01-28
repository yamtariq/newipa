using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("master_fetch")]
public class ContentController : ControllerBase
{
    private readonly IContentService _contentService;

    public ContentController(IContentService contentService)
    {
        _contentService = contentService;
    }

    [HttpGet]
    public async Task<ActionResult<MasterFetchResponse>> Get([FromQuery] MasterFetchRequest request)
    {
        if (string.IsNullOrEmpty(request.Action))
        {
            return Ok(new MasterFetchResponse
            {
                Success = false,
                Message = "Missing required parameter: action"
            });
        }

        try
        {
            switch (request.Action.ToLower())
            {
                case "checkupdate":
                    var updates = await _contentService.FetchLastUpdatesAsync();
                    if (updates.Count == 0)
                    {
                        return Ok(new MasterFetchResponse
                        {
                            Success = false,
                            Message = "No content found"
                        });
                    }
                    return Ok(new MasterFetchResponse
                    {
                        Success = true,
                        Data = updates
                    });

                case "fetchdata":
                    var content = await _contentService.FetchAllContentAsync();
                    if (content.Count == 0)
                    {
                        return Ok(new MasterFetchResponse
                        {
                            Success = false,
                            Message = "No content found"
                        });
                    }
                    return Ok(new MasterFetchResponse
                    {
                        Success = true,
                        Data = content
                    });

                default:
                    return Ok(new MasterFetchResponse
                    {
                        Success = false,
                        Message = "Invalid action"
                    });
            }
        }
        catch (Exception ex)
        {
            return Ok(new MasterFetchResponse
            {
                Success = false,
                Message = $"Server error: {ex.Message}"
            });
        }
    }
} 