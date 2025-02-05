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

            try
            {
                _logger.LogInformation("Creating bank customer for National ID: {NationalId}", request.NationalId);

                // Check if customer exists
                var customer = await _context.Customers
                    .FirstOrDefaultAsync(c => c.NationalId == request.NationalId);

                if (customer == null)
                {
                    _logger.LogWarning("Customer not found for National ID: {NationalId}", request.NationalId);
                    return Ok(new BankCustomerResponse
                    {
                        Success = true,
                        Result = new BankCustomerResult
                        {
                            NationalId = request.NationalId,
                            ApplicationFlag = "N",
                            ApplicationStatus = "REJECTED",
                            ErrCode = 404,
                            ErrMsg = "Customer not found",
                            Type = "N"
                        }
                    });
                }

                // Generate unique request ID
                string requestId = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff") + request.NationalId;

                // Create application based on product type
                string applicationId;
                string applicationStatus = "APPROVED";
                decimal eligibleAmount = request.FinAmount;
                decimal eligibleEmi = request.FinAmount / request.Tenure;

                if (request.ProductType == 0) // Loan
                {
                    var loanApp = new LoanApplication
                    {
                        NationalId = request.NationalId,
                        ApplicationNo = requestId,
                        Status = "pending",
                        StatusDate = DateTime.UtcNow,
                        LoanAmount = request.FinAmount,
                        LoanTenure = request.Tenure,
                        EffectiveRate = request.EffRate,
                        Purpose = request.FinPurpose
                    };

                    _context.LoanApplications.Add(loanApp);
                    applicationId = loanApp.ApplicationNo;
                }
                else // Card
                {
                    var cardApp = new CardApplication
                    {
                        NationalId = request.NationalId,
                        ApplicationNo = requestId,
                        Status = "pending",
                        StatusDate = DateTime.UtcNow,
                        CardType = "REWARD",
                        CardLimit = request.FinAmount
                    };

                    _context.CardApplications.Add(cardApp);
                    applicationId = cardApp.ApplicationNo;
                }

                await _context.SaveChangesAsync();

                var response = new BankCustomerResponse
                {
                    Success = true,
                    Result = new BankCustomerResult
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
                        ErrMsg = null
                    },
                    Type = "N"
                };

                // Store the request in the database
                var bankCustomer = new BankCustomer
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
                    ErrMsg = null,
                    Type = "N",
                    CreatedAt = DateTime.UtcNow
                };

                _context.BankCustomers.Add(bankCustomer);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Successfully created bank customer application. RequestId: {RequestId}", requestId);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating bank customer for National ID: {NationalId}", request.NationalId);
                
                var errorResponse = new BankCustomerResponse
                {
                    Success = true,
                    Result = new BankCustomerResult
                    {
                        NationalId = request.NationalId,
                        ApplicationFlag = "N",
                        ApplicationStatus = "ERROR",
                        ErrCode = 500,
                        ErrMsg = "Internal server error",
                        Type = "N"
                    }
                };

                // Store the error in the database
                var bankCustomer = new BankCustomer
                {
                    RequestId = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff") + request.NationalId,
                    NationalId = request.NationalId,
                    ApplicationFlag = "N",
                    ApplicationStatus = "ERROR",
                    ErrCode = 500,
                    ErrMsg = "Internal server error",
                    Type = "N",
                    CreatedAt = DateTime.UtcNow
                };

                _context.BankCustomers.Add(bankCustomer);
                await _context.SaveChangesAsync();

                return Ok(errorResponse);
            }
        }
    }
} 