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
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProxyController : ApiBaseController
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<ProxyController> _logger;
        private readonly HttpClient _sslIgnorantClient;

        public ProxyController(
            ApplicationDbContext context,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            ILogger<ProxyController> logger
        ) : base(context, configuration)
        {
            _httpClientFactory = httpClientFactory;
            _logger = logger;
            // 💡 Create a more permissive HttpClient that completely ignores SSL
            var handler = new HttpClientHandler
            {
                ServerCertificateCustomValidationCallback = (sender, cert, chain, sslPolicyErrors) => true,
                ClientCertificateOptions = ClientCertificateOption.Manual,
                SslProtocols = System.Security.Authentication.SslProtocols.Tls12 | System.Security.Authentication.SslProtocols.Tls13,
                CheckCertificateRevocationList = false,
                UseProxy = false
            };

            // Add allowed hosts
            var allowedHosts = new[] {
                "172.22.226.190",
                "172.22.226.203"  // Adding the new internal IP
            };

            _sslIgnorantClient = new HttpClient(handler);
            _sslIgnorantClient.Timeout = TimeSpan.FromSeconds(30);
        }

        [HttpPost("forward")]
        [Produces("application/json")]
        [ResponseCache(Duration = 300)] // Cache for 5 minutes, adjust as needed
        public async Task<IActionResult> ForwardRequest()
        {
            string targetUrl = string.Empty; // Declare at method level
            try
            {
                // 💡 Detailed logging added: Starting ForwardRequest
                _logger.LogInformation("T_PROXY_Starting ForwardRequest. Request Method: {Method}, Request Path: {Path}", Request.Method, Request.Path);
                _logger.LogInformation("T_PROXY_Received headers: {Headers}", Request.Headers);

                // 1. Validate API key
                if (!ValidateApiKey())
                {
                    _logger.LogWarning("T_PROXY_Invalid API Key provided.");
                    return BadRequest(new { success = false, message = "Invalid API key" });
                }

                // 2. Get target URL from ?url= query string
                targetUrl = Request.Query["url"].ToString().Trim(); // Assign to the outer scope variable
                _logger.LogInformation("T_PROXY_Extracted Query Parameter 'url': {TargetUrl}", targetUrl);
                if (string.IsNullOrEmpty(targetUrl))
                    return BadRequest(new { success = false, message = "URL parameter is required" });

                // Validate allowed hosts first
                var allowedHosts = new[] {
                    "172.22.226.190",
                    "172.22.226.203"  // Adding the new internal IP
                };
                
                if (!allowedHosts.Any(host => targetUrl.Contains(host)))
                {
                    _logger.LogWarning("T_PROXY_Unauthorized target URL attempted: {TargetUrl}", targetUrl);
                    return BadRequest(new { success = false, message = "Unauthorized target URL" });
                }

                // 3. Read raw JSON body from the incoming request
                string rawBody;
                using (var reader = new StreamReader(Request.Body, Encoding.UTF8, leaveOpen: true))
                {
                    rawBody = await reader.ReadToEndAsync();
                }
                _logger.LogInformation("T_PROXY_Received Request Body: {RawBody}", rawBody);

                // 4. Create a new HttpRequestMessage
                var forwardRequest = new HttpRequestMessage(HttpMethod.Post, targetUrl)
                {
                    Content = new StringContent(rawBody, Encoding.UTF8, "application/json")
                };
                _logger.LogInformation("T_PROXY_Preparing forward HttpRequestMessage. Target URL: {TargetUrl}", targetUrl);
                _logger.LogInformation("T_PROXY_Initial Request Body set for forwarding: {ForwardBody}", rawBody);

                // 5. Copy headers except Host
                foreach (var header in Request.Headers)
                {
                    if (!header.Key.Equals("Host", StringComparison.OrdinalIgnoreCase))
                    {
                        forwardRequest.Headers.TryAddWithoutValidation(header.Key, header.Value.ToArray());
                        _logger.LogInformation("T_PROXY_Copying header: {HeaderKey} = {HeaderValues}", header.Key, string.Join(", ", header.Value.ToArray()));
                    }
                    else
                    {
                        _logger.LogInformation("T_PROXY_Skipping 'Host' header");
                    }
                }

                // 6. Send request using our SSL-ignorant client instead
                _logger.LogInformation("T_PROXY_Using SSL-ignorant client to forward request");
                try
                {
                    var httpResponse = await _sslIgnorantClient.SendAsync(forwardRequest);
                    _logger.LogInformation("T_PROXY_Request sent successfully.");
                    
                    _logger.LogInformation("T_PROXY_Response received with status code: {StatusCode}", httpResponse.StatusCode);
                    _logger.LogInformation("T_PROXY_Response Headers:");
                    foreach (var header in httpResponse.Headers)
                    {
                        _logger.LogInformation("T_PROXY_Header: {HeaderKey} = {HeaderValues}", header.Key, string.Join(", ", header.Value));
                    }

                    // Read response as bytes first
                    var responseBytes = await httpResponse.Content.ReadAsByteArrayAsync();
                    _logger.LogInformation("T_PROXY_Response raw byte length: {Length}", responseBytes.Length);
                    
                    // Check if response is compressed (look for gzip magic numbers)
                    if (responseBytes.Length >= 2 && responseBytes[0] == 0x1f && responseBytes[1] == 0x8b)
                    {
                        _logger.LogInformation("T_PROXY_Detected GZip compression in response.");
                        using var compressedStream = new MemoryStream(responseBytes);
                        using var gzipStream = new System.IO.Compression.GZipStream(compressedStream, System.IO.Compression.CompressionMode.Decompress);
                        using var resultStream = new MemoryStream();
                        await gzipStream.CopyToAsync(resultStream);
                        responseBytes = resultStream.ToArray();
                        _logger.LogInformation("T_PROXY_Response decompressed. New byte length: {Length}", responseBytes.Length);
                    }

                    // Convert to string, handling potential encoding issues
                    var responseString = Encoding.UTF8.GetString(responseBytes);
                    _logger.LogInformation("T_PROXY_Converted response bytes to string. Response: {ResponseString}", responseString);

                    // Get content type from response headers
                    var contentType = httpResponse.Content.Headers.ContentType?.MediaType ?? "application/json";
                    _logger.LogInformation("T_PROXY_Detected response Content-Type: {ContentType}", contentType);

                    // Check if it's JSON and try to validate
                    if (contentType.Contains("json"))
                    {
                        try
                        {
                            _logger.LogInformation("T_PROXY_Attempting to parse JSON response.");
                            // Try to parse as JSON to validate
                            var jsonObj = System.Text.Json.JsonDocument.Parse(responseString);
                            _logger.LogInformation("T_PROXY_JSON parsed successfully.");
                            return Content(responseString, "application/json");
                        }
                        catch (System.Text.Json.JsonException)
                        {
                            _logger.LogWarning("T_PROXY_Response claimed to be JSON but failed to parse.");
                            // If JSON parsing fails, return raw content
                            return Content(responseString, contentType);
                        }
                    }
                    
                    // For non-JSON responses, return as is with original content type
                    _logger.LogInformation("T_PROXY_Non-JSON response detected. Returning response as-is.");
                    return Content(responseString, contentType);
                }
                catch (HttpRequestException ex)
                {
                    _logger.LogError(ex, "T_PROXY_HTTP Request failed for URL: {TargetUrl}. Error: {Error}", targetUrl, ex.Message);
                    return StatusCode(StatusCodes.Status502BadGateway,
                        new { success = false, message = "Unable to connect to internal service", details = ex.Message });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "T_PROXY_Error occurred while forwarding request to {TargetUrl}", targetUrl); // Now targetUrl is accessible
                return StatusCode(StatusCodes.Status500InternalServerError,
                    new { success = false, message = "Internal server error", details = ex.Message });
            }
        }

        protected new bool ValidateApiKey()
        {
            // Adjust to your real validation logic
            var apiKey = Request.Headers["x-api-key"].FirstOrDefault() ?? string.Empty;
            _logger.LogInformation("T_PROXY_Validating API key. Received API key: {ApiKey}", apiKey);
            var isValid = !string.IsNullOrEmpty(apiKey) && apiKey == "7ca7427b418bdbd0b3b23d7debf69bf7";
            _logger.LogInformation("T_PROXY_API key validation result: {IsValid}", isValid);
            return isValid;
        }

        // 💡 Changed to POST endpoint and modified parameter binding from query to JSON body
        [HttpPost("dakhli/salary")]
        public async Task<IActionResult> GetDakhliSalary([FromBody] DakhliSalaryRequest request)
        {
            try 
            {
                _logger.LogInformation("T_DAKHLI_Starting salary request for CustomerId: {CustomerId}", request.CustomerId);
                
                var url = $"https://172.22.226.190:4043/api/Dakhli/GetDakhliPubPriv?customerId={request.CustomerId}&dob={request.Dob}&reason={request.Reason}";
                var client = _httpClientFactory.CreateClient("DefaultClient");
                
                var response = await client.GetAsync(url);
                var result = await response.Content.ReadAsStringAsync();
                
                _logger.LogInformation("T_DAKHLI_Raw response received: {Response}", result);

                // Validate response is valid JSON
                try {
                    var jsonResponse = System.Text.Json.JsonDocument.Parse(result);
                    
                    // Check if response has expected structure
                    if (jsonResponse.RootElement.TryGetProperty("success", out var successElement))
                    {
                        var success = successElement.GetBoolean();
                        if (!success)
                        {
                            _logger.LogWarning("T_DAKHLI_Request returned success=false");
                            return BadRequest(new { 
                                success = false, 
                                message = "Dakhli service returned unsuccessful response",
                                details = result 
                            });
                        }
                    }

                    // Validate employment info exists
                    if (jsonResponse.RootElement.TryGetProperty("result", out var resultElement) &&
                        resultElement.TryGetProperty("employmentStatusInfo", out var employmentElement))
                    {
                        _logger.LogInformation("T_DAKHLI_Valid response with employment info received");
                        return Content(result, "application/json");
                    }
                    else
                    {
                        _logger.LogWarning("T_DAKHLI_Response missing expected employment data");
                        return BadRequest(new { 
                            success = false, 
                            message = "Response missing employment data",
                            details = result 
                        });
                    }
                }
                catch (System.Text.Json.JsonException ex)
                {
                    _logger.LogError(ex, "T_DAKHLI_Invalid JSON response received");
                    return BadRequest(new { 
                        success = false, 
                        message = "Invalid response format from Dakhli service",
                        details = result 
                    });
                }
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "T_DAKHLI_HTTP Request failed");
                return StatusCode(StatusCodes.Status502BadGateway,
                    new { success = false, message = "Unable to connect to Dakhli service", details = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "T_DAKHLI_Unexpected error occurred");
                return StatusCode(StatusCodes.Status500InternalServerError,
                    new { success = false, message = "Internal server error", details = ex.Message });
            }
        }

        // 💡 DTO for Dakhli salary request
        public class DakhliSalaryRequest
        {
            public string CustomerId { get; set; }
            public string Dob { get; set; }
            public string Reason { get; set; }
        }
    }
}
