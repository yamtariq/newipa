using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    public class MasterConfig
    {
        [Key]
        public int Id { get; set; }
        public string Page { get; set; }
        public string KeyName { get; set; }
        [Column(TypeName = "nvarchar(max)")]
        public string Value { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdated { get; set; }
        public bool IsActive { get; set; }
    }
} 