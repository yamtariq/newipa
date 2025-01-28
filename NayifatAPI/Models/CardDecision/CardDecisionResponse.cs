using System.Text.Json.Serialization;

namespace NayifatAPI.Models.CardDecision;

public class CardDecisionResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "success";

    [JsonPropertyName("decision")]
    public string Decision { get; set; } = "approved";

    [JsonPropertyName("credit_limit")]
    public decimal CreditLimit { get; set; }

    [JsonPropertyName("min_credit_limit")]
    public decimal MinCreditLimit { get; set; }

    [JsonPropertyName("max_credit_limit")]
    public decimal MaxCreditLimit { get; set; }

    [JsonPropertyName("application_number")]
    public string ApplicationNumber { get; set; } = string.Empty;

    [JsonPropertyName("card_type")]
    public string CardType { get; set; } = string.Empty;

    [JsonPropertyName("debug")]
    public CardDecisionDebugInfo Debug { get; set; } = new();
}

public class CardDecisionDebugInfo
{
    [JsonPropertyName("salary")]
    public decimal Salary { get; set; }

    [JsonPropertyName("liabilities")]
    public decimal Liabilities { get; set; }

    [JsonPropertyName("expenses")]
    public decimal Expenses { get; set; }

    [JsonPropertyName("max_credit_limit")]
    public decimal MaxCreditLimit { get; set; }

    [JsonPropertyName("monthly_dbr")]
    public decimal MonthlyDbr { get; set; }

    [JsonPropertyName("available_monthly")]
    public decimal AvailableMonthly { get; set; }

    [JsonPropertyName("payment_capacity")]
    public decimal PaymentCapacity { get; set; }

    [JsonPropertyName("credit_limit_from_capacity")]
    public decimal CreditLimitFromCapacity { get; set; }

    [JsonPropertyName("final_credit_limit")]
    public decimal FinalCreditLimit { get; set; }
}

public class CardDecisionErrorResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "error";

    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;

    [JsonPropertyName("message")]
    public string Message { get; set; } = string.Empty;

    [JsonPropertyName("message_ar")]
    public string? MessageAr { get; set; }

    [JsonPropertyName("application_no")]
    public string? ApplicationNo { get; set; }

    [JsonPropertyName("current_status")]
    public string? CurrentStatus { get; set; }

    [JsonPropertyName("errors")]
    public List<string>? Errors { get; set; }
} 