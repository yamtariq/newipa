using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace NayifatAPI.Models.Generated;

public partial class NayifatAppContext : DbContext
{
    public NayifatAppContext()
    {
    }

    public NayifatAppContext(DbContextOptions<NayifatAppContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Customer> Customers { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=.;Database=NayifatApp;Trusted_Connection=True;TrustServerCertificate=True;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Customer>(entity =>
        {
            entity.HasKey(e => e.NationalId);

            entity.Property(e => e.City)
                .HasMaxLength(255)
                .UseCollation("Arabic_CI_AS");
            entity.Property(e => e.District)
                .HasMaxLength(255)
                .UseCollation("Arabic_CI_AS");
            entity.Property(e => e.Employer)
                .HasMaxLength(255)
                .UseCollation("Arabic_CI_AS");
            entity.Property(e => e.FamilyNameAr)
                .HasMaxLength(255)
                .UseCollation("Arabic_CI_AS");
            entity.Property(e => e.FirstNameAr)
                .HasMaxLength(255)
                .UseCollation("Arabic_CI_AS");
            entity.Property(e => e.SalaryCustomer).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.SalaryDakhli).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.SecondNameAr)
                .HasMaxLength(255)
                .UseCollation("Arabic_CI_AS");
            entity.Property(e => e.Street)
                .HasMaxLength(255)
                .UseCollation("Arabic_CI_AS");
            entity.Property(e => e.ThirdNameAr)
                .HasMaxLength(255)
                .UseCollation("Arabic_CI_AS");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
