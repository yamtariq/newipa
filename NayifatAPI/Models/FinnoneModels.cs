using System;

namespace NayifatAPI.Models;

public class FinnoneCustomerRequest
{
    public string ApplicationNo { get; set; }
    public string NationalId { get; set; }
    public string FullNameEn { get; set; }
    public string FullNameAr { get; set; }
    public DateTime DateOfBirth { get; set; }
    public string Email { get; set; }
    public string Phone { get; set; }
    public decimal Salary { get; set; }
    public string ApplicationType { get; set; }  // LOAN or CARD
    public decimal RequestedAmount { get; set; }
    public int? Tenure { get; set; }            // For loans
    public string CardType { get; set; }        // For cards
}

public class FinnoneCustomerResponse
{
    public bool Success { get; set; }
    public string Message { get; set; }
    public string FinnoneReference { get; set; }
    public string Status { get; set; }
    public DateTime ProcessedAt { get; set; }
    public Dictionary<string, string> AdditionalData { get; set; }
}

public class FinnoneStatusResponse
{
    public string ApplicationNo { get; set; }
    public string FinnoneReference { get; set; }
    public string Status { get; set; }
    public string StatusDescription { get; set; }
    public DateTime LastUpdated { get; set; }
    public Dictionary<string, string> StatusDetails { get; set; }
}

// Common interface for both loan and card applications
public interface IApplication
{
    string ApplicationNo { get; set; }
    string NationalId { get; set; }
    string Type { get; }  // "LOAN" or "CARD"
    string Status { get; set; }
} 