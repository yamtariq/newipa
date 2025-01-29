using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace NayifatAPI.Models
{
    [Table("master_config")]
    [Index(nameof(Page), nameof(KeyName), IsUnique = true)]
    public class MasterConfig
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public required string Page { get; set; }
        
        [Required]
        public required string KeyName { get; set; }
        
        [Required]
        [Column(TypeName = "nvarchar(max)")]
        public required string Value { get; set; }
        
        public required bool IsActive { get; set; } = true;
        
        public required DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? UpdatedAt { get; set; }
        
        [NotMapped]
        public bool IsValid => !string.IsNullOrEmpty(Value) && IsActive;
    }
} 