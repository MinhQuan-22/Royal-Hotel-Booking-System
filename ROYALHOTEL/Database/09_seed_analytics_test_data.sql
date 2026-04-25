-- 09_seed_analytics_test_data.sql
-- Comprehensive seed data for SQL Trigger, Analytics, Audit & Report Integration
-- Purpose: Create test data spanning 8 quarters (Q1 2025 - Q4 2026) for analytics validation
-- Requirements: Requirement 5 - Comprehensive Test Data Generation

PRINT '========================================================================';
PRINT 'SEED DATA GENERATION FOR ANALYTICS TESTING';
PRINT 'Spec: SQL Trigger, Analytics, Audit & Report Integration';
PRINT '========================================================================';
PRINT '';

-- =============================================================================
-- SECTION 1: CREATE HOTELS (3 hotels in different cities)
-- =============================================================================

PRINT 'SECTION 1: Creating hotels...';

-- Hotel 1: New York
IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 1)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, Name, City)
    VALUES (1, N'Royal Hotel New York', N'New York');
    SET IDENTITY_INSERT Hotels OFF;
    PRINT '  ✓ Hotel 1 (New York) created.';
END
ELSE
BEGIN
    UPDATE Hotels
    SET Name = N'Royal Hotel New York',
        City = N'New York'
    WHERE Id = 1;
    PRINT '  ✓ Hotel 1 (New York) updated.';
END
GO

-- Hotel 4: Los Angeles
IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 4)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, Name, City)
    VALUES (4, N'Royal Hotel Los Angeles', N'Los Angeles');
    SET IDENTITY_INSERT Hotels OFF;
    PRINT '  ✓ Hotel 4 (Los Angeles) created.';
END
ELSE
BEGIN
    PRINT '  ✓ Hotel 4 (Los Angeles) already exists.';
END
GO

-- Hotel 5: Chicago
IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 5)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, Name, City)
    VALUES (5, N'Royal Hotel Chicago', N'Chicago');
    SET IDENTITY_INSERT Hotels OFF;
    PRINT '  ✓ Hotel 5 (Chicago) created.';
END
ELSE
BEGIN
    PRINT '  ✓ Hotel 5 (Chicago) already exists.';
END
GO

PRINT '';
PRINT 'SECTION 1 COMPLETE: 3 hotels created/updated.';
PRINT '';

-- =============================================================================
-- SECTION 2: CREATE ROOMS (12 rooms distributed across 3 hotels)
-- =============================================================================

PRINT 'SECTION 2: Creating rooms...';

-- Hotel 1 (New York) - 4 rooms
IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NY-DLX-101')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('NY-DLX-101', N'New York Deluxe Room 101', N'Deluxe', 2500000, 2, 1, 1, 2500000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room NY-DLX-101 created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NY-DLX-102')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('NY-DLX-102', N'New York Deluxe Room 102', N'Deluxe', 2500000, 2, 1, 1, 2500000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room NY-DLX-102 created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NY-STE-201')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('NY-STE-201', N'New York Suite 201', N'Suite', 4000000, 4, 1, 1, 4000000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room NY-STE-201 created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NY-STE-202')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('NY-STE-202', N'New York Suite 202', N'Suite', 4000000, 4, 1, 1, 4000000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room NY-STE-202 created.';
END
GO

-- Hotel 4 (Los Angeles) - 4 rooms
IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'LA-DLX-101')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('LA-DLX-101', N'LA Deluxe Ocean View 101', N'Deluxe', 3000000, 2, 1, 4, 3000000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room LA-DLX-101 created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'LA-DLX-102')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('LA-DLX-102', N'LA Deluxe Ocean View 102', N'Deluxe', 3000000, 2, 1, 4, 3000000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room LA-DLX-102 created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'LA-STE-301')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('LA-STE-301', N'LA Premium Suite 301', N'Suite', 5000000, 4, 1, 4, 5000000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room LA-STE-301 created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'LA-STE-302')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('LA-STE-302', N'LA Premium Suite 302', N'Suite', 5000000, 4, 1, 4, 5000000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room LA-STE-302 created.';
END
GO

-- Hotel 5 (Chicago) - 4 rooms
IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'CH-DLX-101')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('CH-DLX-101', N'Chicago Deluxe Room 101', N'Deluxe', 2200000, 2, 1, 5, 2200000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room CH-DLX-101 created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'CH-DLX-102')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('CH-DLX-102', N'Chicago Deluxe Room 102', N'Deluxe', 2200000, 2, 1, 5, 2200000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room CH-DLX-102 created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'CH-STE-201')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('CH-STE-201', N'Chicago Executive Suite 201', N'Suite', 3500000, 4, 1, 5, 3500000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room CH-STE-201 created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'CH-STE-202')
BEGIN
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, HotelId, Rate, Status, CreatedAt, UpdatedAt)
    VALUES ('CH-STE-202', N'Chicago Executive Suite 202', N'Suite', 3500000, 4, 1, 5, 3500000, 'ACTIVE', SYSDATETIME(), SYSDATETIME());
    PRINT '  ✓ Room CH-STE-202 created.';
