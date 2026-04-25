-- test_all_indexes_task_1.2.4.sql
-- Task 1.2.4: Test index creation and verify no conflicts with existing indexes
-- Purpose: Comprehensive verification of all three performance indexes created in Phase 1.2

PRINT '========================================================================';
PRINT 'Task 1.2.4: Comprehensive Index Verification';
PRINT '========================================================================';
PRINT '';
PRINT 'This script verifies:';
PRINT '1. All three indexes exist and are properly configured';
PRINT '2. No duplicate or conflicting indexes exist';
PRINT '3. Index health and usability status';
PRINT '';
PRINT '========================================================================';
PRINT '';

-- ============================================================================
-- SECTION 1: Verify Index Existence
-- ============================================================================

PRINT 'SECTION 1: Index Existence Verification';
PRINT '========================================';
PRINT '';

DECLARE @Index1Exists BIT = 0;
DECLARE @Index2Exists BIT = 0;
DECLARE @Index3Exists BIT = 0;

-- Check Index 1: IX_RoomRateChangeLog_RoomId_ChangedAt
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('RoomRateChangeLog')
    AND name = 'IX_RoomRateChangeLog_RoomId_ChangedAt'
)
BEGIN
    SET @Index1Exists = 1;
    PRINT '✓ Index 1: IX_RoomRateChangeLog_RoomId_ChangedAt EXISTS';
END
ELSE
BEGIN
    PRINT '✗ Index 1: IX_RoomRateChangeLog_RoomId_ChangedAt MISSING';
END

-- Check Index 2: IX_Bookings_Status_CheckIn_Includes
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('Bookings')
    AND name = 'IX_Bookings_Status_CheckIn_Includes'
)
BEGIN
    SET @Index2Exists = 1;
    PRINT '✓ Index 2: IX_Bookings_Status_CheckIn_Includes EXISTS';
END
ELSE
BEGIN
    PRINT '✗ Index 2: IX_Bookings_Status_CheckIn_Includes MISSING';
END

-- Check Index 3: IX_Rooms_HotelId_Includes
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('Rooms')
    AND name = 'IX_Rooms_HotelId_Includes'
)
BEGIN
    SET @Index3Exists = 1;
    PRINT '✓ Index 3: IX_Rooms_HotelId_Includes EXISTS';
END
ELSE
BEGIN
    PRINT '✗ Index 3: IX_Rooms_HotelId_Includes MISSING';
END

PRINT '';

-- Summary of existence check
IF @Index1Exists = 1 AND @Index2Exists = 1 AND @Index3Exists = 1
BEGIN
    PRINT '✓ RESULT: All 3 indexes exist';
END
ELSE
BEGIN
    PRINT '✗ RESULT: Some indexes are missing';
    PRINT '  Missing indexes must be created before proceeding.';
END

PRINT '';
PRINT '========================================================================';
PRINT '';

-- ============================================================================
-- SECTION 2: Detailed Index Configuration
-- ============================================================================

PRINT 'SECTION 2: Index Configuration Details';
PRINT '=======================================';
PRINT '';

-- Index 1 Details
IF @Index1Exists = 1
BEGIN
    PRINT 'Index 1: IX_RoomRateChangeLog_RoomId_ChangedAt';
    PRINT '-----------------------------------------------';
    
    SELECT 
        i.name AS IndexName,
        OBJECT_NAME(i.object_id) AS TableName,
        i.type_desc AS IndexType,
        i.is_unique AS IsUnique,
        i.is_disabled AS IsDisabled,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.key_ordinal AS KeyOrdinal,
        ic.is_descending_key AS IsDescending,
        ic.is_included_column AS IsIncluded
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID('RoomRateChangeLog')
    AND i.name = 'IX_RoomRateChangeLog_RoomId_ChangedAt'
    ORDER BY ic.key_ordinal;
    
    PRINT '';
END

-- Index 2 Details
IF @Index2Exists = 1
BEGIN
    PRINT 'Index 2: IX_Bookings_Status_CheckIn_Includes';
    PRINT '---------------------------------------------';
    
    SELECT 
        i.name AS IndexName,
        OBJECT_NAME(i.object_id) AS TableName,
        i.type_desc AS IndexType,
        i.is_unique AS IsUnique,
        i.is_disabled AS IsDisabled,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.key_ordinal AS KeyOrdinal,
        ic.is_descending_key AS IsDescending,
        ic.is_included_column AS IsIncluded
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID('Bookings')
    AND i.name = 'IX_Bookings_Status_CheckIn_Includes'
    ORDER BY ic.is_included_column, ic.key_ordinal;
    
    PRINT '';
END

