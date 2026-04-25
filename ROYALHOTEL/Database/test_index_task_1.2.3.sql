-- test_index_task_1.2.3.sql
-- Test script for Task 1.2.3: IX_Rooms_HotelId_Includes index
-- Purpose: Demonstrate index usage and performance benefits

PRINT '========================================';
PRINT 'Task 1.2.3 Index Usage Test';
PRINT '========================================';
PRINT '';

-- Enable execution plan display
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT 'Test 1: Query rooms by HotelId with Code and Name';
PRINT '--------------------------------------------------';
PRINT 'This query should use IX_Rooms_HotelId_Includes as a covering index';
PRINT '';

-- Test query that should use the index
SELECT 
    r.Id,
    r.HotelId,
    r.Code,
    r.Name
FROM Rooms r
WHERE r.HotelId = 1;

PRINT '';
PRINT 'Expected: Index Seek on IX_Rooms_HotelId_Includes';
PRINT 'No Key Lookup should be needed (covering index)';
PRINT '';

PRINT 'Test 2: Join Rooms with Hotels filtered by HotelId';
PRINT '---------------------------------------------------';
PRINT 'This query simulates the join pattern in Quarterly_Revenue_Analytics';
PRINT '';

-- Test join query
SELECT 
    h.Id AS HotelId,
    h.Name AS HotelName,
    r.Code AS RoomCode,
    r.Name AS RoomName
FROM Hotels h
INNER JOIN Rooms r ON h.Id = r.HotelId
WHERE h.Id = 1;

PRINT '';
PRINT 'Expected: Index Seek on IX_Rooms_HotelId_Includes for Rooms table';
PRINT '';

PRINT 'Test 3: Simulate Quarterly_Revenue_Analytics join pattern';
PRINT '----------------------------------------------------------';
PRINT 'This query simulates the full join pattern used in analytics';
PRINT '';

-- Test full analytics join pattern
SELECT 
    h.Id AS HotelId,
    h.Name AS HotelName,
    r.Code AS RoomCode,
    r.Name AS RoomName,
    COUNT(b.Id) AS TotalBookings,
    SUM(b.TotalAmount) AS TotalRevenue
FROM Bookings b
INNER JOIN Rooms r ON b.RoomId = r.Id
INNER JOIN Hotels h ON r.HotelId = h.Id
WHERE b.Status = 'Completed'
    AND YEAR(b.CheckIn) = 2025
    AND MONTH(b.CheckIn) BETWEEN 1 AND 3
GROUP BY h.Id, h.Name, r.Code, r.Name
ORDER BY TotalRevenue DESC;

PRINT '';
PRINT 'Expected Execution Plan:';
PRINT '- Index Seek on IX_Bookings_Status_CheckIn_Includes (Bookings)';
PRINT '- Index Seek on IX_Rooms_HotelId_Includes (Rooms)';
PRINT '- No Key Lookups (both are covering indexes)';
PRINT '';

-- Disable statistics
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

PRINT '';
PRINT 'Performance Analysis:';
PRINT '--------------------';
PRINT 'Review the execution plan and statistics output above.';
PRINT 'Key indicators of good performance:';
PRINT '- Index Seek operations (not Table Scan)';
PRINT '- Low logical reads';
PRINT '- No Key Lookup operations';
PRINT '- Fast execution time';
PRINT '';
PRINT 'Task 1.2.3: TEST COMPLETE ✓';
PRINT '';
GO