END
GO

PRINT '';
PRINT 'SECTION 2 COMPLETE: 12 rooms created.';
PRINT '';

-- =============================================================================
-- SECTION 3: CREATE BOOKINGS (8 quarters: Q1 2025 - Q4 2026)
-- Each hotel needs 5+ completed bookings per quarter for 4 quarters
-- =============================================================================

PRINT 'SECTION 3: Creating bookings for 8 quarters...';
PRINT '';

-- NOTE: Due to SQL Server limitations with variables in GO blocks,
-- we'll use inline subqueries to get RoomIds

-- ============= Q1 2025 (Jan-Mar) =============
PRINT 'Creating Q1 2025 bookings...';

-- Hotel 1 (New York) - Q1 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-NY-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2025-01-15', '2025-01-18', 2, 'Completed', 7500000, 'BK-2025Q1-NY-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-NY-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2025-01-20', '2025-01-23', 2, 'Completed', 7500000, 'BK-2025Q1-NY-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-NY-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-201'), '2025-02-10', '2025-02-14', 4, 'Completed', 16000000, 'BK-2025Q1-NY-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-NY-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-202'), '2025-02-15', '2025-02-19', 4, 'Completed', 16000000, 'BK-2025Q1-NY-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-NY-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2025-03-10', '2025-03-13', 2, 'Completed', 7500000, 'BK-2025Q1-NY-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-NY-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2025-03-15', '2025-03-18', 2, 'Completed', 7500000, 'BK-2025Q1-NY-006', 1);

-- Hotel 4 (Los Angeles) - Q1 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-LA-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2025-01-10', '2025-01-13', 2, 'Completed', 9000000, 'BK-2025Q1-LA-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-LA-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2025-01-15', '2025-01-18', 2, 'Completed', 9000000, 'BK-2025Q1-LA-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-LA-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-301'), '2025-02-05', '2025-02-10', 4, 'Completed', 25000000, 'BK-2025Q1-LA-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-LA-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-302'), '2025-02-12', '2025-02-17', 4, 'Completed', 25000000, 'BK-2025Q1-LA-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-LA-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2025-03-05', '2025-03-08', 2, 'Completed', 9000000, 'BK-2025Q1-LA-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-LA-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2025-03-10', '2025-03-13', 2, 'Completed', 9000000, 'BK-2025Q1-LA-006', 1);

-- Hotel 5 (Chicago) - Q1 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-CH-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2025-01-12', '2025-01-15', 2, 'Completed', 6600000, 'BK-2025Q1-CH-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-CH-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2025-01-18', '2025-01-21', 2, 'Completed', 6600000, 'BK-2025Q1-CH-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-CH-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-201'), '2025-02-08', '2025-02-12', 4, 'Completed', 14000000, 'BK-2025Q1-CH-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-CH-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-202'), '2025-02-14', '2025-02-18', 4, 'Completed', 14000000, 'BK-2025Q1-CH-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-CH-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2025-03-08', '2025-03-11', 2, 'Completed', 6600000, 'BK-2025Q1-CH-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q1-CH-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2025-03-12', '2025-03-15', 2, 'Completed', 6600000, 'BK-2025Q1-CH-006', 1);

