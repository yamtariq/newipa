using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("Customers")]
    public class Customer
    {
        [Key]
        public required string NationalId { get; set; }

        [Required]
        public required string FirstNameEn { get; set; }
        [Required]
        public required string SecondNameEn { get; set; }
        [Required]
        public required string ThirdNameEn { get; set; }
        [Required]
        public required string FamilyNameEn { get; set; }

        [Required]
        public required string FirstNameAr { get; set; }
        [Required]
        public required string SecondNameAr { get; set; }
        [Required]
        public required string ThirdNameAr { get; set; }
        [Required]
        public required string FamilyNameAr { get; set; }

        public DateTime? DateOfBirth { get; set; }
        public DateTime? IdExpiryDate { get; set; }

        [Required]
        [EmailAddress]
        public required string Email { get; set; }

        [Required]
        [Phone]
        public required string Phone { get; set; }

        // Address Information
        public string? BuildingNo { get; set; }
        public string? Street { get; set; }
        public string? District { get; set; }
        public string? City { get; set; }
        public string? Zipcode { get; set; }
        public string? AddNo { get; set; }

        // Financial Information
        public string? Iban { get; set; }
        public int? Dependents { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal? SalaryDakhli { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal? SalaryCustomer { get; set; }
        
        public int? Los { get; set; }

        // Employment Information
        public string? Sector { get; set; }
        public string? Employer { get; set; }

        // Security
        [Required]
        public required string Password { get; set; }
        
        public string? Mpin { get; set; }
        
        public bool MpinEnabled { get; set; }
        
        // Timestamps and Status
        [Required]
        public DateTime RegistrationDate { get; set; } = DateTime.UtcNow;
        
        [Required]
        public bool Consent { get; set; }
        
        public DateTime? ConsentDate { get; set; }
        
        public string? NafathStatus { get; set; }
        
        public DateTime? NafathTimestamp { get; set; }

        // Navigation Properties
        public virtual ICollection<CustomerDevice> Devices { get; set; } = new List<CustomerDevice>();
        public virtual ICollection<UserNotification> Notifications { get; set; } = new List<UserNotification>();
        public virtual ICollection<OtpCode> OtpCodes { get; set; } = new List<OtpCode>();
        public virtual ICollection<AuthLog> AuthLogs { get; set; } = new List<AuthLog>();

        // Computed Properties
        [NotMapped]
        public string FullNameEn => $"{FirstNameEn} {SecondNameEn} {ThirdNameEn} {FamilyNameEn}".Trim();
        
        [NotMapped]
        public string FullNameAr => $"{FirstNameAr} {SecondNameAr} {ThirdNameAr} {FamilyNameAr}".Trim();
        
        [NotMapped]
        public bool HasBiometricDevice => Devices.Any(d => d.BiometricEnabled && d.IsActive);
    }
} 