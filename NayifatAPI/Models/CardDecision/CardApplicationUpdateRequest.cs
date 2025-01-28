using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models.CardDecision;

public class CardApplicationUpdateRequest
{
    [Required(ErrorMessage = "National ID is required")]
    public string national_id { get; set; } = string.Empty;

    [Required(ErrorMessage = "Card type is required")]
    public string card_type { get; set; } = string.Empty;

    [Required(ErrorMessage = "Card limit is required")]
    public decimal card_limit { get; set; }

    [Required(ErrorMessage = "Status is required")]
    public string status { get; set; } = string.Empty;

    [Required(ErrorMessage = "Customer decision is required")]
    public string customerDecision { get; set; } = string.Empty;

    [Required(ErrorMessage = "Note user is required")]
    public string noteUser { get; set; } = string.Empty;

    [Required(ErrorMessage = "Application number is required")]
    public string application_number { get; set; } = string.Empty;

    // Optional fields
    public string? remarks { get; set; }
    public string? note { get; set; }
} 