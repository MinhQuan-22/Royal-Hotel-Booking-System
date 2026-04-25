using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ROYALHOTEL.Migrations
{
    /// <inheritdoc />
    public partial class AddRefundAndTransactionFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(name: "CancelReason", table: "Bookings", type: "nvarchar(255)", maxLength: 255, nullable: true);
            migrationBuilder.AddColumn<DateTime>(name: "CancelledAt", table: "Bookings", type: "datetime2", nullable: true);
            migrationBuilder.AddColumn<decimal>(name: "RefundAmount", table: "Bookings", type: "decimal(18,2)", precision: 18, scale: 2, nullable: true);
            migrationBuilder.AddColumn<string>(name: "RefundPolicyApplied", table: "Bookings", type: "nvarchar(255)", maxLength: 255, nullable: true);
            migrationBuilder.AddColumn<DateTime>(name: "RefundProcessedAt", table: "Bookings", type: "datetime2", nullable: true);
            migrationBuilder.AddColumn<string>(name: "RefundStatus", table: "Bookings", type: "nvarchar(50)", maxLength: 50, nullable: true);

            migrationBuilder.AddColumn<string>(name: "Note", table: "PaymentTransactions", type: "nvarchar(255)", maxLength: 255, nullable: true);
            migrationBuilder.AddColumn<int>(name: "ParentTransactionId", table: "PaymentTransactions", type: "int", nullable: true);
            migrationBuilder.AddColumn<DateTime>(name: "ProcessedAt", table: "PaymentTransactions", type: "datetime2", nullable: true);
            migrationBuilder.AddColumn<string>(name: "TransactionType", table: "PaymentTransactions", type: "nvarchar(20)", maxLength: 20, nullable: false, defaultValue: "Payment");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentTransactions_ParentTransactionId",
                table: "PaymentTransactions",
                column: "ParentTransactionId");

            migrationBuilder.AddForeignKey(
                name: "FK_PaymentTransactions_PaymentTransactions_ParentTransactionId",
                table: "PaymentTransactions",
                column: "ParentTransactionId",
                principalTable: "PaymentTransactions",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_PaymentTransactions_PaymentTransactions_ParentTransactionId",
                table: "PaymentTransactions");

            migrationBuilder.DropIndex(
                name: "IX_PaymentTransactions_ParentTransactionId",
                table: "PaymentTransactions");

            migrationBuilder.DropColumn(name: "CancelReason", table: "Bookings");
            migrationBuilder.DropColumn(name: "CancelledAt", table: "Bookings");
            migrationBuilder.DropColumn(name: "RefundAmount", table: "Bookings");
            migrationBuilder.DropColumn(name: "RefundPolicyApplied", table: "Bookings");
            migrationBuilder.DropColumn(name: "RefundProcessedAt", table: "Bookings");
            migrationBuilder.DropColumn(name: "RefundStatus", table: "Bookings");

            migrationBuilder.DropColumn(name: "Note", table: "PaymentTransactions");
            migrationBuilder.DropColumn(name: "ParentTransactionId", table: "PaymentTransactions");
            migrationBuilder.DropColumn(name: "ProcessedAt", table: "PaymentTransactions");
            migrationBuilder.DropColumn(name: "TransactionType", table: "PaymentTransactions");
        }
    }
}
