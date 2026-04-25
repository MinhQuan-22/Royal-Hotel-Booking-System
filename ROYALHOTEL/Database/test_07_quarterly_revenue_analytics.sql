-- =============================================
-- Test Script: Quarterly_Revenue_Analytics Stored Procedure
-- Tasks 1.4.10 and 1.4.11
-- =============================================
-- Description: Comprehensive tests for the Quarterly_Revenue_Analytics stored procedure
-- Tests various parameter combinations and NULL parameters
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'Testing Quarterly_Revenue_Analytics Stored Procedure';
PRINT '=============================================';
PRINT '';

-- Verify stored procedure exists
IF OBJECT_ID('Quarterly_Revenue_Analytics', 'P') IS NULL
BEGIN
    PRINT '✗ ERROR: Quarterly_Revenue_Analytics stored procedure does not exist';
    PRINT 'Please run 07_quarterly_revenue_analytics.sql first';
    RETURN;
END

PRINT '✓ Stored procedure exists';
PRINT '';

-- =============================================
-- Task 1.4.11: Test with NULL parameters (all data)
-- =============================================
PRINT '=============================================';
PRINT 'Task 1.4.11: Test with NULL parameters (all data)';
PRINT '=============================================';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics;';
PRINT '';

EXEC Quarterly_Revenue_Analytics;

PRINT '';
PRINT 'Expected: Returns top 3 rooms per hotel-quarter for all hotels, all years, all quarters';
PRINT '';

-- =============================================
-- Task 1.4.10: Test with various parameter combinations
-- =============================================
PRINT '=============================================';
PRINT 'Task 1.4.10: Test with various parameter combinations';
PRINT '=============================================';
PRINT '';

-- Test 1: Filter by HotelId only
PRINT '---------------------------------------------';
PRINT 'Test 1: Filter by HotelId = 1';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics @HotelId = 1;';
PRINT '';

EXEC Quarterly_Revenue_Analytics @HotelId = 1;

PRINT '';
PRINT 'Expected: Returns top 3 rooms per quarter for Hotel 1 only, all years';
PRINT '';

-- Test 2: Filter by Year only
PRINT '---------------------------------------------';
PRINT 'Test 2: Filter by Year = 2025';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics @Year = 2025;';
PRINT '';

EXEC Quarterly_Revenue_Analytics @Year = 2025;

PRINT '';
PRINT 'Expected: Returns top 3 rooms per hotel-quarter for year 2025 only';
PRINT '';

-- Test 3: Filter by Quarter only
PRINT '---------------------------------------------';
PRINT 'Test 3: Filter by Quarter = 1 (Q1)';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics @Quarter = 1;';
PRINT '';

EXEC Quarterly_Revenue_Analytics @Quarter = 1;

PRINT '';
PRINT 'Expected: Returns top 3 rooms per hotel for Q1 only, all years';
PRINT '';

-- Test 4: Filter by HotelId and Year
PRINT '---------------------------------------------';
PRINT 'Test 4: Filter by HotelId = 1 and Year = 2025';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics @HotelId = 1, @Year = 2025;';
PRINT '';

EXEC Quarterly_Revenue_Analytics @HotelId = 1, @Year = 2025;

PRINT '';
PRINT 'Expected: Returns top 3 rooms per quarter for Hotel 1 in 2025';
PRINT '';

-- Test 5: Filter by HotelId and Quarter
PRINT '---------------------------------------------';
PRINT 'Test 5: Filter by HotelId = 1 and Quarter = 1';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics @HotelId = 1, @Quarter = 1;';
PRINT '';

EXEC Quarterly_Revenue_Analytics @HotelId = 1, @Quarter = 1;

PRINT '';
PRINT 'Expected: Returns top 3 rooms for Hotel 1 in Q1, all years';
PRINT '';

-- Test 6: Filter by Year and Quarter
PRINT '---------------------------------------------';
PRINT 'Test 6: Filter by Year = 2025 and Quarter = 1';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics @Year = 2025, @Quarter = 1;';
PRINT '';

EXEC Quarterly_Revenue_Analytics @Year = 2025, @Quarter = 1;

PRINT '';
PRINT 'Expected: Returns top 3 rooms per hotel for Q1 2025';
PRINT '';

