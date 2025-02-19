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
        public DbSet<NotificationTemplate> NotificationTemplates { get; set; }
        public DbSet<LoanApplication> LoanApplications { get; set; }
        public DbSet<CardApplication> CardApplications { get; set; }
        public DbSet<LeadAppCard> LeadAppCards { get; set; }
        public DbSet<LeadAppLoan> LeadAppLoans { get; set; }
        public DbSet<BankCustomer> BankCustomers { get; set; }
        public DbSet<CustomerDocument> CustomerDocuments { get; set; }
        public DbSet<Constant> Constants { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // BankCustomer configuration
            modelBuilder.Entity<BankCustomer>(entity =>
            {
                entity.ToTable("bank_customers");
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.RequestId).IsUnique();
                entity.HasIndex(e => e.NationalId);
                entity.HasIndex(e => e.ApplicationId);
                
                entity.Property(e => e.EligibleAmount)
                    .HasColumnType("decimal(18,2)");
                
                entity.Property(e => e.EligibleEmi)
                    .HasColumnType("decimal(18,2)");
                
                entity.Property(e => e.CreatedAt)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");
            });

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

                entity.HasMany(e => e.LoanApplications)
                    .WithOne(la => la.Customer)
                    .HasForeignKey(la => la.NationalId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasMany(e => e.CardApplications)
                    .WithOne(ca => ca.Customer)
                    .HasForeignKey(ca => ca.NationalId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Configure decimal precision
                entity.Property(e => e.SalaryCustomer)
                    .HasColumnType("decimal(18,2)");
                
                entity.Property(e => e.SalaryDakhli)
                    .HasColumnType("decimal(18,2)");
            });

            // Lead Applications configuration
            modelBuilder.Entity<LeadAppCard>(entity =>
            {
                entity.ToTable("lead_apps_cards");
                entity.HasKey(e => e.id);
                entity.HasIndex(e => e.national_id);
                
                entity.Property(e => e.id)
                    .HasColumnName("id");
                
                entity.Property(e => e.national_id)
                    .HasColumnName("national_id")
                    .HasMaxLength(20);
                
                entity.Property(e => e.name)
                    .HasColumnName("name")
                    .HasMaxLength(100);
                
                entity.Property(e => e.phone)
                    .HasColumnName("phone")
                    .HasMaxLength(15);
                
                entity.Property(e => e.status)
                    .HasColumnName("status")
                    .HasMaxLength(50)
                    .HasDefaultValue("PENDING");
                
                entity.Property(e => e.status_timestamp)
                    .HasColumnName("status_timestamp")
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");
            });

            modelBuilder.Entity<LeadAppLoan>(entity =>
            {
                entity.ToTable("lead_apps_loans");
                entity.HasKey(e => e.id);
                entity.HasIndex(e => e.national_id);
                
                entity.Property(e => e.id)
                    .HasColumnName("id");
                
                entity.Property(e => e.national_id)
                    .HasColumnName("national_id")
                    .HasMaxLength(20);
                
                entity.Property(e => e.name)
                    .HasColumnName("name")
                    .HasMaxLength(100);
                
                entity.Property(e => e.phone)
                    .HasColumnName("phone")
                    .HasMaxLength(15);
                
                entity.Property(e => e.status)
                    .HasColumnName("status")
                    .HasMaxLength(50)
                    .HasDefaultValue("PENDING");
                
                entity.Property(e => e.status_timestamp)
                    .HasColumnName("status_timestamp")
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");
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
                entity.HasKey(e => e.NationalId);
                
                entity.Property(e => e.Notifications)
                    .HasColumnType("nvarchar(max)");
                
                entity.Property(e => e.LastUpdated)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");
            });

            // NotificationTemplate configuration
            modelBuilder.Entity<NotificationTemplate>(entity =>
            {
                entity.ToTable("notification_templates");
                
                entity.Property(e => e.Title)
                    .HasMaxLength(255);
                
                entity.Property(e => e.Body)
                    .HasColumnType("text");
                
                entity.Property(e => e.TitleEn)
                    .HasMaxLength(255);
                
                entity.Property(e => e.BodyEn)
                    .HasColumnType("text");
                
                entity.Property(e => e.TitleAr)
                    .HasMaxLength(255);
                
                entity.Property(e => e.BodyAr)
                    .HasColumnType("nvarchar(max)");
                
                entity.Property(e => e.Route)
                    .HasMaxLength(255);
                
                entity.Property(e => e.AdditionalData)
                    .HasColumnType("json");
                
                entity.Property(e => e.TargetCriteria)
                    .HasColumnType("json");
                
                entity.Property(e => e.CreatedAt)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");
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
                entity.ToTable("master_config");
                entity.HasKey(e => e.ConfigId);
                
                entity.Property(e => e.ConfigId)
                    .HasColumnName("config_id");
                
                entity.Property(e => e.Page)
                    .HasColumnName("page");
                
                entity.Property(e => e.KeyName)
                    .HasColumnName("key_name");
                
                entity.Property(e => e.Value)
                    .HasColumnName("value");
                
                entity.Property(e => e.LastUpdated)
                    .HasColumnName("last_updated");

                entity.HasIndex(e => new { e.Page, e.KeyName }).IsUnique();
            });

            // ApiKey configuration
            modelBuilder.Entity<ApiKey>(entity =>
            {
                entity.HasKey(e => e.api_Key);
                entity.Property(e => e.api_Key)
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

            // Constants configuration
            modelBuilder.Entity<Constant>(entity =>
            {
                entity.ToTable("Constants");
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.ConstantName).IsUnique();
                
                entity.Property(e => e.ConstantName)
                    .HasMaxLength(255)
                    .UseCollation("Arabic_CI_AS");
                
                entity.Property(e => e.ConstantValue)
                    .HasMaxLength(255)
                    .UseCollation("Arabic_CI_AS");
                
                entity.Property(e => e.ConstantValueAr)
                    .HasMaxLength(255)
                    .UseCollation("Arabic_CI_AS");
                
                entity.Property(e => e.Description)
                    .HasMaxLength(255)
                    .UseCollation("Arabic_CI_AS");
                
                entity.Property(e => e.LastUpdated)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");
            });
        }
    }
} 