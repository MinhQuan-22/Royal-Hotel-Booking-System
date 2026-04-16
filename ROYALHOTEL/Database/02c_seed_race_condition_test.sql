-- 02b_seed_race_condition_test.sql
-- Prepare two overlapping bookings for race-condition demo

-- Clean old race test records first
DELETE FROM PaymentTransactions
WHERE BookingId IN (
    SELECT Id
    FROM Bookings
    WHERE BookingCode IN ('RACE-BK-1', 'RACE-BK-2')
);

DELETE FROM Bookings
WHERE BookingCode IN ('RACE-BK-1', 'RACE-BK-2');
GO

DECLARE @RoomId INT;
DECLARE @Rate DECIMAL(18,2);

SELECT @RoomId = Id, @Rate = Rate
FROM Rooms
WHERE Code = 'NT-STE-301';

IF @RoomId IS NULL
    THROW 52001, 'Room NT-STE-301 not found.', 1;

-- Booking 1
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
    'RACE-BK-1',
    @RoomId,
    '2026-09-10',
    '2026-09-12',
    2,
    'Pending',
    N'Race Guest 1',
    'race1@test.com',
    '0900001001',
    @Rate * DATEDIFF(DAY, '2026-09-10', '2026-09-12'),
    SYSDATETIME(),
    @Rate,
    NULL,
    NULL
);

-- Booking 2 (same room, overlapping dates)
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
    'RACE-BK-2',
    @RoomId,
    '2026-09-11',
    '2026-09-13',
    2,
    'Pending',
    N'Race Guest 2',
    'race2@test.com',
    '0900001002',
    @Rate * DATEDIFF(DAY, '2026-09-11', '2026-09-13'),
    SYSDATETIME(),
    @Rate,
    NULL,
    NULL
);
GO

SELECT Id, BookingCode, RoomId, CheckIn, CheckOut, Status
FROM Bookings
WHERE BookingCode IN ('RACE-BK-1', 'RACE-BK-2')
ORDER BY BookingCode;
