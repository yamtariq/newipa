using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("card_applications")]
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
        [Column("customerDecision")]
        [StringLength(50)]
        public string CustomerDecision { get; set; } = "PENDING";

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
        [StringLength(255)]
        public string? Remarks { get; set; }

        [Required]
        [Column("noteUser")]
        [StringLength(50)]
        public string NoteUser { get; set; } = "CUSTOMER";

        [Required]
        [Column("note")]
        [StringLength(255)]
        public string Note { get; set; } = string.Empty;

        [Required]
        [Column("NameOnCard")]
        [StringLength(100)]
        public string NameOnCard { get; set; } = string.Empty;

        [Column("consent_status")]
        [StringLength(50)]
        public string? ConsentStatus { get; set; }

        [Column("consent_status_date")]
        public DateTime? ConsentStatusDate { get; set; }

        [Column("nafath_status")]
        [StringLength(50)]
        public string? NafathStatus { get; set; }

        [Column("nafath_status_date")]
        public DateTime? NafathStatusDate { get; set; }

        [ForeignKey(nameof(NationalId))]
        public virtual Customer Customer { get; set; } = null!;
    }
} 