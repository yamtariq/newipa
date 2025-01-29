using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models.Auth
{
    public class BiometricsRequest
    {
        [Required]
        public string NationalId { get; set; }

        [Required]
        public string DeviceId { get; set; }

        [Required]
        public bool EnableBiometrics { get; set; }

        [Required]
        public string BiometricToken { get; set; }

        [Required]
        public DeviceInfo DeviceInfo { get; set; }
    }
} 