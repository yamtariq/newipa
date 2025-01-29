using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("Customer_Devices")]
    public class CustomerDevice
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public required string NationalId { get; set; }
        
        [Required]
        public required string DeviceId { get; set; }
        
        [Required]
        public required string Platform { get; set; }
        
        [Required]
        public required string Model { get; set; }
        
        [Required]
        public required string Manufacturer { get; set; }
        
        public string? OsVersion { get; set; }
        
        public bool BiometricEnabled { get; set; }
        
        [Required]
        public string Status { get; set; } = "active";
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? LastUsedAt { get; set; }
        
        public string? BiometricToken { get; set; }
        
        public bool IsActive => Status == "active";
        
        public string DeviceName => $"{Manufacturer} {Model}";
        
        public bool IsBiometricEnabled => BiometricEnabled;
        
        public DateTime RegisteredAt => CreatedAt;
    }
} 