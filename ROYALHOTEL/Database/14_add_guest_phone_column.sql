-- 14_add_guest_phone_column.sql
-- Migration script for Live Chat Guest Identification feature
-- Purpose: Add GuestPhone column to ChatConversations table for storing guest phone numbers

-- Step 1: Check if column already exists and add if not
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'ChatConversations'
    AND COLUMN_NAME = 'GuestPhone'
)
BEGIN
    -- Add GuestPhone column
    ALTER TABLE ChatConversations
    ADD GuestPhone NVARCHAR(20) NULL;

    PRINT 'GuestPhone column added successfully to ChatConversations table.';
END
ELSE
BEGIN
    PRINT 'GuestPhone column already exists in ChatConversations table.';
END
GO

-- Step 2: Verify column was added
PRINT '';
PRINT 'Verification: GuestPhone column details';
PRINT '---------------------------------------';

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ChatConversations'
AND COLUMN_NAME = 'GuestPhone';
GO

-- Step 3: Display updated ChatConversations table structure
PRINT '';
PRINT 'Verification: Updated ChatConversations table structure';
PRINT '-------------------------------------------------------';

SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable,
    dc.definition AS DefaultValue
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
WHERE c.object_id = OBJECT_ID('ChatConversations')
ORDER BY c.column_id;
GO

PRINT '';
PRINT '====================================================';
PRINT 'Migration 14_add_guest_phone_column.sql completed';
PRINT '====================================================';
GO
