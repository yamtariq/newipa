using System.Text.Json.Serialization;

namespace NayifatAPI.Models;

public class ApiResponse<T>
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "success";

    [JsonPropertyName("code")]
    public string? Code { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    [JsonPropertyName("data")]
    public T? Data { get; set; }

    public static ApiResponse<T> Success(T data, string? message = null)
    {
        return new ApiResponse<T>
        {
            Status = "success",
            Message = message,
            Data = data
        };
    }

    public static ApiResponse<T> Error(string code, string message)
    {
        return new ApiResponse<T>
        {
            Status = "error",
            Code = code,
            Message = message
        };
    }
} 