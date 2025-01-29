using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models.Auth
{
    public class RegisterRequest
    {
        [Required]
        [StringLength(10, MinimumLength = 10)]
        public string NationalId { get; set; }

        [Required]
        [StringLength(100, MinimumLength = 8)]
        public string Password { get; set; }

        [Required]
        public DeviceInfo DeviceInfo { get; set; }

        [Required]
        [DataType(DataType.Date)]
        public DateTime DateOfBirth { get; set; }

        [Required]
        [DataType(DataType.Date)]
        public DateTime IdExpiryDate { get; set; }

        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        [Phone]
        public string Phone { get; set; }
    }
} 