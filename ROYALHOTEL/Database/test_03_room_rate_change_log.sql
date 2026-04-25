-- test_03_room_rate_change_log.sql
-- Test script for RoomRateChangeLog table creation
-- This script validates the table structure and constraints

PRINT 'Starting RoomRateChangeLog table tests...';
PRINT '';

-- Test 1: Verify table exists
PRINT 'Test 1: Verify RoomRateChangeLog table exists';
IF OBJECT_ID('RoomRateChangeLog', 'U') IS NOT NULL
    PRINT '  ✓ PASS: RoomRateChangeLog table exists';
ELSE
BEGIN
    PRINT '  ✗ FAIL: RoomRateChangeLog table does not exist';
    PRINT '  Please run 03_room_rate_change_log.sql first';
    RETURN;
END
PRINT '';

-- Test 2: Verify all required columns exist
PRINT 'Test 2: Verify all required columns exist';
DECLARE @MissingColumns TABLE (ColumnName NVARCHAR(100));

IF COL_LENGTH('RoomRateChangeLog', 'Id') IS NULL
    INSERT INTO @MissingColumns VALUES ('Id');
IF COL_LENGTH('RoomRateChangeLog', 'RoomId') IS NULL
    INSERT INTO @MissingColumns VALUES ('RoomId');
IF COL_LENGTH('RoomRateChangeLog', 'OldRate') IS NULL
    INSERT INTO @MissingColumns VALUES ('OldRate');
IF COL_LENGTH('RoomRateChangeLog', 'NewRate') IS NULL
    INSERT INTO @MissingColumns VALUES ('NewRate');
IF COL_LENGTH('RoomRateChangeLog', 'ChangePercent') IS NULL
    INSERT INTO @MissingColumns VALUES ('ChangePercent');
IF COL_LENGTH('RoomRateChangeLog', 'ChangedAt') IS NULL
    INSERT INTO @MissingColumns VALUES ('ChangedAt');
IF COL_LENGTH('RoomRateChangeLog', 'ChangedBy') IS NULL
    INSERT INTO @MissingColumns VALUES ('ChangedBy');

IF NOT EXISTS (SELECT 1 FROM @MissingColumns)
    PRINT '  ✓ PASS: All required columns exist';
ELSE
BEGIN
    PRINT '  ✗ FAIL: Missing columns:';
    SELECT '    - ' + ColumnName FROM @MissingColumns;
END
PRINT '';

-- Test 3: Verify column data types
PRINT 'Test 3: Verify column data types';
DECLARE @TypeErrors TABLE (ColumnName NVARCHAR(100), Expected NVARCHAR(50), Actual NVARCHAR(50));

-- Check Id column (INT IDENTITY)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID('RoomRateChangeLog')
    AND c.name = 'Id'
    AND t.name = 'int'
    AND c.is_identity = 1
)
    INSERT INTO @TypeErrors VALUES ('Id', 'INT IDENTITY', 'Incorrect');

-- Check RoomId column (INT NOT NULL)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID('RoomRateChangeLog')
    AND c.name = 'RoomId'
    AND t.name = 'int'
    AND c.is_nullable = 0
)
    INSERT INTO @TypeErrors VALUES ('RoomId', 'INT NOT NULL', 'Incorrect');

-- Check OldRate column (DECIMAL(18,2) NOT NULL)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID('RoomRateChangeLog')
    AND c.name = 'OldRate'
    AND t.name = 'decimal'
    AND c.precision = 18
    AND c.scale = 2
    AND c.is_nullable = 0
)
    INSERT INTO @TypeErrors VALUES ('OldRate', 'DECIMAL(18,2) NOT NULL', 'Incorrect');

-- Check NewRate column (DECIMAL(18,2) NOT NULL)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID('RoomRateChangeLog')
    AND c.name = 'NewRate'
    AND t.name = 'decimal'
    AND c.precision = 18
    AND c.scale = 2
    AND c.is_nullable = 0
)
    INSERT INTO @TypeErrors VALUES ('NewRate', 'DECIMAL(18,2) NOT NULL', 'Incorrect');

-- Check ChangePercent column (DECIMAL(5,2) NOT NULL)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID('RoomRateChangeLog')
    AND c.name = 'ChangePercent'
    AND t.name = 'decimal'
    AND c.precision = 5
    AND c.scale = 2
    AND c.is_nullable = 0
)
    INSERT INTO @TypeErrors VALUES ('ChangePercent', 'DECIMAL(5,2) NOT NULL', 'Incorrect');

-- Check ChangedAt column (DATETIME2 NOT NULL with DEFAULT)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID('RoomRateChangeLog')
    AND c.name = 'ChangedAt'
    AND t.name = 'datetime2'
    AND c.is_nullable = 0
)
    INSERT INTO @TypeErrors VALUES ('ChangedAt', 'DATETIME2 NOT NULL', 'Incorrect');

-- Check ChangedBy column (NVARCHAR(100) NULL)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID('RoomRateChangeLog')
    AND c.name = 'ChangedBy'
    AND t.name = 'nvarchar'
    AND c.max_length = 200  -- nvarchar stores 2 bytes per character
    AND c.is_nullable = 1
)
    INSERT INTO @TypeErrors VALUES ('ChangedBy', 'NVARCHAR(100) NULL', 'Incorrect');

