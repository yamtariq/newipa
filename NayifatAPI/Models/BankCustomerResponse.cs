using System;

namespace NayifatAPI.Models
{
    public class BankCustomerResponse
    {
        public bool Success { get; set; }
        public string[] Errors { get; set; } = Array.Empty<string>();
        public required BankCustomerResult Result { get; set; }
        public required string Type { get; set; }
    }

    public class BankCustomerResult
    {
        public required string RequestId { get; set; }
        public required string NationalId { get; set; }
        public required string ApplicationFlag { get; set; }
        public required string ApplicationId { get; set; }
        public required string ApplicationStatus { get; set; }
        public required string CustomerId { get; set; }
        public required string EligibleStatus { get; set; }
        public decimal EligibleAmount { get; set; }
        public decimal EligibleEmi { get; set; }
        public required string ProductType { get; set; }
        public required string SuccessMsg { get; set; }
        public int ErrCode { get; set; }
        public required string ErrMsg { get; set; }
        public required string Type { get; set; }
    }
} 