-- =============================================
-- Script: verify_index_seeks_task_1.5.4.sql
-- Purpose: Verify index seeks (not table scans) in execution plan
-- Related Requirements: Requirement 6 - Query Performance Optimization
-- Related Tasks: Task 1.5.4
-- =============================================
--
-- This script verifies that the Quarterly_Revenue_Analytics stored procedure
-- uses index seeks instead of table scans for optimal performance.
--
-- Verification Method:
-- 1. Query sys.dm_exec_query_stats to get execution statistics
-- 2. Analyze execution plan XML for index operations
-- 3. Verify no table scans on Bookings or Rooms tables
--
-- =============================================

USE RoyalHotel;
GO

PRINT '========================================';
PRINT 'Task 1.5.4: Verify Index Seeks';
PRINT '========================================';
PRINT '';

-- =============================================
-- Clear procedure cache for fresh execution plan
-- =============================================
PRINT 'Clearing procedure cache for Quarterly_Revenue_Analytics...';
DECLARE @ProcName NVARCHAR(128) = 'Quarterly_Revenue_Analytics';

-- Find and clear the specific procedure from cache
DECLARE @PlanHandle VARBINARY(64);
SELECT @PlanHandle = plan_handle
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE st.objectid = OBJECT_ID(@ProcName);

IF @PlanHandle IS NOT NULL
BEGIN
    DBCC FREEPROCCACHE(@PlanHandle);
    PRINT '✓ Procedure cache cleared';
END
ELSE
BEGIN
    PRINT '⚠ Procedure not found in cache (will be compiled on first execution)';
END
PRINT '';

-- =============================================
-- Execute stored procedure to generate execution plan
-- =============================================
PRINT 'Executing stored procedure to generate execution plan...';
PRINT '';

-- Execute with various parameter combinations
EXEC Quarterly_Revenue_Analytics NULL, NULL, NULL;
EXEC Quarterly_Revenue_Analytics 1, NULL, NULL;
EXEC Quarterly_Revenue_Analytics NULL, 2025, 1;

PRINT '✓ Stored procedure executed';
PRINT '';

-- =============================================
-- Wait for statistics to be updated
-- =============================================
WAITFOR DELAY '00:00:02';

-- =============================================
-- Analyze execution plan from cache
-- =============================================
PRINT '========================================';
PRINT 'Analyzing Execution Plan';
PRINT '========================================';
PRINT '';

-- Query execution plan from cache
DECLARE @PlanXML XML;

SELECT TOP 1 @PlanXML = qp.query_plan
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE st.objectid = OBJECT_ID('Quarterly_Revenue_Analytics')
ORDER BY cp.usecounts DESC;

IF @PlanXML IS NULL
BEGIN
    PRINT '✗ ERROR: Could not retrieve execution plan from cache';
    PRINT 'Please execute the stored procedure first';
    PRINT '';
    RETURN;
END

PRINT '✓ Execution plan retrieved from cache';
PRINT '';

-- =============================================
-- Parse execution plan XML for index operations
-- =============================================
PRINT 'Parsing execution plan for index operations...';
PRINT '';

-- Check for Index Seek operations
DECLARE @IndexSeekCount INT;
DECLARE @TableScanCount INT;
DECLARE @ClusteredIndexScanCount INT;

-- Count Index Seek operations
SELECT @IndexSeekCount = @PlanXML.value('count(//RelOp[@PhysicalOp="Index Seek"])', 'INT');

-- Count Table Scan operations
SELECT @TableScanCount = @PlanXML.value('count(//RelOp[@PhysicalOp="Table Scan"])', 'INT');

-- Count Clustered Index Scan operations
SELECT @ClusteredIndexScanCount = @PlanXML.value('count(//RelOp[@PhysicalOp="Clustered Index Scan"])', 'INT');

PRINT 'Execution Plan Statistics:';
PRINT '-------------------------';
PRINT 'Index Seek operations: ' + CAST(@IndexSeekCount AS NVARCHAR(20));
PRINT 'Table Scan operations: ' + CAST(@TableScanCount AS NVARCHAR(20));
PRINT 'Clustered Index Scan operations: ' + CAST(@ClusteredIndexScanCount AS NVARCHAR(20));
PRINT '';

