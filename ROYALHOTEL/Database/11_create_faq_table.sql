-- 11_create_faq_table.sql
-- Migration script for AI Live Chat Support feature - FAQ table
-- Purpose: Create FAQ table for caching frequently asked questions

-- Step 1: Create FAQ table if it doesn't exist
IF OBJECT_ID('FAQ', 'U') IS NULL
BEGIN
    CREATE TABLE FAQ (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Question NVARCHAR(500) NOT NULL,
        Answer NVARCHAR(MAX) NOT NULL,
        Category NVARCHAR(100) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT CK_FAQ_Category
            CHECK (Category IN ('Policies', 'Amenities', 'Booking', 'Payment'))
    );

    PRINT 'FAQ table created successfully.';
END
ELSE
BEGIN
    PRINT 'FAQ table already exists.';
END
GO

-- Step 2: Create index for efficient queries on Category and IsActive
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_FAQ_Category_IsActive' 
    AND object_id = OBJECT_ID('FAQ')
)
BEGIN
    CREATE INDEX IX_FAQ_Category_IsActive
        ON FAQ(Category, IsActive);

    PRINT 'Index IX_FAQ_Category_IsActive created successfully.';
END
ELSE
BEGIN
    PRINT 'Index IX_FAQ_Category_IsActive already exists.';
END
GO

-- Step 3: Verify FAQ table structure
IF OBJECT_ID('FAQ', 'U') IS NOT NULL
BEGIN
    PRINT '';
    PRINT 'Verification: FAQ table structure';
    PRINT '---------------------------------';
    
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
    WHERE c.object_id = OBJECT_ID('FAQ')
    ORDER BY c.column_id;

    PRINT '';
    PRINT 'Verification: FAQ Constraints';
    PRINT '-----------------------------';
    
    -- Check Constraints
    SELECT 
        cc.name AS ConstraintName,
        'CHECK' AS ConstraintType,
        cc.definition AS Definition
    FROM sys.check_constraints cc
    WHERE cc.parent_object_id = OBJECT_ID('FAQ');

    PRINT '';
    PRINT 'Verification: FAQ Indexes';
    PRINT '-------------------------';
    
    SELECT 
        i.name AS IndexName,
        i.type_desc AS IndexType,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.key_ordinal AS KeyOrdinal,
        ic.is_descending_key AS IsDescending
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID('FAQ')
    AND i.name IS NOT NULL
    ORDER BY i.name, ic.key_ordinal;

    PRINT '';
    PRINT 'FAQ table verification complete.';
END
GO

PRINT '';
PRINT '==============================================';
PRINT 'Migration 11_create_faq_table.sql completed';
PRINT '==============================================';
GO