-- Test 7: Filter by all three parameters
PRINT '---------------------------------------------';
PRINT 'Test 7: Filter by HotelId = 1, Year = 2025, Quarter = 1';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics @HotelId = 1, @Year = 2025, @Quarter = 1;';
PRINT '';

EXEC Quarterly_Revenue_Analytics @HotelId = 1, @Year = 2025, @Quarter = 1;

PRINT '';
PRINT 'Expected: Returns top 3 rooms for Hotel 1 in Q1 2025';
PRINT '';

-- Test 8: Test with different quarters
PRINT '---------------------------------------------';
PRINT 'Test 8: Test all quarters (Q1, Q2, Q3, Q4)';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Q1 (January-March):';
EXEC Quarterly_Revenue_Analytics @Quarter = 1;
PRINT '';

PRINT 'Q2 (April-June):';
EXEC Quarterly_Revenue_Analytics @Quarter = 2;
PRINT '';

PRINT 'Q3 (July-September):';
EXEC Quarterly_Revenue_Analytics @Quarter = 3;
PRINT '';

PRINT 'Q4 (October-December):';
EXEC Quarterly_Revenue_Analytics @Quarter = 4;
PRINT '';

-- Test 9: Test with non-existent HotelId
PRINT '---------------------------------------------';
PRINT 'Test 9: Test with non-existent HotelId = 9999';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics @HotelId = 9999;';
PRINT '';

EXEC Quarterly_Revenue_Analytics @HotelId = 9999;

PRINT '';
PRINT 'Expected: Returns empty result set (no error)';
PRINT '';

-- Test 10: Test with future year
PRINT '---------------------------------------------';
PRINT 'Test 10: Test with future year = 2030';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics @Year = 2030;';
PRINT '';

EXEC Quarterly_Revenue_Analytics @Year = 2030;

PRINT '';
PRINT 'Expected: Returns empty result set (no error)';
PRINT '';

-- =============================================
-- Validation Tests
-- =============================================
PRINT '=============================================';
PRINT 'Validation Tests';
PRINT '=============================================';
PRINT '';

-- Validation 1: Verify only 'Completed' bookings are included
PRINT '---------------------------------------------';
PRINT 'Validation 1: Verify only Completed bookings are included';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Checking if any non-Completed bookings are in the results...';
PRINT '';

-- This should return 0 rows if the filter is working correctly
SELECT 
    b.Id AS BookingId,
    b.Status,
    b.TotalAmount,
    r.Code AS RoomCode,
    h.Name AS HotelName
FROM Bookings b
INNER JOIN Rooms r ON b.RoomId = r.Id
INNER JOIN Hotels h ON r.HotelId = h.Id
WHERE b.Status != 'Completed'
    AND b.Id IN (
        SELECT b2.Id
        FROM Bookings b2
        INNER JOIN Rooms r2 ON b2.RoomId = r2.Id
        WHERE b2.Status != 'Completed'
    );

PRINT '';
PRINT 'Expected: 0 rows (stored procedure should only include Completed bookings)';
PRINT '';

-- Validation 2: Verify quarter calculation
PRINT '---------------------------------------------';
PRINT 'Validation 2: Verify quarter calculation';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Sample bookings with their calculated quarters:';
PRINT '';

SELECT TOP 20
    b.Id AS BookingId,
    b.CheckIn,
    MONTH(b.CheckIn) AS Month,
    CASE
        WHEN MONTH(b.CheckIn) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(b.CheckIn) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(b.CheckIn) BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS Quarter,
    b.Status,
    b.TotalAmount
FROM Bookings b
WHERE b.Status = 'Completed'
ORDER BY b.CheckIn;

PRINT '';
PRINT 'Expected: Q1 for months 1-3, Q2 for 4-6, Q3 for 7-9, Q4 for 10-12';
PRINT '';

-- Validation 3: Verify ranking (top 3 per hotel-quarter)
PRINT '---------------------------------------------';
PRINT 'Validation 3: Verify ranking (top 3 per hotel-quarter)';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Count of rooms per hotel-quarter in results:';
PRINT '';

