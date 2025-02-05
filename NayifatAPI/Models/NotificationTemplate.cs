using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("notification_templates")]
    public class NotificationTemplate
    {
        [Key]
        public int Id { get; set; }

        public string? Title { get; set; }
        public string? Body { get; set; }
        
        [Column("title_en")]
        public string? TitleEn { get; set; }
        
        [Column("body_en")]
        public string? BodyEn { get; set; }
        
        [Column("title_ar")]
        public string? TitleAr { get; set; }
        
        [Column("body_ar")]
        public string? BodyAr { get; set; }
        
        public string? Route { get; set; }
        
        [Column("additional_data")]
        public string? AdditionalData { get; set; }  // Stored as JSON
        
        [Column("target_criteria")]
        public string? TargetCriteria { get; set; }  // Stored as JSON
        
        [Column("created_at")]
        public DateTime CreatedAt { get; set; }
        
        [Column("expiry_at")]
        public DateTime? ExpiryAt { get; set; }

        // 💡 Added image URL fields
        [Column("big_picture_url")]
        public string? BigPictureUrl { get; set; }  // For large notification image
        
        [Column("large_icon_url")]
        public string? LargeIconUrl { get; set; }   // For notification icon
    }
} 