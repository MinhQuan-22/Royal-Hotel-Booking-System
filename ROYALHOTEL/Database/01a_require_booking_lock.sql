CREATE OR ALTER PROCEDURE sp_RequireBookingLock
    @RoomId INT,
    @CheckIn DATE,
    @CheckOut DATE,
    @ExcludeBookingId INT = 0,
    @HasOverlap BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM Rooms WITH (UPDLOCK, HOLDLOCK, ROWLOCK)
        WHERE Id = @RoomId
          AND Status = 'ACTIVE'
          AND IsActive = 1
    )
    BEGIN
        THROW 50020, 'Room is not active or not available for booking draft.', 1;
    END

    SET @HasOverlap =
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM Bookings WITH (UPDLOCK, HOLDLOCK)
                WHERE RoomId = @RoomId
                  AND Id <> @ExcludeBookingId
                  AND Status IN ('Confirmed', 'CheckedIn')
                  AND @CheckIn < CheckOut
                  AND @CheckOut > CheckIn
            )
            THEN 1
            ELSE 0
        END;
END
GO
