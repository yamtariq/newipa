using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NayifatAPI.Migrations
{
    /// <inheritdoc />
    public partial class CreateBankCustomersTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "bank_customers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RequestId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    NationalId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ApplicationFlag = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ApplicationId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ApplicationStatus = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CustomerId = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    EligibleStatus = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    EligibleAmount = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    EligibleEmi = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    ProductType = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SuccessMsg = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ErrCode = table.Column<int>(type: "int", nullable: false),
                    ErrMsg = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Type = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_bank_customers", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_bank_customers_ApplicationId",
                table: "bank_customers",
                column: "ApplicationId");

            migrationBuilder.CreateIndex(
                name: "IX_bank_customers_NationalId",
                table: "bank_customers",
                column: "NationalId");

            migrationBuilder.CreateIndex(
                name: "IX_bank_customers_RequestId",
                table: "bank_customers",
                column: "RequestId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "bank_customers");
        }
    }
}
