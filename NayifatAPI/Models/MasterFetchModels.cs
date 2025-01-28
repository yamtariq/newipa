using System.Text.Json.Serialization;

namespace NayifatAPI.Models;

public class MasterFetchRequest
{
    [JsonPropertyName("action")]
    public string Action { get; set; } = string.Empty;
}

public class MasterFetchResponse
{
    [JsonPropertyName("success")]
    public bool Success { get; set; }

    [JsonPropertyName("data")]
    public object? Data { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }
}

public class ContentData
{
    [JsonPropertyName("page")]
    public string Page { get; set; } = string.Empty;

    [JsonPropertyName("key_name")]
    public string KeyName { get; set; } = string.Empty;

    [JsonPropertyName("data")]
    public object? Data { get; set; }

    [JsonPropertyName("last_updated")]
    public string? LastUpdated { get; set; }
}

public class ContentType
{
    public string Page { get; set; } = string.Empty;
    public string KeyName { get; set; } = string.Empty;
}

public static class ContentTypes
{
    public static readonly List<ContentType> All = new()
    {
        new ContentType { Page = "home", KeyName = "slideshow_content" },
        new ContentType { Page = "home", KeyName = "slideshow_content_ar" },
        new ContentType { Page = "home", KeyName = "contact_details" },
        new ContentType { Page = "home", KeyName = "contact_details_ar" },
        new ContentType { Page = "loans", KeyName = "loan_ad" },
        new ContentType { Page = "cards", KeyName = "card_ad" }
    };
} 