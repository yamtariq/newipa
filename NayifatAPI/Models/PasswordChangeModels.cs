using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models;

public class PasswordChangeRequest
{
    [Required]
    public string NationalId { get; set; } = string.Empty;
    
    [Required]
    public string NewPassword { get; set; } = string.Empty;
    
    public string Type { get; set; } = "reset_password";
}

public class PasswordChangeResponse
{
    public string Status { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string MessageAr { get; set; } = string.Empty;
}

public class PasswordChangeErrorResponse
{
    public string Status { get; set; } = "error";
    public string Code { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string MessageAr { get; set; } = string.Empty;
}

public class PasswordChangeLog
{
    public string NationalId { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string IpAddress { get; set; } = string.Empty;
    public string UserAgent { get; set; } = string.Empty;
} 