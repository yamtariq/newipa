using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models.Auth
{
    public class SignInRequest
    {
        [Required]
        public string NationalId { get; set; }
        
        public string? Password { get; set; }
        
        public string? Mpin { get; set; }
        
        public BiometricData? BiometricData { get; set; }
        
        [Required]
        public string AuthMethod { get; set; } // "password", "mpin", "biometric"
        
        [Required]
        public DeviceInfo DeviceInfo { get; set; }
    }

    public class BiometricData
    {
        [Required]
        public string DeviceId { get; set; }
        
        [Required]
        public string BiometricToken { get; set; }
    }

    public class DeviceInfo
    {
        [Required]
        public string DeviceId { get; set; }
        
        [Required]
        public string DeviceModel { get; set; }
        
        [Required]
        public string DeviceType { get; set; } // "android", "ios"
        
        [Required]
        public string OsVersion { get; set; }
        
        public string? PushToken { get; set; }
    }
} 