using Microsoft.AspNetCore.Mvc;
using NayifatAPI.Models;
using NayifatAPI.Services;
using System.Text.Json;

namespace NayifatAPI.Controllers;

[ApiController]
[Route("api")]
public class LoanApplicationController : ControllerBase
{
    private readonly DatabaseService _db;
    private readonly ILogger<LoanApplicationController> _logger;
    private readonly AuditLogService _auditLog;

    public LoanApplicationController(
        DatabaseService db, 
        ILogger<LoanApplicationController> logger,
        AuditLogService auditLog)
    {
        _db = db;
        _logger = logger;
        _auditLog = auditLog;
    }

    [HttpPost("update_loan_application")]
    public async Task<IActionResult> UpdateLoanApplication([FromBody] LoanApplicationUpdateRequest request)
    {
        // Add cache control headers to match PHP version exactly
        Response.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        Response.Headers.Add("Pragma", "no-cache");

        try
        {
            // Start transaction
            using var connection = await _db.GetConnection();
            await connection.OpenAsync();
            using var transaction = await connection.BeginTransactionAsync();

            try
            {
                // First check if the loan application exists
                var checkCommand = connection.CreateCommand();
                checkCommand.Transaction = transaction;
                checkCommand.CommandText = @"
                    SELECT loan_id 
                    FROM loan_application_details 
                    WHERE national_id = @national_id 
                    AND application_no = @application_no";

                checkCommand.Parameters.AddWithValue("@national_id", request.NationalId);
                checkCommand.Parameters.AddWithValue("@application_no", request.ApplicationNo);

                var loanId = await checkCommand.ExecuteScalarAsync();

                var command = connection.CreateCommand();
                command.Transaction = transaction;

                if (loanId == null)
                {
                    // Insert new record
                    command.CommandText = @"
                        INSERT INTO loan_application_details (
                            national_id,
                            application_no,
                            customerDecision,
                            loan_amount,
                            loan_purpose,
                            loan_tenure,
                            interest_rate,
                            status,
                            status_date,
                            remarks,
                            noteUser,
                            note
                        ) VALUES (
                            @national_id,
                            @application_no,
                            @customerDecision,
                            @loan_amount,
                            @loan_purpose,
                            @loan_tenure,
                            @interest_rate,
                            @status,
                            CURRENT_TIMESTAMP,
                            @remarks,
                            @noteUser,
                            @note
                        )";

                    await _auditLog.LogAsync(connection, transaction, "LOAN_APPLICATION_CREATED", 
                        request.NationalId, 
                        $"New loan application created: {request.ApplicationNo}");
                }
                else
                {
                    // Update existing record
                    command.CommandText = @"
                        UPDATE loan_application_details SET 
                            customerDecision = @customerDecision,
                            loan_amount = @loan_amount,
                            loan_purpose = @loan_purpose,
                            loan_tenure = @loan_tenure,
                            interest_rate = @interest_rate,
                            status = @status,
                            status_date = CURRENT_TIMESTAMP,
                            remarks = @remarks,
                            noteUser = @noteUser,
                            note = @note
                        WHERE national_id = @national_id 
                        AND application_no = @application_no";

                    await _auditLog.LogAsync(connection, transaction, "LOAN_APPLICATION_UPDATED", 
                        request.NationalId, 
                        $"Loan application updated: {request.ApplicationNo}, Status: {request.Status}");
                }

                command.Parameters.AddWithValue("@national_id", request.NationalId);
                command.Parameters.AddWithValue("@application_no", request.ApplicationNo);
                command.Parameters.AddWithValue("@customerDecision", request.CustomerDecision);
                command.Parameters.AddWithValue("@loan_amount", request.LoanAmount);
                command.Parameters.AddWithValue("@loan_purpose", request.LoanPurpose ?? (object)DBNull.Value);
                command.Parameters.AddWithValue("@loan_tenure", request.LoanTenure ?? (object)DBNull.Value);
                command.Parameters.AddWithValue("@interest_rate", request.InterestRate ?? (object)DBNull.Value);
                command.Parameters.AddWithValue("@status", request.Status);
                command.Parameters.AddWithValue("@remarks", request.Remarks ?? (object)DBNull.Value);
                command.Parameters.AddWithValue("@noteUser", request.NoteUser);
                command.Parameters.AddWithValue("@note", request.Note ?? (object)DBNull.Value);

                await command.ExecuteNonQueryAsync();
                await transaction.CommitAsync();

                var response = new LoanApplicationUpdateResponse
                {
                    LoanDetails = new LoanDetails
                    {
                        NationalId = request.NationalId,
                        ApplicationNo = request.ApplicationNo,
                        CustomerDecision = request.CustomerDecision,
                        LoanAmount = request.LoanAmount,
                        LoanPurpose = request.LoanPurpose,
                        LoanTenure = request.LoanTenure,
                        InterestRate = request.InterestRate,
                        Status = request.Status,
                        Remarks = request.Remarks,
                        NoteUser = request.NoteUser,
                        Note = request.Note
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                await _auditLog.LogAsync(connection, null, "LOAN_APPLICATION_ERROR", 
                    request.NationalId, 
                    $"Error processing loan application: {ex.Message}");
                throw new Exception($"Failed to process loan application: {ex.Message}");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating loan application");
            return BadRequest(new { status = "error", message = ex.Message });
        }
    }
} 