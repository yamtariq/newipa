using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models
{
    public class OtpCode
    {
        [Key]
        public int Id { get; set; }
        public string NationalId { get; set; }
        public string Code { get; set; }
        public string Purpose { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime ExpiresAt { get; set; }
        public bool IsUsed { get; set; }
        public DateTime? UsedAt { get; set; }
        public string Channel { get; set; }
    }
} 