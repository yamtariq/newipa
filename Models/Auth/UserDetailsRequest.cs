using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models.Auth
{
    public class UserDetailsRequest
    {
        [Required]
        public string NationalId { get; set; }

        [Required]
        public string FirstNameEn { get; set; }

        [Required]
        public string SecondNameEn { get; set; }

        [Required]
        public string ThirdNameEn { get; set; }

        [Required]
        public string FamilyNameEn { get; set; }

        [Required]
        public string FirstNameAr { get; set; }

        [Required]
        public string SecondNameAr { get; set; }

        [Required]
        public string ThirdNameAr { get; set; }

        [Required]
        public string FamilyNameAr { get; set; }

        [Required]
        [DataType(DataType.Date)]
        public DateTime DateOfBirth { get; set; }

        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        [Phone]
        public string Phone { get; set; }
    }
} 