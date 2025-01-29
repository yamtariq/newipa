using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NayifatAPI.Migrations
{
    /// <inheritdoc />
    public partial class UpdateAuthLogIdType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CustomerDevices_Customers_NationalId",
                table: "CustomerDevices");

            migrationBuilder.DropForeignKey(
                name: "FK_OtpCodes_Customers_NationalId",
                table: "OtpCodes");

            migrationBuilder.DropForeignKey(
                name: "FK_UserNotifications_Customers_NationalId",
                table: "UserNotifications");

            migrationBuilder.DropPrimaryKey(
                name: "PK_UserNotifications",
                table: "UserNotifications");

            migrationBuilder.DropPrimaryKey(
                name: "PK_OtpCodes",
                table: "OtpCodes");

            migrationBuilder.DropPrimaryKey(
                name: "PK_CustomerDevices",
                table: "CustomerDevices");

            migrationBuilder.DropColumn(
                name: "IsSuccessful",
                table: "AuthLogs");

            migrationBuilder.DropColumn(
                name: "Channel",
                table: "OtpCodes");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "CustomerDevices");

            migrationBuilder.DropColumn(
                name: "RegisteredAt",
                table: "CustomerDevices");

            migrationBuilder.RenameTable(
                name: "UserNotifications",
                newName: "User_Notifications");

            migrationBuilder.RenameTable(
                name: "OtpCodes",
                newName: "OTP_Codes");

            migrationBuilder.RenameTable(
                name: "CustomerDevices",
                newName: "Customer_Devices");

            migrationBuilder.RenameColumn(
                name: "ErrorMessage",
                table: "AuthLogs",
                newName: "Status");

            migrationBuilder.RenameIndex(
                name: "IX_UserNotifications_NationalId",
                table: "User_Notifications",
                newName: "IX_User_Notifications_NationalId");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "OTP_Codes",
                newName: "id");

            migrationBuilder.RenameColumn(
                name: "UsedAt",
                table: "OTP_Codes",
                newName: "used_at");

            migrationBuilder.RenameColumn(
                name: "NationalId",
                table: "OTP_Codes",
                newName: "national_id");

            migrationBuilder.RenameColumn(
                name: "IsUsed",
                table: "OTP_Codes",
                newName: "is_used");

            migrationBuilder.RenameColumn(
                name: "ExpiresAt",
                table: "OTP_Codes",
                newName: "expires_at");

            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "OTP_Codes",
                newName: "created_at");

            migrationBuilder.RenameColumn(
                name: "Code",
                table: "OTP_Codes",
                newName: "otp_code");

            migrationBuilder.RenameColumn(
                name: "Purpose",
                table: "OTP_Codes",
                newName: "type");

            migrationBuilder.RenameIndex(
                name: "IX_OtpCodes_NationalId",
                table: "OTP_Codes",
                newName: "IX_OTP_Codes_national_id");

            migrationBuilder.RenameColumn(
                name: "PushToken",
                table: "Customer_Devices",
                newName: "Status");

            migrationBuilder.RenameColumn(
                name: "IsBiometricEnabled",
                table: "Customer_Devices",
                newName: "BiometricEnabled");

            migrationBuilder.RenameColumn(
                name: "DeviceName",
                table: "Customer_Devices",
                newName: "Model");

            migrationBuilder.RenameIndex(
                name: "IX_CustomerDevices_NationalId",
                table: "Customer_Devices",
                newName: "IX_Customer_Devices_NationalId");

            migrationBuilder.RenameIndex(
                name: "IX_CustomerDevices_DeviceId",
                table: "Customer_Devices",
                newName: "IX_Customer_Devices_DeviceId");

            migrationBuilder.AlterColumn<string>(
                name: "UserAgent",
                table: "AuthLogs",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "IpAddress",
                table: "AuthLogs",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "DeviceId",
                table: "AuthLogs",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "AuthLogs",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AddColumn<string>(
                name: "FailureReason",
                table: "AuthLogs",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Data",
                table: "User_Notifications",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "User_Notifications",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AddColumn<DateTime>(
                name: "LastUpdated",
                table: "User_Notifications",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "NotificationId",
                table: "User_Notifications",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AlterColumn<DateTime>(
                name: "created_at",
                table: "OTP_Codes",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "OsVersion",
                table: "Customer_Devices",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<string>(
                name: "BiometricToken",
                table: "Customer_Devices",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Customer_Devices",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AddColumn<string>(
                name: "Manufacturer",
                table: "Customer_Devices",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddPrimaryKey(
                name: "PK_User_Notifications",
                table: "User_Notifications",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_OTP_Codes",
                table: "OTP_Codes",
                column: "id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Customer_Devices",
                table: "Customer_Devices",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Customer_Devices_Customers_NationalId",
                table: "Customer_Devices",
                column: "NationalId",
                principalTable: "Customers",
                principalColumn: "NationalId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_OTP_Codes_Customers_national_id",
                table: "OTP_Codes",
                column: "national_id",
                principalTable: "Customers",
                principalColumn: "NationalId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_User_Notifications_Customers_NationalId",
                table: "User_Notifications",
                column: "NationalId",
                principalTable: "Customers",
                principalColumn: "NationalId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Customer_Devices_Customers_NationalId",
                table: "Customer_Devices");

            migrationBuilder.DropForeignKey(
                name: "FK_OTP_Codes_Customers_national_id",
                table: "OTP_Codes");

            migrationBuilder.DropForeignKey(
                name: "FK_User_Notifications_Customers_NationalId",
                table: "User_Notifications");

            migrationBuilder.DropPrimaryKey(
                name: "PK_User_Notifications",
                table: "User_Notifications");

            migrationBuilder.DropPrimaryKey(
                name: "PK_OTP_Codes",
                table: "OTP_Codes");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Customer_Devices",
                table: "Customer_Devices");

            migrationBuilder.DropColumn(
                name: "FailureReason",
                table: "AuthLogs");

            migrationBuilder.DropColumn(
                name: "LastUpdated",
                table: "User_Notifications");

            migrationBuilder.DropColumn(
                name: "NotificationId",
                table: "User_Notifications");

            migrationBuilder.DropColumn(
                name: "BiometricToken",
                table: "Customer_Devices");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Customer_Devices");

            migrationBuilder.DropColumn(
                name: "Manufacturer",
                table: "Customer_Devices");

            migrationBuilder.RenameTable(
                name: "User_Notifications",
                newName: "UserNotifications");

            migrationBuilder.RenameTable(
                name: "OTP_Codes",
                newName: "OtpCodes");

            migrationBuilder.RenameTable(
                name: "Customer_Devices",
                newName: "CustomerDevices");

            migrationBuilder.RenameColumn(
                name: "Status",
                table: "AuthLogs",
                newName: "ErrorMessage");

            migrationBuilder.RenameIndex(
                name: "IX_User_Notifications_NationalId",
                table: "UserNotifications",
                newName: "IX_UserNotifications_NationalId");

            migrationBuilder.RenameColumn(
                name: "id",
                table: "OtpCodes",
                newName: "Id");

            migrationBuilder.RenameColumn(
                name: "used_at",
                table: "OtpCodes",
                newName: "UsedAt");

            migrationBuilder.RenameColumn(
                name: "otp_code",
                table: "OtpCodes",
                newName: "Code");

            migrationBuilder.RenameColumn(
                name: "national_id",
                table: "OtpCodes",
                newName: "NationalId");

            migrationBuilder.RenameColumn(
                name: "is_used",
                table: "OtpCodes",
                newName: "IsUsed");

            migrationBuilder.RenameColumn(
                name: "expires_at",
                table: "OtpCodes",
                newName: "ExpiresAt");

            migrationBuilder.RenameColumn(
                name: "created_at",
                table: "OtpCodes",
                newName: "CreatedAt");

            migrationBuilder.RenameColumn(
                name: "type",
                table: "OtpCodes",
                newName: "Purpose");

            migrationBuilder.RenameIndex(
                name: "IX_OTP_Codes_national_id",
                table: "OtpCodes",
                newName: "IX_OtpCodes_NationalId");

            migrationBuilder.RenameColumn(
                name: "Status",
                table: "CustomerDevices",
                newName: "PushToken");

            migrationBuilder.RenameColumn(
                name: "Model",
                table: "CustomerDevices",
                newName: "DeviceName");

            migrationBuilder.RenameColumn(
                name: "BiometricEnabled",
                table: "CustomerDevices",
                newName: "IsBiometricEnabled");

            migrationBuilder.RenameIndex(
                name: "IX_Customer_Devices_NationalId",
                table: "CustomerDevices",
                newName: "IX_CustomerDevices_NationalId");

            migrationBuilder.RenameIndex(
                name: "IX_Customer_Devices_DeviceId",
                table: "CustomerDevices",
                newName: "IX_CustomerDevices_DeviceId");

            migrationBuilder.AlterColumn<string>(
                name: "UserAgent",
                table: "AuthLogs",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "IpAddress",
                table: "AuthLogs",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "DeviceId",
                table: "AuthLogs",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "AuthLogs",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AddColumn<bool>(
                name: "IsSuccessful",
                table: "AuthLogs",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<string>(
                name: "Data",
                table: "UserNotifications",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "UserNotifications",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "OtpCodes",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AddColumn<string>(
                name: "Channel",
                table: "OtpCodes",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AlterColumn<string>(
                name: "OsVersion",
                table: "CustomerDevices",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "CustomerDevices",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "RegisteredAt",
                table: "CustomerDevices",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddPrimaryKey(
                name: "PK_UserNotifications",
                table: "UserNotifications",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_OtpCodes",
                table: "OtpCodes",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_CustomerDevices",
                table: "CustomerDevices",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_CustomerDevices_Customers_NationalId",
                table: "CustomerDevices",
                column: "NationalId",
                principalTable: "Customers",
                principalColumn: "NationalId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_OtpCodes_Customers_NationalId",
                table: "OtpCodes",
                column: "NationalId",
                principalTable: "Customers",
                principalColumn: "NationalId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_UserNotifications_Customers_NationalId",
                table: "UserNotifications",
                column: "NationalId",
                principalTable: "Customers",
                principalColumn: "NationalId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
