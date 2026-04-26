-- 10_create_chat_tables.sql
-- Migration script for AI Live Chat Support feature
-- Purpose: Create ChatConversations and ChatMessages tables for storing chat interactions

-- Step 1: Create ChatConversations table if it doesn't exist
IF OBJECT_ID('ChatConversations', 'U') IS NULL
BEGIN
    CREATE TABLE ChatConversations (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ConversationCode NVARCHAR(50) NOT NULL UNIQUE,
        AccountId INT NULL,
        GuestName NVARCHAR(200) NULL,
        GuestEmail NVARCHAR(200) NULL,
        Status NVARCHAR(30) NOT NULL DEFAULT 'Open',
        EscalationReason NVARCHAR(500) NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT FK_ChatConversations_Accounts 
            FOREIGN KEY (AccountId) REFERENCES Accounts(Id) ON DELETE SET NULL,

        CONSTRAINT CK_ChatConversations_Status
            CHECK (Status IN ('Open', 'EscalatedToAdmin', 'AnsweredByAdmin', 'Closed'))
    );

    PRINT 'ChatConversations table created successfully.';
END
ELSE
BEGIN
    PRINT 'ChatConversations table already exists.';
END
GO

-- Step 2: Create ChatMessages table if it doesn't exist
IF OBJECT_ID('ChatMessages', 'U') IS NULL
BEGIN
    CREATE TABLE ChatMessages (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ConversationId INT NOT NULL,
        SenderType NVARCHAR(20) NOT NULL,
        MessageText NVARCHAR(MAX) NOT NULL,
        IsEscalationMessage BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT FK_ChatMessages_Conversations 
            FOREIGN KEY (ConversationId) REFERENCES ChatConversations(Id) ON DELETE CASCADE,

        CONSTRAINT CK_ChatMessages_SenderType
            CHECK (SenderType IN ('User', 'AI', 'Admin'))
    );

    PRINT 'ChatMessages table created successfully.';
END
ELSE
BEGIN
    PRINT 'ChatMessages table already exists.';
END
GO

-- Step 3: Create indexes for ChatConversations
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_ChatConversations_Status' 
    AND object_id = OBJECT_ID('ChatConversations')
)
BEGIN
    CREATE INDEX IX_ChatConversations_Status
        ON ChatConversations(Status);

    PRINT 'Index IX_ChatConversations_Status created successfully.';
END
ELSE
BEGIN
    PRINT 'Index IX_ChatConversations_Status already exists.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_ChatConversations_AccountId' 
    AND object_id = OBJECT_ID('ChatConversations')
)
BEGIN
    CREATE INDEX IX_ChatConversations_AccountId
        ON ChatConversations(AccountId);

    PRINT 'Index IX_ChatConversations_AccountId created successfully.';
END
ELSE
BEGIN
    PRINT 'Index IX_ChatConversations_AccountId already exists.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_ChatConversations_UpdatedAt' 
    AND object_id = OBJECT_ID('ChatConversations')
)
BEGIN
    CREATE INDEX IX_ChatConversations_UpdatedAt
        ON ChatConversations(UpdatedAt DESC);

    PRINT 'Index IX_ChatConversations_UpdatedAt created successfully.';
END
ELSE
BEGIN
    PRINT 'Index IX_ChatConversations_UpdatedAt already exists.';
END
GO

-- Step 4: Create index for ChatMessages
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_ChatMessages_ConversationId_CreatedAt' 
    AND object_id = OBJECT_ID('ChatMessages')
)
BEGIN
    CREATE INDEX IX_ChatMessages_ConversationId_CreatedAt
        ON ChatMessages(ConversationId, CreatedAt);

    PRINT 'Index IX_ChatMessages_ConversationId_CreatedAt created successfully.';
END
ELSE
BEGIN
    PRINT 'Index IX_ChatMessages_ConversationId_CreatedAt already exists.';
END
GO

-- Step 5: Verify ChatConversations table structure
IF OBJECT_ID('ChatConversations', 'U') IS NOT NULL
BEGIN
    PRINT '';
    PRINT 'Verification: ChatConversations table structure';
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
    WHERE c.object_id = OBJECT_ID('ChatConversations')
    ORDER BY c.column_id;

    PRINT '';
    PRINT 'Verification: ChatConversations Constraints';
    PRINT '-------------------------------------------';
    
    -- Foreign Keys
    SELECT 
        fk.name AS ConstraintName,
        'FOREIGN KEY' AS ConstraintType,
        OBJECT_NAME(fk.parent_object_id) AS TableName,
        COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
        OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
        COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn,
        fk.delete_referential_action_desc AS DeleteAction
    FROM sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    WHERE fk.parent_object_id = OBJECT_ID('ChatConversations');

    -- Check Constraints
    SELECT 
        cc.name AS ConstraintName,
        'CHECK' AS ConstraintType,
        cc.definition AS Definition
    FROM sys.check_constraints cc
    WHERE cc.parent_object_id = OBJECT_ID('ChatConversations');

    PRINT '';
    PRINT 'Verification: ChatConversations Indexes';
    PRINT '---------------------------------------';
    
    SELECT 
        i.name AS IndexName,
        i.type_desc AS IndexType,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.key_ordinal AS KeyOrdinal,
        ic.is_descending_key AS IsDescending
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID('ChatConversations')
    AND i.name IS NOT NULL
    ORDER BY i.name, ic.key_ordinal;

    PRINT '';
    PRINT 'ChatConversations table verification complete.';
END
GO

-- Step 6: Verify ChatMessages table structure
IF OBJECT_ID('ChatMessages', 'U') IS NOT NULL
BEGIN
    PRINT '';
    PRINT 'Verification: ChatMessages table structure';
    PRINT '------------------------------------------';
    
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
    WHERE c.object_id = OBJECT_ID('ChatMessages')
    ORDER BY c.column_id;

    PRINT '';
    PRINT 'Verification: ChatMessages Constraints';
    PRINT '--------------------------------------';
    
    -- Foreign Keys
    SELECT 
        fk.name AS ConstraintName,
        'FOREIGN KEY' AS ConstraintType,
        OBJECT_NAME(fk.parent_object_id) AS TableName,
        COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
        OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
        COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn,
        fk.delete_referential_action_desc AS DeleteAction
    FROM sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    WHERE fk.parent_object_id = OBJECT_ID('ChatMessages');

    -- Check Constraints
    SELECT 
        cc.name AS ConstraintName,
        'CHECK' AS ConstraintType,
        cc.definition AS Definition
    FROM sys.check_constraints cc
    WHERE cc.parent_object_id = OBJECT_ID('ChatMessages');

    PRINT '';
    PRINT 'Verification: ChatMessages Indexes';
    PRINT '----------------------------------';
    
    SELECT 
        i.name AS IndexName,
        i.type_desc AS IndexType,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.key_ordinal AS KeyOrdinal,
        ic.is_descending_key AS IsDescending
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID('ChatMessages')
    AND i.name IS NOT NULL
    ORDER BY i.name, ic.key_ordinal;

    PRINT '';
    PRINT 'ChatMessages table verification complete.';
END
GO

PRINT '';
PRINT '==============================================';
PRINT 'Migration 10_create_chat_tables.sql completed';
PRINT '==============================================';
GO
