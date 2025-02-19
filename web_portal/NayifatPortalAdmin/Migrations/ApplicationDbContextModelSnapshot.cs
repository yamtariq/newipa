﻿// <auto-generated />
using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using NayifatPortalAdmin.Data;

#nullable disable

namespace NayifatPortalAdmin.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    partial class ApplicationDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "9.0.1")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("NayifatPortalAdmin.Models.ActivityLog", b =>
                {
                    b.Property<int>("LogId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("LogId"));

                    b.Property<string>("Action")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Details")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("EmployeeId")
                        .HasColumnType("int");

                    b.Property<string>("IpAddress")
                        .HasMaxLength(45)
                        .HasColumnType("nvarchar(45)");

                    b.HasKey("LogId");

                    b.HasIndex("EmployeeId");

                    b.ToTable("ActivityLogs");
                });

            modelBuilder.Entity("NayifatPortalAdmin.Models.PortalEmployee", b =>
                {
                    b.Property<int>("EmployeeId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("EmployeeId"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Email")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<DateTime?>("LastLogin")
                        .HasColumnType("datetime2");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<string>("Password")
                        .IsRequired()
                        .HasMaxLength(255)
                        .HasColumnType("nvarchar(255)");

                    b.Property<string>("Phone")
                        .HasMaxLength(15)
                        .HasColumnType("nvarchar(15)");

                    b.Property<int>("Status")
                        .HasColumnType("int");

                    b.HasKey("EmployeeId");

                    b.HasIndex("Email")
                        .IsUnique();

                    b.ToTable("Employees");

                    b.HasData(
                        new
                        {
                            EmployeeId = 1,
                            CreatedAt = new DateTime(2025, 2, 3, 14, 29, 38, 916, DateTimeKind.Utc).AddTicks(5917),
                            Email = "admin@nayifat.com",
                            Name = "Super Admin",
                            Password = "$2a$11$SxwRD/TjRrF/i0/ypq/cHeKJQPQuNMUNAlcbnmkuBZ0E1RuH.AaBi",
                            Phone = "0501234567",
                            Status = 0
                        });
                });

            modelBuilder.Entity("NayifatPortalAdmin.Models.PortalRole", b =>
                {
                    b.Property<int>("RoleId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("RoleId"));

                    b.Property<DateTime>("AssignedAt")
                        .HasColumnType("datetime2");

                    b.Property<int>("EmployeeId")
                        .HasColumnType("int");

                    b.Property<string>("Role")
                        .IsRequired()
                        .HasMaxLength(50)
                        .HasColumnType("nvarchar(50)");

                    b.HasKey("RoleId");

                    b.HasIndex("EmployeeId");

                    b.ToTable("Roles");

                    b.HasData(
                        new
                        {
                            RoleId = 1,
                            AssignedAt = new DateTime(2025, 2, 3, 14, 29, 38, 918, DateTimeKind.Utc).AddTicks(4275),
                            EmployeeId = 1,
                            Role = "super_admin"
                        });
                });

            modelBuilder.Entity("NayifatPortalAdmin.Models.ActivityLog", b =>
                {
                    b.HasOne("NayifatPortalAdmin.Models.PortalEmployee", "Employee")
                        .WithMany("ActivityLogs")
                        .HasForeignKey("EmployeeId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Employee");
                });

            modelBuilder.Entity("NayifatPortalAdmin.Models.PortalRole", b =>
                {
                    b.HasOne("NayifatPortalAdmin.Models.PortalEmployee", "Employee")
                        .WithMany("Roles")
                        .HasForeignKey("EmployeeId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Employee");
                });

            modelBuilder.Entity("NayifatPortalAdmin.Models.PortalEmployee", b =>
                {
                    b.Navigation("ActivityLogs");

                    b.Navigation("Roles");
                });
#pragma warning restore 612, 618
        }
    }
}
