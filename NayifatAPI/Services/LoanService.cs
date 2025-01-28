using MySql.Data.MySqlClient;
using NayifatAPI.Models;
using System.Text.Json;

namespace NayifatAPI.Services;

public interface ILoanService
{
    Task<LoanDecisionResponse> GetLoanDecisionAsync(LoanDecisionRequest request);
}

public class LoanService : ILoanService
{
    private readonly DatabaseService _db;
    private readonly ILogger<LoanService> _logger;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IAuditService _auditService;

    public LoanService(
        DatabaseService db,
        ILogger<LoanService> logger,
        IHttpContextAccessor httpContextAccessor,
        IAuditService auditService)
    {
        _db = db;
        _logger = logger;
        _httpContextAccessor = httpContextAccessor;
        _auditService = auditService;
    }

    public async Task<LoanDecisionResponse> GetLoanDecisionAsync(LoanDecisionRequest request)
    {
        try
        {
            using var connection = await _db.GetConnectionAsync();
            await connection.OpenAsync();

            // Get user ID for audit logging
            using var userCmd = connection.CreateCommand();
            userCmd.CommandText = "SELECT id FROM Customers WHERE national_id = @nationalId";
            userCmd.Parameters.Add("@nationalId", MySqlDbType.VarChar).Value = request.NationalId;
            var userId = await userCmd.ExecuteScalarAsync();
            var userIdInt = userId != null ? Convert.ToInt32(userId) : 0;

            // Check for active applications first
            using var command = connection.CreateCommand();
            command.CommandText = @"SELECT application_no, status 
                FROM loan_application_details 
                WHERE national_id = @nationalId 
                AND status NOT IN ('Rejected', 'Declined')
                AND status_date >= DATE_SUB(NOW(), INTERVAL 5 DAY)
                ORDER BY loan_id DESC 
                LIMIT 1";

            command.Parameters.Add("@nationalId", MySqlDbType.VarChar).Value = request.NationalId;

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                var appNo = reader.GetString("application_no");
                var status = reader.GetString("status");

                await _auditService.LogAuditAsync(userIdInt, "Loan Decision Failed", 
                    $"Active application exists: {appNo} with status: {status}");

                return LoanDecisionResponse.Error(
                    "ACTIVE_APPLICATION_EXISTS",
                    "You have an active loan application. Please check your application status.",
                    "لديك طلب تمويل نشط. يرجى التحقق من حالة طلبك.",
                    appNo,
                    status
                );
            }

            // Basic validations
            if (request.Salary < 4000)
            {
                await _auditService.LogAuditAsync(userIdInt, "Loan Decision Failed", 
                    "Validation error: Salary below minimum requirement");

                return LoanDecisionResponse.Error(
                    "VALIDATION_ERROR",
                    "Invalid input data",
                    "بيانات غير صالحة",
                    null,
                    null
                );
            }

            // NEW CALCULATION LOGIC per specifications
            // 1. dbr_emi = salary * 0.15
            var dbrEmi = request.Salary * 0.15;

            // 2. max_emi = salary - liabilities
            var maxEmi = request.Salary - request.Liabilities;

            // 3. final EMI = which is lower between dbr_emi and max_emi
            var allowedEmi = Math.Min(dbrEmi, maxEmi);

            // Force a 60-month tenure (5 years) for the new calculations
            const int tenureMonths = 60;
            var tenureYears = tenureMonths / 12.0;

            // Define a flat annual interest rate
            const double flatRate = 0.16; // 16%

            // 4. total loan with interest = emi * 60
            var initialTotalRepayment = allowedEmi * tenureMonths;

            // 5. Backward calculation of principal
            var rawPrincipal = initialTotalRepayment / (1 + (flatRate * tenureYears));

            // 6. Clamp principal between 10,000 and 300,000
            const double minPrincipal = 10000;
            const double maxPrincipal = 300000;

            var finalPrincipal = Math.Clamp(rawPrincipal, minPrincipal, maxPrincipal);

            // 7. Recalculate final numbers based on clamped principal
            var totalRepayment = finalPrincipal * (1 + (flatRate * tenureYears));
            var actualEmi = totalRepayment / tenureMonths;
            var totalInterest = totalRepayment - finalPrincipal;

            // Generate a unique 7-digit application number
            var random = new Random();
            var applicationNumber = random.Next(1000000, 9999999).ToString().PadLeft(7, '0');

            // Prepare debug info
            var debugInfo = new LoanDebugInfo
            {
                Salary = request.Salary,
                Liabilities = request.Liabilities,
                Expenses = request.Expenses,
                FlatRate = flatRate,
                DbrEmi = dbrEmi,
                MaxEmi = maxEmi,
                AllowedEmi = allowedEmi,
                InitialTotalRepayment = initialTotalRepayment,
                RawPrincipalCalc = rawPrincipal,
                ClampedPrincipal = finalPrincipal,
                TenureMonths = tenureMonths,
                TenureYears = tenureYears,
                TotalInterest = totalInterest,
                RecalculatedEmi = actualEmi
            };

            await _auditService.LogAuditAsync(userIdInt, "Loan Decision Approved", 
                JsonSerializer.Serialize(new {
                    application_no = applicationNumber,
                    principal = finalPrincipal,
                    tenure = tenureMonths,
                    emi = actualEmi,
                    total_repayment = totalRepayment,
                    debug_info = debugInfo
                }));

            return LoanDecisionResponse.Success(
                "approved",
                finalPrincipal,
                tenureMonths,
                actualEmi,
                flatRate,
                totalRepayment,
                totalInterest,
                applicationNumber,
                debugInfo
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing loan decision for national ID: {NationalId}", request.NationalId);
            
            await _auditService.LogAuditAsync(0, "Loan Decision Error", 
                $"Error processing loan decision for national ID: {request.NationalId}. Error: {ex.Message}");

            return LoanDecisionResponse.Error(
                "SYSTEM_ERROR",
                ex.Message
            );
        }
    }
} 