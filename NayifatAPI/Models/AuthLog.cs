using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models
{
    public class AuthLog
    {
        [Key]
        public long Id { get; set; }
        
        [Required]
        public required string NationalId { get; set; }
        
        public string? DeviceId { get; set; }
        
        [Required]
        public required string AuthType { get; set; }
        
        [Required]
        public required string Status { get; set; }
        
        public string? FailureReason { get; set; }
        
        public string? IpAddress { get; set; }
        
        public string? UserAgent { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
} 