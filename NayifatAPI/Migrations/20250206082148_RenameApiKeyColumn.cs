using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NayifatAPI.Migrations
{
    /// <inheritdoc />
    public partial class RenameApiKeyColumn : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Key",
                table: "ApiKeys",
                newName: "api_Key");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "api_Key",
                table: "ApiKeys",
                newName: "Key");
        }
    }
}