PRINT '  ✓ Q1 2025 bookings created (18 bookings).';

-- ============= Q2 2025 (Apr-Jun) =============
PRINT 'Creating Q2 2025 bookings...';

-- Hotel 1 (New York) - Q2 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-NY-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2025-04-10', '2025-04-13', 2, 'Completed', 7500000, 'BK-2025Q2-NY-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-NY-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2025-04-15', '2025-04-18', 2, 'Completed', 7500000, 'BK-2025Q2-NY-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-NY-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-201'), '2025-05-10', '2025-05-14', 4, 'Completed', 16000000, 'BK-2025Q2-NY-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-NY-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-202'), '2025-05-15', '2025-05-19', 4, 'Completed', 16000000, 'BK-2025Q2-NY-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-NY-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2025-06-10', '2025-06-13', 2, 'Completed', 7500000, 'BK-2025Q2-NY-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-NY-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2025-06-15', '2025-06-18', 2, 'Completed', 7500000, 'BK-2025Q2-NY-006', 1);

-- Hotel 4 (Los Angeles) - Q2 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-LA-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2025-04-08', '2025-04-11', 2, 'Completed', 9000000, 'BK-2025Q2-LA-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-LA-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2025-04-12', '2025-04-15', 2, 'Completed', 9000000, 'BK-2025Q2-LA-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-LA-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-301'), '2025-05-05', '2025-05-10', 4, 'Completed', 25000000, 'BK-2025Q2-LA-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-LA-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-302'), '2025-05-12', '2025-05-17', 4, 'Completed', 25000000, 'BK-2025Q2-LA-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-LA-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2025-06-05', '2025-06-08', 2, 'Completed', 9000000, 'BK-2025Q2-LA-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-LA-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2025-06-10', '2025-06-13', 2, 'Completed', 9000000, 'BK-2025Q2-LA-006', 1);

-- Hotel 5 (Chicago) - Q2 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-CH-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2025-04-12', '2025-04-15', 2, 'Completed', 6600000, 'BK-2025Q2-CH-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-CH-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2025-04-18', '2025-04-21', 2, 'Completed', 6600000, 'BK-2025Q2-CH-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-CH-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-201'), '2025-05-08', '2025-05-12', 4, 'Completed', 14000000, 'BK-2025Q2-CH-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-CH-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-202'), '2025-05-14', '2025-05-18', 4, 'Completed', 14000000, 'BK-2025Q2-CH-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-CH-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2025-06-08', '2025-06-11', 2, 'Completed', 6600000, 'BK-2025Q2-CH-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q2-CH-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2025-06-12', '2025-06-15', 2, 'Completed', 6600000, 'BK-2025Q2-CH-006', 1);

PRINT '  ✓ Q2 2025 bookings created (18 bookings).';

-- ============= Q3 2025 (Jul-Sep) =============
PRINT 'Creating Q3 2025 bookings...';

-- Hotel 1 (New York) - Q3 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-NY-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2025-07-10', '2025-07-13', 2, 'Completed', 7500000, 'BK-2025Q3-NY-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-NY-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2025-07-15', '2025-07-18', 2, 'Completed', 7500000, 'BK-2025Q3-NY-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-NY-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-201'), '2025-08-10', '2025-08-14', 4, 'Completed', 16000000, 'BK-2025Q3-NY-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-NY-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-202'), '2025-08-15', '2025-08-19', 4, 'Completed', 16000000, 'BK-2025Q3-NY-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-NY-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2025-09-10', '2025-09-13', 2, 'Completed', 7500000, 'BK-2025Q3-NY-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-NY-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2025-09-15', '2025-09-18', 2, 'Completed', 7500000, 'BK-2025Q3-NY-006', 1);

