-- verify_index_task_1.2.2.sql
-- Verification script for Task 1.2.2: Verify index IX_Bookings_Status_CheckIn_Includes exists

PRINT 'Task 1.2.2: Verifying index IX_Bookings_Status_CheckIn_Includes';
PRINT '================================================================';
PRINT '';

-- Check if the index exists
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('Bookings')
    AND name = 'IX_Bookings_Status_CheckIn_Includes'
)
BEGIN
    PRINT '✓ SUCCESS: Index IX_Bookings_Status_CheckIn_Includes exists';
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
    WHERE i.object_id = OBJECT_ID('Bookings')
    AND i.name = 'IX_Bookings_Status_CheckIn_Includes'
    ORDER BY ic.is_included_column, ic.key_ordinal;
    
    PRINT '';
    PRINT 'Verification Details:';
    PRINT '--------------------';
    PRINT '- Index Name: IX_Bookings_Status_CheckIn_Includes';
    PRINT '- Table: Bookings';
    PRINT '- Key Columns: Status (ASC), CheckIn (ASC)';
    PRINT '- Included Columns: RoomId, TotalAmount';
    PRINT '- Purpose: Optimize quarterly revenue analytics queries';
    PRINT '';
    PRINT 'Performance Benefits:';
    PRINT '--------------------';
    PRINT '- Enables index seeks for Status filtering (e.g., Status = ''Completed'')';
    PRINT '- Supports efficient date range queries on CheckIn';
    PRINT '- Covering index eliminates key lookups for RoomId and TotalAmount';
    PRINT '- Expected to reduce query execution time for 100,000 booking records to <2 seconds';
    PRINT '';
    PRINT 'Task 1.2.2: COMPLETE ✓';
END
ELSE
BEGIN
    PRINT '✗ FAILURE: Index IX_Bookings_Status_CheckIn_Includes does NOT exist';
    PRINT '';
    PRINT 'Expected Configuration:';
    PRINT '----------------------';
    PRINT '- Index Name: IX_Bookings_Status_CheckIn_Includes';
    PRINT '- Table: Bookings';
    PRINT '- Key Columns: Status (ASC), CheckIn (ASC)';
    PRINT '- Included Columns: RoomId, TotalAmount';
    PRINT '';
    PRINT 'Action Required:';
    PRINT '---------------';
    PRINT 'Run the migration script: 04_create_index_bookings_status_checkin.sql';
    PRINT '';
    PRINT 'Task 1.2.2: FAILED ✗';
END
PRINT '';
PRINT '================================================================';
