using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;
using System.Text.Json;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore.Metadata.Internal;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/loan-application")]
    public class LoanApplicationController : ApiBaseController
    {
        private readonly ILogger<LoanApplicationController> _logger;
        private static readonly TimeZoneInfo SaudiTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Arab Standard Time");

        public LoanApplicationController(
            ApplicationDbContext context,
            ILogger<LoanApplicationController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
        }

        [HttpPost("initial")]
        public async Task<IActionResult> CreateInitialApplication([FromBody] InitialLoanApplicationRequest request)
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
                var existingPendingApplication = await _context.LoanApplications
                    .Where(l => l.NationalId == request.NationalId && l.Status == "pending")
                    .FirstOrDefaultAsync();

                if (existingPendingApplication != null)
                {
                    return Error($"A pending loan application already exists for this National ID. Application number: {existingPendingApplication.ApplicationNo}", 400);
                }

                // Start transaction
                await using var transaction = await _context.Database.BeginTransactionAsync();

                try
                {
                    // Get next application number
                    var lastAppNo = await _context.LoanApplications
                        .OrderByDescending(l => l.ApplicationNo)
                        .Select(l => l.ApplicationNo)
                        .FirstOrDefaultAsync();
                    var nextAppNo = lastAppNo + 1;

                    var saudiTime = TimeZoneInfo.ConvertTime(DateTime.UtcNow, SaudiTimeZone);

                    // Create initial loan application
                    var application = new LoanApplication
                    {
                        NationalId = request.NationalId,
                        ApplicationNo = nextAppNo,
                        CustomerDecision = "pending",
                        Amount = 0,
                        Status = "pending",
                        StatusDate = saudiTime,
                        NoteUser = "CUSTOMER",
                        Note = $"Initial application created from landing page. Name: {request.Name}, Phone: {request.Phone}",
                        Purpose = null,
                        Tenure = null,
                        InterestRate = null,
                        Remarks = null
                    };

                    _context.LoanApplications.Add(application);
                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Success(new
                    {
                        message = "Initial loan application created successfully",
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
                _logger.LogError(ex, "Error creating initial loan application for National ID: {NationalId}", request.NationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("update")]
        public async Task<IActionResult> UpdateLoanApplication([FromBody] UpdateLoanApplicationRequest request)
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

                // Validate loan amount
                if (request.LoanAmount <= 0)
                {
                    return Error("Loan amount must be greater than 0.", 400);
                }

                // Start transaction
                await using var transaction = await _context.Database.BeginTransactionAsync();

                try
                {
                    // Check if loan application exists
                    var existingApplication = await _context.LoanApplications
                        .FirstOrDefaultAsync(l => 
                            l.NationalId == request.NationalId && 
                            l.ApplicationNo == request.ApplicationNo);

                    if (existingApplication == null)
                    {
                        return Error("Loan application not found. Please create an initial application first.", 404);
                    }

                    var saudiTime = TimeZoneInfo.ConvertTime(DateTime.UtcNow, SaudiTimeZone);

                    // Update existing application
                    existingApplication.CustomerDecision = request.CustomerDecision;
                    existingApplication.Amount = request.LoanAmount;
                    existingApplication.Purpose = request.LoanPurpose;
                    existingApplication.Tenure = request.LoanTenure;
                    existingApplication.InterestRate = request.InterestRate;
                    existingApplication.Status = request.Status ?? existingApplication.Status;
                    existingApplication.StatusDate = saudiTime;
                    existingApplication.Remarks = request.Remarks;
                    existingApplication.NoteUser = request.NoteUser ?? "SYSTEM";
                    existingApplication.Note = request.Note ?? "Application updated";

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Success(new
                    {
                        message = "Loan application updated successfully",
                        details = new
                        {
                            national_id = request.NationalId,
                            application_no = request.ApplicationNo,
                            customer_decision = request.CustomerDecision,
                            loan_amount = request.LoanAmount,
                            loan_purpose = request.LoanPurpose,
                            loan_tenure = request.LoanTenure,
                            interest_rate = request.InterestRate,
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
                _logger.LogError(ex, "Error updating loan application for National ID: {NationalId}", request.NationalId);
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
                _logger.LogInformation("LOANS_CHECK_START: Getting latest status for National ID: {NationalId}", nationalId);

                // Get latest from lead_apps_loans
                var leadAppQuery = _context.LeadAppLoans
                    .Where(l => l.national_id == nationalId)
                    .OrderByDescending(l => l.status_timestamp);
                
                _logger.LogInformation("LOANS_CHECK_LEAD_SQL: {Query}", leadAppQuery.ToQueryString());
                var latestLeadApp = await leadAppQuery.FirstOrDefaultAsync();

                _logger.LogInformation("LOANS_CHECK_LEAD_RESULT: Found={Found}, Status={Status}, Timestamp={Timestamp}", 
                    latestLeadApp != null,
                    latestLeadApp?.status ?? "null", 
                    latestLeadApp?.status_timestamp.ToString() ?? "null");

                // Get latest from loan_application_details
                var loanAppQuery = _context.LoanApplications
                    .Where(l => l.NationalId == nationalId)
                    .OrderByDescending(l => l.StatusDate);
                
                _logger.LogInformation("LOANS_CHECK_LOAN_SQL: {Query}", loanAppQuery.ToQueryString());
                var latestLoanApp = await loanAppQuery.FirstOrDefaultAsync();

                _logger.LogInformation("LOANS_CHECK_LOAN_RESULT: Found={Found}, Status={Status}, Timestamp={Timestamp}", 
                    latestLoanApp != null,
                    latestLoanApp?.Status ?? "null", 
                    latestLoanApp?.StatusDate.ToString() ?? "null");

                string status;
                DateTime? statusTimestamp = null;

                if (latestLeadApp == null && latestLoanApp == null)
                {
                    _logger.LogInformation("LOANS_CHECK_DECISION: No applications found in either table");
                    status = "NO_APPLICATIONS";
                }
                else if (latestLeadApp == null)
                {
                    status = latestLoanApp?.Status ?? "UNKNOWN";
                    statusTimestamp = latestLoanApp?.StatusDate;
                    _logger.LogInformation("LOANS_CHECK_DECISION: Using Loan App (Lead App not found). Status={Status}, Date={Date}", status, statusTimestamp);
                }
                else if (latestLoanApp == null)
                {
                    status = latestLeadApp.status;
                    statusTimestamp = latestLeadApp.status_timestamp;
                    _logger.LogInformation("LOANS_CHECK_DECISION: Using Lead App (Loan App not found). Status={Status}, Date={Date}", status, statusTimestamp);
                }
                else
                {
                    var leadAppTime = DateTime.SpecifyKind(latestLeadApp.status_timestamp, DateTimeKind.Utc);
                    var loanAppTime = DateTime.SpecifyKind(latestLoanApp.StatusDate, DateTimeKind.Utc);

                    _logger.LogInformation("LOANS_CHECK_COMPARISON: Lead App Time={LeadTime}, Status={LeadStatus} | Loan App Time={LoanTime}, Status={LoanStatus}", 
                        leadAppTime, 
                        latestLeadApp.status,
                        loanAppTime,
                        latestLoanApp.Status);

                    if (leadAppTime > loanAppTime)
                    {
                        status = latestLeadApp.status;
                        statusTimestamp = leadAppTime;
                        _logger.LogInformation("LOANS_CHECK_DECISION: Selected Lead App (more recent). Status={Status}, Date={Date}", status, statusTimestamp);
                    }
                    else
                    {
                        status = latestLoanApp.Status;
                        statusTimestamp = loanAppTime;
                        _logger.LogInformation("LOANS_CHECK_DECISION: Selected Loan App (more recent). Status={Status}, Date={Date}", status, statusTimestamp);
                    }
                }

                _logger.LogInformation("LOANS_CHECK_FINAL: Returning Status={Status}, Timestamp={Timestamp}", status, statusTimestamp);
                return Success(new { status, timestamp = statusTimestamp });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "LOANS_CHECK_ERROR: Failed to get latest application status for National ID: {NationalId}", nationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpPost("insert")]
        public async Task<IActionResult> InsertLoanApplication([FromBody] InsertLoanApplicationRequest request)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                _logger.LogInformation("=== Inserting Loan Application ===");
                _logger.LogInformation($"Request Data: NationalId={request.national_id}, Amount={request.loan_amount}, Purpose={request.loan_purpose}");

                // Start transaction
                await using var transaction = await _context.Database.BeginTransactionAsync();

                try
                {
                    var saudiTime = TimeZoneInfo.ConvertTime(DateTime.UtcNow, SaudiTimeZone);

                    // Create new loan application
                    var application = new LoanApplication
                    {
                        ApplicationNo = request.application_no,
                        NationalId = request.national_id,
                        CustomerDecision = request.customerDecision,
                        Amount = request.loan_amount ?? 0,
                        Purpose = request.loan_purpose,
                        Tenure = request.loan_tenure ?? 0,
                        InterestRate = request.interest_rate ?? 0,
                        Status = request.status,
                        StatusDate = request.status_date ?? DateTime.Now,
                        Remarks = request.remarks,
                        NoteUser = request.noteUser,
                        Note = request.note,
                        // Set fixed values for Consent and Nafath
                        ConsentStatus = "True",
                        ConsentStatusDate = request.consent_status_date,
                        NafathStatus = "True",
                        NafathStatusDate = request.nafath_status_date,
                        LoanEmi = request.loan_emi
                    };

                    _context.LoanApplications.Add(application);
                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    _logger.LogInformation($"Successfully created loan application with ID: {application.Id}");

                    return Success(new
                    {
                        message = "Loan application created successfully",
                        loan_id = application.Id,
                        application_no = application.ApplicationNo,
                        details = new
                        {
                            national_id = application.NationalId,
                            customer_decision = application.CustomerDecision,
                            loan_amount = application.Amount,
                            loan_purpose = application.Purpose,
                            loan_tenure = application.Tenure,
                            interest_rate = application.InterestRate,
                            status = application.Status,
                            status_date = application.StatusDate,
                            remarks = application.Remarks,
                            note_user = application.NoteUser,
                            note = application.Note,
                            consent_status = application.ConsentStatus,
                            consent_status_date = application.ConsentStatusDate,
                            nafath_status = application.NafathStatus,
                            nafath_status_date = application.NafathStatusDate,
                            loan_emi = application.LoanEmi
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
                _logger.LogError(ex, "Error inserting loan application for National ID: {NationalId}. Error details: {ErrorMessage}, Stack trace: {StackTrace}", 
                    request.national_id, 
                    ex.Message,
                    ex.StackTrace);
                return Error($"Internal server error: {ex.Message}", 500);
            }
        }
    }

    public class InitialLoanApplicationRequest
    {
        public required string NationalId { get; set; }
        public required string Name { get; set; }
        public required string Phone { get; set; }
        public string? Email { get; set; }
    }

    public class UpdateLoanApplicationRequest
    {
        public required string NationalId { get; set; }
        public required int ApplicationNo { get; set; }
        public required string CustomerDecision { get; set; }
        public required decimal LoanAmount { get; set; }
        public string? LoanPurpose { get; set; }
        public int? LoanTenure { get; set; }
        public decimal? InterestRate { get; set; }
        public string? Status { get; set; }
        public string? Remarks { get; set; }
        public string? NoteUser { get; set; }
        public string? Note { get; set; }
    }

    public class InsertLoanApplicationRequest
    {
        [Required] 
        public int application_no { get; set; }
        
        [Required]
        [StringLength(50)] 
        public required string national_id { get; set; }
        
        [Required]
        [StringLength(50)] 
        public required string customerDecision { get; set; }
        
        [Column(TypeName = "decimal(18,2)")] 
        public decimal? loan_amount { get; set; }
        
        [Required]
        [StringLength(100)] 
        public required string loan_purpose { get; set; }
        
        public int? loan_tenure { get; set; }
        
        [Column(TypeName = "decimal(5,2)")] 
        public decimal? interest_rate { get; set; }
        
        [Required]
        [StringLength(50)] 
        public required string status { get; set; } = "pending";
        
        public DateTime? status_date { get; set; } = DateTime.Now;
        
        [Required]
        [StringLength(255)] 
        public required string remarks { get; set; }
        
        [Required]
        [StringLength(50)] 
        public required string noteUser { get; set; }
        
        [Required]
        [StringLength(255)] 
        public required string note { get; set; }
        
        [Required]
        [StringLength(50)] 
        public required string consent_status { get; set; } = "True";
        
        public DateTime? consent_status_date { get; set; } = DateTime.Now;
        
        [Required]
        [StringLength(50)] 
        public required string nafath_status { get; set; } = "True";
        
        public DateTime? nafath_status_date { get; set; } = DateTime.Now;
        
        [Column(TypeName = "decimal(18,2)")] 
        public decimal? loan_emi { get; set; }
    }
} 