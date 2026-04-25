-- =============================================
-- Script: seed_more_sample_rooms.sql
-- Purpose: Add more sample rooms for testing Top Booked Room Types feature
-- Hotel: Royal Hotel (HotelId = 1)
-- =============================================

USE RoyalHotelDb;
GO

-- =========================
-- STANDARD ROOMS (5 rooms)
-- =========================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'STD-101')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('STD-101', N'Standard Room 101', N'Standard', 800000, 2, 1, 1, 800000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'STD-102')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('STD-102', N'Standard Room 102', N'Standard', 850000, 2, 1, 1, 850000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'STD-103')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('STD-103', N'Standard Room 103', N'Standard', 800000, 2, 1, 1, 800000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'STD-104')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('STD-104', N'Standard Room 104', N'Standard', 820000, 2, 1, 1, 820000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'STD-105')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('STD-105', N'Standard Room 105', N'Standard', 800000, 2, 1, 1, 800000, 'ACTIVE');
END

-- =========================
-- DELUXE ROOMS (7 rooms - already has DL-01)
-- =========================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'DLX-201')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('DLX-201', N'Deluxe Room 201', N'Deluxe', 1200000, 2, 1, 1, 1200000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'DLX-202')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('DLX-202', N'Deluxe Room 202', N'Deluxe', 1250000, 2, 1, 1, 1250000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'DLX-203')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('DLX-203', N'Deluxe Room 203', N'Deluxe', 1200000, 3, 1, 1, 1200000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'DLX-204')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('DLX-204', N'Deluxe Room 204', N'Deluxe', 1300000, 2, 1, 1, 1300000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'DLX-205')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('DLX-205', N'Deluxe Ocean View', N'Deluxe', 1400000, 2, 1, 1, 1400000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'DLX-206')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('DLX-206', N'Deluxe City View', N'Deluxe', 1150000, 2, 1, 1, 1150000, 'ACTIVE');
END

-- =========================
-- SUITE ROOMS (4 rooms - already has STE-01)
-- =========================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'STE-301')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('STE-301', N'Executive Suite 301', N'Suite', 2000000, 4, 1, 1, 2000000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'STE-302')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('STE-302', N'Family Suite 302', N'Suite', 2200000, 4, 1, 1, 2200000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'STE-303')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('STE-303', N'Presidential Suite', N'Suite', 3500000, 6, 1, 1, 3500000, 'ACTIVE');
END

-- =========================
-- PREMIUM ROOMS (3 rooms - new type)
-- =========================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'PRM-401')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('PRM-401', N'Premium Room 401', N'Premium', 1600000, 2, 1, 1, 1600000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'PRM-402')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('PRM-402', N'Premium Room 402', N'Premium', 1650000, 2, 1, 1, 1650000, 'ACTIVE');
END

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'PRM-403')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status)
    VALUES ('PRM-403', N'Premium Balcony Room', N'Premium', 1700000, 3, 1, 1, 1700000, 'ACTIVE');
END

GO

PRINT 'Sample rooms seeded successfully!';
PRINT 'Total rooms added: 19 new rooms';
PRINT 'Room Types:';
PRINT '  - Standard: 5 rooms';
PRINT '  - Deluxe: 6 new rooms (+ 1 existing = 7 total)';
PRINT '  - Suite: 3 new rooms (+ 1 existing = 4 total)';
PRINT '  - Premium: 3 rooms (new type)';
GO

-- Verify the data
SELECT 
    RoomType,
    COUNT(*) AS RoomCount,
    MIN(BasePricePerNight) AS MinPrice,
    MAX(BasePricePerNight) AS MaxPrice
FROM Rooms
GROUP BY RoomType
ORDER BY RoomType;
GO
