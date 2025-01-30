using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NayifatAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddYakeenCitizenInfo : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "YakeenCitizenInfo",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    IqamaNumber = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    DateOfBirthHijri = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    IdExpiryDate = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    DateOfBirth = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    EnglishFirstName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    EnglishLastName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    EnglishSecondName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    EnglishThirdName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    FamilyName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    FatherName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    FirstName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Gender = table.Column<int>(type: "int", nullable: false),
                    GenderFieldSpecified = table.Column<bool>(type: "bit", nullable: false),
                    GrandFatherName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    HifizaIssuePlace = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    HifizaNumber = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    IdIssueDate = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    IdIssuePlace = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    IdVersionNumber = table.Column<int>(type: "int", nullable: false),
                    LogIdField = table.Column<int>(type: "int", nullable: false),
                    NumberOfVehiclesReg = table.Column<int>(type: "int", nullable: false),
                    OccupationCode = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    SocialStatusDetailedDesc = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    SubtribeName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    TotalNumberOfCurrentDependents = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_YakeenCitizenInfo", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_YakeenCitizenInfo_IqamaNumber",
                table: "YakeenCitizenInfo",
                column: "IqamaNumber");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "YakeenCitizenInfo");
        }
    }
}
