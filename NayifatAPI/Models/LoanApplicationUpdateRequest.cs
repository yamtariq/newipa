using System.Text.Json.Serialization;

namespace NayifatAPI.Models;

public class LoanApplicationUpdateRequest
{
    [JsonPropertyName("national_id")]
    public required string NationalId { get; set; }

    [JsonPropertyName("application_no")]
    public required string ApplicationNo { get; set; }

    [JsonPropertyName("customerDecision")]
    public required string CustomerDecision { get; set; }

    [JsonPropertyName("loan_amount")]
    public required decimal LoanAmount { get; set; }

    [JsonPropertyName("loan_purpose")]
    public string? LoanPurpose { get; set; }

    [JsonPropertyName("loan_tenure")]
    public int? LoanTenure { get; set; }

    [JsonPropertyName("interest_rate")]
    public decimal? InterestRate { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = "pending";

    [JsonPropertyName("remarks")]
    public string? Remarks { get; set; }

    [JsonPropertyName("noteUser")]
    public string NoteUser { get; set; } = "SYSTEM";

    [JsonPropertyName("note")]
    public string? Note { get; set; }
} 