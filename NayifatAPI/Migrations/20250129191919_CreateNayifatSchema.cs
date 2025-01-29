using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NayifatAPI.Migrations
{
    /// <inheritdoc />
    public partial class CreateNayifatSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_User_Notifications_NationalId",
                table: "User_Notifications");

            migrationBuilder.DropIndex(
                name: "IX_OTP_Codes_national_id",
                table: "OTP_Codes");

            migrationBuilder.DropIndex(
                name: "IX_Customer_Devices_NationalId",
                table: "Customer_Devices");

            migrationBuilder.DropPrimaryKey(
                name: "PK_MasterConfigs",
                table: "MasterConfigs");

            migrationBuilder.DropColumn(
                name: "LastUpdated",
                table: "MasterConfigs");

            migrationBuilder.RenameTable(
                name: "MasterConfigs",
                newName: "master_config");

            migrationBuilder.RenameIndex(
                name: "IX_MasterConfigs_Page",
                table: "master_config",
                newName: "IX_master_config_Page");

            migrationBuilder.AlterColumn<string>(
                name: "NotificationId",
                table: "User_Notifications",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "User_Notifications",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AlterColumn<string>(
                name: "type",
                table: "OTP_Codes",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "created_at",
                table: "OTP_Codes",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AlterColumn<string>(
                name: "Zipcode",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Street",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Sector",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "RegistrationDate",
                table: "Customers",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AlterColumn<string>(
                name: "NafathStatus",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "IdExpiryDate",
                table: "Customers",
                type: "datetime2",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "Iban",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Employer",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "District",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "DateOfBirth",
                table: "Customers",
                type: "datetime2",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "City",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "BuildingNo",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "AddNo",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<string>(
                name: "Mpin",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "MpinEnabled",
                table: "Customers",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Customer_Devices",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AlterColumn<string>(
                name: "NationalId",
                table: "AuthLogs",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "AuthLogs",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AlterColumn<string>(
                name: "KeyName",
                table: "master_config",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "master_config",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_master_config",
                table: "master_config",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_User_Notifications_NationalId_IsRead",
                table: "User_Notifications",
                columns: new[] { "NationalId", "IsRead" });

            migrationBuilder.CreateIndex(
                name: "IX_User_Notifications_NotificationId",
                table: "User_Notifications",
                column: "NotificationId");

            migrationBuilder.CreateIndex(
                name: "IX_OTP_Codes_expires_at",
                table: "OTP_Codes",
                column: "expires_at");

            migrationBuilder.CreateIndex(
                name: "IX_OTP_Codes_national_id_type_is_used",
                table: "OTP_Codes",
                columns: new[] { "national_id", "type", "is_used" });

            migrationBuilder.CreateIndex(
                name: "IX_Customer_Devices_NationalId_DeviceId",
                table: "Customer_Devices",
                columns: new[] { "NationalId", "DeviceId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_AuthLogs_NationalId_CreatedAt",
                table: "AuthLogs",
                columns: new[] { "NationalId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_master_config_Page_KeyName",
                table: "master_config",
                columns: new[] { "Page", "KeyName" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_AuthLogs_Customers_NationalId",
                table: "AuthLogs",
                column: "NationalId",
                principalTable: "Customers",
                principalColumn: "NationalId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AuthLogs_Customers_NationalId",
                table: "AuthLogs");

            migrationBuilder.DropIndex(
                name: "IX_User_Notifications_NationalId_IsRead",
                table: "User_Notifications");

            migrationBuilder.DropIndex(
                name: "IX_User_Notifications_NotificationId",
                table: "User_Notifications");

            migrationBuilder.DropIndex(
                name: "IX_OTP_Codes_expires_at",
                table: "OTP_Codes");

            migrationBuilder.DropIndex(
                name: "IX_OTP_Codes_national_id_type_is_used",
                table: "OTP_Codes");

            migrationBuilder.DropIndex(
                name: "IX_Customer_Devices_NationalId_DeviceId",
                table: "Customer_Devices");

            migrationBuilder.DropIndex(
                name: "IX_AuthLogs_NationalId_CreatedAt",
                table: "AuthLogs");

            migrationBuilder.DropPrimaryKey(
                name: "PK_master_config",
                table: "master_config");

            migrationBuilder.DropIndex(
                name: "IX_master_config_Page_KeyName",
                table: "master_config");

            migrationBuilder.DropColumn(
                name: "Mpin",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "MpinEnabled",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "master_config");

            migrationBuilder.RenameTable(
                name: "master_config",
                newName: "MasterConfigs");

            migrationBuilder.RenameIndex(
                name: "IX_master_config_Page",
                table: "MasterConfigs",
                newName: "IX_MasterConfigs_Page");

            migrationBuilder.AlterColumn<string>(
                name: "NotificationId",
                table: "User_Notifications",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "User_Notifications",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "type",
                table: "OTP_Codes",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "created_at",
                table: "OTP_Codes",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "Zipcode",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Street",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Sector",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "RegistrationDate",
                table: "Customers",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "NafathStatus",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "IdExpiryDate",
                table: "Customers",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified),
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Iban",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Employer",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "District",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "DateOfBirth",
                table: "Customers",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified),
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "City",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "BuildingNo",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "AddNo",
                table: "Customers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Customer_Devices",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "NationalId",
                table: "AuthLogs",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "AuthLogs",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "KeyName",
                table: "MasterConfigs",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AddColumn<DateTime>(
                name: "LastUpdated",
                table: "MasterConfigs",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddPrimaryKey(
                name: "PK_MasterConfigs",
                table: "MasterConfigs",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_User_Notifications_NationalId",
                table: "User_Notifications",
                column: "NationalId");

            migrationBuilder.CreateIndex(
                name: "IX_OTP_Codes_national_id",
                table: "OTP_Codes",
                column: "national_id");

            migrationBuilder.CreateIndex(
                name: "IX_Customer_Devices_NationalId",
                table: "Customer_Devices",
                column: "NationalId");
        }
    }
}
