using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("customer_documents")]
    public class CustomerDocument
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("national_id")]
        [StringLength(10)]
        public required string NationalId { get; set; }

        [Required]
        [Column("document_type")]
        [StringLength(50)]
        public required string DocumentType { get; set; }

        [Required]
        [Column("file_name")]
        [StringLength(255)]
        public required string FileName { get; set; }

        [Required]
        [Column("file_path")]
        [StringLength(1000)]
        public required string FilePath { get; set; }

        [Required]
        [Column("upload_date")]
        public DateTime UploadDate { get; set; }

        [Required]
        [Column("status")]
        [StringLength(20)]
        public required string Status { get; set; }

        [Required]
        [Column("file_size")]
        public long FileSize { get; set; }

        [Required]
        [Column("file_type")]
        [StringLength(10)]
        public required string FileType { get; set; }

        [Column("verification_date")]
        public DateTime? VerificationDate { get; set; }

        [Column("verified_by")]
        [StringLength(50)]
        public string? VerifiedBy { get; set; }

        [Column("verification_remarks")]
        [StringLength(500)]
        public string? VerificationRemarks { get; set; }
    }
} 