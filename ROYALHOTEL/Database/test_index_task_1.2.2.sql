-- test_index_task_1.2.2.sql
-- Test script for index IX_Bookings_Status_CheckIn_Includes
-- Purpose: Demonstrate index usage and performance benefits

PRINT '========================================================================';
PRINT 'Test Script for Task 1.2.2: IX_Bookings_Status_CheckIn_Includes';
PRINT '========================================================================';
PRINT '';

-- Test 1: Verify index exists
PRINT 'Test 1: Verify Index Exists';
PRINT '----------------------------';

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('Bookings')
    AND name = 'IX_Bookings_Status_CheckIn_Includes'
)
BEGIN
    PRINT '✓ PASS: Index IX_Bookings_Status_CheckIn_Includes exists';
END
ELSE
BEGIN
    PRINT '✗ FAIL: Index IX_Bookings_Status_CheckIn_Includes does NOT exist';
    PRINT 'Please run the migration script: 04_create_index_bookings_status_checkin.sql';
    RETURN;
END
PRINT '';

-- Test 2: Verify index structure
PRINT 'Test 2: Verify Index Structure';
PRINT '-------------------------------';

DECLARE @KeyColumnCount INT;
DECLARE @IncludedColumnCount INT;

SELECT @KeyColumnCount = COUNT(*)
FROM sys.index_columns ic
INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
WHERE i.object_id = OBJECT_ID('Bookings')
    AND i.name = 'IX_Bookings_Status_CheckIn_Includes'
    AND ic.is_included_column = 0;

SELECT @IncludedColumnCount = COUNT(*)
FROM sys.index_columns ic
INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
WHERE i.object_id = OBJECT_ID('Bookings')
    AND i.name = 'IX_Bookings_Status_CheckIn_Includes'
    AND ic.is_included_column = 1;

IF @KeyColumnCount = 2 AND @IncludedColumnCount = 2
BEGIN
    PRINT '✓ PASS: Index has correct structure (2 key columns, 2 included columns)';
END
ELSE
BEGIN
    PRINT '✗ FAIL: Index structure is incorrect';
    PRINT '  Expected: 2 key columns (Status, CheckIn), 2 included columns (RoomId, TotalAmount)';
    PRINT '  Actual: ' + CAST(@KeyColumnCount AS VARCHAR) + ' key columns, ' + CAST(@IncludedColumnCount AS VARCHAR) + ' included columns';
END
PRINT '';

-- Test 3: Sample query to demonstrate index usage
PRINT 'Test 3: Sample Query Using Index';
PRINT '---------------------------------';
PRINT 'Query: Get completed bookings for Q1 2025 with revenue aggregation';
PRINT '';

-- Enable execution statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Sample query that should use the index
SELECT 
    b.RoomId,
    COUNT(*) AS TotalBookings,
    SUM(b.TotalAmount) AS TotalRevenue,
    MIN(b.CheckIn) AS FirstCheckIn,
    MAX(b.CheckIn) AS LastCheckIn
FROM Bookings b
WHERE b.Status = 'Completed'
    AND b.CheckIn >= '2025-01-01'
    AND b.CheckIn < '2025-04-01'
GROUP BY b.RoomId
ORDER BY TotalRevenue DESC;

-- Disable execution statistics
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

PRINT '';
PRINT 'Note: Check the execution plan to verify index usage';
PRINT '      Expected: Index Seek on IX_Bookings_Status_CheckIn_Includes';
PRINT '      Expected: No Key Lookups (covering index)';
PRINT '';

-- Test 4: Check index usage statistics
PRINT 'Test 4: Index Usage Statistics';
PRINT '-------------------------------';

IF EXISTS (
    SELECT 1 FROM sys.dm_db_index_usage_stats s
    INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
    WHERE OBJECT_NAME(s.object_id) = 'Bookings'
        AND i.name = 'IX_Bookings_Status_CheckIn_Includes'
)
BEGIN
    SELECT 
        'IX_Bookings_Status_CheckIn_Includes' AS IndexName,
        s.user_seeks AS UserSeeks,
        s.user_scans AS UserScans,
        s.user_lookups AS UserLookups,
        s.user_updates AS UserUpdates,
        s.last_user_seek AS LastUserSeek,
        s.last_user_scan AS LastUserScan
    FROM sys.dm_db_index_usage_stats s
    INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
    WHERE OBJECT_NAME(s.object_id) = 'Bookings'
        AND i.name = 'IX_Bookings_Status_CheckIn_Includes';
    
    PRINT '';
    PRINT '✓ Index usage statistics available';
    PRINT '  UserSeeks: Number of times index was used for seeks';
    PRINT '  UserScans: Number of times index was scanned';
    PRINT '  UserLookups: Number of times index was used for lookups';
    PRINT '  UserUpdates: Number of times index was updated';
END
ELSE
BEGIN
    PRINT 'ℹ INFO: No usage statistics available yet';
    PRINT '  Run some queries that filter by Status and CheckIn to populate statistics';
END
PRINT '';

-- Test 5: Check index fragmentation
PRINT 'Test 5: Index Fragmentation';
PRINT '---------------------------';

SELECT 
    i.name AS IndexName,
    ps.avg_fragmentation_in_percent AS FragmentationPercent,
    ps.page_count AS PageCount,
    CASE 
        WHEN ps.avg_fragmentation_in_percent < 10 THEN 'Good (No action needed)'
        WHEN ps.avg_fragmentation_in_percent < 30 THEN 'Moderate (Consider reorganize)'
        ELSE 'High (Consider rebuild)'
    END AS FragmentationStatus
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Bookings'), NULL, NULL, 'LIMITED') ps
INNER JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE i.name = 'IX_Bookings_Status_CheckIn_Includes';

PRINT '';

-- Test 6: Estimate index size
PRINT 'Test 6: Index Size Information';
PRINT '-------------------------------';

SELECT 
    i.name AS IndexName,
    SUM(ps.used_page_count) * 8 / 1024.0 AS IndexSizeMB,
    SUM(ps.row_count) AS RowCount
FROM sys.dm_db_partition_stats ps
INNER JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE i.object_id = OBJECT_ID('Bookings')
    AND i.name = 'IX_Bookings_Status_CheckIn_Includes'
GROUP BY i.name;

PRINT '';

-- Summary
PRINT '========================================================================';
PRINT 'Test Summary';
PRINT '========================================================================';
PRINT '';
PRINT 'All tests completed. Review the results above.';
PRINT '';
PRINT 'Key Points:';
PRINT '- Index should be used for queries filtering by Status and CheckIn';
PRINT '- Covering index eliminates key lookups for RoomId and TotalAmount';
PRINT '- Monitor fragmentation and rebuild if >30%';
PRINT '- Update statistics regularly for optimal query plans';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Run the Quarterly_Revenue_Analytics stored procedure (Task 1.4)';
PRINT '2. Analyze execution plan to verify index usage (Task 1.5)';
PRINT '3. Run performance tests with 100,000 booking records (Task 4.6)';
PRINT '';
PRINT '========================================================================';
