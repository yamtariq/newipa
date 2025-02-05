using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NayifatAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationImageUrls : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_User_Notifications_Customers_NationalId",
                table: "User_Notifications");

            migrationBuilder.DropPrimaryKey(
                name: "PK_User_Notifications",
                table: "User_Notifications");

            migrationBuilder.DropIndex(
                name: "IX_User_Notifications_NationalId_IsRead",
                table: "User_Notifications");

            migrationBuilder.DropIndex(
                name: "IX_User_Notifications_NotificationId",
                table: "User_Notifications");

            migrationBuilder.DropIndex(
                name: "IX_master_config_Page",
                table: "master_config");

            migrationBuilder.DropColumn(
                name: "Id",
                table: "User_Notifications");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "User_Notifications");

            migrationBuilder.DropColumn(
                name: "Data",
                table: "User_Notifications");

            migrationBuilder.DropColumn(
                name: "IsRead",
                table: "User_Notifications");

            migrationBuilder.DropColumn(
                name: "Message",
                table: "User_Notifications");

            migrationBuilder.DropColumn(
                name: "NotificationId",
                table: "User_Notifications");

            migrationBuilder.DropColumn(
                name: "NotificationType",
                table: "User_Notifications");

            migrationBuilder.DropColumn(
                name: "ReadAt",
                table: "User_Notifications");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "master_config");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "master_config");

            migrationBuilder.RenameTable(
                name: "User_Notifications",
                newName: "user_notifications");

            migrationBuilder.RenameColumn(
                name: "NationalId",
                table: "user_notifications",
                newName: "national_id");

            migrationBuilder.RenameColumn(
                name: "LastUpdated",
                table: "user_notifications",
                newName: "last_updated");

            migrationBuilder.RenameColumn(
                name: "Title",
                table: "user_notifications",
                newName: "notifications");

            migrationBuilder.RenameColumn(
                name: "Value",
                table: "master_config",
                newName: "value");

            migrationBuilder.RenameColumn(
                name: "Page",
                table: "master_config",
                newName: "page");

            migrationBuilder.RenameColumn(
                name: "KeyName",
                table: "master_config",
                newName: "key_name");

            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "master_config",
                newName: "last_updated");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "master_config",
                newName: "config_id");

            migrationBuilder.RenameIndex(
                name: "IX_master_config_Page_KeyName",
                table: "master_config",
                newName: "IX_master_config_page_key_name");

            migrationBuilder.AlterColumn<DateTime>(
                name: "last_updated",
                table: "user_notifications",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AddPrimaryKey(
                name: "PK_user_notifications",
                table: "user_notifications",
                column: "national_id");

            migrationBuilder.CreateTable(
                name: "card_application_details",
                columns: table => new
                {
                    card_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    application_no = table.Column<int>(type: "int", nullable: false),
                    national_id = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    card_type = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    card_limit = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    status_date = table.Column<DateTime>(type: "datetime2", nullable: false),
                    remarks = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    noteUser = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    note = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_card_application_details", x => x.card_id);
                    table.ForeignKey(
                        name: "FK_card_application_details_Customers_national_id",
                        column: x => x.national_id,
                        principalTable: "Customers",
                        principalColumn: "NationalId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "lead_apps_cards",
                columns: table => new
                {
                    id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    national_id = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    phone = table.Column<string>(type: "nvarchar(15)", maxLength: 15, nullable: false),
                    status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false, defaultValue: "PENDING"),
                    status_timestamp = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_lead_apps_cards", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "lead_apps_loans",
                columns: table => new
                {
                    id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    national_id = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    phone = table.Column<string>(type: "nvarchar(15)", maxLength: 15, nullable: false),
                    status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false, defaultValue: "PENDING"),
                    status_timestamp = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_lead_apps_loans", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "loan_application_details",
                columns: table => new
                {
                    loan_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    application_no = table.Column<int>(type: "int", nullable: false),
                    national_id = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    customerDecision = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    loan_amount = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    loan_purpose = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    loan_tenure = table.Column<int>(type: "int", nullable: true),
                    interest_rate = table.Column<decimal>(type: "decimal(5,2)", nullable: true),
                    status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    status_date = table.Column<DateTime>(type: "datetime2", nullable: false),
                    remarks = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    noteUser = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    note = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_loan_application_details", x => x.loan_id);
                    table.ForeignKey(
                        name: "FK_loan_application_details_Customers_national_id",
                        column: x => x.national_id,
                        principalTable: "Customers",
                        principalColumn: "NationalId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "notification_templates",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Title = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    Body = table.Column<string>(type: "text", nullable: true),
                    title_en = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    body_en = table.Column<string>(type: "text", nullable: true),
                    title_ar = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    body_ar = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Route = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    additional_data = table.Column<string>(type: "json", nullable: true),
                    target_criteria = table.Column<string>(type: "json", nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    expiry_at = table.Column<DateTime>(type: "datetime2", nullable: true),
                    big_picture_url = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    large_icon_url = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_notification_templates", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_card_application_details_national_id",
                table: "card_application_details",
                column: "national_id");

            migrationBuilder.CreateIndex(
                name: "IX_lead_apps_cards_national_id",
                table: "lead_apps_cards",
                column: "national_id");

            migrationBuilder.CreateIndex(
                name: "IX_lead_apps_loans_national_id",
                table: "lead_apps_loans",
                column: "national_id");

            migrationBuilder.CreateIndex(
                name: "IX_loan_application_details_national_id",
                table: "loan_application_details",
                column: "national_id");

            migrationBuilder.AddForeignKey(
                name: "FK_user_notifications_Customers_national_id",
                table: "user_notifications",
                column: "national_id",
                principalTable: "Customers",
                principalColumn: "NationalId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddColumn<string>(
                name: "big_picture_url",
                table: "notification_templates",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "large_icon_url",
                table: "notification_templates",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.Sql(@"
                UPDATE notification_templates 
                SET big_picture_url = NULL, 
                    large_icon_url = NULL 
                WHERE big_picture_url IS NULL 
                   OR large_icon_url IS NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_user_notifications_Customers_national_id",
                table: "user_notifications");

            migrationBuilder.DropTable(
                name: "card_application_details");

            migrationBuilder.DropTable(
                name: "lead_apps_cards");

            migrationBuilder.DropTable(
                name: "lead_apps_loans");

            migrationBuilder.DropTable(
                name: "loan_application_details");

            migrationBuilder.DropTable(
                name: "notification_templates");

            migrationBuilder.DropPrimaryKey(
                name: "PK_user_notifications",
                table: "user_notifications");

            migrationBuilder.RenameTable(
                name: "user_notifications",
                newName: "User_Notifications");

            migrationBuilder.RenameColumn(
                name: "last_updated",
                table: "User_Notifications",
                newName: "LastUpdated");

            migrationBuilder.RenameColumn(
                name: "national_id",
                table: "User_Notifications",
                newName: "NationalId");

            migrationBuilder.RenameColumn(
                name: "notifications",
                table: "User_Notifications",
                newName: "Title");

            migrationBuilder.RenameColumn(
                name: "value",
                table: "master_config",
                newName: "Value");

            migrationBuilder.RenameColumn(
                name: "page",
                table: "master_config",
                newName: "Page");

            migrationBuilder.RenameColumn(
                name: "key_name",
                table: "master_config",
                newName: "KeyName");

            migrationBuilder.RenameColumn(
                name: "last_updated",
                table: "master_config",
                newName: "CreatedAt");

            migrationBuilder.RenameColumn(
                name: "config_id",
                table: "master_config",
                newName: "Id");

            migrationBuilder.RenameIndex(
                name: "IX_master_config_page_key_name",
                table: "master_config",
                newName: "IX_master_config_Page_KeyName");

            migrationBuilder.AlterColumn<DateTime>(
                name: "LastUpdated",
                table: "User_Notifications",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AddColumn<int>(
                name: "Id",
                table: "User_Notifications",
                type: "int",
                nullable: false,
                defaultValue: 0)
                .Annotation("SqlServer:Identity", "1, 1");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "User_Notifications",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "Data",
                table: "User_Notifications",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsRead",
                table: "User_Notifications",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Message",
                table: "User_Notifications",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "NotificationId",
                table: "User_Notifications",
                type: "nvarchar(450)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "NotificationType",
                table: "User_Notifications",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "ReadAt",
                table: "User_Notifications",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "master_config",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "master_config",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_User_Notifications",
                table: "User_Notifications",
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
                name: "IX_master_config_Page",
                table: "master_config",
                column: "Page");

            migrationBuilder.AddForeignKey(
                name: "FK_User_Notifications_Customers_NationalId",
                table: "User_Notifications",
                column: "NationalId",
                principalTable: "Customers",
                principalColumn: "NationalId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.DropColumn(
                name: "big_picture_url",
                table: "notification_templates");

            migrationBuilder.DropColumn(
                name: "large_icon_url",
                table: "notification_templates");
        }
    }
}
