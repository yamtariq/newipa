using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using NayifatAPI.Models;
using System.Net.Http;
using System.Text.Json;

namespace NayifatAPI.Controllers
{
    public class NafathController : ApiBaseController
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<NafathController> _logger;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly string _nafathBaseUrl = "https://api.nayifat.com/nafath/api/Nafath";

        public NafathController(
            ApplicationDbContext context,
            ILogger<NafathController> logger,
            IHttpClientFactory httpClientFactory)
        {
            _context = context;
            _logger = logger;
            _httpClientFactory = httpClientFactory;
        }

        [HttpPost("CreateRequest")]
        public async Task<IActionResult> CreateRequest([FromBody] NafathCreateRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var customer = await _context.Customers.FindAsync(request.NationalId);
                if (customer == null)
                {
                    return Error("Customer not found", 404);
                }

                var httpClient = _httpClientFactory.CreateClient();
                var response = await httpClient.PostAsJsonAsync(
                    $"{_nafathBaseUrl}/CreateRequest",
                    new { request.NationalId, request.ServiceId });

                if (!response.IsSuccessStatusCode)
                {
                    return Error("Failed to create Nafath request", (int)response.StatusCode);
                }

                var nafathResponse = await response.Content.ReadFromJsonAsync<NafathCreateResponse>();
                if (nafathResponse == null)
                {
                    return Error("Invalid response from Nafath service", 500);
                }

                // Update customer's Nafath status
                customer.NafathStatus = "PENDING";
                customer.NafathTimestamp = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Success(new
                {
                    transId = nafathResponse.TransId,
                    random = nafathResponse.Random,
                    status = "PENDING"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating Nafath request for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("RequestStatus")]
        public async Task<IActionResult> GetRequestStatus([FromBody] NafathStatusRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var customer = await _context.Customers.FindAsync(request.NationalId);
                if (customer == null)
                {
                    return Error("Customer not found", 404);
                }

                var httpClient = _httpClientFactory.CreateClient();
                var response = await httpClient.PostAsJsonAsync(
                    $"{_nafathBaseUrl}/RequestStatus",
                    new { request.TransId });

                if (!response.IsSuccessStatusCode)
                {
                    return Error("Failed to get Nafath status", (int)response.StatusCode);
                }

                var nafathResponse = await response.Content.ReadFromJsonAsync<NafathStatusResponse>();
                if (nafathResponse == null)
                {
                    return Error("Invalid response from Nafath service", 500);
                }

                // Update customer's Nafath status
                customer.NafathStatus = nafathResponse.Status;
                customer.NafathTimestamp = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Success(new
                {
                    status = nafathResponse.Status,
                    message = nafathResponse.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting Nafath status for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }
    }

    public class NafathCreateRequest
    {
        public required string NationalId { get; set; }
        public required string ServiceId { get; set; }
    }

    public class NafathStatusRequest
    {
        public required string NationalId { get; set; }
        public required string TransId { get; set; }
    }

    public class NafathCreateResponse
    {
        public required string TransId { get; set; }
        public required string Random { get; set; }
    }

    public class NafathStatusResponse
    {
        public required string Status { get; set; }
        public required string Message { get; set; }
    }

    public class StartAuthRequest
    {
        public required string NationalId { get; set; }
        public required string ServiceId { get; set; }
    }

    public class CheckAuthRequest
    {
        public required string NationalId { get; set; }
        public required string TransId { get; set; }
    }

    public class GenerateRandomRequest
    {
        public required string TransId { get; set; }
        public required string Random { get; set; }
    }

    public class NafathResponse
    {
        public required string Status { get; set; }
        public required string Message { get; set; }
        public object? Data { get; set; }
    }
} 