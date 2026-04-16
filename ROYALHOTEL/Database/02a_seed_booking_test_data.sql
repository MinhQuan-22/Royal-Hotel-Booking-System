-- 02a_seed_booking_test_data.sql
-- Seed booking test data for sp_ConfirmBooking

DECLARE @RoomId_NT_DLX INT;
DECLARE @RoomRate_NT_DLX DECIMAL(18,2);
DECLARE @RoomId_PQ_DLX INT;
DECLARE @RoomRate_PQ_DLX DECIMAL(18,2);

SELECT 
    @RoomId_NT_DLX = Id,
    @RoomRate_NT_DLX = Rate
FROM Rooms
WHERE Code = 'NT-DLX-201';

SELECT 
    @RoomId_PQ_DLX = Id,
    @RoomRate_PQ_DLX = Rate
FROM Rooms
WHERE Code = 'PQ-DLX-201';

IF @RoomId_NT_DLX IS NULL
    THROW 51001, 'Room NT-DLX-201 not found.', 1;

IF @RoomId_PQ_DLX IS NULL
    THROW 51002, 'Room PQ-DLX-201 not found.', 1;

-- TEST-BK-A: should confirm successfully
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'TEST-BK-A')
BEGIN
    INSERT INTO Bookings (
        BookingCode,
        RoomId,
        CheckIn,
        CheckOut,
        Guests,
        Status,
        GuestName,
        GuestEmail,
        GuestPhone,
        TotalAmount,
        CreatedAt,
        PricePerNight,
        PaymentMethod,
        AccountId
    )
    VALUES (
        'TEST-BK-A',
        @RoomId_NT_DLX,
        '2026-07-10',
        '2026-07-12',
        2,
        'Pending',
        N'Test Guest A',
        'guesta@test.com',
        '0900000001',
        @RoomRate_NT_DLX * DATEDIFF(DAY, '2026-07-10', '2026-07-12'),
        SYSDATETIME(),
        @RoomRate_NT_DLX,
        NULL,
        NULL
    );
END
GO

-- TEST-BK-B: overlaps with A, should fail after A is confirmed
DECLARE @RoomId_B INT;
DECLARE @RoomRate_B DECIMAL(18,2);

SELECT @RoomId_B = Id, @RoomRate_B = Rate
FROM Rooms
WHERE Code = 'NT-DLX-201';

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'TEST-BK-B')
BEGIN
    INSERT INTO Bookings (
        BookingCode,
        RoomId,
        CheckIn,
        CheckOut,
        Guests,
        Status,
        GuestName,
        GuestEmail,
        GuestPhone,
        TotalAmount,
        CreatedAt,
        PricePerNight,
        PaymentMethod,
        AccountId
    )
    VALUES (
        'TEST-BK-B',
        @RoomId_B,
        '2026-07-11',
        '2026-07-13',
        2,
        'Pending',
        N'Test Guest B',
        'guestb@test.com',
        '0900000002',
        @RoomRate_B * DATEDIFF(DAY, '2026-07-11', '2026-07-13'),
        SYSDATETIME(),
        @RoomRate_B,
        NULL,
        NULL
    );
END
GO

-- TEST-BK-C: non-overlap boundary case, should succeed
DECLARE @RoomId_C INT;
DECLARE @RoomRate_C DECIMAL(18,2);

SELECT @RoomId_C = Id, @RoomRate_C = Rate
FROM Rooms
WHERE Code = 'NT-DLX-201';

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'TEST-BK-C')
BEGIN
    INSERT INTO Bookings (
        BookingCode,
        RoomId,
        CheckIn,
        CheckOut,
        Guests,
        Status,
        GuestName,
        GuestEmail,
        GuestPhone,
        TotalAmount,
        CreatedAt,
        PricePerNight,
        PaymentMethod,
        AccountId
    )
    VALUES (
        'TEST-BK-C',
        @RoomId_C,
        '2026-07-12',
        '2026-07-14',
        2,
        'Pending',
        N'Test Guest C',
        'guestc@test.com',
        '0900000003',
        @RoomRate_C * DATEDIFF(DAY, '2026-07-12', '2026-07-14'),
        SYSDATETIME(),
        @RoomRate_C,
        NULL,
        NULL
    );
END
GO

-- TEST-BK-D: used to test inactive room
DECLARE @RoomId_D INT;
DECLARE @RoomRate_D DECIMAL(18,2);

SELECT @RoomId_D = Id, @RoomRate_D = Rate
FROM Rooms
WHERE Code = 'PQ-DLX-201';

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'TEST-BK-D')
BEGIN
    INSERT INTO Bookings (
        BookingCode,
        RoomId,
        CheckIn,
        CheckOut,
        Guests,
        Status,
        GuestName,
        GuestEmail,
        GuestPhone,
        TotalAmount,
        CreatedAt,
        PricePerNight,
        PaymentMethod,
        AccountId
    )
    VALUES (
        'TEST-BK-D',
        @RoomId_D,
        '2026-08-01',
        '2026-08-03',
        2,
        'Pending',
        N'Test Guest D',
        'guestd@test.com',
        '0900000004',
        @RoomRate_D * DATEDIFF(DAY, '2026-08-01', '2026-08-03'),
        SYSDATETIME(),
        @RoomRate_D,
        NULL,
        NULL
    );
END
GO
