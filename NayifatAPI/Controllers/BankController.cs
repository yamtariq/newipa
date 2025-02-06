using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;
using System;
using System.Threading.Tasks;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/Bank")]
    public class BankController : ApiBaseController
    {
        private readonly ILogger<BankController> _logger;

        public BankController(
            ApplicationDbContext context,
            ILogger<BankController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpPost("CreateCustomer")]
        public async Task<IActionResult> CreateCustomer([FromBody] BankCustomerRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            // Validate required fields
            if (string.IsNullOrEmpty(request.NationalId))
            {
                return BadRequest(new { error = "NationalId is required" });
            }

            if (!request.ProductType.HasValue)
            {
                return BadRequest(new { error = "ProductType is required" });
            }

            if (!request.FinAmount.HasValue)
            {
                return BadRequest(new { error = "FinAmount is required" });
            }

            if (!request.Tenure.HasValue)
            {
                return BadRequest(new { error = "Tenure is required" });
            }

            try
            {
                _logger.LogInformation("Creating bank customer for National ID: {NationalId}", request.NationalId);

                // Check if customer exists
                var customer = await _context.Customers
                    .FirstOrDefaultAsync(c => c.NationalId == request.NationalId);

                if (customer == null)
                {
                    _logger.LogWarning("Customer not found for National ID: {NationalId}", request.NationalId);
                    
                    // Create rejection response
                    var rejection = new CreateCustomerResponse
                    {
                        RequestId = $"{DateTime.Now:yyMMddHHmmssfff}{request.NationalId.Substring(0, 4)}",
                        NationalId = request.NationalId,
                        ApplicationFlag = "N",
                        ApplicationId = string.Empty,
                        ApplicationStatus = "REJECTED",
                        CustomerId = string.Empty,
                        EligibleStatus = "N",
                        EligibleAmount = 0,
                        EligibleEmi = 0,
                        ProductType = request.ProductType == 0 ? "Loan" : "Card",
                        SuccessMsg = string.Empty,
                        ErrCode = 404,
                        ErrMsg = "Customer not found",
                        Type = "N",
                        CreatedAt = DateTime.Now
                    };

                    // Save to bank_customers table
                    var bankCustomer = new BankCustomer
                    {
                        RequestId = rejection.RequestId,
                        NationalId = rejection.NationalId,
                        ApplicationFlag = rejection.ApplicationFlag,
                        ApplicationId = rejection.ApplicationId,
                        ApplicationStatus = rejection.ApplicationStatus,
                        CustomerId = rejection.CustomerId,
                        EligibleStatus = rejection.EligibleStatus,
                        EligibleAmount = rejection.EligibleAmount,
                        EligibleEmi = rejection.EligibleEmi,
                        ProductType = rejection.ProductType,
                        SuccessMsg = rejection.SuccessMsg,
                        ErrCode = rejection.ErrCode,
                        ErrMsg = rejection.ErrMsg,
                        Type = rejection.Type,
                        CreatedAt = rejection.CreatedAt
                    };

                    _context.BankCustomers.Add(bankCustomer);
                    await _context.SaveChangesAsync();

                    return Ok(rejection);
                }

                // Generate unique request ID with format similar to "140220230952521047"
                string requestId = $"{DateTime.Now:yyMMddHHmmssfff}{request.NationalId.Substring(0, 4)}";

                // Create application based on product type
                string applicationId = $"{DateTime.Now:HHmmss}{customer.NationalId.Substring(0, 4)}";
                string applicationStatus = "APPROVED";
                decimal eligibleAmount = request.FinAmount.Value;
                decimal eligibleEmi = decimal.Round(request.FinAmount.Value / request.Tenure.Value, 2);

                if (request.ProductType == 0) // Loan
                {
                    var loanApp = new LoanApplication
                    {
                        NationalId = request.NationalId,
                        ApplicationNo = int.Parse(requestId),
                        Status = "pending",
                        StatusDate = DateTime.UtcNow,
                        Amount = request.FinAmount.Value,
                        Tenure = request.Tenure.Value,
                        InterestRate = request.EffRate ?? 0,
                        Purpose = request.FinPurpose ?? "General",
                        NoteUser = "CUSTOMER",
                        Note = $"Application created via Bank API. Amount: {request.FinAmount}, Tenure: {request.Tenure}"
                    };

                    _context.LoanApplications.Add(loanApp);
                }
                else // Card
                {
                    var cardApp = new CardApplication
                    {
                        NationalId = request.NationalId,
                        ApplicationNo = int.Parse(requestId),
                        Status = "pending",
                        StatusDate = DateTime.UtcNow,
                        CardType = "REWARD",
                        CardLimit = request.FinAmount.Value,
                        NoteUser = "CUSTOMER",
                        Note = $"Application created via Bank API. Card Limit: {request.FinAmount}"
                    };

                    _context.CardApplications.Add(cardApp);
                }

                await _context.SaveChangesAsync();

                // Create success response
                var response = new CreateCustomerResponse
                {
                    RequestId = requestId,
                    NationalId = request.NationalId,
                    ApplicationFlag = "S",
                    ApplicationId = applicationId,
                    ApplicationStatus = applicationStatus,
                    CustomerId = customer.NationalId,
                    EligibleStatus = "Y",
                    EligibleAmount = eligibleAmount,
                    EligibleEmi = eligibleEmi,
                    ProductType = request.ProductType == 0 ? "Loan" : "Card",
                    SuccessMsg = "SUCCESS",
                    ErrCode = 0,
                    ErrMsg = "NULL",
                    Type = "N",
                    CreatedAt = DateTime.Now
                };

                // Save to bank_customers table
                var successBankCustomer = new BankCustomer
                {
                    RequestId = response.RequestId,
                    NationalId = response.NationalId,
                    ApplicationFlag = response.ApplicationFlag,
                    ApplicationId = response.ApplicationId,
                    ApplicationStatus = response.ApplicationStatus,
                    CustomerId = response.CustomerId,
                    EligibleStatus = response.EligibleStatus,
                    EligibleAmount = response.EligibleAmount,
                    EligibleEmi = response.EligibleEmi,
                    ProductType = response.ProductType,
                    SuccessMsg = response.SuccessMsg,
                    ErrCode = response.ErrCode,
                    ErrMsg = response.ErrMsg,
                    Type = response.Type,
                    CreatedAt = response.CreatedAt
                };

                _context.BankCustomers.Add(successBankCustomer);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Successfully created bank customer application. RequestId: {RequestId}", requestId);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating bank customer for National ID: {NationalId}", request.NationalId);
                
                // Create error response
                var errorResponse = new CreateCustomerResponse
                {
                    RequestId = $"{DateTime.Now:yyMMddHHmmssfff}{request.NationalId.Substring(0, 4)}",
                    NationalId = request.NationalId,
                    ApplicationFlag = "N",
                    ApplicationId = string.Empty,
                    ApplicationStatus = "ERROR",
                    CustomerId = string.Empty,
                    EligibleStatus = "N",
                    EligibleAmount = 0,
                    EligibleEmi = 0,
                    ProductType = request.ProductType == 0 ? "Loan" : "Card",
                    SuccessMsg = string.Empty,
                    ErrCode = 500,
                    ErrMsg = "Internal server error",
                    Type = "N",
                    CreatedAt = DateTime.Now
                };

                // Save to bank_customers table
                var errorBankCustomer = new BankCustomer
                {
                    RequestId = errorResponse.RequestId,
                    NationalId = errorResponse.NationalId,
                    ApplicationFlag = errorResponse.ApplicationFlag,
                    ApplicationId = errorResponse.ApplicationId,
                    ApplicationStatus = errorResponse.ApplicationStatus,
                    CustomerId = errorResponse.CustomerId,
                    EligibleStatus = errorResponse.EligibleStatus,
                    EligibleAmount = errorResponse.EligibleAmount,
                    EligibleEmi = errorResponse.EligibleEmi,
                    ProductType = errorResponse.ProductType,
                    SuccessMsg = errorResponse.SuccessMsg,
                    ErrCode = errorResponse.ErrCode,
                    ErrMsg = errorResponse.ErrMsg,
                    Type = errorResponse.Type,
                    CreatedAt = errorResponse.CreatedAt
                };

                _context.BankCustomers.Add(errorBankCustomer);
                await _context.SaveChangesAsync();

                return Ok(errorResponse);
            }
        }
    }
} 