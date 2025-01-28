using System.Text.Json.Serialization;

namespace NayifatAPI.Models;

public class RefreshTokenResponse
{
    [JsonPropertyName("success")]
    public bool success { get; set; }

    [JsonPropertyName("access_token")]
    public string? access_token { get; set; }

    [JsonPropertyName("expires_in")]
    public int? expires_in { get; set; }

    [JsonPropertyName("token_type")]
    public string? token_type { get; set; }

    // For error responses
    [JsonPropertyName("error")]
    public string? error { get; set; }

    [JsonPropertyName("message")]
    public string? message { get; set; }
} 