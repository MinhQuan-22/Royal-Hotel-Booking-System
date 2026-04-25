using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ROYALHOTEL.Migrations
{
    /// <inheritdoc />
    public partial class AddCancelNoteField : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CancelNote",
                table: "Bookings",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CancelNote",
                table: "Bookings");
        }
    }
}