-- =============================================
-- Extract specific index usage details
-- =============================================
PRINT 'Index Usage Details:';
PRINT '-------------------';
PRINT '';

-- Extract index seek details from execution plan
WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT 
    RelOp.value('@PhysicalOp', 'NVARCHAR(50)') AS OperationType,
    RelOp.value('(./IndexScan/Object/@Table)[1]', 'NVARCHAR(128)') AS TableName,
    RelOp.value('(./IndexScan/Object/@Index)[1]', 'NVARCHAR(128)') AS IndexName,
    RelOp.value('@EstimateRows', 'FLOAT') AS EstimatedRows,
    RelOp.value('@EstimateIO', 'FLOAT') AS EstimatedIO,
    RelOp.value('@EstimateCPU', 'FLOAT') AS EstimatedCPU
FROM @PlanXML.nodes('//RelOp') AS T(RelOp)
WHERE RelOp.value('@PhysicalOp', 'NVARCHAR(50)') IN ('Index Seek', 'Table Scan', 'Clustered Index Scan')
ORDER BY 
    CASE RelOp.value('@PhysicalOp', 'NVARCHAR(50)')
        WHEN 'Index Seek' THEN 1
        WHEN 'Clustered Index Scan' THEN 2
        WHEN 'Table Scan' THEN 3
    END;

PRINT '';

-- =============================================
-- Verify specific indexes are used
-- =============================================
PRINT '========================================';
PRINT 'Verifying Required Index Usage';
PRINT '========================================';
PRINT '';

DECLARE @BookingsIndexUsed BIT = 0;
DECLARE @RoomsIndexUsed BIT = 0;

-- Check if IX_Bookings_Status_CheckIn_Includes is used
IF @PlanXML.exist('//IndexScan/Object[@Index="[IX_Bookings_Status_CheckIn_Includes]"]') = 1
BEGIN
    SET @BookingsIndexUsed = 1;
    PRINT '✓ IX_Bookings_Status_CheckIn_Includes is used';
END
ELSE
BEGIN
    PRINT '✗ IX_Bookings_Status_CheckIn_Includes is NOT used';
    PRINT '  This index is critical for performance!';
END

-- Check if IX_Rooms_HotelId_Includes is used
IF @PlanXML.exist('//IndexScan/Object[@Index="[IX_Rooms_HotelId_Includes]"]') = 1
BEGIN
    SET @RoomsIndexUsed = 1;
    PRINT '✓ IX_Rooms_HotelId_Includes is used';
END
ELSE
BEGIN
    PRINT '✗ IX_Rooms_HotelId_Includes is NOT used';
    PRINT '  This index is critical for performance!';
END

PRINT '';

-- =============================================
-- Check for table scans on critical tables
-- =============================================
PRINT 'Checking for table scans on critical tables...';
PRINT '';

DECLARE @BookingsTableScan BIT = 0;
DECLARE @RoomsTableScan BIT = 0;

-- Check for table scan on Bookings
IF @PlanXML.exist('//RelOp[@PhysicalOp="Table Scan"]/*/Object[@Table="[Bookings]"]') = 1
BEGIN
    SET @BookingsTableScan = 1;
    PRINT '✗ WARNING: Table Scan detected on Bookings table';
    PRINT '  This will cause poor performance on large datasets!';
END
ELSE
BEGIN
    PRINT '✓ No table scan on Bookings table';
END

-- Check for table scan on Rooms
IF @PlanXML.exist('//RelOp[@PhysicalOp="Table Scan"]/*/Object[@Table="[Rooms]"]') = 1
BEGIN
    SET @RoomsTableScan = 1;
    PRINT '✗ WARNING: Table Scan detected on Rooms table';
    PRINT '  This will cause poor performance on large datasets!';
END
ELSE
BEGIN
    PRINT '✓ No table scan on Rooms table';
END

PRINT '';

-- =============================================
-- Check for missing index recommendations
-- =============================================
PRINT 'Checking for missing index recommendations...';
PRINT '';

