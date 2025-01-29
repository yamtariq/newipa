using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models
{
    public class AuthLog
    {
        [Key]
        public long Id { get; set; }
        public string NationalId { get; set; }
        public string DeviceId { get; set; }
        public string AuthType { get; set; }
        public bool IsSuccessful { get; set; }
        public string ErrorMessage { get; set; }
        public string IpAddress { get; set; }
        public string UserAgent { get; set; }
        public DateTime CreatedAt { get; set; }
    }
} 