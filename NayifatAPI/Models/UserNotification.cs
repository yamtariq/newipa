using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("user_notifications")]
    public class UserNotification
    {
        [Key]
        [Column("national_id")]
        public string NationalId { get; set; } = string.Empty;
        
        [Column("notifications")]
        public string Notifications { get; set; } = "[]";  // Stored as JSON array
        
        [Column("last_updated")]
        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
    }
} 