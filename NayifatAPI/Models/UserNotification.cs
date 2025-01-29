using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    public class UserNotification
    {
        [Key]
        public int Id { get; set; }
        public string NationalId { get; set; }
        public string Title { get; set; }
        public string Message { get; set; }
        [Column(TypeName = "nvarchar(max)")]
        public string Data { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ReadAt { get; set; }
        public string NotificationType { get; set; }
    }
} 