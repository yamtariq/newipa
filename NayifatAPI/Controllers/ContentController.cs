using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ContentController : ApiBaseController
    {
        private readonly ILogger<ContentController> _logger;

        public ContentController(
            ApplicationDbContext context,
            ILogger<ContentController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpPost("timestamps")]
        public async Task<IActionResult> GetTimestamps()
        {
            _logger.LogInformation("TTT_");
            _logger.LogInformation("TTT_=== Getting Content Timestamps ===");

            if (!ValidateApiKey())
            {
                _logger.LogInformation("TTT_Invalid API key");
                return Error("Invalid API key", 401);
            }

            try
            {
                _logger.LogInformation("TTT_Fetching timestamps from database");
                
                var timestamps = await _context.MasterConfigs
                    .Select(c => new { c.Page, c.KeyName, c.LastUpdated })
                    .ToListAsync();

                _logger.LogInformation("TTT_Found {Count} content items", timestamps.Count);

                var result = timestamps.GroupBy(t => t.Page)
                    .ToDictionary(
                        g => g.Key,
                        g => g.ToDictionary(t => t.KeyName, t => t.LastUpdated)
                    );

                foreach (var page in result.Keys)
                {
                    _logger.LogInformation("TTT_Page: {Page}", page);
                    foreach (var (key, timestamp) in result[page])
                    {
                        _logger.LogInformation("TTT_  - {Key}: {Timestamp}", key, timestamp);
                    }
                }

                _logger.LogInformation("TTT_Successfully retrieved all timestamps");
                return Success(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "TTT_Error getting content timestamps: {Message}", ex.Message);
                return Error("Error getting content timestamps");
            }
        }

        [HttpPost("fetch")]
        public async Task<IActionResult> MasterFetch([FromBody] MasterFetchRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var config = await _context.MasterConfigs
                    .FirstOrDefaultAsync(c => 
                        c.Page == request.Page && 
                        c.KeyName == request.KeyName);

                if (config == null)
                {
                    return Success(new { content = "" });
                }

                // Special handling for different content types
                switch (request.Page.ToLower())
                {
                    case "home":
                        switch (request.KeyName)
                        {
                            case "slideshow_content":
                            case "slideshow_content_ar":
                                return Success(new { slides = ParseJsonContent(config.Value) });

                            case "contact_details":
                            case "contact_details_ar":
                                return Success(new { contact = ParseJsonContent(config.Value) });
                        }
                        break;

                    case "loans":
                        if (request.KeyName == "loan_ad")
                        {
                            return Success(new { ads = ParseJsonContent(config.Value) });
                        }
                        break;

                    case "cards":
                        if (request.KeyName == "card_ad")
                        {
                            return Success(new { ads = ParseJsonContent(config.Value) });
                        }
                        break;
                }

                // Default response for other content types
                return Success(new { content = config.Value });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching content for page: {Page}, key: {Key}", request.Page, request.KeyName);
                return Error("Internal server error", 500);
            }
        }

        private object ParseJsonContent(string json)
        {
            try
            {
                return System.Text.Json.JsonSerializer.Deserialize<object>(json) ?? json;
            }
            catch
            {
                return json;
            }
        }
    }

    public class MasterFetchRequest
    {
        public required string Page { get; set; }
        public required string KeyName { get; set; }
    }
} 