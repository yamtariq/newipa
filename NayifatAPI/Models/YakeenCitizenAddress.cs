using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatAPI.Models
{
    [Table("YakeenCitizenAddress")]
    public class YakeenCitizenAddress
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
        [MaxLength(2)]
        public string AddressLanguage { get; set; } = string.Empty;

        public int LogId { get; set; }

        public virtual ICollection<CitizenAddressListItem> CitizenAddressLists { get; set; } = new List<CitizenAddressListItem>();
    }

    [Table("CitizenAddressListItem")]
    public class CitizenAddressListItem
    {
        [Key]
        public int Id { get; set; }

        public int AdditionalNumber { get; set; }
        
        public int BuildingNumber { get; set; }
        
        [MaxLength(100)]
        public string City { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string District { get; set; } = string.Empty;
        
        public bool IsPrimaryAddress { get; set; }
        
        [MaxLength(100)]
        public string LocationCoordinates { get; set; } = string.Empty;
        
        public int PostCode { get; set; }
        
        [MaxLength(100)]
        public string StreetName { get; set; } = string.Empty;
        
        public int UnitNumber { get; set; }

        public int YakeenCitizenAddressId { get; set; }
        
        [ForeignKey("YakeenCitizenAddressId")]
        public virtual YakeenCitizenAddress? YakeenCitizenAddress { get; set; }
    }
} 