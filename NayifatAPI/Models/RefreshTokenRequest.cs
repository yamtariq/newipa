using System.Text.Json.Serialization;

namespace NayifatAPI.Models;

public class RefreshTokenRequest
{
    [JsonPropertyName("refresh_token")]
    public string? refresh_token { get; set; }
} 