-- Hotel 4 (Los Angeles) - Q3 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-LA-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2025-07-08', '2025-07-11', 2, 'Completed', 9000000, 'BK-2025Q3-LA-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-LA-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2025-07-12', '2025-07-15', 2, 'Completed', 9000000, 'BK-2025Q3-LA-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-LA-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-301'), '2025-08-05', '2025-08-10', 4, 'Completed', 25000000, 'BK-2025Q3-LA-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-LA-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-302'), '2025-08-12', '2025-08-17', 4, 'Completed', 25000000, 'BK-2025Q3-LA-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-LA-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2025-09-05', '2025-09-08', 2, 'Completed', 9000000, 'BK-2025Q3-LA-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-LA-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2025-09-10', '2025-09-13', 2, 'Completed', 9000000, 'BK-2025Q3-LA-006', 1);

-- Hotel 5 (Chicago) - Q3 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-CH-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2025-07-12', '2025-07-15', 2, 'Completed', 6600000, 'BK-2025Q3-CH-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-CH-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2025-07-18', '2025-07-21', 2, 'Completed', 6600000, 'BK-2025Q3-CH-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-CH-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-201'), '2025-08-08', '2025-08-12', 4, 'Completed', 14000000, 'BK-2025Q3-CH-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-CH-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-202'), '2025-08-14', '2025-08-18', 4, 'Completed', 14000000, 'BK-2025Q3-CH-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-CH-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2025-09-08', '2025-09-11', 2, 'Completed', 6600000, 'BK-2025Q3-CH-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q3-CH-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2025-09-12', '2025-09-15', 2, 'Completed', 6600000, 'BK-2025Q3-CH-006', 1);

PRINT '  ✓ Q3 2025 bookings created (18 bookings).';

-- ============= Q4 2025 (Oct-Dec) =============
PRINT 'Creating Q4 2025 bookings...';

-- Hotel 1 (New York) - Q4 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-NY-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2025-10-10', '2025-10-13', 2, 'Completed', 7500000, 'BK-2025Q4-NY-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-NY-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2025-10-15', '2025-10-18', 2, 'Completed', 7500000, 'BK-2025Q4-NY-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-NY-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-201'), '2025-11-10', '2025-11-14', 4, 'Completed', 16000000, 'BK-2025Q4-NY-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-NY-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-202'), '2025-11-15', '2025-11-19', 4, 'Completed', 16000000, 'BK-2025Q4-NY-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-NY-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2025-12-10', '2025-12-13', 2, 'Completed', 7500000, 'BK-2025Q4-NY-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-NY-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2025-12-15', '2025-12-18', 2, 'Completed', 7500000, 'BK-2025Q4-NY-006', 1);

-- Hotel 4 (Los Angeles) - Q4 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-LA-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2025-10-08', '2025-10-11', 2, 'Completed', 9000000, 'BK-2025Q4-LA-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-LA-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2025-10-12', '2025-10-15', 2, 'Completed', 9000000, 'BK-2025Q4-LA-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-LA-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-301'), '2025-11-05', '2025-11-10', 4, 'Completed', 25000000, 'BK-2025Q4-LA-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-LA-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-302'), '2025-11-12', '2025-11-17', 4, 'Completed', 25000000, 'BK-2025Q4-LA-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-LA-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2025-12-05', '2025-12-08', 2, 'Completed', 9000000, 'BK-2025Q4-LA-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-LA-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2025-12-10', '2025-12-13', 2, 'Completed', 9000000, 'BK-2025Q4-LA-006', 1);

-- Hotel 5 (Chicago) - Q4 2025
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-CH-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2025-10-12', '2025-10-15', 2, 'Completed', 6600000, 'BK-2025Q4-CH-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-CH-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2025-10-18', '2025-10-21', 2, 'Completed', 6600000, 'BK-2025Q4-CH-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-CH-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-201'), '2025-11-08', '2025-11-12', 4, 'Completed', 14000000, 'BK-2025Q4-CH-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-CH-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-202'), '2025-11-14', '2025-11-18', 4, 'Completed', 14000000, 'BK-2025Q4-CH-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-CH-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2025-12-08', '2025-12-11', 2, 'Completed', 6600000, 'BK-2025Q4-CH-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2025Q4-CH-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2025-12-12', '2025-12-15', 2, 'Completed', 6600000, 'BK-2025Q4-CH-006', 1);

