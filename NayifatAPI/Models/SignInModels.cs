namespace NayifatAPI.Models;

public class SignInRequest
{
    public string national_id { get; set; } = string.Empty;
    public string? deviceId { get; set; }
    public string? password { get; set; }
}

public class SignInResponse
{
    public string status { get; set; } = string.Empty;
    public string code { get; set; } = string.Empty;
    public string message { get; set; } = string.Empty;
    public string? token { get; set; }
    public bool? require_otp { get; set; }
    public Dictionary<string, object>? user { get; set; }
} 