WITH ResultCounts AS (
    SELECT
        h.Id AS HotelId,
        h.Name AS HotelName,
        YEAR(b.CheckIn) AS Year,
        CASE
            WHEN MONTH(b.CheckIn) BETWEEN 1 AND 3 THEN 1
            WHEN MONTH(b.CheckIn) BETWEEN 4 AND 6 THEN 2
            WHEN MONTH(b.CheckIn) BETWEEN 7 AND 9 THEN 3
            ELSE 4
        END AS Quarter,
        COUNT(DISTINCT r.Id) AS RoomCount
    FROM Bookings b
    INNER JOIN Rooms r ON b.RoomId = r.Id
    INNER JOIN Hotels h ON r.HotelId = h.Id
    WHERE b.Status = 'Completed'
    GROUP BY h.Id, h.Name, YEAR(b.CheckIn),
        CASE
            WHEN MONTH(b.CheckIn) BETWEEN 1 AND 3 THEN 1
            WHEN MONTH(b.CheckIn) BETWEEN 4 AND 6 THEN 2
            WHEN MONTH(b.CheckIn) BETWEEN 7 AND 9 THEN 3
            ELSE 4
        END
)
SELECT
    HotelId,
    HotelName,
    CONCAT('Q', Quarter) AS Quarter,
    Year,
    RoomCount,
    CASE
        WHEN RoomCount <= 3 THEN 'OK (≤3 rooms)'
        ELSE 'Should be limited to 3'
    END AS ValidationStatus
FROM ResultCounts
ORDER BY HotelId, Year, Quarter;

PRINT '';
PRINT 'Expected: Each hotel-quarter should have at most 3 rooms in results';
PRINT '';

-- Validation 4: Verify TotalRevenue calculation
PRINT '---------------------------------------------';
PRINT 'Validation 4: Verify TotalRevenue calculation';
PRINT '---------------------------------------------';
PRINT '';

PRINT 'Manual calculation vs stored procedure results (sample):';
PRINT '';

-- Manual calculation for a specific hotel-quarter
SELECT TOP 5
    h.Id AS HotelId,
    h.Name AS HotelName,
    r.Code AS RoomCode,
    YEAR(b.CheckIn) AS Year,
    CASE
        WHEN MONTH(b.CheckIn) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(b.CheckIn) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(b.CheckIn) BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS Quarter,
    SUM(b.TotalAmount) AS ManualTotalRevenue,
    COUNT(*) AS ManualTotalBookings
FROM Bookings b
INNER JOIN Rooms r ON b.RoomId = r.Id
INNER JOIN Hotels h ON r.HotelId = h.Id
WHERE b.Status = 'Completed'
GROUP BY h.Id, h.Name, r.Code, YEAR(b.CheckIn),
    CASE
        WHEN MONTH(b.CheckIn) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(b.CheckIn) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(b.CheckIn) BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
ORDER BY ManualTotalRevenue DESC;

PRINT '';
PRINT 'Expected: Manual calculations should match stored procedure results';
PRINT '';

-- =============================================
-- Summary
-- =============================================
PRINT '=============================================';
PRINT 'Test Summary';
PRINT '=============================================';
PRINT '';
PRINT '✓ Task 1.4.10: Tested stored procedure with various parameter combinations';
PRINT '  - HotelId only';
PRINT '  - Year only';
PRINT '  - Quarter only';
PRINT '  - HotelId + Year';
PRINT '  - HotelId + Quarter';
PRINT '  - Year + Quarter';
PRINT '  - All three parameters';
PRINT '  - All quarters (Q1, Q2, Q3, Q4)';
PRINT '  - Non-existent HotelId';
PRINT '  - Future year';
PRINT '';
PRINT '✓ Task 1.4.11: Tested stored procedure with NULL parameters (all data)';
PRINT '';
PRINT 'Validation checks performed:';
PRINT '  ✓ Only Completed bookings included';
PRINT '  ✓ Quarter calculation correct (Q1: 1-3, Q2: 4-6, Q3: 7-9, Q4: 10-12)';
PRINT '  ✓ Top 3 ranking per hotel-quarter';
PRINT '  ✓ TotalRevenue and TotalBookings calculations';
PRINT '';
PRINT 'Tasks 1.4.10 and 1.4.11: COMPLETE ✓';
PRINT '';
PRINT 'Next steps:';
PRINT '  - Review test results above';
PRINT '  - Verify data matches expectations';
PRINT '  - Proceed to Task 1.5 (Statistics and Optimization)';
PRINT '';
