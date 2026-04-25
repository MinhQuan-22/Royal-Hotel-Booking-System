-- verify_index_task_1.2.3.sql
-- Verification script for Task 1.2.3: IX_Rooms_HotelId_Includes index
-- Purpose: Verify index exists and is properly configured

PRINT '========================================';
PRINT 'Task 1.2.3 Index Verification';
PRINT '========================================';
PRINT '';

-- Check if index exists
IF EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Rooms_HotelId_Includes' 
    AND object_id = OBJECT_ID('Rooms')
)
BEGIN
    PRINT '✓ Index IX_Rooms_HotelId_Includes exists on Rooms table';
    PRINT '';
    
    -- Display detailed index information
    PRINT 'Index Details:';
    PRINT '--------------';
    SELECT 
        i.name AS IndexName,
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
    PRINT 'Expected Configuration:';
    PRINT '----------------------';
    PRINT '- Key Column: HotelId (ASC)';
    PRINT '- Included Columns: Code, Name';
    PRINT '';
    
    -- Verify key columns
    DECLARE @KeyColumns NVARCHAR(MAX);
    SELECT @KeyColumns = STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ')
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID('Rooms')
    AND i.name = 'IX_Rooms_HotelId_Includes'
    AND ic.is_included_column = 0;
    
    -- Verify included columns
    DECLARE @IncludedColumns NVARCHAR(MAX);
    SELECT @IncludedColumns = STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ')
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID('Rooms')
    AND i.name = 'IX_Rooms_HotelId_Includes'
    AND ic.is_included_column = 1;
    
    PRINT 'Actual Configuration:';
    PRINT '--------------------';
    PRINT '- Key Columns: ' + ISNULL(@KeyColumns, 'NONE');
    PRINT '- Included Columns: ' + ISNULL(@IncludedColumns, 'NONE');
    PRINT '';
    
    -- Validation checks
    IF @KeyColumns = 'HotelId' AND @IncludedColumns LIKE '%Code%' AND @IncludedColumns LIKE '%Name%'
    BEGIN
        PRINT '✓ Index configuration is CORRECT';
        PRINT '';
        PRINT 'Performance Impact:';
        PRINT '------------------';
        PRINT '- Optimizes joins: Bookings -> Rooms -> Hotels';
        PRINT '- Eliminates key lookups for room Code and Name';
        PRINT '- Supports efficient filtering by HotelId';
        PRINT '- Improves Quarterly_Revenue_Analytics performance';
        PRINT '';
        PRINT 'Task 1.2.3: VERIFICATION PASSED ✓';
    END
    ELSE
    BEGIN
        PRINT '✗ Index configuration is INCORRECT';
        PRINT 'Expected: Key=HotelId, Included=Code,Name';
        PRINT 'Please recreate the index with correct configuration.';
        PRINT '';
        PRINT 'Task 1.2.3: VERIFICATION FAILED ✗';
    END
END
ELSE
BEGIN
    PRINT '✗ Index IX_Rooms_HotelId_Includes does NOT exist on Rooms table';
    PRINT '';
    PRINT 'Action Required:';
    PRINT '---------------';
    PRINT 'Run the migration script: 05_create_index_rooms_hotelid.sql';
    PRINT '';
    PRINT 'Task 1.2.3: VERIFICATION FAILED ✗';
END
GO
