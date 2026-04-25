-- 05_create_index_rooms_hotelid.sql
-- Migration script for Task 1.2.3: Create performance index on Rooms table
-- Purpose: Optimize hotel-room joins in quarterly revenue analytics

-- Step 1: Check if index already exists
IF EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Rooms_HotelId_Includes' 
    AND object_id = OBJECT_ID('Rooms')
)
BEGIN
    PRINT 'Index IX_Rooms_HotelId_Includes already exists.';
    PRINT 'Skipping index creation.';
END
ELSE
BEGIN
    -- Step 2: Create the covering index
    CREATE INDEX IX_Rooms_HotelId_Includes
        ON Rooms(HotelId)
        INCLUDE (Code, Name);

    PRINT 'Index IX_Rooms_HotelId_Includes created successfully.';
END
GO

-- Step 3: Verify index creation
IF EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Rooms_HotelId_Includes' 
    AND object_id = OBJECT_ID('Rooms')
)
BEGIN
    PRINT '';
    PRINT 'Verification: Index IX_Rooms_HotelId_Includes';
    PRINT '==============================================';
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
    WHERE i.object_id = OBJECT_ID('Rooms')
    AND i.name = 'IX_Rooms_HotelId_Includes'
    ORDER BY ic.is_included_column, ic.key_ordinal;
    
    PRINT '';
    PRINT 'Index Configuration:';
    PRINT '-------------------';
    PRINT '- Index Name: IX_Rooms_HotelId_Includes';
    PRINT '- Table: Rooms';
    PRINT '- Key Column: HotelId (ASC)';
    PRINT '- Included Columns: Code, Name';
    PRINT '- Purpose: Optimize hotel-room joins in analytics queries';
    PRINT '';
    PRINT 'Performance Benefits:';
    PRINT '--------------------';
    PRINT '- Enables index seeks for HotelId filtering';
    PRINT '- Supports efficient joins between Bookings and Rooms tables';
    PRINT '- Supports efficient joins between Rooms and Hotels tables';
    PRINT '- Covering index eliminates key lookups for Code and Name';
    PRINT '- Optimizes Quarterly_Revenue_Analytics stored procedure';
    PRINT '- Reduces I/O operations when displaying room information';
    PRINT '';
    PRINT 'Task 1.2.3: Index creation COMPLETE ✓';
END
ELSE
BEGIN
    PRINT '';
    PRINT '✗ ERROR: Index IX_Rooms_HotelId_Includes was not created';
    PRINT 'Please review the script and try again.';
    PRINT '';
    PRINT 'Task 1.2.3: FAILED ✗';
END
GO