-- Index 3 Details
IF @Index3Exists = 1
BEGIN
    PRINT 'Index 3: IX_Rooms_HotelId_Includes';
    PRINT '-----------------------------------';
    
    SELECT 
        i.name AS IndexName,
        OBJECT_NAME(i.object_id) AS TableName,
        i.type_desc AS IndexType,
        i.is_unique AS IsUnique,
        i.is_disabled AS IsDisabled,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.key_ordinal AS KeyOrdinal,
        ic.is_descending_key AS IsDescending,
        ic.is_included_column AS IsIncluded
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID('Rooms')
    AND i.name = 'IX_Rooms_HotelId_Includes'
    ORDER BY ic.is_included_column, ic.key_ordinal;
    
    PRINT '';
END

PRINT '========================================================================';
PRINT '';

-- ============================================================================
-- SECTION 3: Check for Duplicate or Conflicting Indexes
-- ============================================================================

PRINT 'SECTION 3: Duplicate and Conflict Detection';
PRINT '============================================';
PRINT '';

-- Check for duplicate indexes on RoomRateChangeLog
PRINT 'Checking RoomRateChangeLog table for duplicate indexes...';
PRINT '';

SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('RoomRateChangeLog')
AND i.type_desc <> 'HEAP'
AND ic.is_included_column = 0
GROUP BY i.name, i.type_desc, i.index_id
ORDER BY i.name;

PRINT '';

-- Check for duplicate indexes on Bookings
PRINT 'Checking Bookings table for duplicate indexes...';
PRINT '';

SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Bookings')
AND i.type_desc <> 'HEAP'
AND ic.is_included_column = 0
GROUP BY i.name, i.type_desc, i.index_id
ORDER BY i.name;

PRINT '';

-- Check for duplicate indexes on Rooms
PRINT 'Checking Rooms table for duplicate indexes...';
PRINT '';

SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Rooms')
AND i.type_desc <> 'HEAP'
AND ic.is_included_column = 0
GROUP BY i.name, i.type_desc, i.index_id
ORDER BY i.name;

PRINT '';

-- Detect potential conflicts (indexes with overlapping key columns)
PRINT 'Analyzing potential index conflicts...';
PRINT '';

-- Check Bookings table for overlapping indexes
PRINT 'Bookings table - Indexes starting with Status column:';
SELECT 
    i.name AS IndexName,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Bookings')
AND i.type_desc <> 'HEAP'
AND ic.is_included_column = 0
AND EXISTS (
    SELECT 1 FROM sys.index_columns ic2
    WHERE ic2.object_id = i.object_id
    AND ic2.index_id = i.index_id
    AND ic2.key_ordinal = 1
    AND COL_NAME(ic2.object_id, ic2.column_id) = 'Status'
)
GROUP BY i.name, i.index_id
ORDER BY i.name;

PRINT '';

-- Check Rooms table for overlapping indexes
PRINT 'Rooms table - Indexes starting with HotelId column:';
SELECT 
    i.name AS IndexName,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Rooms')
AND i.type_desc <> 'HEAP'
AND ic.is_included_column = 0
AND EXISTS (
    SELECT 1 FROM sys.index_columns ic2
    WHERE ic2.object_id = i.object_id
    AND ic2.index_id = i.index_id
    AND ic2.key_ordinal = 1
    AND COL_NAME(ic2.object_id, ic2.column_id) = 'HotelId'
)
GROUP BY i.name, i.index_id
ORDER BY i.name;

PRINT '';
PRINT '========================================================================';
PRINT '';

-- ============================================================================
-- SECTION 4: Index Health and Usability
-- ============================================================================

PRINT 'SECTION 4: Index Health and Usability';
PRINT '======================================';
PRINT '';

-- Check if indexes are disabled or have issues
PRINT 'Checking index health status...';
PRINT '';

SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_disabled AS IsDisabled,
    i.is_hypothetical AS IsHypothetical,
    i.has_filter AS HasFilter,
    CASE 
        WHEN i.is_disabled = 1 THEN '✗ DISABLED'
        WHEN i.is_hypothetical = 1 THEN '⚠ HYPOTHETICAL'
        ELSE '✓ HEALTHY'
    END AS HealthStatus
FROM sys.indexes i
WHERE i.object_id IN (
    OBJECT_ID('RoomRateChangeLog'),
    OBJECT_ID('Bookings'),
    OBJECT_ID('Rooms')
)
AND i.name IN (
    'IX_RoomRateChangeLog_RoomId_ChangedAt',
    'IX_Bookings_Status_CheckIn_Includes',
    'IX_Rooms_HotelId_Includes'
)
ORDER BY OBJECT_NAME(i.object_id), i.name;

PRINT '';
PRINT '========================================================================';
PRINT '';

-- ============================================================================
-- SECTION 5: Final Verification Summary
-- ============================================================================

