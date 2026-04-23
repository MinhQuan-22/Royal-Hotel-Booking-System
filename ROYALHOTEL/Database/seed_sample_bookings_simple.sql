-- =============================================
-- Script: seed_sample_bookings_simple.sql
-- Purpose: Add sample bookings to test Top Booked Room Types feature
-- =============================================

USE RoyalHotelDb;
GO

DECLARE @Today DATETIME2 = CAST(GETDATE() AS DATE);

-- =========================
-- DELUXE BOOKINGS (Most bookings - should be #1)
-- =========================

-- Get Deluxe room IDs
DECLARE @DLX1 INT = (SELECT Id FROM Rooms WHERE Code = 'DLX-201');
DECLARE @DLX2 INT = (SELECT Id FROM Rooms WHERE Code = 'DLX-202');
DECLARE @DLX3 INT = (SELECT Id FROM Rooms WHERE Code = 'DLX-203');
DECLARE @DLX4 INT = (SELECT Id FROM Rooms WHERE Code = 'DLX-204');
DECLARE @DLX5 INT = (SELECT Id FROM Rooms WHERE Code = 'DLX-205');

-- Deluxe bookings (15 total)
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-001')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-001', @DLX1, DATEADD(DAY, -30, @Today), DATEADD(DAY, -28, @Today), 2, 'Completed', N'Nguyễn Văn A', 'a@example.com', 2400000, 1200000, DATEADD(DAY, -35, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-002')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-002', @DLX2, DATEADD(DAY, -25, @Today), DATEADD(DAY, -23, @Today), 2, 'Completed', N'Trần Thị B', 'b@example.com', 2500000, 1250000, DATEADD(DAY, -30, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-003')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-003', @DLX3, DATEADD(DAY, -20, @Today), DATEADD(DAY, -18, @Today), 2, 'Completed', N'Lê Văn C', 'c@example.com', 2400000, 1200000, DATEADD(DAY, -25, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-004')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-004', @DLX4, DATEADD(DAY, -15, @Today), DATEADD(DAY, -13, @Today), 2, 'Completed', N'Phạm Thị D', 'd@example.com', 2600000, 1300000, DATEADD(DAY, -20, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-005')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-005', @DLX5, DATEADD(DAY, -10, @Today), DATEADD(DAY, -8, @Today), 2, 'Completed', N'Hoàng Văn E', 'e@example.com', 2800000, 1400000, DATEADD(DAY, -15, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-006')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-006', @DLX1, DATEADD(DAY, 10, @Today), DATEADD(DAY, 13, @Today), 2, 'Confirmed', N'Vũ Thị F', 'f@example.com', 3600000, 1200000, @Today);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-007')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-007', @DLX2, DATEADD(DAY, 15, @Today), DATEADD(DAY, 18, @Today), 2, 'Confirmed', N'Đỗ Văn G', 'g@example.com', 3750000, 1250000, @Today);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-008')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-008', @DLX3, DATEADD(DAY, 20, @Today), DATEADD(DAY, 22, @Today), 2, 'Confirmed', N'Bùi Thị H', 'h@example.com', 2400000, 1200000, @Today);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-009')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-009', @DLX4, DATEADD(DAY, -1, @Today), DATEADD(DAY, 2, @Today), 2, 'CheckedIn', N'Đinh Văn I', 'i@example.com', 3900000, 1300000, DATEADD(DAY, -2, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-010')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-010', @DLX5, DATEADD(DAY, -5, @Today), DATEADD(DAY, -3, @Today), 2, 'CheckedOut', N'Mai Thị J', 'j@example.com', 2800000, 1400000, DATEADD(DAY, -10, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-011')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-011', @DLX1, DATEADD(DAY, -40, @Today), DATEADD(DAY, -38, @Today), 2, 'Completed', N'Lý Văn K', 'k@example.com', 2400000, 1200000, DATEADD(DAY, -45, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-012')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-012', @DLX2, DATEADD(DAY, -35, @Today), DATEADD(DAY, -33, @Today), 2, 'Completed', N'Dương Thị L', 'l@example.com', 2500000, 1250000, DATEADD(DAY, -40, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-013')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-013', @DLX3, DATEADD(DAY, 25, @Today), DATEADD(DAY, 27, @Today), 2, 'Confirmed', N'Hồ Văn M', 'm@example.com', 2400000, 1200000, @Today);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-014')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-014', @DLX4, DATEADD(DAY, 30, @Today), DATEADD(DAY, 32, @Today), 2, 'Confirmed', N'Tô Thị N', 'n@example.com', 2600000, 1300000, @Today);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-DLX-015')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-DLX-015', @DLX5, DATEADD(DAY, 35, @Today), DATEADD(DAY, 37, @Today), 2, 'Confirmed', N'Phan Văn O', 'o@example.com', 2800000, 1400000, @Today);

-- =========================
-- SUITE BOOKINGS (Medium bookings - should be #2)
-- =========================

DECLARE @STE1 INT = (SELECT Id FROM Rooms WHERE Code = 'STE-01');
DECLARE @STE2 INT = (SELECT Id FROM Rooms WHERE Code = 'STE-301');
DECLARE @STE3 INT = (SELECT Id FROM Rooms WHERE Code = 'STE-302');
DECLARE @STE4 INT = (SELECT Id FROM Rooms WHERE Code = 'STE-303');

-- Suite bookings (10 total)
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STE-001')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STE-001', @STE1, DATEADD(DAY, -30, @Today), DATEADD(DAY, -27, @Today), 4, 'Completed', N'Cao Văn P', 'p@example.com', 6000000, 2000000, DATEADD(DAY, -35, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STE-002')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STE-002', @STE2, DATEADD(DAY, -25, @Today), DATEADD(DAY, -22, @Today), 4, 'Completed', N'Tạ Thị Q', 'q@example.com', 6000000, 2000000, DATEADD(DAY, -30, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STE-003')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STE-003', @STE3, DATEADD(DAY, -20, @Today), DATEADD(DAY, -17, @Today), 4, 'Completed', N'Ông Văn R', 'r@example.com', 6600000, 2200000, DATEADD(DAY, -25, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STE-004')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STE-004', @STE4, DATEADD(DAY, -15, @Today), DATEADD(DAY, -12, @Today), 6, 'Completed', N'Từ Thị S', 's@example.com', 10500000, 3500000, DATEADD(DAY, -20, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STE-005')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STE-005', @STE1, DATEADD(DAY, 10, @Today), DATEADD(DAY, 13, @Today), 4, 'Confirmed', N'Lâm Văn T', 't@example.com', 6000000, 2000000, @Today);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STE-006')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STE-006', @STE2, DATEADD(DAY, 15, @Today), DATEADD(DAY, 18, @Today), 4, 'Confirmed', N'Quách Thị U', 'u@example.com', 6000000, 2000000, @Today);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STE-007')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STE-007', @STE3, DATEADD(DAY, 20, @Today), DATEADD(DAY, 23, @Today), 4, 'Confirmed', N'Nghiêm Văn V', 'v@example.com', 6600000, 2200000, @Today);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STE-008')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STE-008', @STE4, DATEADD(DAY, -1, @Today), DATEADD(DAY, 2, @Today), 6, 'CheckedIn', N'Ứng Thị W', 'w@example.com', 10500000, 3500000, DATEADD(DAY, -2, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STE-009')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STE-009', @STE1, DATEADD(DAY, -40, @Today), DATEADD(DAY, -37, @Today), 4, 'Completed', N'Khúc Văn X', 'x@example.com', 6000000, 2000000, DATEADD(DAY, -45, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STE-010')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STE-010', @STE2, DATEADD(DAY, 25, @Today), DATEADD(DAY, 28, @Today), 4, 'Confirmed', N'Kiều Thị Y', 'y@example.com', 6000000, 2000000, @Today);

-- =========================
-- PREMIUM BOOKINGS (Few bookings - should be #3)
-- =========================

DECLARE @PRM1 INT = (SELECT Id FROM Rooms WHERE Code = 'PRM-401');
DECLARE @PRM2 INT = (SELECT Id FROM Rooms WHERE Code = 'PRM-402');
DECLARE @PRM3 INT = (SELECT Id FROM Rooms WHERE Code = 'PRM-403');

-- Premium bookings (6 total)
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-PRM-001')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-PRM-001', @PRM1, DATEADD(DAY, -30, @Today), DATEADD(DAY, -28, @Today), 2, 'Completed', N'An Văn Z', 'z@example.com', 3200000, 1600000, DATEADD(DAY, -35, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-PRM-002')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-PRM-002', @PRM2, DATEADD(DAY, -25, @Today), DATEADD(DAY, -23, @Today), 2, 'Completed', N'Bình Thị AA', 'aa@example.com', 3300000, 1650000, DATEADD(DAY, -30, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-PRM-003')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-PRM-003', @PRM3, DATEADD(DAY, -20, @Today), DATEADD(DAY, -18, @Today), 3, 'Completed', N'Cường Văn BB', 'bb@example.com', 3400000, 1700000, DATEADD(DAY, -25, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-PRM-004')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-PRM-004', @PRM1, DATEADD(DAY, 10, @Today), DATEADD(DAY, 12, @Today), 2, 'Confirmed', N'Dũng Thị CC', 'cc@example.com', 3200000, 1600000, @Today);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-PRM-005')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-PRM-005', @PRM2, DATEADD(DAY, 15, @Today), DATEADD(DAY, 17, @Today), 2, 'Confirmed', N'Hùng Văn DD', 'dd@example.com', 3300000, 1650000, @Today);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-PRM-006')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-PRM-006', @PRM3, DATEADD(DAY, -1, @Today), DATEADD(DAY, 1, @Today), 3, 'CheckedIn', N'Khoa Thị EE', 'ee@example.com', 3400000, 1700000, DATEADD(DAY, -2, @Today));

-- =========================
-- STANDARD BOOKINGS (Very few - should NOT be in top 3)
-- =========================

DECLARE @STD1 INT = (SELECT Id FROM Rooms WHERE Code = 'STD-101');
DECLARE @STD2 INT = (SELECT Id FROM Rooms WHERE Code = 'STD-102');

-- Standard bookings (2 total)
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STD-001')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STD-001', @STD1, DATEADD(DAY, -20, @Today), DATEADD(DAY, -18, @Today), 2, 'Completed', N'Long Văn FF', 'ff@example.com', 1600000, 800000, DATEADD(DAY, -25, @Today));

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-STD-002')
    INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, TotalAmount, PricePerNight, CreatedAt)
    VALUES ('BK-STD-002', @STD2, DATEADD(DAY, -15, @Today), DATEADD(DAY, -13, @Today), 2, 'Completed', N'Minh Thị GG', 'gg@example.com', 1700000, 850000, DATEADD(DAY, -20, @Today));

GO

PRINT '========================================';
PRINT 'Sample bookings seeded successfully!';
PRINT '========================================';
PRINT '';
PRINT 'Booking Distribution:';
PRINT '  - Deluxe: 15 bookings (MOST)';
PRINT '  - Suite: 10 bookings (MEDIUM)';
PRINT '  - Premium: 6 bookings (FEW)';
PRINT '  - Standard: 2 bookings (VERY FEW)';
PRINT '';
PRINT 'Expected Top 3:';
PRINT '  1. Deluxe';
PRINT '  2. Suite';
PRINT '  3. Premium';
PRINT '';
PRINT '========================================';
GO

-- Verify by calling the stored procedure
PRINT 'Actual Top 3 from stored procedure:';
PRINT '========================================';
EXEC dbo.sp_GetTopBookedRoomTypes;
GO
