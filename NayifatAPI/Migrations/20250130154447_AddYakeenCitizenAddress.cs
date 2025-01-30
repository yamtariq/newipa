using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NayifatAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddYakeenCitizenAddress : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "YakeenCitizenAddress",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    IqamaNumber = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    DateOfBirthHijri = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    AddressLanguage = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    LogId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_YakeenCitizenAddress", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "CitizenAddressListItem",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AdditionalNumber = table.Column<int>(type: "int", nullable: false),
                    BuildingNumber = table.Column<int>(type: "int", nullable: false),
                    City = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    District = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    IsPrimaryAddress = table.Column<bool>(type: "bit", nullable: false),
                    LocationCoordinates = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PostCode = table.Column<int>(type: "int", nullable: false),
                    StreetName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    UnitNumber = table.Column<int>(type: "int", nullable: false),
                    YakeenCitizenAddressId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CitizenAddressListItem", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CitizenAddressListItem_YakeenCitizenAddress_YakeenCitizenAddressId",
                        column: x => x.YakeenCitizenAddressId,
                        principalTable: "YakeenCitizenAddress",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CitizenAddressListItem_YakeenCitizenAddressId",
                table: "CitizenAddressListItem",
                column: "YakeenCitizenAddressId");

            migrationBuilder.CreateIndex(
                name: "IX_YakeenCitizenAddress_IqamaNumber",
                table: "YakeenCitizenAddress",
                column: "IqamaNumber");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CitizenAddressListItem");

            migrationBuilder.DropTable(
                name: "YakeenCitizenAddress");
        }
    }
}
