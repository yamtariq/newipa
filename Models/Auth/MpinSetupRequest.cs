using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models.Auth
{
    public class MpinSetupRequest
    {
        [Required]
        public string NationalId { get; set; }

        [Required]
        [StringLength(6, MinimumLength = 6)]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "MPIN must be exactly 6 digits")]
        public string Mpin { get; set; }

        [Required]
        public string CurrentPassword { get; set; }

        [Required]
        public DeviceInfo DeviceInfo { get; set; }
    }
} 