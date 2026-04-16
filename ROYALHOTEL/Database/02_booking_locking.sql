-- 02_booking_locking.sql

CREATE OR ALTER PROCEDURE sp_ConfirmBooking
    @BookingId INT,
    @PaymentMethod NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RoomId INT;
    DECLARE @CheckIn DATE;
    DECLARE @CheckOut DATE;
    DECLARE @CurrentStatus NVARCHAR(20);
    DECLARE @FinalPaymentMethod NVARCHAR(50);
    DECLARE @TotalAmount DECIMAL(18,2);
    DECLARE @TransactionCode NVARCHAR(200);

    BEGIN TRAN;

    -- Step 1: Lock and read booking row
    SELECT 
        @RoomId = RoomId,
        @CheckIn = CheckIn,
        @CheckOut = CheckOut,
        @CurrentStatus = Status,
        @TotalAmount = TotalAmount
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

    -- Step 2: Validate and lock target room
    IF NOT EXISTS (
        SELECT 1
        FROM Rooms WITH (UPDLOCK, HOLDLOCK, ROWLOCK)
        WHERE Id = @RoomId
          AND Status = 'ACTIVE'
          AND IsActive = 1
    )
    BEGIN
        ROLLBACK TRAN;
        THROW 50012, 'Room is not active or not available.', 1;
    END

    -- Optional: only for race-condition demo, comment out after screenshot
    -- WAITFOR DELAY '00:00:05';

    -- Step 3: Check overlap against FINALIZED occupancy only
    IF EXISTS (
        SELECT 1
        FROM Bookings WITH (UPDLOCK, HOLDLOCK)
        WHERE RoomId = @RoomId
          AND Id <> @BookingId
          AND Status IN ('Confirmed', 'CheckedIn')
          AND @CheckIn < CheckOut
          AND @CheckOut > CheckIn
    )
    BEGIN
        ROLLBACK TRAN;
        THROW 50013, 'Room is no longer available for the selected dates.', 1;
    END

    -- Step 4: Confirm booking
    SET @FinalPaymentMethod = COALESCE(@PaymentMethod, 'Unknown');
    SET @TransactionCode = CONCAT('TXN-', @BookingId, '-', FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss'));

    UPDATE Bookings
    SET Status = 'Confirmed',
        PaymentMethod = @FinalPaymentMethod
    WHERE Id = @BookingId
      AND Status = 'Pending';

    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK TRAN;
        THROW 50014, 'Booking status changed during processing.', 1;
    END

    -- Step 5: Insert payment record once
    IF OBJECT_ID('PaymentTransactions', 'U') IS NOT NULL
       AND NOT EXISTS (
            SELECT 1
            FROM PaymentTransactions WITH (UPDLOCK, HOLDLOCK)
            WHERE BookingId = @BookingId
              AND Status = 'Paid'
       )
    BEGIN
        INSERT INTO PaymentTransactions (
            BookingId,
            PaymentMethod,
            Amount,
            Status,
            TransactionCode,
            CreatedAt
        )
        VALUES (
            @BookingId,
            @FinalPaymentMethod,
            ISNULL(@TotalAmount, 0),
            'Paid',
            @TransactionCode,
            SYSDATETIME()
        );
    END

    COMMIT TRAN;
END
GO
