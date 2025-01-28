using System.Text.Json.Serialization;

namespace NayifatAPI.Models.CardDecision;

public class CardDecisionRequest
{
    [JsonPropertyName("national_id")]
    public required string NationalId { get; set; }

    [JsonPropertyName("salary")]
    public required decimal Salary { get; set; }

    [JsonPropertyName("liabilities")]
    public required decimal Liabilities { get; set; }

    [JsonPropertyName("expenses")]
    public required decimal Expenses { get; set; }
} 