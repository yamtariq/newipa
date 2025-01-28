using System;

namespace NayifatAPI.Models
{
    public class GovServiceRequest
    {
        public string NationalId { get; set; }
    }

    public class GovServiceResponse
    {
        public string Status { get; set; }
        public GovServiceData Data { get; set; }
        public string Message { get; set; }
        public string NationalId { get; set; }
    }

    public class GovServiceData
    {
        public string NationalId { get; set; }
        public string FullName { get; set; }
        public string ArabicName { get; set; }
        public DateTime? Dob { get; set; }
        public decimal? Salary { get; set; }
        public string EmploymentStatus { get; set; }
        public string EmployerName { get; set; }
        public DateTime? EmploymentDate { get; set; }
        public string NationalAddress { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
} 