-- verify_index_task_1.2.1.sql
-- Verification script for Task 1.2.1: Verify index IX_RoomRateChangeLog_RoomId_ChangedAt exists

PRINT 'Task 1.2.1: Verifying index IX_RoomRateChangeLog_RoomId_ChangedAt';
PRINT '================================================================';
PRINT '';

-- Check if the index exists
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('RoomRateChangeLog')
    AND name = 'IX_RoomRateChangeLog_RoomId_ChangedAt'
)
BEGIN
    PRINT '✓ SUCCESS: Index IX_RoomRateChangeLog_RoomId_ChangedAt exists';
    PRINT '';
    
    -- Display index details
    PRINT 'Index Details:';
    PRINT '--------------';
    
    SELECT 
        i.name AS IndexName,
        i.type_desc AS IndexType,
        i.is_unique AS IsUnique,
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
    PRINT 'Verification Details:';
    PRINT '--------------------';
    PRINT '- Index Name: IX_RoomRateChangeLog_RoomId_ChangedAt';
    PRINT '- Table: RoomRateChangeLog';
    PRINT '- Columns: RoomId (ASC), ChangedAt (DESC)';
    PRINT '- Purpose: Optimize audit queries by RoomId and time range';
    PRINT '';
    PRINT 'Task 1.2.1: COMPLETE ✓';
END
ELSE
BEGIN
    PRINT '✗ FAILURE: Index IX_RoomRateChangeLog_RoomId_ChangedAt does NOT exist';
    PRINT '';
    PRINT 'Expected Configuration:';
    PRINT '----------------------';
    PRINT '- Index Name: IX_RoomRateChangeLog_RoomId_ChangedAt';
    PRINT '- Table: RoomRateChangeLog';
    PRINT '- Columns: RoomId (ASC), ChangedAt (DESC)';
    PRINT '';
    PRINT 'Action Required:';
    PRINT '---------------';
    PRINT 'Run the migration script: 03_room_rate_change_log.sql';
    PRINT '';
    PRINT 'Task 1.2.1: FAILED ✗';
END
PRINT '';
PRINT '================================================================';
