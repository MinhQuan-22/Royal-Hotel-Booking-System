using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ROYALHOTEL.Migrations
{
    /// <inheritdoc />
    public partial class UpdatePessimisticLockSP_AddHoldlock : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                ALTER PROCEDURE sp_RequireBookingLock 
                    @RoomId INT,
                    @CheckIn DATETIME2,
                    @CheckOut DATETIME2,
                    @ExcludeBookingId INT = 0,
                    @HasOverlap BIT OUTPUT
                AS
                BEGIN
                    SET NOCOUNT ON;
                    -- Lock the room using UPDLOCK, HOLDLOCK
                    DECLARE @Dummy INT;
                    SELECT @Dummy = Id FROM Rooms WITH (UPDLOCK, HOLDLOCK, ROWLOCK) WHERE Id = @RoomId;

                    -- Check for overlap
                    IF EXISTS (
                        SELECT 1 FROM Bookings 
                        WHERE RoomId = @RoomId 
                          AND Id <> @ExcludeBookingId
                          AND Status IN ('Confirmed', 'CheckedIn')
                          AND CheckIn < @CheckOut 
                          AND CheckOut > @CheckIn
                    )
                    BEGIN
                        SET @HasOverlap = 1;
                    END
                    ELSE
                    BEGIN
                        SET @HasOverlap = 0;
                    END
                END
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                ALTER PROCEDURE sp_RequireBookingLock 
                    @RoomId INT,
                    @CheckIn DATETIME2,
                    @CheckOut DATETIME2,
                    @ExcludeBookingId INT = 0,
                    @HasOverlap BIT OUTPUT
                AS
                BEGIN
                    SET NOCOUNT ON;
                    -- Lock the room using UPDLOCK
                    DECLARE @Dummy INT;
                    SELECT @Dummy = Id FROM Rooms WITH (UPDLOCK, ROWLOCK) WHERE Id = @RoomId;

                    -- Check for overlap
                    IF EXISTS (
                        SELECT 1 FROM Bookings 
                        WHERE RoomId = @RoomId 
                          AND Id <> @ExcludeBookingId
                          AND Status IN ('Confirmed', 'CheckedIn')
                          AND CheckIn < @CheckOut 
                          AND CheckOut > @CheckIn
                    )
                    BEGIN
                        SET @HasOverlap = 1;
                    END
                    ELSE
                    BEGIN
                        SET @HasOverlap = 0;
                    END
                END
            ");
        }
    }
}
