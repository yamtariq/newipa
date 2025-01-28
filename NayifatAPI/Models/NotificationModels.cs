using System.Text.Json.Serialization;

namespace NayifatAPI.Models;

public class GetNotificationsRequest
{
    [JsonPropertyName("national_id")]
    public required string NationalId { get; set; }

    [JsonPropertyName("mark_as_read")]
    public bool? MarkAsRead { get; set; }
}

public class NotificationTemplate
{
    [JsonPropertyName("id")]
    public required string Id { get; set; }

    [JsonPropertyName("title")]
    public string? Title { get; set; }

    [JsonPropertyName("body")]
    public string? Body { get; set; }

    [JsonPropertyName("title_en")]
    public string? TitleEn { get; set; }

    [JsonPropertyName("body_en")]
    public string? BodyEn { get; set; }

    [JsonPropertyName("title_ar")]
    public string? TitleAr { get; set; }

    [JsonPropertyName("body_ar")]
    public string? BodyAr { get; set; }

    [JsonPropertyName("route")]
    public string? Route { get; set; }

    [JsonPropertyName("additional_data")]
    public Dictionary<string, object>? AdditionalData { get; set; }

    [JsonPropertyName("created_at")]
    public string? CreatedAt { get; set; }

    [JsonPropertyName("expires_at")]
    public string? ExpiresAt { get; set; }

    [JsonPropertyName("status")]
    public string? Status { get; set; }
}

public class GetNotificationsResponse : ApiResponse<List<NotificationTemplate>>
{
    public GetNotificationsResponse(List<NotificationTemplate> notifications) : base("success", notifications) { }
    public GetNotificationsResponse(string error) : base("error", null, error) { }
}

public class SendNotificationRequest
{
    [JsonPropertyName("national_id")]
    public string? NationalId { get; set; }

    [JsonPropertyName("national_ids")]
    public List<string>? NationalIds { get; set; }

    [JsonPropertyName("filters")]
    public Dictionary<string, object>? Filters { get; set; }

    [JsonPropertyName("filter_operation")]
    public string? FilterOperation { get; set; }

    [JsonPropertyName("title")]
    public string? Title { get; set; }

    [JsonPropertyName("body")]
    public string? Body { get; set; }

    [JsonPropertyName("title_en")]
    public string? TitleEn { get; set; }

    [JsonPropertyName("body_en")]
    public string? BodyEn { get; set; }

    [JsonPropertyName("title_ar")]
    public string? TitleAr { get; set; }

    [JsonPropertyName("body_ar")]
    public string? BodyAr { get; set; }

    [JsonPropertyName("route")]
    public string? Route { get; set; }

    [JsonPropertyName("additional_data")]
    public Dictionary<string, object>? AdditionalData { get; set; }

    [JsonPropertyName("expires_at")]
    public string? ExpiresAt { get; set; }
}

public class SendNotificationResponse : ApiResponse<object>
{
    public SendNotificationResponse() : base("success", new {}) { }
    public SendNotificationResponse(string error) : base("error", null, error) { }
}

public class UserNotification
{
    [JsonPropertyName("template_id")]
    public required string TemplateId { get; set; }

    [JsonPropertyName("created_at")]
    public required string CreatedAt { get; set; }

    [JsonPropertyName("expires_at")]
    public string? ExpiresAt { get; set; }

    [JsonPropertyName("status")]
    public required string Status { get; set; }

    [JsonPropertyName("read_at")]
    public string? ReadAt { get; set; }
} 