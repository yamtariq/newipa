using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("Constants")]
    public class Constant
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [Column("ConstantName")]
        [StringLength(255)]
        public string ConstantName { get; set; } = string.Empty;

        [Required]
        [Column("ConstantValue")]
        [StringLength(255)]
        public string ConstantValue { get; set; } = string.Empty;

        [Required]
        [Column("ConstantValue_ar")]
        [StringLength(255)]
        public string ConstantValueAr { get; set; } = string.Empty;

        [Column("Description")]
        [StringLength(255)]
        public string? Description { get; set; }

        [Column("LastUpdated")]
        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
    }

    public class GetConstantsResponse
    {
        public required string Name { get; set; }
        public required string Value { get; set; }
        public required string ValueAr { get; set; }
        public string? Description { get; set; }
        public DateTime LastUpdated { get; set; }
    }

    public class CreateConstantRequest
    {
        [Required]
        [StringLength(255)]
        public required string Name { get; set; }

        [Required]
        [StringLength(255)]
        public required string Value { get; set; }

        [Required]
        [StringLength(255)]
        public required string ValueAr { get; set; }

        [StringLength(255)]
        public string? Description { get; set; }
    }

    public class UpdateConstantRequest
    {
        [Required]
        [StringLength(255)]
        public required string Value { get; set; }

        [Required]
        [StringLength(255)]
        public required string ValueAr { get; set; }

        [StringLength(255)]
        public string? Description { get; set; }
    }
} 