using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;
using System.Text.Json;

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
} 