using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("card_application_details")]
    public class CardApplication
    {
        [Key]
        [Column("card_id")]
        public int Id { get; set; }

        [Required]
        [Column("application_no")]
        public int ApplicationNo { get; set; }

        [Required]
        [Column("national_id")]
        public required string NationalId { get; set; }

        [Required]
        [Column("card_type")]
        [StringLength(50)]
        public required string CardType { get; set; }

        [Column("card_limit", TypeName = "decimal(18,2)")]
        public decimal CardLimit { get; set; }

        [Required]
        [Column("status")]
        [StringLength(50)]
        public string Status { get; set; } = "pending";

        [Required]
        [Column("status_date")]
        public DateTime StatusDate { get; set; } = DateTime.UtcNow;

        [Column("remarks")]
        public string? Remarks { get; set; }

        [Required]
        [Column("noteUser")]
        public string NoteUser { get; set; } = "CUSTOMER";

        [Required]
        [Column("note")]
        public string Note { get; set; } = string.Empty;

        [ForeignKey(nameof(NationalId))]
        public virtual Customer Customer { get; set; } = null!;
    }
} 