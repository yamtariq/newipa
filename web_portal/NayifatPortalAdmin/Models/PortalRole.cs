using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NayifatPortalAdmin.Models;

public class PortalRole
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int RoleId { get; set; }

    [Required]
    public int EmployeeId { get; set; }

    [Required]
    [MaxLength(50)]
    public string Role { get; set; } = string.Empty;

    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;

    // Navigation property
    [ForeignKey(nameof(EmployeeId))]
    public virtual PortalEmployee Employee { get; set; } = null!;
}
