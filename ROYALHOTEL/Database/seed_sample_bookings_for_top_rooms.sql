-- =============================================
-- Script: seed_sample_bookings_for_top_rooms.sql
-- Purpose: Add sample bookings to test Top Booked Room Types feature
-- Strategy: Create different booking counts for each room type
--   - Deluxe: Most bookings (should be #1)
--   - Suite: Medium bookings (should be #2)
--   - Premium: Few bookings (should be #3)
--   - Standard: Very few bookings (should NOT be in top 3)
-- =============================================

USE RoyalHotelDb;
GO

DECLARE @Today DATETIME2 = CAST(GETDATE() AS DATE);
DECLARE @BookingCounter INT = 1;

-- =========================
-- DELUXE BOOKINGS (15 bookings - MOST)
-- =========================

-- Deluxe Room bookings (past completed bookings)
INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, CreatedAt)
SELECT 
    'BK-DLX-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4),
    r.Id,
    DATEADD(DAY, -30, @Today),
    DATEADD(DAY, -28, @Today),
    2,
    'Completed',
    N'Nguyễn Văn ' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS NVARCHAR),
    'guest' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR) + '@example.com',
    '0901234' + RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 3),
    r.BasePricePerNight * 2,
    r.BasePricePerNight,
    DATEADD(DAY, -35, @Today)
FROM Rooms r
WHERE r.RoomType = 'Deluxe' AND r.Code LIKE 'DLX-%'
AND NOT EXISTS (
    SELECT 1 FROM Bookings b 
    WHERE b.RoomId = r.Id 
    AND b.BookingCode = 'BK-DLX-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4)
);

-- More Deluxe bookings (confirmed future bookings)
INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, CreatedAt)
SELECT 
    'BK-DLX-F-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4),
    r.Id,
    DATEADD(DAY, 10, @Today),
    DATEADD(DAY, 13, @Today),
    2,
    'Confirmed',
    N'Trần Thị ' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS NVARCHAR),
    'tran' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR) + '@example.com',
    '0912345' + RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 3),
    r.BasePricePerNight * 3,
    r.BasePricePerNight,
    @Today
FROM Rooms r
WHERE r.RoomType = 'Deluxe' AND r.Code LIKE 'DLX-%'
AND NOT EXISTS (
    SELECT 1 FROM Bookings b 
    WHERE b.RoomId = r.Id 
    AND b.BookingCode = 'BK-DLX-F-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4)
);

-- Even more Deluxe bookings (checked in)
INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, CreatedAt)
SELECT TOP 2
    'BK-DLX-CI-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4),
    r.Id,
    DATEADD(DAY, -1, @Today),
    DATEADD(DAY, 2, @Today),
    2,
    'CheckedIn',
    N'Lê Văn ' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS NVARCHAR),
    'le' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR) + '@example.com',
    '0923456' + RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 3),
    r.BasePricePerNight * 3,
    r.BasePricePerNight,
    DATEADD(DAY, -2, @Today)
FROM Rooms r
WHERE r.RoomType = 'Deluxe' AND r.Code LIKE 'DLX-%'
AND NOT EXISTS (
    SELECT 1 FROM Bookings b 
    WHERE b.RoomId = r.Id 
    AND b.BookingCode = 'BK-DLX-CI-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4)
);

-- =========================
-- SUITE BOOKINGS (10 bookings - MEDIUM)
-- =========================

-- Suite bookings (completed)
INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, CreatedAt)
SELECT 
    'BK-STE-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4),
    r.Id,
    DATEADD(DAY, -25, @Today),
    DATEADD(DAY, -22, @Today),
    4,
    'Completed',
    N'Phạm Văn ' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS NVARCHAR),
    'pham' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR) + '@example.com',
    '0934567' + RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 3),
    r.BasePricePerNight * 3,
    r.BasePricePerNight,
    DATEADD(DAY, -30, @Today)
FROM Rooms r
WHERE r.RoomType = 'Suite'
AND NOT EXISTS (
    SELECT 1 FROM Bookings b 
    WHERE b.RoomId = r.Id 
    AND b.BookingCode = 'BK-STE-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4)
);

