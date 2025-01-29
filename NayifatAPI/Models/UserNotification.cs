using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("User_Notifications")]
    public class UserNotification
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public required string NotificationId { get; set; }
        
        [Required]
        public required string NationalId { get; set; }
        
        [Required]
        public required string Title { get; set; }
        
        [Required]
        public required string Message { get; set; }
        
        public string? Data { get; set; }
        
        [Required]
        public required string NotificationType { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
        
        public DateTime? ReadAt { get; set; }
        
        public bool IsRead { get; set; }
    }
} 