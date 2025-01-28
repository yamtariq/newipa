namespace NayifatAPI.Models.CardDecision;

public class CardApplicationUpdateResponse
{
    public string status { get; set; } = "success";
    public string message { get; set; } = "Card application saved successfully";
    public CardDetails card_details { get; set; } = new();
}

public class CardDetails
{
    public string application_no { get; set; } = string.Empty;
    public string national_id { get; set; } = string.Empty;
    public string card_type { get; set; } = string.Empty;
    public decimal card_limit { get; set; }
    public string status { get; set; } = string.Empty;
    public string status_date { get; set; } = string.Empty;
    public string customerDecision { get; set; } = string.Empty;
    public string noteUser { get; set; } = string.Empty;
} 