PRINT '  ✓ Q4 2025 bookings created (18 bookings).';

-- ============= Q1 2026 (Jan-Mar) =============
PRINT 'Creating Q1 2026 bookings...';

-- Hotel 1 (New York) - Q1 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-NY-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2026-01-15', '2026-01-18', 2, 'Completed', 7500000, 'BK-2026Q1-NY-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-NY-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2026-01-20', '2026-01-23', 2, 'Completed', 7500000, 'BK-2026Q1-NY-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-NY-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-201'), '2026-02-10', '2026-02-14', 4, 'Completed', 16000000, 'BK-2026Q1-NY-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-NY-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-202'), '2026-02-15', '2026-02-19', 4, 'Completed', 16000000, 'BK-2026Q1-NY-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-NY-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2026-03-10', '2026-03-13', 2, 'Completed', 7500000, 'BK-2026Q1-NY-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-NY-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2026-03-15', '2026-03-18', 2, 'Completed', 7500000, 'BK-2026Q1-NY-006', 1);

-- Hotel 4 (Los Angeles) - Q1 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-LA-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2026-01-10', '2026-01-13', 2, 'Completed', 9000000, 'BK-2026Q1-LA-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-LA-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2026-01-15', '2026-01-18', 2, 'Completed', 9000000, 'BK-2026Q1-LA-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-LA-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-301'), '2026-02-05', '2026-02-10', 4, 'Completed', 25000000, 'BK-2026Q1-LA-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-LA-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-302'), '2026-02-12', '2026-02-17', 4, 'Completed', 25000000, 'BK-2026Q1-LA-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-LA-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2026-03-05', '2026-03-08', 2, 'Completed', 9000000, 'BK-2026Q1-LA-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-LA-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2026-03-10', '2026-03-13', 2, 'Completed', 9000000, 'BK-2026Q1-LA-006', 1);

-- Hotel 5 (Chicago) - Q1 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-CH-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2026-01-12', '2026-01-15', 2, 'Completed', 6600000, 'BK-2026Q1-CH-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-CH-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2026-01-18', '2026-01-21', 2, 'Completed', 6600000, 'BK-2026Q1-CH-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-CH-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-201'), '2026-02-08', '2026-02-12', 4, 'Completed', 14000000, 'BK-2026Q1-CH-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-CH-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-202'), '2026-02-14', '2026-02-18', 4, 'Completed', 14000000, 'BK-2026Q1-CH-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-CH-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2026-03-08', '2026-03-11', 2, 'Completed', 6600000, 'BK-2026Q1-CH-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q1-CH-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2026-03-12', '2026-03-15', 2, 'Completed', 6600000, 'BK-2026Q1-CH-006', 1);

PRINT '  ✓ Q1 2026 bookings created (18 bookings).';

-- ============= Q2 2026 (Apr-Jun) =============
PRINT 'Creating Q2 2026 bookings...';

-- Hotel 1 (New York) - Q2 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-NY-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2026-04-10', '2026-04-13', 2, 'Completed', 7500000, 'BK-2026Q2-NY-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-NY-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2026-04-15', '2026-04-18', 2, 'Completed', 7500000, 'BK-2026Q2-NY-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-NY-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-201'), '2026-05-10', '2026-05-14', 4, 'Completed', 16000000, 'BK-2026Q2-NY-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-NY-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-202'), '2026-05-15', '2026-05-19', 4, 'Completed', 16000000, 'BK-2026Q2-NY-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-NY-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2026-06-10', '2026-06-13', 2, 'Completed', 7500000, 'BK-2026Q2-NY-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-NY-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2026-06-15', '2026-06-18', 2, 'Completed', 7500000, 'BK-2026Q2-NY-006', 1);

