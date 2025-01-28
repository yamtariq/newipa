using System.Text.Json.Serialization;

namespace NayifatAPI.Models
{
    public class DeviceInfo
    {
        [JsonPropertyName("deviceId")]
        public string DeviceId { get; set; }

        [JsonPropertyName("platform")]
        public string Platform { get; set; }

        [JsonPropertyName("model")]
        public string Model { get; set; }

        [JsonPropertyName("manufacturer")]
        public string Manufacturer { get; set; }
    }

    public class UserRegistrationRequest
    {
        [JsonPropertyName("national_id")]
        public string NationalId { get; set; }

        [JsonPropertyName("first_name_en")]
        public string? FirstNameEn { get; set; }

        [JsonPropertyName("second_name_en")]
        public string? SecondNameEn { get; set; }

        [JsonPropertyName("third_name_en")]
        public string? ThirdNameEn { get; set; }

        [JsonPropertyName("family_name_en")]
        public string? FamilyNameEn { get; set; }

        [JsonPropertyName("first_name_ar")]
        public string? FirstNameAr { get; set; }

        [JsonPropertyName("second_name_ar")]
        public string? SecondNameAr { get; set; }

        [JsonPropertyName("third_name_ar")]
        public string? ThirdNameAr { get; set; }

        [JsonPropertyName("family_name_ar")]
        public string? FamilyNameAr { get; set; }

        [JsonPropertyName("email")]
        public string? Email { get; set; }

        [JsonPropertyName("password")]
        public string? Password { get; set; }

        [JsonPropertyName("phone")]
        public string? Phone { get; set; }

        [JsonPropertyName("date_of_birth")]
        public string? DateOfBirth { get; set; }

        [JsonPropertyName("id_expiry_date")]
        public string? IdExpiryDate { get; set; }

        [JsonPropertyName("building_no")]
        public string? BuildingNo { get; set; }

        [JsonPropertyName("street")]
        public string? Street { get; set; }

        [JsonPropertyName("district")]
        public string? District { get; set; }

        [JsonPropertyName("city")]
        public string? City { get; set; }

        [JsonPropertyName("zipcode")]
        public string? Zipcode { get; set; }

        [JsonPropertyName("add_no")]
        public string? AddNo { get; set; }

        [JsonPropertyName("iban")]
        public string? Iban { get; set; }

        [JsonPropertyName("dependents")]
        public int? Dependents { get; set; }

        [JsonPropertyName("salary_dakhli")]
        public decimal? SalaryDakhli { get; set; }

        [JsonPropertyName("salary_customer")]
        public decimal? SalaryCustomer { get; set; }

        [JsonPropertyName("los")]
        public string? Los { get; set; }

        [JsonPropertyName("sector")]
        public string? Sector { get; set; }

        [JsonPropertyName("employer")]
        public string? Employer { get; set; }

        [JsonPropertyName("consent")]
        public bool Consent { get; set; }

        [JsonPropertyName("consent_date")]
        public string? ConsentDate { get; set; }

        [JsonPropertyName("nafath_status")]
        public string? NafathStatus { get; set; }

        [JsonPropertyName("nafath_timestamp")]
        public string? NafathTimestamp { get; set; }

        [JsonPropertyName("device_info")]
        public DeviceInfo? DeviceInfo { get; set; }

        [JsonPropertyName("check_only")]
        public bool? CheckOnly { get; set; }
    }

    public class UserRegistrationResponse
    {
        [JsonPropertyName("status")]
        public string Status { get; set; }

        [JsonPropertyName("message")]
        public string Message { get; set; }

        [JsonPropertyName("gov_data")]
        public GovData? GovData { get; set; }
    }

    public class GovData
    {
        [JsonPropertyName("national_id")]
        public string NationalId { get; set; }

        [JsonPropertyName("first_name_en")]
        public string? FirstNameEn { get; set; }

        [JsonPropertyName("family_name_en")]
        public string? FamilyNameEn { get; set; }

        [JsonPropertyName("first_name_ar")]
        public string? FirstNameAr { get; set; }

        [JsonPropertyName("family_name_ar")]
        public string? FamilyNameAr { get; set; }

        [JsonPropertyName("date_of_birth")]
        public string? DateOfBirth { get; set; }
    }
} 