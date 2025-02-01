using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("loan_application_details")]
    public class LoanApplication
    {
        [Key]
        [Column("loan_id")]
        public int Id { get; set; }

        [Required]
        [Column("application_no")]
        public int ApplicationNo { get; set; }

        [Required]
        [Column("national_id")]
        public required string NationalId { get; set; }

        [Required]
        [Column("customerDecision")]
        public string CustomerDecision { get; set; } = "pending";

        [Required]
        [Column("loan_amount", TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        [Column("loan_purpose")]
        public string? Purpose { get; set; }

        [Column("loan_tenure")]
        public int? Tenure { get; set; }

        [Column("interest_rate", TypeName = "decimal(5,2)")]
        public decimal? InterestRate { get; set; }

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