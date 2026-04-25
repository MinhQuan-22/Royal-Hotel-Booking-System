-- =============================================
-- Script: analyze_execution_plan_quarterly_revenue.sql
-- Purpose: Analyze execution plan for Quarterly_Revenue_Analytics stored procedure
-- Related Requirements: Requirement 6 - Query Performance Optimization
-- Related Tasks: Task 1.5.3, Task 1.5.4
-- =============================================
--
-- This script analyzes the execution plan to verify:
-- 1. Index seeks (not table scans) are used
-- 2. Covering indexes eliminate key lookups
-- 3. Query executes efficiently
--
-- Usage:
--   1. Enable "Include Actual Execution Plan" in SSMS (Ctrl+M)
--   2. Execute this script
--   3. Review the "Execution Plan" tab
--   4. Look for "Index Seek" operations (good)
--   5. Avoid "Table Scan" or "Clustered Index Scan" (bad for large tables)
--
-- =============================================

USE RoyalHotel;
GO

PRINT '========================================';
PRINT 'Execution Plan Analysis';
PRINT 'Quarterly_Revenue_Analytics';
PRINT '========================================';
PRINT '';

-- =============================================
-- Verify stored procedure exists
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = 'Quarterly_Revenue_Analytics')
BEGIN
    PRINT '✗ ERROR: Quarterly_Revenue_Analytics stored procedure does not exist';
    PRINT 'Please run 07_quarterly_revenue_analytics.sql first';
    PRINT '';
    RETURN;
END

PRINT '✓ Quarterly_Revenue_Analytics stored procedure exists';
PRINT '';

-- =============================================
-- Verify required indexes exist
-- =============================================
PRINT 'Checking required indexes...';
PRINT '';

DECLARE @Index1Exists BIT = 0;
DECLARE @Index2Exists BIT = 0;
DECLARE @Index3Exists BIT = 0;

-- Index 1: IX_RoomRateChangeLog_RoomId_ChangedAt
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RoomRateChangeLog_RoomId_ChangedAt')
BEGIN
    SET @Index1Exists = 1;
    PRINT '✓ IX_RoomRateChangeLog_RoomId_ChangedAt exists';
END
ELSE
BEGIN
    PRINT '⚠ IX_RoomRateChangeLog_RoomId_ChangedAt NOT found';
END

-- Index 2: IX_Bookings_Status_CheckIn_Includes
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Bookings_Status_CheckIn_Includes')
BEGIN
    SET @Index2Exists = 1;
    PRINT '✓ IX_Bookings_Status_CheckIn_Includes exists';
END
ELSE
BEGIN
    PRINT '⚠ IX_Bookings_Status_CheckIn_Includes NOT found (CRITICAL for performance)';
END

-- Index 3: IX_Rooms_HotelId_Includes
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Rooms_HotelId_Includes')
BEGIN
    SET @Index3Exists = 1;
    PRINT '✓ IX_Rooms_HotelId_Includes exists';
END
ELSE
BEGIN
    PRINT '⚠ IX_Rooms_HotelId_Includes NOT found (CRITICAL for performance)';
END

PRINT '';

IF @Index2Exists = 0 OR @Index3Exists = 0
BEGIN
    PRINT '⚠ WARNING: Missing critical indexes will result in poor performance';
    PRINT 'Please create missing indexes before analyzing execution plan';
    PRINT '';
END

-- =============================================
-- Check data volume
-- =============================================
PRINT 'Checking data volume...';
PRINT '';

DECLARE @BookingCount INT;
DECLARE @RoomCount INT;
DECLARE @HotelCount INT;

SELECT @BookingCount = COUNT(*) FROM Bookings;
SELECT @RoomCount = COUNT(*) FROM Rooms;
SELECT @HotelCount = COUNT(*) FROM Hotels;

PRINT 'Data Volume:';
PRINT '- Bookings: ' + CAST(@BookingCount AS NVARCHAR(20));
PRINT '- Rooms: ' + CAST(@RoomCount AS NVARCHAR(20));
PRINT '- Hotels: ' + CAST(@HotelCount AS NVARCHAR(20));
PRINT '';

IF @BookingCount < 1000
BEGIN
    PRINT '⚠ NOTE: Small dataset may not show realistic performance characteristics';
    PRINT 'Consider running seed_completed_bookings_for_analytics.sql for larger dataset';
    PRINT '';
END

-- =============================================
-- Enable execution plan statistics
-- =============================================
PRINT '========================================';
PRINT 'Enabling Execution Statistics';
PRINT '========================================';
PRINT '';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
PRINT '✓ Statistics enabled';
PRINT '';

-- =============================================
-- Test Case 1: All data (no filters)
-- =============================================
PRINT '========================================';
PRINT 'Test Case 1: All Data (No Filters)';
PRINT '========================================';
PRINT '';
PRINT 'Executing: EXEC Quarterly_Revenue_Analytics NULL, NULL, NULL';
PRINT '';

DECLARE @StartTime1 DATETIME2 = SYSDATETIME();

EXEC Quarterly_Revenue_Analytics NULL, NULL, NULL;

DECLARE @EndTime1 DATETIME2 = SYSDATETIME();
DECLARE @Duration1 INT = DATEDIFF(MILLISECOND, @StartTime1, @EndTime1);

PRINT '';
PRINT 'Execution Time: ' + CAST(@Duration1 AS NVARCHAR(20)) + ' ms';
PRINT '';

IF @Duration1 > 2000
BEGIN
    PRINT '⚠ WARNING: Execution time exceeds 2 second target';
    PRINT 'Review execution plan for optimization opportunities';
