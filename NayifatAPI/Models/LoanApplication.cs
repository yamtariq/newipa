using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("loan_applications")]
    public class LoanApplication
    {
        [Key]
        [Column("loan_id")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
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

        [Column("loan_amount", TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        [Column("loan_purpose")]
        [StringLength(100)]
        public string? Purpose { get; set; }

        [Column("loan_tenure")]
        public int? Tenure { get; set; }

        [Column("interest_rate", TypeName = "decimal(18,2)")]
        public decimal? InterestRate { get; set; }

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

        [Column("loan_emi", TypeName = "decimal(18,2)")]
        public decimal? LoanEmi { get; set; }

        [ForeignKey(nameof(NationalId))]
        public virtual Customer Customer { get; set; } = null!;
    }
} 