-- Hotel 4 (Los Angeles) - Q2 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-LA-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2026-04-08', '2026-04-11', 2, 'Completed', 9000000, 'BK-2026Q2-LA-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-LA-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2026-04-12', '2026-04-15', 2, 'Completed', 9000000, 'BK-2026Q2-LA-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-LA-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-301'), '2026-05-05', '2026-05-10', 4, 'Completed', 25000000, 'BK-2026Q2-LA-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-LA-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-302'), '2026-05-12', '2026-05-17', 4, 'Completed', 25000000, 'BK-2026Q2-LA-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-LA-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2026-06-05', '2026-06-08', 2, 'Completed', 9000000, 'BK-2026Q2-LA-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-LA-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2026-06-10', '2026-06-13', 2, 'Completed', 9000000, 'BK-2026Q2-LA-006', 1);

-- Hotel 5 (Chicago) - Q2 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-CH-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2026-04-12', '2026-04-15', 2, 'Completed', 6600000, 'BK-2026Q2-CH-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-CH-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2026-04-18', '2026-04-21', 2, 'Completed', 6600000, 'BK-2026Q2-CH-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-CH-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-201'), '2026-05-08', '2026-05-12', 4, 'Completed', 14000000, 'BK-2026Q2-CH-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-CH-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-202'), '2026-05-14', '2026-05-18', 4, 'Completed', 14000000, 'BK-2026Q2-CH-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-CH-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2026-06-08', '2026-06-11', 2, 'Completed', 6600000, 'BK-2026Q2-CH-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q2-CH-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2026-06-12', '2026-06-15', 2, 'Completed', 6600000, 'BK-2026Q2-CH-006', 1);

PRINT '  ✓ Q2 2026 bookings created (18 bookings).';

-- ============= Q3 2026 (Jul-Sep) =============
PRINT 'Creating Q3 2026 bookings...';

-- Hotel 1 (New York) - Q3 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-NY-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2026-07-10', '2026-07-13', 2, 'Completed', 7500000, 'BK-2026Q3-NY-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-NY-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2026-07-15', '2026-07-18', 2, 'Completed', 7500000, 'BK-2026Q3-NY-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-NY-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-201'), '2026-08-10', '2026-08-14', 4, 'Completed', 16000000, 'BK-2026Q3-NY-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-NY-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-202'), '2026-08-15', '2026-08-19', 4, 'Completed', 16000000, 'BK-2026Q3-NY-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-NY-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2026-09-10', '2026-09-13', 2, 'Completed', 7500000, 'BK-2026Q3-NY-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-NY-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2026-09-15', '2026-09-18', 2, 'Completed', 7500000, 'BK-2026Q3-NY-006', 1);

-- Hotel 4 (Los Angeles) - Q3 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-LA-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2026-07-08', '2026-07-11', 2, 'Completed', 9000000, 'BK-2026Q3-LA-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-LA-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2026-07-12', '2026-07-15', 2, 'Completed', 9000000, 'BK-2026Q3-LA-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-LA-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-301'), '2026-08-05', '2026-08-10', 4, 'Completed', 25000000, 'BK-2026Q3-LA-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-LA-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-302'), '2026-08-12', '2026-08-17', 4, 'Completed', 25000000, 'BK-2026Q3-LA-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-LA-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2026-09-05', '2026-09-08', 2, 'Completed', 9000000, 'BK-2026Q3-LA-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-LA-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2026-09-10', '2026-09-13', 2, 'Completed', 9000000, 'BK-2026Q3-LA-006', 1);

-- Hotel 5 (Chicago) - Q3 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-CH-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2026-07-12', '2026-07-15', 2, 'Completed', 6600000, 'BK-2026Q3-CH-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-CH-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2026-07-18', '2026-07-21', 2, 'Completed', 6600000, 'BK-2026Q3-CH-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-CH-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-201'), '2026-08-08', '2026-08-12', 4, 'Completed', 14000000, 'BK-2026Q3-CH-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-CH-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-202'), '2026-08-14', '2026-08-18', 4, 'Completed', 14000000, 'BK-2026Q3-CH-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-CH-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2026-09-08', '2026-09-11', 2, 'Completed', 6600000, 'BK-2026Q3-CH-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q3-CH-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2026-09-12', '2026-09-15', 2, 'Completed', 6600000, 'BK-2026Q3-CH-006', 1);

