using System.Text.Json.Serialization;

namespace NayifatAPI.Models
{
    public class DeviceRegistrationRequest
    {
        [JsonPropertyName("national_id")]
        public required string NationalId { get; set; }

        [JsonPropertyName("deviceId")]
        public string? DeviceId { get; set; }

        [JsonPropertyName("platform")]
        public string? Platform { get; set; }

        [JsonPropertyName("model")]
        public string? Model { get; set; }

        [JsonPropertyName("manufacturer")]
        public string? Manufacturer { get; set; }
    }

    public class DeviceRegistrationResponse : ApiResponse
    {
        [JsonPropertyName("device_id")]
        public int? DeviceId { get; set; }

        public DeviceRegistrationResponse(string status, string message, int? deviceId = null) 
            : base(status, message)
        {
            DeviceId = deviceId;
        }

        public static DeviceRegistrationResponse Success(string message, int? deviceId = null)
        {
            return new DeviceRegistrationResponse("success", message, deviceId);
        }

        public static DeviceRegistrationResponse Error(string message)
        {
            return new DeviceRegistrationResponse("error", message);
        }
    }
} 