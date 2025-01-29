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
        public DbSet<UserNotification> UserNotifications { get; set; }
        public DbSet<MasterConfig> MasterConfigs { get; set; }
        public DbSet<AuthLog> AuthLogs { get; set; }
        public DbSet<OtpCode> OtpCodes { get; set; }
        public DbSet<CustomerDevice> CustomerDevices { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Customers
            modelBuilder.Entity<Customer>()
                .HasKey(c => c.NationalId);

            modelBuilder.Entity<Customer>()
                .Property(c => c.RegistrationDate)
                .HasDefaultValueSql("CURRENT_TIMESTAMP");

            // Configure UserNotifications
            modelBuilder.Entity<UserNotification>()
                .HasKey(n => n.Id);

            modelBuilder.Entity<UserNotification>()
                .HasOne<Customer>()
                .WithMany()
                .HasForeignKey(n => n.NationalId);

            // Configure CustomerDevices
            modelBuilder.Entity<CustomerDevice>()
                .HasKey(d => d.Id);

            modelBuilder.Entity<CustomerDevice>()
                .HasOne<Customer>()
                .WithMany()
                .HasForeignKey(d => d.NationalId);

            // Configure OtpCodes
            modelBuilder.Entity<OtpCode>()
                .HasKey(o => o.Id);

            modelBuilder.Entity<OtpCode>()
                .HasOne<Customer>()
                .WithMany()
                .HasForeignKey(o => o.NationalId);

            modelBuilder.Entity<OtpCode>()
                .Property(o => o.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP");

            modelBuilder.Entity<OtpCode>()
                .Property(o => o.Type)
                .IsRequired();

            modelBuilder.Entity<OtpCode>()
                .Property(o => o.UsedAt)
                .IsRequired(false);

            // Configure AuthLogs
            modelBuilder.Entity<AuthLog>()
                .HasKey(a => a.Id);

            // Configure MasterConfig
            modelBuilder.Entity<MasterConfig>()
                .HasKey(m => m.Id);

            // Configure default timestamps
            modelBuilder.Entity<CustomerDevice>()
                .Property(d => d.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP");

            modelBuilder.Entity<AuthLog>()
                .Property(a => a.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP");

            modelBuilder.Entity<UserNotification>()
                .Property(n => n.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP");

            // Configure indexes
            modelBuilder.Entity<AuthLog>()
                .HasIndex(a => a.CreatedAt);

            modelBuilder.Entity<CustomerDevice>()
                .HasIndex(d => d.DeviceId);

            modelBuilder.Entity<MasterConfig>()
                .HasIndex(m => m.Page);
        }
    }
} 