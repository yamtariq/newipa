using System.Text.Json.Serialization;

namespace NayifatAPI.Models;

public class LoanApplicationUpdateResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "success";

    [JsonPropertyName("message")]
    public string Message { get; set; } = "Loan application processed successfully";

    [JsonPropertyName("loan_details")]
    public LoanDetails LoanDetails { get; set; } = new();
}

public class LoanDetails
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
    public required string Status { get; set; }

    [JsonPropertyName("remarks")]
    public string? Remarks { get; set; }

    [JsonPropertyName("noteUser")]
    public required string NoteUser { get; set; }

    [JsonPropertyName("note")]
    public string? Note { get; set; }

    [JsonPropertyName("update_date")]
    public string UpdateDate { get; set; } = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
} 