END
ELSE
BEGIN
    PRINT '✓ Execution time within target (<2 seconds)';
END
PRINT '';

-- =============================================
-- Test Case 2: Filter by HotelId
-- =============================================
PRINT '========================================';
PRINT 'Test Case 2: Filter by HotelId';
PRINT '========================================';
PRINT '';

-- Get a sample HotelId
DECLARE @SampleHotelId INT;
SELECT TOP 1 @SampleHotelId = Id FROM Hotels ORDER BY Id;

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics @HotelId=' + CAST(@SampleHotelId AS NVARCHAR(20));
PRINT '';

DECLARE @StartTime2 DATETIME2 = SYSDATETIME();

EXEC Quarterly_Revenue_Analytics @SampleHotelId, NULL, NULL;

DECLARE @EndTime2 DATETIME2 = SYSDATETIME();
DECLARE @Duration2 INT = DATEDIFF(MILLISECOND, @StartTime2, @EndTime2);

PRINT '';
PRINT 'Execution Time: ' + CAST(@Duration2 AS NVARCHAR(20)) + ' ms';
PRINT '';

-- =============================================
-- Test Case 3: Filter by Year and Quarter
-- =============================================
PRINT '========================================';
PRINT 'Test Case 3: Filter by Year and Quarter';
PRINT '========================================';
PRINT '';

PRINT 'Executing: EXEC Quarterly_Revenue_Analytics NULL, 2025, 1';
PRINT '';

DECLARE @StartTime3 DATETIME2 = SYSDATETIME();

EXEC Quarterly_Revenue_Analytics NULL, 2025, 1;

DECLARE @EndTime3 DATETIME2 = SYSDATETIME();
DECLARE @Duration3 INT = DATEDIFF(MILLISECOND, @StartTime3, @EndTime3);

PRINT '';
PRINT 'Execution Time: ' + CAST(@Duration3 AS NVARCHAR(20)) + ' ms';
PRINT '';

-- =============================================
-- Disable statistics
-- =============================================
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- =============================================
-- Analysis Summary
-- =============================================
PRINT '========================================';
PRINT 'Execution Plan Analysis Summary';
PRINT '========================================';
PRINT '';

PRINT 'Performance Metrics:';
PRINT '-------------------';
PRINT 'Test Case 1 (All Data): ' + CAST(@Duration1 AS NVARCHAR(20)) + ' ms';
PRINT 'Test Case 2 (HotelId Filter): ' + CAST(@Duration2 AS NVARCHAR(20)) + ' ms';
PRINT 'Test Case 3 (Year/Quarter Filter): ' + CAST(@Duration3 AS NVARCHAR(20)) + ' ms';
PRINT '';

PRINT 'What to Look For in Execution Plan:';
PRINT '-----------------------------------';
PRINT '';
PRINT '✓ GOOD INDICATORS:';
PRINT '  - Index Seek on IX_Bookings_Status_CheckIn_Includes';
PRINT '  - Index Seek on IX_Rooms_HotelId_Includes';
PRINT '  - Covering index eliminates Key Lookup operations';
PRINT '  - Hash Match or Nested Loops for joins (optimizer choice)';
PRINT '  - Sort operation for ROW_NUMBER() window function';
PRINT '';
PRINT '✗ BAD INDICATORS:';
PRINT '  - Table Scan on Bookings (indicates missing or unused index)';
PRINT '  - Clustered Index Scan on large tables';
PRINT '  - Key Lookup operations (indicates non-covering index)';
PRINT '  - High estimated cost operations (>50% of total)';
PRINT '  - Missing Index warnings in execution plan';
PRINT '';

PRINT 'Index Usage Verification:';
PRINT '-------------------------';
PRINT '';
PRINT 'To verify index seeks (Task 1.5.4):';
PRINT '1. Review the "Execution Plan" tab in SSMS';
PRINT '2. Look for "Index Seek" operations on:';
PRINT '   - Bookings table using IX_Bookings_Status_CheckIn_Includes';
PRINT '   - Rooms table using IX_Rooms_HotelId_Includes';
PRINT '3. Verify no "Table Scan" or "Clustered Index Scan" on these tables';
PRINT '4. Check "Actual Number of Rows" vs "Estimated Number of Rows"';
PRINT '   (Large discrepancies indicate stale statistics)';
PRINT '';

PRINT 'Statistics Information:';
PRINT '----------------------';
PRINT 'Review the "Messages" tab for:';
PRINT '- Logical reads (lower is better)';
PRINT '- Scan count (lower is better)';
PRINT '- CPU time and elapsed time';
PRINT '';

PRINT 'Optimization Recommendations:';
PRINT '-----------------------------';
IF @Index2Exists = 0
    PRINT '⚠ Create IX_Bookings_Status_CheckIn_Includes (CRITICAL)';
IF @Index3Exists = 0
    PRINT '⚠ Create IX_Rooms_HotelId_Includes (CRITICAL)';
IF @BookingCount > 10000
    PRINT '✓ Dataset size sufficient for realistic performance testing';
ELSE
    PRINT '⚠ Consider larger dataset for performance testing';
PRINT '';

PRINT 'Next Steps:';
PRINT '-----------';
PRINT '1. Review execution plan in SSMS (Ctrl+L for estimated, Ctrl+M for actual)';
PRINT '2. Verify index seeks are used (not table scans)';
PRINT '3. Check for missing index recommendations';
PRINT '4. Update statistics if row count estimates are inaccurate';
PRINT '5. Document findings in AI_Audit_Report.md';
PRINT '';

PRINT '========================================';
PRINT 'Analysis Complete';
PRINT '========================================';
