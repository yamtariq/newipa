using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/lead")]
    public class LeadApplicationController : ApiBaseController
    {
        private readonly ILogger<LeadApplicationController> _logger;

        public LeadApplicationController(
            ApplicationDbContext context,
            ILogger<LeadApplicationController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpPost("card/create")]
        public async Task<IActionResult> CreateCardLead([FromBody] LeadApplicationRequest request)
        {
            _logger.LogInformation("=== Creating Card Lead Application ===");
            _logger.LogInformation($"Request Data: NationalId={request.NationalId}, Name={request.Name}, Phone={request.Phone}");

            if (!ValidateApiKey())
            {
                _logger.LogWarning("Invalid API key");
                return Error("Invalid API key", 401);
            }

            try
            {
                // Validate phone number format
                if (!request.Phone.StartsWith("9665") || request.Phone.Length != 12)
                {
                    _logger.LogWarning($"Invalid phone format: {request.Phone}");
                    return Error("Invalid phone number format. Must start with 9665 and be 12 digits long", 400);
                }

                // Validate national ID format
                if (request.NationalId.Length != 10 || (!request.NationalId.StartsWith("1") && !request.NationalId.StartsWith("2")))
                {
                    _logger.LogWarning($"Invalid national ID format: {request.NationalId}");
                    return Error("Invalid national ID format. Must be 10 digits and start with 1 or 2", 400);
                }

                // Check for existing application
                _logger.LogInformation("Checking for existing applications...");
                var existingApp = await _context.LeadAppCards
                    .Where(l => l.national_id == request.NationalId && l.status == "PENDING")
                    .FirstOrDefaultAsync();

                if (existingApp != null)
                {
                    _logger.LogWarning($"Found existing pending application for NationalId: {request.NationalId}");
                    return Error("A pending application already exists for this national ID", 400);
                }

                _logger.LogInformation("Creating new lead application...");
                var leadApp = new LeadAppCard
                {
                    national_id = request.NationalId,
                    name = request.Name,
                    phone = request.Phone,
                    status = "PENDING",
                    status_timestamp = DateTime.UtcNow
                };

                _context.LeadAppCards.Add(leadApp);
                _logger.LogInformation("Saving to database...");
                await _context.SaveChangesAsync();
                _logger.LogInformation($"Successfully created lead application with ID: {leadApp.id}");

                return Success(new
                {
                    id = leadApp.id,
                    national_id = leadApp.national_id,
                    name = leadApp.name,
                    phone = leadApp.phone,
                    status = leadApp.status,
                    status_timestamp = leadApp.status_timestamp
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating card lead application for National ID: {NationalId}. Error details: {ErrorMessage}, Stack trace: {StackTrace}", 
                    request.NationalId, 
                    ex.Message,
                    ex.StackTrace);
                return Error($"Internal server error: {ex.Message}", 500);
            }
        }

        [HttpPost("loan/create")]
        public async Task<IActionResult> CreateLoanLead([FromBody] LeadApplicationRequest request)
        {
            _logger.LogInformation("=== Creating Loan Lead Application ===");
            _logger.LogInformation($"Request Data: NationalId={request.NationalId}, Name={request.Name}, Phone={request.Phone}");

            if (!ValidateApiKey())
            {
                _logger.LogWarning("Invalid API key");
                return Error("Invalid API key", 401);
            }

            try
            {
                // Validate phone number format
                if (!request.Phone.StartsWith("9665") || request.Phone.Length != 12)
                {
                    _logger.LogWarning($"Invalid phone format: {request.Phone}");
                    return Error("Invalid phone number format. Must start with 9665 and be 12 digits long", 400);
                }

                // Validate national ID format
                if (request.NationalId.Length != 10 || (!request.NationalId.StartsWith("1") && !request.NationalId.StartsWith("2")))
                {
                    _logger.LogWarning($"Invalid national ID format: {request.NationalId}");
                    return Error("Invalid national ID format. Must be 10 digits and start with 1 or 2", 400);
                }

                // Check for existing application
                _logger.LogInformation("Checking for existing applications...");
                var existingApp = await _context.LeadAppLoans
                    .Where(l => l.national_id == request.NationalId && l.status == "PENDING")
                    .FirstOrDefaultAsync();

                if (existingApp != null)
                {
                    _logger.LogWarning($"Found existing pending application for NationalId: {request.NationalId}");
                    return Error("A pending application already exists for this national ID", 400);
                }

                _logger.LogInformation("Creating new lead application...");
                var leadApp = new LeadAppLoan
                {
                    national_id = request.NationalId,
                    name = request.Name,
                    phone = request.Phone,
                    status = "PENDING",
                    status_timestamp = DateTime.UtcNow
                };

                _context.LeadAppLoans.Add(leadApp);
                _logger.LogInformation("Saving to database...");
                await _context.SaveChangesAsync();
                _logger.LogInformation($"Successfully created lead application with ID: {leadApp.id}");

                return Success(new
                {
                    id = leadApp.id,
                    national_id = leadApp.national_id,
                    name = leadApp.name,
                    phone = leadApp.phone,
                    status = leadApp.status,
                    status_timestamp = leadApp.status_timestamp
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating loan lead application for National ID: {NationalId}. Error details: {ErrorMessage}, Stack trace: {StackTrace}", 
                    request.NationalId, 
                    ex.Message,
                    ex.StackTrace);
                return Error($"Internal server error: {ex.Message}", 500);
            }
        }
    }
} 