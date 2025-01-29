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
                .HasOne<Customer>()
                .WithMany()
                .HasForeignKey(n => n.NationalId);

            // Configure CustomerDevices
            modelBuilder.Entity<CustomerDevice>()
                .HasOne<Customer>()
                .WithMany()
                .HasForeignKey(d => d.NationalId);

            // Configure OtpCodes
            modelBuilder.Entity<OtpCode>()
                .HasOne<Customer>()
                .WithMany()
                .HasForeignKey(o => o.NationalId);

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