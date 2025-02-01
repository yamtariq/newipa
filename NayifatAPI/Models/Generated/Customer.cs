using System;
using System.Collections.Generic;

namespace NayifatAPI.Models.Generated;

public partial class Customer
{
    public string NationalId { get; set; } = null!;

    public string FirstNameEn { get; set; } = null!;

    public string SecondNameEn { get; set; } = null!;

    public string ThirdNameEn { get; set; } = null!;

    public string FamilyNameEn { get; set; } = null!;

    public string? FirstNameAr { get; set; }

    public string? SecondNameAr { get; set; }

    public string? ThirdNameAr { get; set; }

    public string? FamilyNameAr { get; set; }

    public DateTime? DateOfBirth { get; set; }

    public DateTime? IdExpiryDate { get; set; }

    public string Email { get; set; } = null!;

    public string Phone { get; set; } = null!;

    public string? BuildingNo { get; set; }

    public string? Street { get; set; }

    public string? District { get; set; }

    public string? City { get; set; }

    public string? Zipcode { get; set; }

    public string? AddNo { get; set; }

    public string? Iban { get; set; }

    public int? Dependents { get; set; }

    public decimal? SalaryDakhli { get; set; }

    public decimal? SalaryCustomer { get; set; }

    public int? Los { get; set; }

    public string? Sector { get; set; }

    public string? Employer { get; set; }

    public string Password { get; set; } = null!;

    public DateTime RegistrationDate { get; set; }

    public bool Consent { get; set; }

    public DateTime? ConsentDate { get; set; }

    public string? NafathStatus { get; set; }

    public DateTime? NafathTimestamp { get; set; }

    public string? Mpin { get; set; }

    public bool MpinEnabled { get; set; }
}
