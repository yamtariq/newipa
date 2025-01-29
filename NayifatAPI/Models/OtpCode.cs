using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace NayifatAPI.Models
{
    [Table("OTP_Codes")]
    public class OtpCode
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("national_id")]
        public required string NationalId { get; set; }
        
        [Required]
        [Column("otp_code")]
        public required string Code { get; set; }
        
        [Column("expires_at")]
        public DateTime ExpiresAt { get; set; }
        
        [Column("is_used")]
        public bool IsUsed { get; set; }
        
        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [Column("type")]
        public required string Type { get; set; }

        [Column("used_at")]
        public DateTime? UsedAt { get; set; }
    }
} 