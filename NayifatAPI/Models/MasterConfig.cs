using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    public class MasterConfig
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public required string Page { get; set; }
        
        [Required]
        public required string KeyName { get; set; }
        
        [Required]
        public required string Value { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
        
        public bool IsActive { get; set; }
    }
} 