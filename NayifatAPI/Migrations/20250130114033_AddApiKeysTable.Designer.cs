﻿// <auto-generated />
using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using NayifatAPI.Data;

#nullable disable

namespace NayifatAPI.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20250130114033_AddApiKeysTable")]
    partial class AddApiKeysTable
    {
        /// <inheritdoc />
        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "8.0.1")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("NayifatAPI.Controllers.ApiKey", b =>
                {
                    b.Property<string>("Key")
                        .HasMaxLength(255)
                        .HasColumnType("nvarchar(255)");

                    b.Property<DateTime>("CreatedAt")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("datetime2")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<string>("Description")
                        .HasMaxLength(500)
                        .HasColumnType("nvarchar(500)");

                    b.Property<DateTime?>("ExpiresAt")
                        .HasColumnType("datetime2");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(true);

                    b.Property<DateTime?>("LastUsedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Key");

                    b.ToTable("ApiKeys");
                });

            modelBuilder.Entity("NayifatAPI.Models.AuthLog", b =>
                {
                    b.Property<long>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bigint");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<long>("Id"));

                    b.Property<string>("AuthType")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("DeviceId")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("FailureReason")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("IpAddress")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("NationalId")
                        .IsRequired()
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Status")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("UserAgent")
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("Id");

                    b.HasIndex("CreatedAt");

                    b.HasIndex("NationalId", "CreatedAt");

                    b.ToTable("AuthLogs");
                });

            modelBuilder.Entity("NayifatAPI.Models.Customer", b =>
                {
                    b.Property<string>("NationalId")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("AddNo")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("BuildingNo")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("City")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("Consent")
                        .HasColumnType("bit");

                    b.Property<DateTime?>("ConsentDate")
                        .HasColumnType("datetime2");

                    b.Property<DateTime?>("DateOfBirth")
                        .HasColumnType("datetime2");

                    b.Property<int?>("Dependents")
                        .HasColumnType("int");

                    b.Property<string>("District")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Email")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Employer")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("FamilyNameAr")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("FamilyNameEn")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("FirstNameAr")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("FirstNameEn")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Iban")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("IdExpiryDate")
                        .HasColumnType("datetime2");

                    b.Property<int?>("Los")
                        .HasColumnType("int");

                    b.Property<string>("Mpin")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("MpinEnabled")
                        .HasColumnType("bit");

                    b.Property<string>("NafathStatus")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("NafathTimestamp")
                        .HasColumnType("datetime2");

                    b.Property<string>("Password")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Phone")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("RegistrationDate")
                        .HasColumnType("datetime2");

                    b.Property<decimal?>("SalaryCustomer")
                        .HasColumnType("decimal(18,2)");

                    b.Property<decimal?>("SalaryDakhli")
                        .HasColumnType("decimal(18,2)");

                    b.Property<string>("SecondNameAr")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("SecondNameEn")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Sector")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Street")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ThirdNameAr")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ThirdNameEn")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Zipcode")
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("NationalId");

                    b.ToTable("Customers");
                });

            modelBuilder.Entity("NayifatAPI.Models.CustomerDevice", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<bool>("BiometricEnabled")
                        .HasColumnType("bit");

                    b.Property<string>("BiometricToken")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("DeviceId")
                        .IsRequired()
                        .HasColumnType("nvarchar(450)");

                    b.Property<DateTime?>("LastUsedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Manufacturer")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Model")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("NationalId")
                        .IsRequired()
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("OsVersion")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Platform")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Status")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("Id");

                    b.HasIndex("DeviceId");

                    b.HasIndex("NationalId", "DeviceId")
                        .IsUnique();

                    b.ToTable("Customer_Devices");
                });

            modelBuilder.Entity("NayifatAPI.Models.MasterConfig", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<bool>("IsActive")
                        .HasColumnType("bit");

                    b.Property<string>("KeyName")
                        .IsRequired()
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Page")
                        .IsRequired()
                        .HasColumnType("nvarchar(450)");

                    b.Property<DateTime?>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Value")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("Id");

                    b.HasIndex("Page");

                    b.HasIndex("Page", "KeyName")
                        .IsUnique();

                    b.ToTable("master_config");
                });

            modelBuilder.Entity("NayifatAPI.Models.OtpCode", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int")
                        .HasColumnName("id");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("Code")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)")
                        .HasColumnName("otp_code");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2")
                        .HasColumnName("created_at");

                    b.Property<DateTime>("ExpiresAt")
                        .HasColumnType("datetime2")
                        .HasColumnName("expires_at");

                    b.Property<bool>("IsUsed")
                        .HasColumnType("bit")
                        .HasColumnName("is_used");

                    b.Property<string>("NationalId")
                        .IsRequired()
                        .HasColumnType("nvarchar(450)")
                        .HasColumnName("national_id");

                    b.Property<string>("Type")
                        .IsRequired()
                        .HasColumnType("nvarchar(450)")
                        .HasColumnName("type");

                    b.Property<DateTime?>("UsedAt")
                        .HasColumnType("datetime2")
                        .HasColumnName("used_at");

                    b.HasKey("Id");

                    b.HasIndex("ExpiresAt");

                    b.HasIndex("NationalId", "Type", "IsUsed");

                    b.ToTable("OTP_Codes");
                });

            modelBuilder.Entity("NayifatAPI.Models.UserNotification", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Data")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("IsRead")
                        .HasColumnType("bit");

                    b.Property<DateTime>("LastUpdated")
                        .HasColumnType("datetime2");

                    b.Property<string>("Message")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("NationalId")
                        .IsRequired()
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("NotificationId")
                        .IsRequired()
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("NotificationType")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("ReadAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Title")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("Id");

                    b.HasIndex("NotificationId");

                    b.HasIndex("NationalId", "IsRead");

                    b.ToTable("User_Notifications");
                });

            modelBuilder.Entity("NayifatAPI.Models.AuthLog", b =>
                {
                    b.HasOne("NayifatAPI.Models.Customer", null)
                        .WithMany("AuthLogs")
                        .HasForeignKey("NationalId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("NayifatAPI.Models.CustomerDevice", b =>
                {
                    b.HasOne("NayifatAPI.Models.Customer", "Customer")
                        .WithMany("Devices")
                        .HasForeignKey("NationalId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Customer");
                });

            modelBuilder.Entity("NayifatAPI.Models.OtpCode", b =>
                {
                    b.HasOne("NayifatAPI.Models.Customer", null)
                        .WithMany("OtpCodes")
                        .HasForeignKey("NationalId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("NayifatAPI.Models.UserNotification", b =>
                {
                    b.HasOne("NayifatAPI.Models.Customer", null)
                        .WithMany("Notifications")
                        .HasForeignKey("NationalId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("NayifatAPI.Models.Customer", b =>
                {
                    b.Navigation("AuthLogs");

                    b.Navigation("Devices");

                    b.Navigation("Notifications");

                    b.Navigation("OtpCodes");
                });
#pragma warning restore 612, 618
        }
    }
}
