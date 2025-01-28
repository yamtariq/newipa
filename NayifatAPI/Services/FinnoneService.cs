using System.Net.Http;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Models;

namespace NayifatAPI.Services;

public interface IFinnoneService
{
    Task<ApiResponse<FinnoneCustomerResponse>> CreateCustomerAsync(string applicationNo);
    Task<ApiResponse<FinnoneStatusResponse>> CheckStatusAsync(string applicationNo);
}

public class FinnoneService : IFinnoneService
{
    private readonly IConfiguration _configuration;
    private readonly ICustomerService _customerService;
    private readonly ILoanService _loanService;
    private readonly ICardService _cardService;
    private readonly IAuditService _auditService;
    private readonly HttpClient _httpClient;
    private readonly string _finnoneBaseUrl;
    private readonly string _finnoneApiKey;

    public FinnoneService(
        IConfiguration configuration,
        ICustomerService customerService,
        ILoanService loanService,
        ICardService cardService,
        IAuditService auditService,
        IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _customerService = customerService;
        _loanService = loanService;
        _cardService = cardService;
        _auditService = auditService;
        _httpClient = httpClientFactory.CreateClient("FinnoneClient");
        
        _finnoneBaseUrl = _configuration["Finnone:BaseUrl"];
        _finnoneApiKey = _configuration["Finnone:ApiKey"];
        
        // Configure HttpClient
        _httpClient.BaseAddress = new Uri(_finnoneBaseUrl);
        _httpClient.DefaultRequestHeaders.Add("X-API-Key", _finnoneApiKey);
    }

    public async Task<ApiResponse<FinnoneCustomerResponse>> CreateCustomerAsync(string applicationNo)
    {
        try
        {
            // 1. Get application details based on application number
            var application = await GetApplicationDetailsAsync(applicationNo);
            if (application == null)
            {
                return new ApiResponse<FinnoneCustomerResponse>
                {
                    Success = false,
                    Message = "Application not found",
                    Data = null
                };
            }

            // 2. Get customer details
            var customer = await _customerService.GetCustomerByNationalId(application.NationalId);
            if (customer == null)
            {
                return new ApiResponse<FinnoneCustomerResponse>
                {
                    Success = false,
                    Message = "Customer not found",
                    Data = null
                };
            }

            // 3. Prepare Finnone request payload
            var finnoneRequest = new FinnoneCustomerRequest
            {
                ApplicationNo = applicationNo,
                NationalId = customer.NationalId,
                FullNameEn = customer.FullNameEn,
                FullNameAr = customer.FullNameAr,
                DateOfBirth = customer.DateOfBirth,
                Email = customer.Email,
                Phone = customer.Phone,
                Salary = application.Type == "LOAN" ? 
                    ((LoanApplication)application).LoanAmount : 
                    ((CardApplication)application).CardLimit
                // Add other required fields from Finnone documentation
            };

            // 4. Call Finnone API
            var response = await _httpClient.PostAsJsonAsync("/api/customer/create", finnoneRequest);
            var finnoneResponse = await response.Content.ReadFromJsonAsync<FinnoneCustomerResponse>();

            // 5. Update application status
            await UpdateApplicationStatus(applicationNo, 
                response.IsSuccessStatusCode ? "FINNONE_COMPLETED" : "FINNONE_FAILED");

            // 6. Audit log the interaction
            await _auditService.LogAsync(new AuditRequest
            {
                Action = "FINNONE_CREATE_CUSTOMER",
                NationalId = customer.NationalId,
                Details = JsonSerializer.Serialize(new
                {
                    ApplicationNo = applicationNo,
                    Status = response.IsSuccessStatusCode ? "Success" : "Failed",
                    Response = finnoneResponse
                })
            });

            return new ApiResponse<FinnoneCustomerResponse>
            {
                Success = response.IsSuccessStatusCode,
                Message = finnoneResponse?.Message ?? "Failed to create customer in Finnone",
                Data = finnoneResponse
            };
        }
        catch (Exception ex)
        {
            await _auditService.LogAsync(new AuditRequest
            {
                Action = "FINNONE_CREATE_CUSTOMER_ERROR",
                NationalId = applicationNo,
                Details = ex.ToString()
            });

            return new ApiResponse<FinnoneCustomerResponse>
            {
                Success = false,
                Message = "Internal server error",
                Data = null
            };
        }
    }

    public async Task<ApiResponse<FinnoneStatusResponse>> CheckStatusAsync(string applicationNo)
    {
        try
        {
            var response = await _httpClient.GetAsync($"/api/customer/status?applicationNo={applicationNo}");
            var statusResponse = await response.Content.ReadFromJsonAsync<FinnoneStatusResponse>();

            await _auditService.LogAsync(new AuditRequest
            {
                Action = "FINNONE_CHECK_STATUS",
                NationalId = applicationNo,
                Details = JsonSerializer.Serialize(statusResponse)
            });

            return new ApiResponse<FinnoneStatusResponse>
            {
                Success = response.IsSuccessStatusCode,
                Message = statusResponse?.Message ?? "Failed to check status",
                Data = statusResponse
            };
        }
        catch (Exception ex)
        {
            await _auditService.LogAsync(new AuditRequest
            {
                Action = "FINNONE_CHECK_STATUS_ERROR",
                NationalId = applicationNo,
                Details = ex.ToString()
            });

            return new ApiResponse<FinnoneStatusResponse>
            {
                Success = false,
                Message = "Internal server error",
                Data = null
            };
        }
    }

    private async Task<IApplication> GetApplicationDetailsAsync(string applicationNo)
    {
        // Try to get loan application first
        var loanApplication = await _loanService.GetApplicationByNumber(applicationNo);
        if (loanApplication != null)
            return loanApplication;

        // If not found, try card application
        var cardApplication = await _cardService.GetApplicationByNumber(applicationNo);
        return cardApplication;
    }

    private async Task UpdateApplicationStatus(string applicationNo, string status)
    {
        var application = await GetApplicationDetailsAsync(applicationNo);
        if (application == null)
            return;

        if (application is LoanApplication)
        {
            await _loanService.UpdateApplicationStatus(applicationNo, status);
        }
        else if (application is CardApplication)
        {
            await _cardService.UpdateApplicationStatus(applicationNo, status);
        }
    }
} 