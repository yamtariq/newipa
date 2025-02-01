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