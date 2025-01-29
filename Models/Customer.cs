using System;
using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models
{
    public class Customer
    {
        [Key]
        public string NationalId { get; set; }
        
        public string FirstNameEn { get; set; }
        public string SecondNameEn { get; set; }
        public string ThirdNameEn { get; set; }
        public string FamilyNameEn { get; set; }
        
        public string FirstNameAr { get; set; }
        public string SecondNameAr { get; set; }
        public string ThirdNameAr { get; set; }
        public string FamilyNameAr { get; set; }
        
        public DateTime? DateOfBirth { get; set; }
        public DateTime? IdExpiryDate { get; set; }
        
        public string Email { get; set; }
        public string Phone { get; set; }
        public string Password { get; set; }
        
        public DateTime RegistrationDate { get; set; } = DateTime.UtcNow;
        public bool Consent { get; set; }
        public DateTime? ConsentDate { get; set; }
        
        public string NafathStatus { get; set; }
        public DateTime? NafathTimestamp { get; set; }
    }
} 