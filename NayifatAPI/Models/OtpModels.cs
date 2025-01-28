using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models;

public class OtpGenerateRequest
{
    [Required]
    public string NationalId { get; set; } = string.Empty;
}

public class OtpGenerateResponse
{
    public string Status { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? OtpCode { get; set; } // Only for development, remove in production
}

public class OtpVerificationRequest
{
    [Required]
    public string NationalId { get; set; } = string.Empty;
    
    [Required]
    public string OtpCode { get; set; } = string.Empty;
}

public class OtpVerificationResponse
{
    public string Status { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public Dictionary<string, object>? Debug { get; set; } // Only for development
} 