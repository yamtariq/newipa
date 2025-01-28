using MySql.Data.MySqlClient;
using NayifatAPI.Models.CardDecision;
using System.Security.Cryptography;
using System.Text.Json;

namespace NayifatAPI.Services;

public interface ICardDecisionService
{
    Task<object> ProcessCardDecision(CardDecisionRequest request);
    Task<CardApplicationUpdateResponse> UpdateCardApplication(CardApplicationUpdateRequest request);
}

public class CardDecisionService : ICardDecisionService
{
    private readonly IDatabaseService _db;
    private readonly IAuditService _auditService;
    private readonly ILogger<CardDecisionService> _logger;
    private const decimal MIN_CREDIT_LIMIT = 2000m;
    private const decimal MAX_CREDIT_LIMIT = 50000m;
    private const decimal MIN_SALARY = 4000m;
    private const decimal DBR_RATE = 0.15m;

    public CardDecisionService(
        IDatabaseService db, 
        IAuditService auditService,
        ILogger<CardDecisionService> logger)
    {
        _db = db;
        _auditService = auditService;
        _logger = logger;
    }

    public async Task<object> ProcessCardDecision(CardDecisionRequest request)
    {
        try
        {
            // Get user ID for audit logging
            using var userCmd = _db.CreateCommand("SELECT id FROM Customers WHERE national_id = @nationalId");
            userCmd.Parameters.AddWithValue("@nationalId", request.NationalId);
            var userId = await userCmd.ExecuteScalarAsync();
            var userIdInt = userId != null ? Convert.ToInt32(userId) : 0;

            // Check for active applications first
            var activeApplication = await CheckActiveApplications(request.NationalId);
            if (activeApplication != null)
            {
                await _auditService.LogAuditAsync(userIdInt, "Card Decision Failed", 
                    $"Active application exists: {activeApplication.ApplicationNo} with status: {activeApplication.CurrentStatus}");

                return activeApplication;
            }

            // Validate salary
            if (request.Salary < MIN_SALARY)
            {
                await _auditService.LogAuditAsync(userIdInt, "Card Decision Failed", 
                    "Validation error: Salary below minimum requirement");

                return new CardDecisionErrorResponse
                {
                    Code = "VALIDATION_ERROR",
                    Message = "Invalid input data",
                    Errors = new List<string> { "Minimum salary must be 4000." }
                };
            }

            // Calculate credit limit
            var (creditLimit, debugInfo) = CalculateCreditLimit(request);

            // Generate application number
            string applicationNumber = GenerateApplicationNumber();

            // Determine card type
            string cardType = creditLimit >= 17500 ? "GOLD" : "REWARD";

            // Save application
            await SaveCardApplication(request.NationalId, applicationNumber, cardType, creditLimit);

            // Log success
            await _auditService.LogAuditAsync(userIdInt, "Card Decision Approved", 
                JsonSerializer.Serialize(new {
                    application_no = applicationNumber,
                    card_type = cardType,
                    credit_limit = creditLimit,
                    debug_info = debugInfo
                }));

            // Return response
            return new CardDecisionResponse
            {
                CreditLimit = creditLimit,
                MinCreditLimit = MIN_CREDIT_LIMIT,
                MaxCreditLimit = MAX_CREDIT_LIMIT,
                ApplicationNumber = applicationNumber,
                CardType = cardType,
                Debug = debugInfo
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing card decision for national ID: {NationalId}", request.NationalId);
            
            await _auditService.LogAuditAsync(0, "Card Decision Error", 
                $"Error processing card decision for national ID: {request.NationalId}. Error: {ex.Message}");

            return new CardDecisionErrorResponse
            {
                Code = "SYSTEM_ERROR",
                Message = ex.Message
            };
        }
    }

    private async Task<CardDecisionErrorResponse?> CheckActiveApplications(string nationalId)
    {
        using var cmd = _db.CreateCommand(@"
            SELECT application_no, status 
            FROM card_application_details 
            WHERE national_id = @nationalId 
            AND status NOT IN ('Rejected', 'Declined')
            AND status_date >= DATE_SUB(NOW(), INTERVAL 5 DAY)
            ORDER BY card_id DESC 
            LIMIT 1");

        cmd.Parameters.AddWithValue("@nationalId", nationalId);
        
        using var reader = await cmd.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return new CardDecisionErrorResponse
            {
                Code = "ACTIVE_APPLICATION_EXISTS",
                Message = "You have an active card application. Please check your application status.",
                MessageAr = "لديك طلب بطاقة نشط. يرجى التحقق من حالة طلبك.",
                ApplicationNo = reader.GetString("application_no"),
                CurrentStatus = reader.GetString("status")
            };
        }

        return null;
    }

    private (decimal creditLimit, CardDecisionDebugInfo debugInfo) CalculateCreditLimit(CardDecisionRequest request)
    {
        // 1. Calculate maximum credit limit (2x monthly salary)
        decimal maxCreditLimit = request.Salary * 2;

        // 2. Calculate DBR-based limit (15% of salary for monthly payment)
        decimal monthlyDbr = request.Salary * DBR_RATE;

        // 3. Calculate available monthly payment capacity
        decimal availableMonthly = request.Salary - request.Liabilities - request.Expenses;

        // 4. Use the lower of DBR and available monthly as the payment capacity
        decimal paymentCapacity = Math.Min(monthlyDbr, availableMonthly);

        // 5. Calculate credit limit based on payment capacity (assuming 5% minimum payment)
        decimal creditLimitFromCapacity = paymentCapacity * 20;

        // 6. Take the lower of maximum credit limit and capacity-based limit
        decimal finalCreditLimit = Math.Min(maxCreditLimit, creditLimitFromCapacity);

        // 7. Apply minimum and maximum bounds
        finalCreditLimit = Math.Max(MIN_CREDIT_LIMIT, Math.Min(finalCreditLimit, MAX_CREDIT_LIMIT));

        // 8. Round to nearest 100
        finalCreditLimit = Math.Floor(finalCreditLimit / 100) * 100;

        var debugInfo = new CardDecisionDebugInfo
        {
            Salary = request.Salary,
            Liabilities = request.Liabilities,
            Expenses = request.Expenses,
            MaxCreditLimit = maxCreditLimit,
            MonthlyDbr = monthlyDbr,
            AvailableMonthly = availableMonthly,
            PaymentCapacity = paymentCapacity,
            CreditLimitFromCapacity = creditLimitFromCapacity,
            FinalCreditLimit = finalCreditLimit
        };

        return (finalCreditLimit, debugInfo);
    }

    private string GenerateApplicationNumber()
    {
        using var rng = RandomNumberGenerator.Create();
        var bytes = new byte[4];
        rng.GetBytes(bytes);
        int number = Math.Abs(BitConverter.ToInt32(bytes, 0) % 9000000) + 1000000;
        return number.ToString();
    }

    private async Task SaveCardApplication(string nationalId, string applicationNumber, string cardType, decimal creditLimit)
    {
        using var cmd = _db.CreateCommand(@"
            INSERT INTO card_application_details (
                application_no,
                national_id,
                card_type,
                card_limit,
                status
            ) VALUES (
                @applicationNo,
                @nationalId,
                @cardType,
                @cardLimit,
                @status
            )");

        cmd.Parameters.AddWithValue("@applicationNo", applicationNumber);
        cmd.Parameters.AddWithValue("@nationalId", nationalId);
        cmd.Parameters.AddWithValue("@cardType", cardType);
        cmd.Parameters.AddWithValue("@cardLimit", creditLimit);
        cmd.Parameters.AddWithValue("@status", "pending");

        await cmd.ExecuteNonQueryAsync();
    }

    public async Task<CardApplicationUpdateResponse> UpdateCardApplication(CardApplicationUpdateRequest request)
    {
        using var connection = await _db.GetConnection();
        await connection.OpenAsync();

        using var transaction = await connection.BeginTransactionAsync();

        try
        {
            var riyadhTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Riyadh");
            var statusDate = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, riyadhTimeZone)
                .ToString("yyyy-MM-dd HH:mm:ss");
            var applicationNo = int.Parse(request.application_number);

            // First check if the card application exists
            var checkCommand = connection.CreateCommand();
            checkCommand.CommandText = "SELECT card_id FROM card_application_details WHERE national_id = @national_id AND application_no = @application_no";
            checkCommand.Parameters.AddWithValue("@national_id", request.national_id);
            checkCommand.Parameters.AddWithValue("@application_no", applicationNo);
            
            var cardId = await checkCommand.ExecuteScalarAsync();

            MySqlCommand command;
            if (cardId == null)
            {
                // Insert new record
                command = connection.CreateCommand();
                command.CommandText = @"INSERT INTO card_application_details (
                    national_id,
                    application_no,
                    card_type,
                    card_limit,
                    status,
                    status_date,
                    customerDecision,
                    remarks,
                    noteUser,
                    note
                ) VALUES (
                    @national_id,
                    @application_no,
                    @card_type,
                    @card_limit,
                    @status,
                    @status_date,
                    @customerDecision,
                    @remarks,
                    @noteUser,
                    @note
                )";
            }
            else
            {
                // Update existing record
                command = connection.CreateCommand();
                command.CommandText = @"UPDATE card_application_details SET 
                    card_limit = @card_limit,
                    status = @status,
                    status_date = @status_date,
                    customerDecision = @customerDecision,
                    remarks = @remarks,
                    noteUser = @noteUser,
                    note = @note
                    WHERE application_no = @application_no AND national_id = @national_id";
            }

            // Add parameters
            command.Parameters.AddWithValue("@national_id", request.national_id);
            command.Parameters.AddWithValue("@application_no", applicationNo);
            command.Parameters.AddWithValue("@card_type", request.card_type);
            command.Parameters.AddWithValue("@card_limit", request.card_limit);
            command.Parameters.AddWithValue("@status", request.status);
            command.Parameters.AddWithValue("@status_date", statusDate);
            command.Parameters.AddWithValue("@customerDecision", request.customerDecision);
            command.Parameters.AddWithValue("@remarks", request.remarks ?? "Card application submitted");
            command.Parameters.AddWithValue("@noteUser", request.noteUser);
            command.Parameters.AddWithValue("@note", request.note ?? (object)DBNull.Value);

            await command.ExecuteNonQueryAsync();

            // Log the successful application update
            var auditCommand = connection.CreateCommand();
            auditCommand.CommandText = "INSERT INTO audit_logs (user_id, action, details) VALUES (@user_id, @action, @details)";
            auditCommand.Parameters.AddWithValue("@user_id", DBNull.Value);
            auditCommand.Parameters.AddWithValue("@action", "Card Application Updated");
            auditCommand.Parameters.AddWithValue("@details", $"Card application updated for National ID: {request.national_id}, Application #: {request.application_number}");
            await auditCommand.ExecuteNonQueryAsync();

            await transaction.CommitAsync();

            return new CardApplicationUpdateResponse
            {
                card_details = new CardDetails
                {
                    application_no = request.application_number,
                    national_id = request.national_id,
                    card_type = request.card_type,
                    card_limit = request.card_limit,
                    status = request.status,
                    status_date = statusDate,
                    customerDecision = request.customerDecision,
                    noteUser = request.noteUser
                }
            };
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            
            // Log the error
            var auditCommand = connection.CreateCommand();
            auditCommand.CommandText = "INSERT INTO audit_logs (user_id, action, details) VALUES (@user_id, @action, @details)";
            auditCommand.Parameters.AddWithValue("@user_id", DBNull.Value);
            auditCommand.Parameters.AddWithValue("@action", "Card Application Error");
            auditCommand.Parameters.AddWithValue("@details", ex.Message);
            await auditCommand.ExecuteNonQueryAsync();

            throw;
        }
    }
} 