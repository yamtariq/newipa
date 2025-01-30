using Microsoft.EntityFrameworkCore;
using NayifatAPI.Models;
using NayifatAPI.Controllers;

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
        public DbSet<ApiKey> ApiKeys { get; set; }
        public DbSet<YakeenCitizenInfo> YakeenCitizenInfos { get; set; }
        public DbSet<YakeenCitizenAddress> YakeenCitizenAddresses { get; set; }
        public DbSet<CitizenAddressListItem> CitizenAddressListItems { get; set; }

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

            // ApiKey configuration
            modelBuilder.Entity<ApiKey>(entity =>
            {
                entity.HasKey(e => e.Key);
                entity.Property(e => e.Key)
                    .HasMaxLength(255);
                entity.Property(e => e.Description)
                    .HasMaxLength(500);
                entity.Property(e => e.IsActive)
                    .HasDefaultValue(true);
                entity.Property(e => e.CreatedAt)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");
            });

            // YakeenCitizenInfo configuration
            modelBuilder.Entity<YakeenCitizenInfo>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.IqamaNumber);
                
                entity.Property(e => e.IqamaNumber)
                    .HasMaxLength(50);
                entity.Property(e => e.DateOfBirthHijri)
                    .HasMaxLength(20);
                entity.Property(e => e.IdExpiryDate)
                    .HasMaxLength(20);
            });

            // YakeenCitizenAddress configuration
            modelBuilder.Entity<YakeenCitizenAddress>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.IqamaNumber);
                
                entity.HasMany(e => e.CitizenAddressLists)
                    .WithOne(e => e.YakeenCitizenAddress)
                    .HasForeignKey(e => e.YakeenCitizenAddressId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // CitizenAddressListItem configuration
            modelBuilder.Entity<CitizenAddressListItem>(entity =>
            {
                entity.HasKey(e => e.Id);
            });
        }
    }
} 