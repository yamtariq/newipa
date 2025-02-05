using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("lead_apps_cards")]
    public class LeadAppCard
    {
        [Key]
        [Column("id")]
        public int id { get; set; }

        [Required]
        [StringLength(20)]
        [Column("national_id")]
        public string national_id { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        [Column("name")]
        public string name { get; set; } = string.Empty;

        [Required]
        [StringLength(15)]
        [Column("phone")]
        public string phone { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        [Column("status")]
        public string status { get; set; } = "PENDING";

        [Column("status_timestamp")]
        public DateTime status_timestamp { get; set; } = DateTime.UtcNow;
    }

    public class LeadAppLoan
    {
        [Key]
        public int id { get; set; }

        [Required]
        [StringLength(20)]
        [Column("national_id")]
        public string national_id { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        [Column("name")]
        public string name { get; set; } = string.Empty;

        [Required]
        [StringLength(15)]
        [Column("phone")]
        public string phone { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        [Column("status")]
        public string status { get; set; } = "PENDING";

        [Column("status_timestamp")]
        public DateTime status_timestamp { get; set; } = DateTime.UtcNow;
    }

    public class LeadApplicationRequest
    {
        [Required]
        [StringLength(20)]
        public string NationalId { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [StringLength(15)]
        public string Phone { get; set; } = string.Empty;
    }
} 