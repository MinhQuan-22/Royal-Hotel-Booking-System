-- 03_room_rate_change_log.sql
-- Migration script for RoomRateChangeLog table
-- Purpose: Create audit table for tracking room rate changes exceeding 50%

-- Step 1: Create RoomRateChangeLog table if it doesn't exist
IF OBJECT_ID('RoomRateChangeLog', 'U') IS NULL
BEGIN
    CREATE TABLE RoomRateChangeLog (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        RoomId INT NOT NULL,
        OldRate DECIMAL(18,2) NOT NULL,
        NewRate DECIMAL(18,2) NOT NULL,
        ChangePercent DECIMAL(5,2) NOT NULL,
        ChangedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
        ChangedBy NVARCHAR(100) NULL,

        CONSTRAINT FK_RoomRateChangeLog_Rooms
            FOREIGN KEY (RoomId) REFERENCES Rooms(Id)
    );

    PRINT 'RoomRateChangeLog table created successfully.';
END
ELSE
BEGIN
    PRINT 'RoomRateChangeLog table already exists.';
END
GO

-- Step 2: Create index for efficient audit queries
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_RoomRateChangeLog_RoomId_ChangedAt' 
    AND object_id = OBJECT_ID('RoomRateChangeLog')
)
BEGIN
    CREATE INDEX IX_RoomRateChangeLog_RoomId_ChangedAt
        ON RoomRateChangeLog(RoomId, ChangedAt DESC);

    PRINT 'Index IX_RoomRateChangeLog_RoomId_ChangedAt created successfully.';
END
ELSE
BEGIN
    PRINT 'Index IX_RoomRateChangeLog_RoomId_ChangedAt already exists.';
END
GO

-- Step 3: Verify table structure
IF OBJECT_ID('RoomRateChangeLog', 'U') IS NOT NULL
BEGIN
    PRINT 'Verification: RoomRateChangeLog table structure';
    PRINT '-----------------------------------------------';
    
    SELECT 
        c.name AS ColumnName,
        t.name AS DataType,
        c.max_length AS MaxLength,
        c.precision AS Precision,
        c.scale AS Scale,
        c.is_nullable AS IsNullable,
        dc.definition AS DefaultValue
    FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
    WHERE c.object_id = OBJECT_ID('RoomRateChangeLog')
    ORDER BY c.column_id;

    PRINT '';
    PRINT 'Verification: Constraints';
    PRINT '-------------------------';
    
    SELECT 
        fk.name AS ConstraintName,
        OBJECT_NAME(fk.parent_object_id) AS TableName,
        COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
        OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
        COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
    FROM sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    WHERE fk.parent_object_id = OBJECT_ID('RoomRateChangeLog');

    PRINT '';
    PRINT 'Verification: Indexes';
    PRINT '--------------------';
    
    SELECT 
        i.name AS IndexName,
        i.type_desc AS IndexType,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.key_ordinal AS KeyOrdinal,
        ic.is_descending_key AS IsDescending
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID('RoomRateChangeLog')
    ORDER BY i.name, ic.key_ordinal;

    PRINT '';
    PRINT 'RoomRateChangeLog table verification complete.';
END
GO
