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
        public DbSet<MasterConfig> MasterConfigs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Customer configuration
            modelBuilder.Entity<Customer>(entity =>
            {
                entity.HasKey(e => e.NationalId);
                
                entity.HasMany(e => e.Devices)
                    .WithOne(e => e.Customer)
                    .HasForeignKey(e => e.NationalId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasMany(e => e.Notifications)
                    .WithOne()
                    .HasForeignKey(e => e.NationalId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasMany(e => e.OtpCodes)
                    .WithOne()
                    .HasForeignKey(e => e.NationalId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasMany(e => e.AuthLogs)
                    .WithOne()
                    .HasForeignKey(e => e.NationalId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Configure decimal precision
                entity.Property(e => e.SalaryCustomer)
                    .HasColumnType("decimal(18,2)");
                
                entity.Property(e => e.SalaryDakhli)
                    .HasColumnType("decimal(18,2)");
            });

            // CustomerDevice configuration
            modelBuilder.Entity<CustomerDevice>(entity =>
            {
                entity.HasIndex(e => e.DeviceId);
                entity.HasIndex(e => new { e.NationalId, e.DeviceId }).IsUnique();
            });

            // UserNotification configuration
            modelBuilder.Entity<UserNotification>(entity =>
            {
                entity.HasIndex(e => e.NotificationId);
                entity.HasIndex(e => new { e.NationalId, e.IsRead });
            });

            // AuthLog configuration
            modelBuilder.Entity<AuthLog>(entity =>
            {
                entity.HasIndex(e => e.CreatedAt);
                entity.HasIndex(e => new { e.NationalId, e.CreatedAt });
            });

            // OtpCode configuration
            modelBuilder.Entity<OtpCode>(entity =>
            {
                entity.HasIndex(e => new { e.NationalId, e.Type, e.IsUsed });
                entity.HasIndex(e => e.ExpiresAt);
            });

            // MasterConfig configuration
            modelBuilder.Entity<MasterConfig>(entity =>
            {
                entity.HasIndex(e => e.Page);
                entity.HasIndex(e => new { e.Page, e.KeyName }).IsUnique();
            });
        }
    }
} 