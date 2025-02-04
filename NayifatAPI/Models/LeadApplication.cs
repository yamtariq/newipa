using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    public class LeadAppCard
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(20)]
        public string NationalId { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [StringLength(15)]
        public string Phone { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string Status { get; set; } = "PENDING";

        public DateTime StatusTimestamp { get; set; } = DateTime.UtcNow;
    }

    public class LeadAppLoan
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(20)]
        public string NationalId { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [StringLength(15)]
        public string Phone { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string Status { get; set; } = "PENDING";

        public DateTime StatusTimestamp { get; set; } = DateTime.UtcNow;
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