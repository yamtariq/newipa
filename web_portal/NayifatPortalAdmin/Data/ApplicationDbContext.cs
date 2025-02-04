using Microsoft.EntityFrameworkCore;
using NayifatPortalAdmin.Models;

namespace NayifatPortalAdmin.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options) { }

    public DbSet<PortalEmployee> Employees { get; set; }
    public DbSet<PortalRole> Roles { get; set; }
    public DbSet<ActivityLog> ActivityLogs { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure PortalEmployee
        modelBuilder.Entity<PortalEmployee>()
            .HasIndex(e => e.Email)
            .IsUnique();

        // Seed default super admin
        var defaultAdmin = new PortalEmployee
        {
            EmployeeId = 1,
            Name = "Super Admin",
            Email = "admin@nayifat.com",
            Password = BCrypt.Net.BCrypt.HashPassword("password"), // We'll implement proper password hashing
            Phone = "0501234567",
            CreatedAt = DateTime.UtcNow,
            Status = EmployeeStatus.Active
        };

        modelBuilder.Entity<PortalEmployee>().HasData(defaultAdmin);

        // Seed default admin role
        modelBuilder.Entity<PortalRole>().HasData(new PortalRole
        {
            RoleId = 1,
            EmployeeId = 1,
            Role = "super_admin",
            AssignedAt = DateTime.UtcNow
        });
    }
}
