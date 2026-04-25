-- 04_create_index_bookings_status_checkin.sql
-- Migration script for Task 1.2.2: Create performance index on Bookings table
-- Purpose: Optimize quarterly revenue analytics queries

-- Step 1: Check if index already exists
IF EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Bookings_Status_CheckIn_Includes' 
    AND object_id = OBJECT_ID('Bookings')
)
BEGIN
    PRINT 'Index IX_Bookings_Status_CheckIn_Includes already exists.';
    PRINT 'Skipping index creation.';
END
ELSE
BEGIN
    -- Step 2: Create the covering index
    CREATE INDEX IX_Bookings_Status_CheckIn_Includes
        ON Bookings(Status, CheckIn)
        INCLUDE (RoomId, TotalAmount);

    PRINT 'Index IX_Bookings_Status_CheckIn_Includes created successfully.';
END
GO

-- Step 3: Verify index creation
IF EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Bookings_Status_CheckIn_Includes' 
    AND object_id = OBJECT_ID('Bookings')
)
BEGIN
    PRINT '';
    PRINT 'Verification: Index IX_Bookings_Status_CheckIn_Includes';
    PRINT '======================================================';
    PRINT '';
    
    -- Display index details
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
    PRINT 'Index Configuration:';
    PRINT '-------------------';
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
    PRINT '- Optimizes Quarterly_Revenue_Analytics stored procedure';
    PRINT '';
    PRINT 'Task 1.2.2: Index creation COMPLETE ✓';
END
ELSE
BEGIN
    PRINT '';
    PRINT '✗ ERROR: Index IX_Bookings_Status_CheckIn_Includes was not created';
    PRINT 'Please review the script and try again.';
    PRINT '';
    PRINT 'Task 1.2.2: FAILED ✗';
END
GO
