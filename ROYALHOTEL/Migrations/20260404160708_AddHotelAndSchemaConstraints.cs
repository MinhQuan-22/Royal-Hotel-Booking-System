using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ROYALHOTEL.Migrations
{
    /// <inheritdoc />
    public partial class AddHotelAndSchemaConstraints : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Bookings_RoomId",
                table: "Bookings");

            migrationBuilder.AddColumn<int>(
                name: "HotelId",
                table: "Rooms",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<decimal>(
                name: "Rate",
                table: "Rooms",
                type: "decimal(18,2)",
                precision: 18,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "Rooms",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "Hotels",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Address = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    City = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Country = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Hotels", x => x.Id);
                });

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT 1 FROM Hotels)
                BEGIN
                    INSERT INTO Hotels (Name, Address, City, Country) 
                    VALUES ('Royal Hotel', 'Default Address', 'Default City', 'Default Country');
                END
                UPDATE Rooms SET HotelId = (SELECT TOP 1 Id FROM Hotels), Status = 'Available', Rate = CASE WHEN BasePricePerNight > 0 THEN BasePricePerNight ELSE 1 END;
            ");

            migrationBuilder.CreateIndex(
                name: "IX_Rooms_HotelId",
                table: "Rooms",
                column: "HotelId");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Room_Rate",
                table: "Rooms",
                sql: "Rate > 0");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_BookingCode",
                table: "Bookings",
                column: "BookingCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_RoomId_CheckIn_CheckOut_Status",
                table: "Bookings",
                columns: new[] { "RoomId", "CheckIn", "CheckOut", "Status" });

            migrationBuilder.AddCheckConstraint(
                name: "CK_Booking_Dates",
                table: "Bookings",
                sql: "CheckOut > CheckIn");

            migrationBuilder.AddForeignKey(
                name: "FK_Rooms_Hotels_HotelId",
                table: "Rooms",
                column: "HotelId",
                principalTable: "Hotels",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Rooms_Hotels_HotelId",
                table: "Rooms");

            migrationBuilder.DropTable(
                name: "Hotels");

            migrationBuilder.DropIndex(
                name: "IX_Rooms_HotelId",
                table: "Rooms");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Room_Rate",
                table: "Rooms");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_BookingCode",
                table: "Bookings");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_RoomId_CheckIn_CheckOut_Status",
                table: "Bookings");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Booking_Dates",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "HotelId",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "Rate",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Rooms");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_RoomId",
                table: "Bookings",
                column: "RoomId");
        }
    }
}