IF @PlanXML.exist('//MissingIndexes') = 1
BEGIN
    PRINT '⚠ WARNING: Execution plan contains missing index recommendations';
    PRINT '';
    
    -- Extract missing index details
    WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
    SELECT 
        MissingIndex.value('(@Database)[1]', 'NVARCHAR(128)') AS DatabaseName,
        MissingIndex.value('(@Schema)[1]', 'NVARCHAR(128)') AS SchemaName,
        MissingIndex.value('(@Table)[1]', 'NVARCHAR(128)') AS TableName,
        MissingIndex.value('(./ColumnGroup[@Usage="EQUALITY"]/Column/@Name)[1]', 'NVARCHAR(MAX)') AS EqualityColumns,
        MissingIndex.value('(./ColumnGroup[@Usage="INCLUDE"]/Column/@Name)[1]', 'NVARCHAR(MAX)') AS IncludeColumns,
        MissingIndexGroup.value('(@Impact)[1]', 'FLOAT') AS ImpactPercent
    FROM @PlanXML.nodes('//MissingIndex') AS T(MissingIndex)
    CROSS APPLY @PlanXML.nodes('//MissingIndexGroup') AS G(MissingIndexGroup);
    
    PRINT '';
END
ELSE
BEGIN
    PRINT '✓ No missing index recommendations';
END

PRINT '';

-- =============================================
-- Final Verification Results
-- =============================================
PRINT '========================================';
PRINT 'Task 1.5.4 Verification Results';
PRINT '========================================';
PRINT '';

DECLARE @AllChecksPassed BIT = 1;

-- Check 1: Index seeks are used
IF @IndexSeekCount > 0
BEGIN
    PRINT '✓ Check 1: Index Seek operations found (' + CAST(@IndexSeekCount AS NVARCHAR(20)) + ')';
END
ELSE
BEGIN
    PRINT '✗ Check 1: No Index Seek operations found';
    SET @AllChecksPassed = 0;
END

-- Check 2: No table scans on critical tables
IF @BookingsTableScan = 0 AND @RoomsTableScan = 0
BEGIN
    PRINT '✓ Check 2: No table scans on Bookings or Rooms tables';
END
ELSE
BEGIN
    PRINT '✗ Check 2: Table scans detected on critical tables';
    SET @AllChecksPassed = 0;
END

-- Check 3: Required indexes are used
IF @BookingsIndexUsed = 1 AND @RoomsIndexUsed = 1
BEGIN
    PRINT '✓ Check 3: Required indexes are used';
END
ELSE
BEGIN
    PRINT '✗ Check 3: Required indexes are not used';
    SET @AllChecksPassed = 0;
END

PRINT '';

-- =============================================
-- Final Status
-- =============================================
IF @AllChecksPassed = 1
BEGIN
    PRINT '========================================';
    PRINT 'Task 1.5.4: PASSED ✓';
    PRINT '========================================';
    PRINT '';
    PRINT 'The execution plan uses index seeks (not table scans)';
    PRINT 'Performance optimization is successful!';
END
ELSE
BEGIN
    PRINT '========================================';
    PRINT 'Task 1.5.4: FAILED ✗';
    PRINT '========================================';
    PRINT '';
    PRINT 'Issues detected:';
    IF @IndexSeekCount = 0
        PRINT '- No index seek operations found';
    IF @BookingsTableScan = 1
        PRINT '- Table scan on Bookings table';
    IF @RoomsTableScan = 1
        PRINT '- Table scan on Rooms table';
    IF @BookingsIndexUsed = 0
        PRINT '- IX_Bookings_Status_CheckIn_Includes not used';
    IF @RoomsIndexUsed = 0
        PRINT '- IX_Rooms_HotelId_Includes not used';
    PRINT '';
    PRINT 'Action Required:';
    PRINT '1. Verify indexes exist (run test_all_indexes_task_1.2.4.sql)';
    PRINT '2. Update statistics (run 08_update_statistics.sql)';
    PRINT '3. Review stored procedure query logic';
    PRINT '4. Check for parameter sniffing issues';
END

PRINT '';
PRINT 'Additional Information:';
PRINT '----------------------';
PRINT 'To view the full execution plan:';
PRINT '1. Enable "Include Actual Execution Plan" in SSMS (Ctrl+M)';
PRINT '2. Execute: EXEC Quarterly_Revenue_Analytics NULL, NULL, NULL';
PRINT '3. Review the "Execution Plan" tab';
PRINT '';
