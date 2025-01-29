using System.Net.Http;
using Microsoft.AspNetCore.Mvc;
using System.Text;
using System.Text.Json;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProxyController : ApiBaseController
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<ProxyController> _logger;
        private readonly IConfiguration _configuration;

        public ProxyController(
            IHttpClientFactory httpClientFactory,
            ILogger<ProxyController> logger,
            IConfiguration configuration)
        {
            _httpClientFactory = httpClientFactory;
            _logger = logger;
            _configuration = configuration;
        }

        [HttpPost("forward")]
        public async Task<IActionResult> ForwardRequest([FromBody] ProxyRequest request)
        {
            try
            {
                // Validate API key
                if (!ValidateApiKey())
                {
                    return Error("Invalid API key", 401);
                }

                // Create HTTP client
                var client = _httpClientFactory.CreateClient();
                
                // Get the local endpoint base URL from configuration
                var localBaseUrl = _configuration["LocalEndpoint:BaseUrl"] ?? "http://localhost:5000";
                
                // Construct the full URL
                var url = $"{localBaseUrl.TrimEnd('/')}/{request.Endpoint.TrimStart('/')}";

                // Create the request message
                var method = ParseHttpMethod(request.Method ?? "POST");
                var httpRequest = new HttpRequestMessage(method, url);

                // Add request body if applicable
                if (request.Data != null && method != HttpMethod.Get)
                {
                    string contentType = request.ContentType ?? "application/json";
                    string content;

                    if (contentType == "application/x-www-form-urlencoded")
                    {
                        // Handle form data
                        var formData = request.Data as Dictionary<string, string>;
                        content = formData != null 
                            ? string.Join("&", formData.Select(kvp => $"{Uri.EscapeDataString(kvp.Key)}={Uri.EscapeDataString(kvp.Value)}"))
                            : "";
                    }
                    else
                    {
                        // Default to JSON
                        content = JsonSerializer.Serialize(request.Data);
                    }

                    httpRequest.Content = new StringContent(content, Encoding.UTF8, contentType);
                }

                // Forward headers
                foreach (var header in Request.Headers)
                {
                    if (!header.Key.Equals("Host", StringComparison.OrdinalIgnoreCase) &&
                        !header.Key.Equals("Content-Length", StringComparison.OrdinalIgnoreCase) &&
                        !header.Key.Equals("Content-Type", StringComparison.OrdinalIgnoreCase))
                    {
                        httpRequest.Headers.TryAddWithoutValidation(header.Key, header.Value.ToArray());
                    }
                }

                // Add custom headers if provided
                if (request.Headers != null)
                {
                    foreach (var header in request.Headers)
                    {
                        httpRequest.Headers.TryAddWithoutValidation(header.Key, header.Value);
                    }
                }

                // Send the request
                var response = await client.SendAsync(httpRequest);
                
                // Read the response content
                var content = await response.Content.ReadAsStringAsync();

                // Get response content type
                var responseContentType = response.Content.Headers.ContentType?.MediaType;
                
                try
                {
                    if (responseContentType?.Contains("json") == true || 
                        (string.IsNullOrEmpty(responseContentType) && IsValidJson(content)))
                    {
                        // Parse JSON response
                        var jsonResponse = JsonSerializer.Deserialize<object>(content);
                        return StatusCode((int)response.StatusCode, jsonResponse);
                    }
                    else if (responseContentType?.Contains("xml") == true)
                    {
                        // Return XML as is with correct content type
                        return Content(content, "application/xml", Encoding.UTF8);
                    }
                    else
                    {
                        // Return other content types as is
                        return Content(content, responseContentType ?? "text/plain", Encoding.UTF8);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error parsing response content. Returning as plain text.");
                    return Content(content, "text/plain", Encoding.UTF8);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error forwarding request to local endpoint");
                return Error("Internal server error", 500);
            }
        }

        private static HttpMethod ParseHttpMethod(string method)
        {
            return method.ToUpper() switch
            {
                "GET" => HttpMethod.Get,
                "POST" => HttpMethod.Post,
                "PUT" => HttpMethod.Put,
                "DELETE" => HttpMethod.Delete,
                "PATCH" => HttpMethod.Patch,
                _ => HttpMethod.Post
            };
        }

        private static bool IsValidJson(string content)
        {
            try
            {
                JsonDocument.Parse(content);
                return true;
            }
            catch
            {
                return false;
            }
        }
    }

    public class ProxyRequest
    {
        public required string Endpoint { get; set; }
        public object? Data { get; set; }
        public string? Method { get; set; }
        public string? ContentType { get; set; }
        public Dictionary<string, string>? Headers { get; set; }
    }
} 