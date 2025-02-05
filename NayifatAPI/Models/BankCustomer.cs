using System;

namespace NayifatAPI.Models
{
    public class BankCustomer
    {
        public int Id { get; set; }
        public string RequestId { get; set; }
        public string NationalId { get; set; }
        public string ApplicationFlag { get; set; }
        public string ApplicationId { get; set; }
        public string ApplicationStatus { get; set; }
        public string CustomerId { get; set; }
        public string EligibleStatus { get; set; }
        public decimal EligibleAmount { get; set; }
        public decimal EligibleEmi { get; set; }
        public string ProductType { get; set; }
        public string SuccessMsg { get; set; }
        public int ErrCode { get; set; }
        public string ErrMsg { get; set; }
        public string Type { get; set; }
        public DateTime CreatedAt { get; set; }
    }
} 