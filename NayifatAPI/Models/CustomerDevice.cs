using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace NayifatAPI.Models
{
    [Table("Customer_Devices")]
    [Index(nameof(DeviceId), IsUnique = false)]
    [Index(nameof(NationalId), nameof(DeviceId), IsUnique = true)]
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
        
        public required bool BiometricEnabled { get; set; }
        
        [Required]
        public string Status { get; set; } = "active";
        
        public required DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? LastUsedAt { get; set; }
        
        public string? BiometricToken { get; set; }
        
        // Navigation Property
        [ForeignKey(nameof(NationalId))]
        public virtual Customer Customer { get; set; } = null!;
        
        // Computed Properties
        [NotMapped]
        public bool IsActive => Status == "active";
        
        [NotMapped]
        public string DeviceName => $"{Manufacturer} {Model}";
        
        [NotMapped]
        public bool IsBiometricEnabled => BiometricEnabled;
        
        [NotMapped]
        public DateTime RegisteredAt => CreatedAt;
    }
} 