PRINT '  ✓ Q3 2026 bookings created (18 bookings).';

-- ============= Q4 2026 (Oct-Dec) =============
PRINT 'Creating Q4 2026 bookings...';

-- Hotel 1 (New York) - Q4 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-NY-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2026-10-10', '2026-10-13', 2, 'Completed', 7500000, 'BK-2026Q4-NY-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-NY-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2026-10-15', '2026-10-18', 2, 'Completed', 7500000, 'BK-2026Q4-NY-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-NY-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-201'), '2026-11-10', '2026-11-14', 4, 'Completed', 16000000, 'BK-2026Q4-NY-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-NY-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-202'), '2026-11-15', '2026-11-19', 4, 'Completed', 16000000, 'BK-2026Q4-NY-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-NY-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2026-12-10', '2026-12-13', 2, 'Completed', 7500000, 'BK-2026Q4-NY-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-NY-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2026-12-15', '2026-12-18', 2, 'Completed', 7500000, 'BK-2026Q4-NY-006', 1);

-- Hotel 4 (Los Angeles) - Q4 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-LA-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2026-10-08', '2026-10-11', 2, 'Completed', 9000000, 'BK-2026Q4-LA-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-LA-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2026-10-12', '2026-10-15', 2, 'Completed', 9000000, 'BK-2026Q4-LA-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-LA-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-301'), '2026-11-05', '2026-11-10', 4, 'Completed', 25000000, 'BK-2026Q4-LA-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-LA-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-302'), '2026-11-12', '2026-11-17', 4, 'Completed', 25000000, 'BK-2026Q4-LA-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-LA-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-101'), '2026-12-05', '2026-12-08', 2, 'Completed', 9000000, 'BK-2026Q4-LA-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-LA-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2026-12-10', '2026-12-13', 2, 'Completed', 9000000, 'BK-2026Q4-LA-006', 1);

-- Hotel 5 (Chicago) - Q4 2026
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-CH-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2026-10-12', '2026-10-15', 2, 'Completed', 6600000, 'BK-2026Q4-CH-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-CH-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2026-10-18', '2026-10-21', 2, 'Completed', 6600000, 'BK-2026Q4-CH-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-CH-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-201'), '2026-11-08', '2026-11-12', 4, 'Completed', 14000000, 'BK-2026Q4-CH-003', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-CH-004')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-202'), '2026-11-14', '2026-11-18', 4, 'Completed', 14000000, 'BK-2026Q4-CH-004', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-CH-005')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2026-12-08', '2026-12-11', 2, 'Completed', 6600000, 'BK-2026Q4-CH-005', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-2026Q4-CH-006')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2026-12-12', '2026-12-15', 2, 'Completed', 6600000, 'BK-2026Q4-CH-006', 1);

PRINT '  ✓ Q4 2026 bookings created (18 bookings).';

PRINT '';
PRINT 'SECTION 3 COMPLETE: Bookings for 8 quarters created (Q1-Q4 2025, Q1-Q4 2026).';
PRINT '';

-- =============================================================================
-- SECTION 4: RATE CHANGE TEST CASES
-- =============================================================================

PRINT 'SECTION 4: Creating rate change test cases...';

-- Test Case 1: Rate increase >50% (should trigger audit log)
UPDATE Rooms SET Rate = 4000000 WHERE Code = 'NY-DLX-101'; -- +60% from 2,500,000
PRINT '  ✓ Test case 1: NY-DLX-101 rate increased by 60%';

-- Test Case 2: Rate increase >50% (should trigger audit log)
UPDATE Rooms SET Rate = 3500000 WHERE Code = 'CH-DLX-101'; -- +59% from 2,200,000
PRINT '  ✓ Test case 2: CH-DLX-101 rate increased by 59%';

-- Test Case 3: Rate decrease >50% (should trigger audit log)
UPDATE Rooms SET Rate = 2000000 WHERE Code = 'LA-STE-301'; -- -60% from 5,000,000
PRINT '  ✓ Test case 3: LA-STE-301 rate decreased by 60%';