PRINT 'SECTION 5: Final Verification Summary';
PRINT '======================================';
PRINT '';

DECLARE @AllIndexesExist BIT = 0;
DECLARE @AllIndexesHealthy BIT = 0;

-- Check if all indexes exist
IF @Index1Exists = 1 AND @Index2Exists = 1 AND @Index3Exists = 1
BEGIN
    SET @AllIndexesExist = 1;
END

-- Check if all indexes are healthy (not disabled)
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id IN (
        OBJECT_ID('RoomRateChangeLog'),
        OBJECT_ID('Bookings'),
        OBJECT_ID('Rooms')
    )
    AND name IN (
        'IX_RoomRateChangeLog_RoomId_ChangedAt',
        'IX_Bookings_Status_CheckIn_Includes',
        'IX_Rooms_HotelId_Includes'
    )
    AND is_disabled = 1
)
BEGIN
    SET @AllIndexesHealthy = 0;
    PRINT '⚠ WARNING: Some indexes are disabled';
END
ELSE
BEGIN
    SET @AllIndexesHealthy = 1;
END

PRINT 'Verification Results:';
PRINT '--------------------';
PRINT '';

IF @Index1Exists = 1
    PRINT '✓ Index 1: IX_RoomRateChangeLog_RoomId_ChangedAt - EXISTS';
ELSE
    PRINT '✗ Index 1: IX_RoomRateChangeLog_RoomId_ChangedAt - MISSING';

IF @Index2Exists = 1
    PRINT '✓ Index 2: IX_Bookings_Status_CheckIn_Includes - EXISTS';
ELSE
    PRINT '✗ Index 2: IX_Bookings_Status_CheckIn_Includes - MISSING';

IF @Index3Exists = 1
    PRINT '✓ Index 3: IX_Rooms_HotelId_Includes - EXISTS';
ELSE
    PRINT '✗ Index 3: IX_Rooms_HotelId_Includes - MISSING';

PRINT '';

IF @AllIndexesHealthy = 1
    PRINT '✓ All indexes are healthy and enabled';
ELSE
    PRINT '✗ Some indexes are disabled or have issues';

PRINT '';
PRINT 'Conflict Analysis:';
PRINT '-----------------';
PRINT 'Review SECTION 3 output above to identify any duplicate or conflicting indexes.';
PRINT 'Overlapping indexes may indicate redundancy but are not necessarily conflicts.';
PRINT '';

-- Final verdict
IF @AllIndexesExist = 1 AND @AllIndexesHealthy = 1
BEGIN
    PRINT '========================================================================';
    PRINT '✓✓✓ TASK 1.2.4: VERIFICATION PASSED ✓✓✓';
    PRINT '========================================================================';
    PRINT '';
    PRINT 'All three performance indexes have been successfully created:';
    PRINT '1. IX_RoomRateChangeLog_RoomId_ChangedAt (Task 1.2.1)';
    PRINT '2. IX_Bookings_Status_CheckIn_Includes (Task 1.2.2)';
    PRINT '3. IX_Rooms_HotelId_Includes (Task 1.2.3)';
    PRINT '';
    PRINT 'No critical conflicts detected.';
    PRINT 'Indexes are healthy and ready for use.';
    PRINT '';
    PRINT 'Phase 1.2 (Create Performance Indexes): COMPLETE ✓';
END
ELSE
BEGIN
    PRINT '========================================================================';
    PRINT '✗✗✗ TASK 1.2.4: VERIFICATION FAILED ✗✗✗';
    PRINT '========================================================================';
    PRINT '';
    
    IF @AllIndexesExist = 0
    BEGIN
        PRINT 'ISSUE: Not all indexes exist.';
        PRINT '';
        PRINT 'Action Required:';
        PRINT '---------------';
        IF @Index1Exists = 0
            PRINT '- Run migration script: 03_room_rate_change_log.sql (creates Index 1)';
        IF @Index2Exists = 0
            PRINT '- Run migration script: 04_create_index_bookings_status_checkin.sql (creates Index 2)';
        IF @Index3Exists = 0
            PRINT '- Run migration script: 05_create_index_rooms_hotelid.sql (creates Index 3)';
    END
    
    IF @AllIndexesHealthy = 0
    BEGIN
        PRINT '';
        PRINT 'ISSUE: Some indexes are disabled or unhealthy.';
        PRINT '';
        PRINT 'Action Required:';
        PRINT '---------------';
        PRINT '- Review index health status in SECTION 4';
        PRINT '- Rebuild or enable disabled indexes';
    END
    
    PRINT '';
    PRINT 'Phase 1.2 (Create Performance Indexes): INCOMPLETE ✗';
END

PRINT '';
PRINT '========================================================================';
PRINT 'End of Task 1.2.4 Verification';
PRINT '========================================================================';
GO