-- More Suite bookings (confirmed)
INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, CreatedAt)
SELECT 
    'BK-STE-F-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4),
    r.Id,
    DATEADD(DAY, 15, @Today),
    DATEADD(DAY, 18, @Today),
    4,
    'Confirmed',
    N'Hoàng Thị ' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS NVARCHAR),
    'hoang' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR) + '@example.com',
    '0945678' + RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 3),
    r.BasePricePerNight * 3,
    r.BasePricePerNight,
    @Today
FROM Rooms r
WHERE r.RoomType = 'Suite'
AND NOT EXISTS (
    SELECT 1 FROM Bookings b 
    WHERE b.RoomId = r.Id 
    AND b.BookingCode = 'BK-STE-F-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4)
);

-- =========================
-- PREMIUM BOOKINGS (6 bookings - FEW)
-- =========================

-- Premium bookings (completed)
INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, CreatedAt)
SELECT 
    'BK-PRM-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4),
    r.Id,
    DATEADD(DAY, -20, @Today),
    DATEADD(DAY, -18, @Today),
    2,
    'Completed',
    N'Vũ Văn ' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS NVARCHAR),
    'vu' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR) + '@example.com',
    '0956789' + RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 3),
    r.BasePricePerNight * 2,
    r.BasePricePerNight,
    DATEADD(DAY, -25, @Today)
FROM Rooms r
WHERE r.RoomType = 'Premium'
AND NOT EXISTS (
    SELECT 1 FROM Bookings b 
    WHERE b.RoomId = r.Id 
    AND b.BookingCode = 'BK-PRM-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4)
);

-- More Premium bookings (confirmed)
INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, CreatedAt)
SELECT 
    'BK-PRM-F-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4),
    r.Id,
    DATEADD(DAY, 20, @Today),
    DATEADD(DAY, 22, @Today),
    2,
    'Confirmed',
    N'Đỗ Thị ' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS NVARCHAR),
    'do' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR) + '@example.com',
    '0967890' + RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 3),
    r.BasePricePerNight * 2,
    r.BasePricePerNight,
    @Today
FROM Rooms r
WHERE r.RoomType = 'Premium'
AND NOT EXISTS (
    SELECT 1 FROM Bookings b 
    WHERE b.RoomId = r.Id 
    AND b.BookingCode = 'BK-PRM-F-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4)
);

-- =========================
-- STANDARD BOOKINGS (2 bookings - VERY FEW, should NOT be in top 3)
-- =========================

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, CreatedAt)
SELECT TOP 2
    'BK-STD-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4),
    r.Id,
    DATEADD(DAY, -15, @Today),
    DATEADD(DAY, -13, @Today),
    2,
    'Completed',
    N'Bùi Văn ' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS NVARCHAR),
    'bui' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR) + '@example.com',
    '0978901' + RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 3),
    r.BasePricePerNight * 2,
    r.BasePricePerNight,
    DATEADD(DAY, -20, @Today)
FROM Rooms r
WHERE r.RoomType = 'Standard'
AND NOT EXISTS (
    SELECT 1 FROM Bookings b 
    WHERE b.RoomId = r.Id 
    AND b.BookingCode = 'BK-STD-' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY r.Id) AS VARCHAR), 4)
);

GO

PRINT 'Sample bookings seeded successfully!';
PRINT '';
PRINT 'Booking Distribution:';
PRINT '  - Deluxe: ~15 bookings (MOST - should be #1)';
PRINT '  - Suite: ~10 bookings (MEDIUM - should be #2)';
PRINT '  - Premium: ~6 bookings (FEW - should be #3)';
PRINT '  - Standard: ~2 bookings (VERY FEW - should NOT be in top 3)';
PRINT '';
PRINT 'Expected Top 3 Room Types:';
PRINT '  1. Deluxe';
PRINT '  2. Suite';
PRINT '  3. Premium';
GO

-- Verify by calling the stored procedure
PRINT '';
PRINT 'Actual Top 3 from stored procedure:';
EXEC dbo.sp_GetTopBookedRoomTypes;
GO

-- Show booking counts by room type
PRINT '';
PRINT 'Booking counts by room type (all statuses):';
SELECT 
    r.RoomType,
    COUNT(b.Id) AS TotalBookings,
    SUM(CASE WHEN b.Status IN ('Confirmed', 'CheckedIn', 'CheckedOut', 'Completed') THEN 1 ELSE 0 END) AS ValidBookings
FROM Bookings b
INNER JOIN Rooms r ON r.Id = b.RoomId
GROUP BY r.RoomType
ORDER BY ValidBookings DESC;
GO
