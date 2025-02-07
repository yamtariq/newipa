using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProxyController : ApiBaseController
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<ProxyController> _logger;
        private readonly HttpClient _httpClient;

        public ProxyController(
            ApplicationDbContext context,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            ILogger<ProxyController> logger,
            HttpClient httpClient
        ) : base(context, configuration)
        {
            _httpClientFactory = httpClientFactory;
            _logger = logger;
            _httpClient = httpClient;
        }

        [HttpPost("forward")]
        [Produces("application/json")]
        public async Task<IActionResult> ForwardRequest()
        {
            try
            {
                // 1. Validate API key
                if (!ValidateApiKey())
                    return BadRequest(new { success = false, message = "Invalid API key" });

                // 2. Get target URL from ?url= query string
                var targetUrl = Request.Query["url"].ToString().Trim();
                if (string.IsNullOrEmpty(targetUrl))
                    return BadRequest(new { success = false, message = "URL parameter is required" });

                // 3. Read raw JSON body from the incoming request
                string rawBody;
                using (var reader = new StreamReader(Request.Body, Encoding.UTF8, leaveOpen: true))
                {
                    rawBody = await reader.ReadToEndAsync();
                }

                // 4. Create a new HttpRequestMessage
                var forwardRequest = new HttpRequestMessage(HttpMethod.Post, targetUrl)
                {
                    Content = new StringContent(rawBody, Encoding.UTF8, "application/json")
                };

                // 5. Copy headers except Host
                foreach (var header in Request.Headers)
                {
                    if (!header.Key.Equals("Host", StringComparison.OrdinalIgnoreCase))
                    {
                        forwardRequest.Headers.TryAddWithoutValidation(header.Key, header.Value.ToArray());
                    }
                }

                // 6. Send request using the named client with decompression
                var client = _httpClientFactory.CreateClient("DecompressClient");
                var httpResponse = await client.SendAsync(forwardRequest);

                // Read response as bytes first
                var responseBytes = await httpResponse.Content.ReadAsByteArrayAsync();
                
                // Check if response is compressed (look for gzip magic numbers)
                if (responseBytes.Length >= 2 && responseBytes[0] == 0x1f && responseBytes[1] == 0x8b)
                {
                    using var compressedStream = new MemoryStream(responseBytes);
                    using var gzipStream = new System.IO.Compression.GZipStream(compressedStream, System.IO.Compression.CompressionMode.Decompress);
                    using var resultStream = new MemoryStream();
                    await gzipStream.CopyToAsync(resultStream);
                    responseBytes = resultStream.ToArray();
                }

                // Convert to string, handling potential encoding issues
                var responseString = Encoding.UTF8.GetString(responseBytes);

                // Log the raw response for debugging
                _logger.LogInformation($"Raw response length: {responseBytes.Length}");
                _logger.LogInformation($"Response content: {responseString}");

                // Get content type from response headers
                var contentType = httpResponse.Content.Headers.ContentType?.MediaType ?? "application/json";

                // Check if it's JSON and try to validate
                if (contentType.Contains("json"))
                {
                    try
                    {
                        // Try to parse as JSON to validate
                        var jsonObj = System.Text.Json.JsonDocument.Parse(responseString);
                        return Content(responseString, "application/json");
                    }
                    catch (System.Text.Json.JsonException)
                    {
                        _logger.LogWarning("Response claimed to be JSON but failed to parse");
                        // If JSON parsing fails, return raw content
                        return Content(responseString, contentType);
                    }
                }
                
                // For non-JSON responses, return as is with original content type
                return Content(responseString, contentType);
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error in proxy: {ex}");
                return StatusCode(StatusCodes.Status500InternalServerError,
                    new { success = false, message = $"Internal server error: {ex.Message}" });
            }
        }

        protected new bool ValidateApiKey()
        {
            // Adjust to your real validation logic
            var apiKey = Request.Headers["x-api-key"].FirstOrDefault() ?? string.Empty;
            return !string.IsNullOrEmpty(apiKey) && apiKey == "7ca7427b418bdbd0b3b23d7debf69bf7";
        }

        // 💡 New endpoint for Dakhli salary
        [HttpGet("dakhli/salary")]
        public async Task<IActionResult> GetDakhliSalary(
            [FromQuery] string customerId,
            [FromQuery] string dob,
            [FromQuery] string reason)
        {
            try 
            {
                var url = $"https://172.22.226.190:4043/api/Dakhli/GetDakhliPubPriv?customerId={customerId}&dob={dob}&reason={reason}";
                var response = await _httpClient.GetAsync(url);
                var result = await response.Content.ReadAsStringAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching Dakhli salary data");
                return Error("Service temporarily unavailable", 503);
            }
        }
    }
}
