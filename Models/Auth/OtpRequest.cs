using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models.Auth
{
    public class OtpRequest
    {
        [Required]
        public string NationalId { get; set; }

        [Required]
        [StringLength(6, MinimumLength = 6)]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "OTP must be exactly 6 digits")]
        public string OtpCode { get; set; }

        [Required]
        public string RequestType { get; set; } // "registration", "password-reset", "device-verification"

        [Required]
        public DeviceInfo DeviceInfo { get; set; }
    }

    public class OtpResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public string Status { get; set; }
        public DateTime? ExpiryTime { get; set; }
    }
} 