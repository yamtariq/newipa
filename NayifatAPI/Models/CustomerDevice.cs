using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models
{
    public class CustomerDevice
    {
        [Key]
        public int Id { get; set; }
        public string NationalId { get; set; }
        public string DeviceId { get; set; }
        public string DeviceName { get; set; }
        public string Platform { get; set; }
        public string OsVersion { get; set; }
        public bool IsBiometricEnabled { get; set; }
        public DateTime RegisteredAt { get; set; }
        public DateTime? LastUsedAt { get; set; }
        public string PushToken { get; set; }
        public bool IsActive { get; set; }
    }
} 