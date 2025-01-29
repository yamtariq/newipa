using Microsoft.EntityFrameworkCore;
using NayifatAPI.Models;

namespace NayifatAPI.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<Customer> Customers { get; set; }
        public DbSet<CustomerDevice> CustomerDevices { get; set; }
        public DbSet<UserNotification> UserNotifications { get; set; }
        public DbSet<AuthLog> AuthLogs { get; set; }
        public DbSet<OtpCode> OtpCodes { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Customer
            modelBuilder.Entity<Customer>()
                .HasKey(c => c.NationalId);

            // Configure CustomerDevice
            modelBuilder.Entity<CustomerDevice>()
                .HasIndex(d => d.DeviceId);

            // Configure UserNotification
            modelBuilder.Entity<UserNotification>()
                .HasIndex(n => n.NotificationId);
        }
    }
} 