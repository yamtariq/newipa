using System.ComponentModel.DataAnnotations;

namespace NayifatAPI.Models;

public class AuditLog
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string ActionDescription { get; set; } = string.Empty;
    public string IpAddress { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public string? Details { get; set; }
}

public class AuditRequest
{
    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "User ID is required and must be greater than 0")]
    public int UserId { get; set; }

    [Required]
    [StringLength(500, ErrorMessage = "Action description cannot exceed 500 characters")]
    public string ActionDescription { get; set; } = string.Empty;

    [StringLength(1000, ErrorMessage = "Details cannot exceed 1000 characters")]
    public string? Details { get; set; }
} 
