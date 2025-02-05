using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;
using System.Text.Json;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/card-application")]
    public class CardApplicationController : ApiBaseController
    {
        private readonly ILogger<CardApplicationController> _logger;
        private static readonly TimeZoneInfo SaudiTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time");

        public CardApplicationController(
            ApplicationDbContext context,
            ILogger<CardApplicationController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpPost("initial")]
        public async Task<IActionResult> CreateInitialApplication([FromBody] InitialCardApplicationRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                // Validate phone number format (should start with 05 and be 10 digits)
                if (!request.Phone.StartsWith("05") || request.Phone.Length != 10)
                {
                    return Error("Invalid phone number format. Must start with 05 and be 10 digits long.", 400);
                }

                // Validate national ID (should be 10 digits and start with 1 or 2)
                if (request.NationalId.Length != 10 || (!request.NationalId.StartsWith("1") && !request.NationalId.StartsWith("2")))
                {
                    return Error("Invalid national ID format. Must be 10 digits and start with 1 or 2.", 400);
                }

                // Check for existing pending application
                var existingPendingApplication = await _context.CardApplications
                    .Where(c => c.NationalId == request.NationalId && c.Status == "pending")
                    .FirstOrDefaultAsync();

                if (existingPendingApplication != null)
                {
                    return Error($"A pending card application already exists for this National ID. Application number: {existingPendingApplication.ApplicationNo}", 400);
                }

                // Start transaction
                await using var transaction = await _context.Database.BeginTransactionAsync();

                try
                {
                    // Get next application number
                    var lastAppNo = await _context.CardApplications
                        .OrderByDescending(c => c.ApplicationNo)
                        .Select(c => c.ApplicationNo)
                        .FirstOrDefaultAsync();
                    var nextAppNo = lastAppNo + 1;

                    var saudiTime = TimeZoneInfo.ConvertTime(DateTime.UtcNow, SaudiTimeZone);

                    // Create initial card application
                    var application = new CardApplication
                    {
                        NationalId = request.NationalId,
                        ApplicationNo = nextAppNo,
                        Status = "pending",
                        StatusDate = saudiTime,
                        CardType = "REWARD", // Default to REWARD card type initially
                        CardLimit = 0, // Will be determined during credit assessment
                        NoteUser = "CUSTOMER",
                        Note = $"Initial card application created from landing page. Name: {request.Name}, Phone: {request.Phone}"
                    };

                    _context.CardApplications.Add(application);
                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Success(new
                    {
                        message = "Initial card application created successfully",
                        application_no = application.ApplicationNo,
                        details = new
                        {
                            national_id = request.NationalId,
                            name = request.Name,
                            phone = request.Phone,
                            status = "pending",
                            created_at = application.StatusDate
                        }
                    });
                }
                catch (Exception)
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating initial card application for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("update")]
        public async Task<IActionResult> UpdateCardApplication([FromBody] UpdateCardApplicationRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                // Validate national ID
                if (request.NationalId.Length != 10 || (!request.NationalId.StartsWith("1") && !request.NationalId.StartsWith("2")))
                {
                    return Error("Invalid national ID format. Must be 10 digits and start with 1 or 2.", 400);
                }

                // Start transaction
                await using var transaction = await _context.Database.BeginTransactionAsync();

                try
                {
                    // Check if card application exists
                    var existingApplication = await _context.CardApplications
                        .FirstOrDefaultAsync(c => 
                            c.NationalId == request.NationalId && 
                            c.ApplicationNo == request.ApplicationNo);

                    if (existingApplication == null)
                    {
                        return Error("Card application not found. Please create an initial application first.", 404);
                    }

                    var saudiTime = TimeZoneInfo.ConvertTime(DateTime.UtcNow, SaudiTimeZone);

                    // Update existing application
                    existingApplication.CardType = request.CardType;
                    existingApplication.CardLimit = request.CardLimit;
                    existingApplication.Status = request.Status ?? existingApplication.Status;
                    existingApplication.StatusDate = saudiTime;
                    existingApplication.Remarks = request.Remarks;
                    existingApplication.NoteUser = request.NoteUser ?? "SYSTEM";
                    existingApplication.Note = request.Note ?? "Application updated";

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Success(new
                    {
                        message = "Card application updated successfully",
                        details = new
                        {
                            national_id = request.NationalId,
                            application_no = request.ApplicationNo,
                            card_type = request.CardType,
                            card_limit = request.CardLimit,
                            status = request.Status ?? existingApplication.Status,
                            remarks = request.Remarks,
                            note_user = request.NoteUser ?? "SYSTEM",
                            note = request.Note ?? "Application updated",
                            update_date = existingApplication.StatusDate
                        }
                    });
                }
                catch (Exception)
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating card application for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpGet("latest-status/{nationalId}")]
        public async Task<IActionResult> GetLatestStatus(string nationalId)
        {
            if (!ValidateApiKey())
            {
                _logger.LogWarning("Invalid API key in GetLatestStatus request");
                return Error("Invalid API key", 401);
            }

            try
            {
                _logger.LogInformation("CARDS_CHECK_START: Getting latest status for National ID: {NationalId}", nationalId);

                // Get latest from lead_apps_cards
                var leadAppQuery = _context.LeadAppCards
                    .Where(l => l.national_id == nationalId)
                    .OrderByDescending(l => l.status_timestamp);
                
                _logger.LogInformation("CARDS_CHECK_LEAD_SQL: {Query}", leadAppQuery.ToQueryString());
                var latestLeadApp = await leadAppQuery.FirstOrDefaultAsync();

                _logger.LogInformation("CARDS_CHECK_LEAD_RESULT: Found={Found}, Status={Status}, Timestamp={Timestamp}", 
                    latestLeadApp != null,
                    latestLeadApp?.status ?? "null", 
                    latestLeadApp?.status_timestamp.ToString() ?? "null");

                // Get latest from card_application_details
                var cardAppQuery = _context.CardApplications
                    .Where(c => c.NationalId == nationalId)
                    .OrderByDescending(c => c.StatusDate);
                
                _logger.LogInformation("CARDS_CHECK_CARD_SQL: {Query}", cardAppQuery.ToQueryString());
                var latestCardApp = await cardAppQuery.FirstOrDefaultAsync();

                _logger.LogInformation("CARDS_CHECK_CARD_RESULT: Found={Found}, Status={Status}, Timestamp={Timestamp}", 
                    latestCardApp != null,
                    latestCardApp?.Status ?? "null", 
                    latestCardApp?.StatusDate.ToString() ?? "null");

                string status;
                DateTime? statusTimestamp = null;

                if (latestLeadApp == null && latestCardApp == null)
                {
                    _logger.LogInformation("CARDS_CHECK_DECISION: No applications found in either table");
                    status = "NO_APPLICATIONS";
                }
                else if (latestLeadApp == null)
                {
                    status = latestCardApp.Status;
                    statusTimestamp = latestCardApp.StatusDate;
                    _logger.LogInformation("CARDS_CHECK_DECISION: Using Card App (Lead App not found). Status={Status}, Date={Date}", status, statusTimestamp);
                }
                else if (latestCardApp == null)
                {
                    status = latestLeadApp.status;
                    statusTimestamp = latestLeadApp.status_timestamp;
                    _logger.LogInformation("CARDS_CHECK_DECISION: Using Lead App (Card App not found). Status={Status}, Date={Date}", status, statusTimestamp);
                }
                else
                {
                    var leadAppTime = DateTime.SpecifyKind(latestLeadApp.status_timestamp, DateTimeKind.Utc);
                    var cardAppTime = DateTime.SpecifyKind(latestCardApp.StatusDate, DateTimeKind.Utc);

                    _logger.LogInformation("CARDS_CHECK_COMPARISON: Lead App Time={LeadTime}, Status={LeadStatus} | Card App Time={LoanTime}, Status={LoanStatus}", 
                        leadAppTime, 
                        latestLeadApp.status,
                        cardAppTime,
                        latestCardApp.Status);

                    if (leadAppTime > cardAppTime)
                    {
                        status = latestLeadApp.status;
                        statusTimestamp = leadAppTime;
                        _logger.LogInformation("CARDS_CHECK_DECISION: Selected Lead App (more recent). Status={Status}, Date={Date}", status, statusTimestamp);
                    }
                    else
                    {
                        status = latestCardApp.Status;
                        statusTimestamp = cardAppTime;
                        _logger.LogInformation("CARDS_CHECK_DECISION: Selected Card App (more recent). Status={Status}, Date={Date}", status, statusTimestamp);
                    }
                }

                _logger.LogInformation("CARDS_CHECK_FINAL: Returning Status={Status}, Timestamp={Timestamp}", status, statusTimestamp);
                return Success(new { status, timestamp = statusTimestamp });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CARDS_CHECK_ERROR: Failed to get latest application status for National ID: {NationalId}", nationalId);
                return Error("Internal server error", 500);
            }
        }
    }

    public class InitialCardApplicationRequest
    {
        public required string NationalId { get; set; }
        public required string Name { get; set; }
        public required string Phone { get; set; }
        public string? Email { get; set; }
    }

    public class UpdateCardApplicationRequest
    {
        public required string NationalId { get; set; }
        public required int ApplicationNo { get; set; }
        public required string CardType { get; set; }
        public required decimal CardLimit { get; set; }
        public string? Status { get; set; }
        public string? Remarks { get; set; }
        public string? NoteUser { get; set; }
        public string? Note { get; set; }
    }
} 