-- Test Case 4: Rate decrease >50% (should trigger audit log)
UPDATE Rooms SET Rate = 1800000 WHERE Code = 'NY-STE-201'; -- -55% from 4,000,000
PRINT '  ✓ Test case 4: NY-STE-201 rate decreased by 55%';

-- Test Case 5: Rate increase within 50% (should NOT trigger audit log)
UPDATE Rooms SET Rate = 4000000 WHERE Code = 'LA-DLX-101'; -- +33% from 3,000,000
PRINT '  ✓ Test case 5: LA-DLX-101 rate increased by 33% (no audit log)';

-- Test Case 6: Rate decrease within 50% (should NOT trigger audit log)
UPDATE Rooms SET Rate = 2500000 WHERE Code = 'CH-STE-201'; -- -29% from 3,500,000
PRINT '  ✓ Test case 6: CH-STE-201 rate decreased by 29% (no audit log)';

PRINT '';
PRINT 'SECTION 4 COMPLETE: 6 rate change test cases created.';
PRINT 'Expected audit log entries: 4 (cases 1-4 only)';
PRINT '';

-- =============================================================================
-- SECTION 5: BOOKING STATUS VARIETY
-- =============================================================================

PRINT 'SECTION 5: Creating bookings with various statuses...';

-- Pending bookings
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-PENDING-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-101'), '2026-04-10', '2026-04-13', 2, 'Pending', 7500000, 'BK-PENDING-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-PENDING-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-301'), '2026-04-15', '2026-04-20', 4, 'Pending', 25000000, 'BK-PENDING-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-PENDING-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-102'), '2026-04-18', '2026-04-21', 2, 'Pending', 6600000, 'BK-PENDING-003', 1);

-- Cancelled bookings
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-CANCELLED-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-STE-202'), '2026-05-10', '2026-05-14', 4, 'Cancelled', 16000000, 'BK-CANCELLED-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-CANCELLED-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-DLX-102'), '2026-05-15', '2026-05-18', 2, 'Cancelled', 9000000, 'BK-CANCELLED-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-CANCELLED-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-STE-202'), '2026-05-20', '2026-05-24', 4, 'Cancelled', 14000000, 'BK-CANCELLED-003', 1);

-- CheckedIn bookings
IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-CHECKEDIN-001')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'NY-DLX-102'), '2026-06-10', '2026-06-13', 2, 'CheckedIn', 7500000, 'BK-CHECKEDIN-001', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-CHECKEDIN-002')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'LA-STE-302'), '2026-06-12', '2026-06-17', 4, 'CheckedIn', 25000000, 'BK-CHECKEDIN-002', 1);

IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingCode = 'BK-CHECKEDIN-003')
    INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode, AccountId)
    VALUES ((SELECT Id FROM Rooms WHERE Code = 'CH-DLX-101'), '2026-06-15', '2026-06-18', 2, 'CheckedIn', 6600000, 'BK-CHECKEDIN-003', 1);

PRINT '  ✓ Created 3 Pending bookings';
PRINT '  ✓ Created 3 Cancelled bookings';
PRINT '  ✓ Created 3 CheckedIn bookings';

PRINT '';
PRINT 'SECTION 5 COMPLETE: 9 bookings with various statuses created.';
PRINT '';

PRINT '';
PRINT '========================================================================';
PRINT 'SEED DATA GENERATION COMPLETED';
PRINT '========================================================================';
PRINT 'Summary:';
PRINT '  - Hotels: 3 (New York, Los Angeles, Chicago)';
PRINT '  - Rooms: 12 (4 per hotel)';
PRINT '  - Bookings: 153 total';
PRINT '    * Q1-Q4 2025: 72 bookings (all Completed)';
PRINT '    * Q1-Q4 2026: 72 bookings (all Completed)';
PRINT '    * Status variety: 9 bookings (3 Pending, 3 Cancelled, 3 CheckedIn)';
PRINT '  - Rate change test cases: 6 (4 should trigger audit log)';
PRINT '';
PRINT 'Analytics ready: 8 quarters of completed bookings for revenue analysis';
PRINT '========================================================================';
GO
