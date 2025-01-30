using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("YakeenCitizenInfo")]
    public class YakeenCitizenInfo
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string IqamaNumber { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(20)]
        public string DateOfBirthHijri { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(20)]
        public string IdExpiryDate { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string DateOfBirth { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string EnglishFirstName { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string EnglishLastName { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string EnglishSecondName { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string EnglishThirdName { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string FamilyName { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string FatherName { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;
        
        public int Gender { get; set; }
        
        public bool GenderFieldSpecified { get; set; }
        
        [MaxLength(100)]
        public string GrandFatherName { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string HifizaIssuePlace { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string HifizaNumber { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string IdIssueDate { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string IdIssuePlace { get; set; } = string.Empty;
        
        public int IdVersionNumber { get; set; }
        
        public int LogIdField { get; set; }
        
        public int NumberOfVehiclesReg { get; set; }
        
        [MaxLength(10)]
        public string OccupationCode { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string SocialStatusDetailedDesc { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string SubtribeName { get; set; } = string.Empty;
        
        public int TotalNumberOfCurrentDependents { get; set; }
    }
} 