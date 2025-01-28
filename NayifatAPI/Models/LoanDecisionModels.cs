using System.Text.Json.Serialization;

namespace NayifatAPI.Models;

public class LoanDecisionRequest
{
    [JsonPropertyName("national_id")]
    public required string NationalId { get; set; }

    [JsonPropertyName("salary")]
    public required double Salary { get; set; }

    [JsonPropertyName("liabilities")]
    public required double Liabilities { get; set; }

    [JsonPropertyName("expenses")]
    public required double Expenses { get; set; }

    [JsonPropertyName("requested_tenure")]
    public required int RequestedTenure { get; set; }
}

public class LoanDebugInfo
{
    [JsonPropertyName("salary")]
    public double Salary { get; set; }

    [JsonPropertyName("liabilities")]
    public double Liabilities { get; set; }

    [JsonPropertyName("expenses")]
    public double Expenses { get; set; }

    [JsonPropertyName("flat_rate")]
    public double FlatRate { get; set; }

    [JsonPropertyName("dbr_emi")]
    public double DbrEmi { get; set; }

    [JsonPropertyName("max_emi")]
    public double MaxEmi { get; set; }

    [JsonPropertyName("allowed_emi")]
    public double AllowedEmi { get; set; }

    [JsonPropertyName("initial_total_repayment")]
    public double InitialTotalRepayment { get; set; }

    [JsonPropertyName("raw_principal_calc")]
    public double RawPrincipalCalc { get; set; }

    [JsonPropertyName("clamped_principal")]
    public double ClampedPrincipal { get; set; }

    [JsonPropertyName("tenure_months")]
    public int TenureMonths { get; set; }

    [JsonPropertyName("tenure_years")]
    public double TenureYears { get; set; }

    [JsonPropertyName("total_interest")]
    public double TotalInterest { get; set; }

    [JsonPropertyName("recalculated_emi")]
    public double RecalculatedEmi { get; set; }
}

public class LoanDecisionResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("code")]
    public string? Code { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }

    [JsonPropertyName("message_ar")]
    public string? MessageAr { get; set; }

    [JsonPropertyName("application_no")]
    public string? ApplicationNo { get; set; }

    [JsonPropertyName("current_status")]
    public string? CurrentStatus { get; set; }

    [JsonPropertyName("decision")]
    public string? Decision { get; set; }

    [JsonPropertyName("finance_amount")]
    public double? FinanceAmount { get; set; }

    [JsonPropertyName("tenure")]
    public int? Tenure { get; set; }

    [JsonPropertyName("emi")]
    public double? Emi { get; set; }

    [JsonPropertyName("flat_rate")]
    public double? FlatRate { get; set; }

    [JsonPropertyName("total_repayment")]
    public double? TotalRepayment { get; set; }

    [JsonPropertyName("interest")]
    public double? Interest { get; set; }

    [JsonPropertyName("application_number")]
    public string? ApplicationNumber { get; set; }

    [JsonPropertyName("debug")]
    public LoanDebugInfo? Debug { get; set; }

    public static LoanDecisionResponse Error(string code, string message, string messageAr = "", string? applicationNo = null, string? currentStatus = null)
    {
        return new LoanDecisionResponse
        {
            Status = "error",
            Code = code,
            Message = message,
            MessageAr = messageAr,
            ApplicationNo = applicationNo,
            CurrentStatus = currentStatus
        };
    }

    public static LoanDecisionResponse Success(
        string decision,
        double financeAmount,
        int tenure,
        double emi,
        double flatRate,
        double totalRepayment,
        double interest,
        string applicationNumber,
        LoanDebugInfo debug)
    {
        return new LoanDecisionResponse
        {
            Status = "success",
            Decision = decision,
            FinanceAmount = Math.Floor(financeAmount),
            Tenure = tenure,
            Emi = Math.Round(emi, 2),
            FlatRate = flatRate,
            TotalRepayment = Math.Round(totalRepayment, 2),
            Interest = Math.Round(interest, 2),
            ApplicationNumber = applicationNumber,
            Debug = debug
        };
    }
} 