IF NOT EXISTS (SELECT 1 FROM @TypeErrors)
    PRINT '  ✓ PASS: All column data types are correct';
ELSE
BEGIN
    PRINT '  ✗ FAIL: Column type errors:';
    SELECT '    - ' + ColumnName + ': Expected ' + Expected + ', Got ' + Actual FROM @TypeErrors;
END
PRINT '';

-- Test 4: Verify PRIMARY KEY constraint
PRINT 'Test 4: Verify PRIMARY KEY constraint on Id';
IF EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID('RoomRateChangeLog')
    AND type = 'PK'
)
    PRINT '  ✓ PASS: PRIMARY KEY constraint exists on Id';
ELSE
    PRINT '  ✗ FAIL: PRIMARY KEY constraint missing';
PRINT '';

-- Test 5: Verify FOREIGN KEY constraint
PRINT 'Test 5: Verify FOREIGN KEY constraint on RoomId';
IF EXISTS (
    SELECT 1 FROM sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    WHERE fk.parent_object_id = OBJECT_ID('RoomRateChangeLog')
    AND fk.name = 'FK_RoomRateChangeLog_Rooms'
    AND fk.referenced_object_id = OBJECT_ID('Rooms')
    AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = 'RoomId'
    AND COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) = 'Id'
)
    PRINT '  ✓ PASS: FOREIGN KEY constraint FK_RoomRateChangeLog_Rooms exists';
ELSE
    PRINT '  ✗ FAIL: FOREIGN KEY constraint missing or incorrect';
PRINT '';

-- Test 6: Verify DEFAULT constraint on ChangedAt
PRINT 'Test 6: Verify DEFAULT constraint on ChangedAt';
IF EXISTS (
    SELECT 1 FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE c.object_id = OBJECT_ID('RoomRateChangeLog')
    AND c.name = 'ChangedAt'
    AND dc.definition LIKE '%getdate%'
)
    PRINT '  ✓ PASS: DEFAULT constraint on ChangedAt exists';
ELSE
    PRINT '  ✗ FAIL: DEFAULT constraint on ChangedAt missing';
PRINT '';

-- Test 7: Verify index exists
PRINT 'Test 7: Verify index IX_RoomRateChangeLog_RoomId_ChangedAt';
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('RoomRateChangeLog')
    AND name = 'IX_RoomRateChangeLog_RoomId_ChangedAt'
)
    PRINT '  ✓ PASS: Index IX_RoomRateChangeLog_RoomId_ChangedAt exists';
ELSE
    PRINT '  ✗ FAIL: Index IX_RoomRateChangeLog_RoomId_ChangedAt missing';
PRINT '';

-- Test 8: Test INSERT operation (if Rooms table has data)
PRINT 'Test 8: Test INSERT operation';
IF EXISTS (SELECT TOP 1 1 FROM Rooms)
BEGIN
    DECLARE @TestRoomId INT;
    SELECT TOP 1 @TestRoomId = Id FROM Rooms;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO RoomRateChangeLog (RoomId, OldRate, NewRate, ChangePercent, ChangedBy)
        VALUES (@TestRoomId, 100.00, 200.00, 100.00, 'TEST_USER');

        DECLARE @InsertedId INT = SCOPE_IDENTITY();

        -- Verify the insert
        IF EXISTS (SELECT 1 FROM RoomRateChangeLog WHERE Id = @InsertedId)
            PRINT '  ✓ PASS: INSERT operation successful';
        ELSE
            PRINT '  ✗ FAIL: INSERT operation failed';

        -- Verify DEFAULT value for ChangedAt
        IF EXISTS (
            SELECT 1 FROM RoomRateChangeLog 
            WHERE Id = @InsertedId 
            AND ChangedAt IS NOT NULL
            AND DATEDIFF(SECOND, ChangedAt, GETDATE()) < 5
        )
            PRINT '  ✓ PASS: DEFAULT value for ChangedAt working correctly';
        ELSE
            PRINT '  ✗ FAIL: DEFAULT value for ChangedAt not working';

        ROLLBACK TRANSACTION;
        PRINT '  (Test data rolled back)';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT '  ✗ FAIL: INSERT operation error: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT '  ⚠ SKIP: No rooms available for testing';
END
PRINT '';

-- Test 9: Test FOREIGN KEY constraint enforcement
PRINT 'Test 9: Test FOREIGN KEY constraint enforcement';
BEGIN TRY
    BEGIN TRANSACTION;

    -- Try to insert with invalid RoomId
    INSERT INTO RoomRateChangeLog (RoomId, OldRate, NewRate, ChangePercent, ChangedBy)
    VALUES (999999, 100.00, 200.00, 100.00, 'TEST_USER');

    ROLLBACK TRANSACTION;
    PRINT '  ✗ FAIL: FOREIGN KEY constraint not enforced (invalid RoomId accepted)';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() = 547  -- FK violation error
        PRINT '  ✓ PASS: FOREIGN KEY constraint enforced correctly';
    ELSE
        PRINT '  ✗ FAIL: Unexpected error: ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Summary
PRINT '';
PRINT '========================================';
PRINT 'RoomRateChangeLog table tests completed';
PRINT '========================================';
