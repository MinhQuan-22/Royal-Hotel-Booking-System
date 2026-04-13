CREATE OR ALTER PROCEDURE sp_ConfirmBooking
    @BookingId INT,
    @PaymentMethod NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RoomId INT;
    DECLARE @CheckIn DATETIME2;
    DECLARE @CheckOut DATETIME2;
    DECLARE @CurrentStatus NVARCHAR(20);

    BEGIN TRAN;

    -- Step 1: Lock and read booking row
    SELECT 
        @RoomId = RoomId,
        @CheckIn = CheckIn,
        @CheckOut = CheckOut,
        @CurrentStatus = Status
    FROM Bookings WITH (UPDLOCK, HOLDLOCK, ROWLOCK)
    WHERE Id = @BookingId;

    IF @RoomId IS NULL
    BEGIN
        ROLLBACK TRAN;
        THROW 50010, 'Booking not found.', 1;
    END

    IF @CurrentStatus <> 'Pending'
    BEGIN
        ROLLBACK TRAN;
        THROW 50011, 'Only pending bookings can be confirmed.', 1;
    END

    -- Step 2: Lock target room row
    SELECT Id
    FROM Rooms WITH (UPDLOCK, HOLDLOCK, ROWLOCK)
    WHERE Id = @RoomId
      AND Status = 'ACTIVE';

    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK TRAN;
        THROW 50012, 'Room is not active or not available.', 1;
    END

    -- Step 3: Lock overlapping bookings
    IF EXISTS (
        SELECT 1
        FROM Bookings WITH (UPDLOCK, HOLDLOCK)
        WHERE RoomId = @RoomId
          AND Id <> @BookingId
          AND Status IN ('Pending', 'Confirmed', 'CheckedIn')
          AND @CheckIn < CheckOut
          AND @CheckOut > CheckIn
    )
    BEGIN
        ROLLBACK TRAN;
        THROW 50013, 'Room is no longer available for the selected dates.', 1;
    END

    -- Step 4: Confirm booking
    UPDATE Bookings
    SET Status = 'Confirmed'
    WHERE Id = @BookingId
      AND Status = 'Pending';

    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK TRAN;
        THROW 50014, 'Booking status changed during processing.', 1;
    END

    -- Step 5: Optional payment record
    IF OBJECT_ID('PaymentTransactions', 'U') IS NOT NULL
    BEGIN
        INSERT INTO PaymentTransactions(BookingID, Amount, Status)
        SELECT Id, TotalAmount, 'Paid'
        FROM Bookings
        WHERE Id = @BookingId;
    END

    COMMIT TRAN;
END
GO
