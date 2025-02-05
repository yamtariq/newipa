using System;

namespace NayifatAPI.Models
{
    public class BankCustomerRequest
    {
        public string NationalId { get; set; }
        public string Dob { get; set; }  // date in hijri format yyyy/mm/dd
        public string Doe { get; set; }  // date in hijri format yyyy/mm/dd
        public string FinPurpose { get; set; }
        public int Language { get; set; }  // 0-English, 1-Arabic
        public int ProductType { get; set; }  // 0-Loan, 1-Card
        public string MobileNo { get; set; }
        public string EmailId { get; set; }
        public string IbanNo { get; set; }
        public int FinAmount { get; set; }
        public int Tenure { get; set; }
        public string PropertyStatus { get; set; }
        public decimal EffRate { get; set; }
        public string Param1 { get; set; }
        public string Param2 { get; set; }
        public string Param3 { get; set; }
        public string Param4 { get; set; }
        public string Param5 { get; set; }
        public string Param6 { get; set; }
        public decimal? Param7 { get; set; }
        public decimal? Param8 { get; set; }
        public DateTime? Param9 { get; set; }
        public DateTime? Param10 { get; set; }
        public int? Param11 { get; set; }
        public int? Param12 { get; set; }
        public bool? Param13 { get; set; }
        public bool? Param14 { get; set; }
    }
} 