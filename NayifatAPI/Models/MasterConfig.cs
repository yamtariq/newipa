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
        [Column("config_id")]
        public int ConfigId { get; set; }

        [Column("page")]
        public string Page { get; set; } = string.Empty;

        [Column("key_name")]
        public string KeyName { get; set; } = string.Empty;

        [Column("value")]
        public string Value { get; set; } = string.Empty;

        [Column("last_updated")]
        public DateTime LastUpdated { get; set; }
    }
} 