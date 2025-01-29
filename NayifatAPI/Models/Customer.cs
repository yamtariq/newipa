using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("Customers")]
    public class Customer
    {
        [Required]
        public required string NationalId { get; set; }
        public required string FirstNameEn { get; set; }
        public required string SecondNameEn { get; set; }
        public required string ThirdNameEn { get; set; }
        public required string FamilyNameEn { get; set; }
        public required string FirstNameAr { get; set; }
        public required string SecondNameAr { get; set; }
        public required string ThirdNameAr { get; set; }
        public required string FamilyNameAr { get; set; }
        public DateTime DateOfBirth { get; set; }
        public DateTime IdExpiryDate { get; set; }
        [Required]
        [EmailAddress]
        public required string Email { get; set; }
        [Required]
        [Phone]
        public required string Phone { get; set; }
        public required string BuildingNo { get; set; }
        public required string Street { get; set; }
        public required string District { get; set; }
        public required string City { get; set; }
        public required string Zipcode { get; set; }
        public required string AddNo { get; set; }
        public required string Iban { get; set; }
        public int? Dependents { get; set; }
        public decimal? SalaryDakhli { get; set; }
        public decimal? SalaryCustomer { get; set; }
        public int? Los { get; set; }
        public required string Sector { get; set; }
        public required string Employer { get; set; }
        [Required]
        public required string Password { get; set; }
        public DateTime RegistrationDate { get; set; }
        public bool Consent { get; set; }
        public DateTime? ConsentDate { get; set; }
        [Required]
        public required string NafathStatus { get; set; }
        public DateTime? NafathTimestamp { get; set; }
    }
} 