-- =============================================
-- Seed Completed Bookings for Analytics Testing
-- =============================================
-- Description: Creates test data with Completed bookings for testing
-- the Quarterly_Revenue_Analytics stored procedure
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'Seeding Completed Bookings for Analytics Testing';
PRINT '=============================================';
PRINT '';

-- Update some existing bookings to Completed status
UPDATE Bookings
SET Status = 'Completed'
WHERE Id IN (2, 4, 6, 8);

PRINT 'Updated 4 existing bookings to Completed status';
PRINT '';

-- Insert additional completed bookings for 2025 Q1
INSERT INTO Bookings (RoomId, CheckIn, CheckOut, Guests, Status, TotalAmount, BookingCode)
VALUES
    -- Hotel 1 (Da Nang) - Q1 2025
    (2, '2025-01-15', '2025-01-18', 2, 'Completed', 4500000.00, 'BK-TEST-Q1-2025-001'),
    (2, '2025-02-10', '2025-02-13', 2, 'Completed', 4800000.00, 'BK-TEST-Q1-2025-002'),
    (3, '2025-03-05', '2025-03-08', 2, 'Completed', 6000000.00, 'BK-TEST-Q1-2025-003'),
    
    -- Hotel 2 (Nha Trang) - Q1 2025
    (1002, '2025-01-20', '2025-01-23', 2, 'Completed', 5200000.00, 'BK-TEST-Q1-2025-004'),
    (1002, '2025-02-15', '2025-02-18', 2, 'Completed', 5500000.00, 'BK-TEST-Q1-2025-005'),
    (1003, '2025-03-10', '2025-03-13', 2, 'Completed', 7200000.00, 'BK-TEST-Q1-2025-006'),
    
    -- Hotel 3 (Phu Quoc) - Q1 2025
    (1004, '2025-01-25', '2025-01-28', 2, 'Completed', 6500000.00, 'BK-TEST-Q1-2025-007'),
    (1004, '2025-02-20', '2025-02-23', 2, 'Completed', 6800000.00, 'BK-TEST-Q1-2025-008'),
    (1005, '2025-03-15', '2025-03-18', 2, 'Completed', 8000000.00, 'BK-TEST-Q1-2025-009'),
    
    -- Hotel 1 (Da Nang) - Q2 2025
    (2, '2025-04-10', '2025-04-13', 2, 'Completed', 5000000.00, 'BK-TEST-Q2-2025-001'),
    (2, '2025-05-15', '2025-05-18', 2, 'Completed', 5200000.00, 'BK-TEST-Q2-2025-002'),
    (3, '2025-06-20', '2025-06-23', 2, 'Completed', 6500000.00, 'BK-TEST-Q2-2025-003'),
    
    -- Hotel 2 (Nha Trang) - Q2 2025
    (1002, '2025-04-12', '2025-04-15', 2, 'Completed', 5600000.00, 'BK-TEST-Q2-2025-004'),
    (1002, '2025-05-18', '2025-05-21', 2, 'Completed', 5800000.00, 'BK-TEST-Q2-2025-005'),
    (1003, '2025-06-22', '2025-06-25', 2, 'Completed', 7500000.00, 'BK-TEST-Q2-2025-006'),
    
    -- Hotel 3 (Phu Quoc) - Q2 2025
    (1004, '2025-04-14', '2025-04-17', 2, 'Completed', 7000000.00, 'BK-TEST-Q2-2025-007'),
    (1004, '2025-05-20', '2025-05-23', 2, 'Completed', 7200000.00, 'BK-TEST-Q2-2025-008'),
    (1005, '2025-06-25', '2025-06-28', 2, 'Completed', 8500000.00, 'BK-TEST-Q2-2025-009'),
    
    -- Hotel 1 (Da Nang) - Q3 2025
    (2, '2025-07-10', '2025-07-13', 2, 'Completed', 5500000.00, 'BK-TEST-Q3-2025-001'),
    (2, '2025-08-15', '2025-08-18', 2, 'Completed', 5700000.00, 'BK-TEST-Q3-2025-002'),
    (3, '2025-09-20', '2025-09-23', 2, 'Completed', 7000000.00, 'BK-TEST-Q3-2025-003'),
    
    -- Hotel 2 (Nha Trang) - Q3 2025
    (1002, '2025-07-12', '2025-07-15', 2, 'Completed', 6000000.00, 'BK-TEST-Q3-2025-004'),
    (1002, '2025-08-18', '2025-08-21', 2, 'Completed', 6200000.00, 'BK-TEST-Q3-2025-005'),
    (1003, '2025-09-22', '2025-09-25', 2, 'Completed', 8000000.00, 'BK-TEST-Q3-2025-006'),
    
    -- Hotel 3 (Phu Quoc) - Q3 2025
    (1004, '2025-07-14', '2025-07-17', 2, 'Completed', 7500000.00, 'BK-TEST-Q3-2025-007'),
    (1004, '2025-08-20', '2025-08-23', 2, 'Completed', 7700000.00, 'BK-TEST-Q3-2025-008'),
    (1005, '2025-09-25', '2025-09-28', 2, 'Completed', 9000000.00, 'BK-TEST-Q3-2025-009'),
    
    -- Hotel 1 (Da Nang) - Q4 2025
    (2, '2025-10-10', '2025-10-13', 2, 'Completed', 6000000.00, 'BK-TEST-Q4-2025-001'),
    (2, '2025-11-15', '2025-11-18', 2, 'Completed', 6200000.00, 'BK-TEST-Q4-2025-002'),
    (3, '2025-12-20', '2025-12-23', 2, 'Completed', 7500000.00, 'BK-TEST-Q4-2025-003'),
    
    -- Hotel 2 (Nha Trang) - Q4 2025
    (1002, '2025-10-12', '2025-10-15', 2, 'Completed', 6500000.00, 'BK-TEST-Q4-2025-004'),
    (1002, '2025-11-18', '2025-11-21', 2, 'Completed', 6700000.00, 'BK-TEST-Q4-2025-005'),
    (1003, '2025-12-22', '2025-12-25', 2, 'Completed', 8500000.00, 'BK-TEST-Q4-2025-006'),
    
    -- Hotel 3 (Phu Quoc) - Q4 2025
    (1004, '2025-10-14', '2025-10-17', 2, 'Completed', 8000000.00, 'BK-TEST-Q4-2025-007'),
    (1004, '2025-11-20', '2025-11-23', 2, 'Completed', 8200000.00, 'BK-TEST-Q4-2025-008'),
    (1005, '2025-12-25', '2025-12-28', 2, 'Completed', 9500000.00, 'BK-TEST-Q4-2025-009');

PRINT 'Inserted 36 new completed bookings for 2025 (9 per quarter)';
PRINT '';

-- Verify the data
PRINT 'Summary of completed bookings by quarter:';
PRINT '';

SELECT
    YEAR(CheckIn) AS Year,
    CASE
        WHEN MONTH(CheckIn) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(CheckIn) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(CheckIn) BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS Quarter,
    COUNT(*) AS CompletedBookings,
    SUM(TotalAmount) AS TotalRevenue
FROM Bookings
WHERE Status = 'Completed'
GROUP BY YEAR(CheckIn),
    CASE
        WHEN MONTH(CheckIn) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(CheckIn) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(CheckIn) BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
ORDER BY Year, Quarter;

PRINT '';
PRINT 'Seed data creation COMPLETE ✓';
PRINT '';
PRINT 'You can now test the Quarterly_Revenue_Analytics stored procedure with:';
PRINT '  EXEC Quarterly_Revenue_Analytics;';
PRINT '';
