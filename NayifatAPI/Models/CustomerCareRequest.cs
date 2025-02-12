namespace NayifatAPI.Models
{
    public class CustomerCareRequest
    {
        public required string NationalId { get; set; }
        public required string Phone { get; set; }
        public required string CustomerName { get; set; }
        public required string Subject { get; set; }
        public required string SubSubject { get; set; }
        public required string Complaint { get; set; }
    }
} 