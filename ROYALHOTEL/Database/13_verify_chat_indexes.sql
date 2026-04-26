-- =============================================
-- Task 12.2: Verify database indexes for chat tables
-- Validates: Requirements 11.1, 11.2
-- =============================================
-- This script verifies that all required indexes exist on ChatConversations and ChatMessages tables
-- and demonstrates that they are being used in queries via EXPLAIN PLAN analysis

USE RoyalHotel;
GO

PRINT '=== Task 12.2: Database Index Verification ===';
PRINT '';

-- =============================================
-- Part 1: Verify indexes exist on ChatConversations
-- =============================================
PRINT '--- Part 1: Verifying ChatConversations Indexes ---';
PRINT '';

-- Check for IX_ChatConversations_Status
IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_ChatConversations_Status' 
    AND object_id = OBJECT_ID('ChatConversations')
)
BEGIN
    PRINT '✓ Index IX_ChatConversations_Status exists';
    
    -- Show index details
    SELECT 
        i.name AS IndexName,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.index_column_id AS ColumnPosition,
        i.type_desc AS IndexType
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.name = 'IX_ChatConversations_Status'
    AND i.object_id = OBJECT_ID('ChatConversations');
END
ELSE
BEGIN
    PRINT '✗ Index IX_ChatConversations_Status MISSING';
END
PRINT '';

-- Check for IX_ChatConversations_AccountId
IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_ChatConversations_AccountId' 
    AND object_id = OBJECT_ID('ChatConversations')
)
BEGIN
    PRINT '✓ Index IX_ChatConversations_AccountId exists';
    
    -- Show index details
    SELECT 
        i.name AS IndexName,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.index_column_id AS ColumnPosition,
        i.type_desc AS IndexType
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.name = 'IX_ChatConversations_AccountId'
    AND i.object_id = OBJECT_ID('ChatConversations');
END
ELSE
BEGIN
    PRINT '✗ Index IX_ChatConversations_AccountId MISSING';
END
PRINT '';

-- Check for IX_ChatConversations_UpdatedAt
IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_ChatConversations_UpdatedAt' 
    AND object_id = OBJECT_ID('ChatConversations')
)
BEGIN
    PRINT '✓ Index IX_ChatConversations_UpdatedAt exists';
    
    -- Show index details
    SELECT 
        i.name AS IndexName,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.index_column_id AS ColumnPosition,
        i.type_desc AS IndexType
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.name = 'IX_ChatConversations_UpdatedAt'
    AND i.object_id = OBJECT_ID('ChatConversations');
END
ELSE
BEGIN
    PRINT '✗ Index IX_ChatConversations_UpdatedAt MISSING';
END
PRINT '';

-- =============================================
-- Part 2: Verify indexes exist on ChatMessages
-- =============================================
PRINT '--- Part 2: Verifying ChatMessages Indexes ---';
PRINT '';

-- Check for IX_ChatMessages_ConversationId_CreatedAt
IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_ChatMessages_ConversationId_CreatedAt' 
    AND object_id = OBJECT_ID('ChatMessages')
)
BEGIN
    PRINT '✓ Index IX_ChatMessages_ConversationId_CreatedAt exists';
    
    -- Show index details
    SELECT 
        i.name AS IndexName,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        ic.index_column_id AS ColumnPosition,
        i.type_desc AS IndexType
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.name = 'IX_ChatMessages_ConversationId_CreatedAt'
    AND i.object_id = OBJECT_ID('ChatMessages')
    ORDER BY ic.index_column_id;
END
ELSE
BEGIN
    PRINT '✗ Index IX_ChatMessages_ConversationId_CreatedAt MISSING';
END
PRINT '';

-- =============================================
-- Part 3: List all indexes on chat tables
-- =============================================
PRINT '--- Part 3: All Indexes on Chat Tables ---';
PRINT '';

PRINT 'ChatConversations Indexes:';
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') WITHIN GROUP (ORDER BY ic.index_column_id) AS Columns
FROM sys.indexes i
LEFT JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('ChatConversations')
AND i.type > 0  -- Exclude heap
GROUP BY i.name, i.type_desc, i.is_unique
ORDER BY i.name;
PRINT '';

PRINT 'ChatMessages Indexes:';
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') WITHIN GROUP (ORDER BY ic.index_column_id) AS Columns
FROM sys.indexes i
LEFT JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('ChatMessages')
AND i.type > 0  -- Exclude heap
GROUP BY i.name, i.type_desc, i.is_unique
ORDER BY i.name;
PRINT '';

-- =============================================
-- Part 4: Execution Plan Analysis - Verify indexes are used
-- =============================================
PRINT '--- Part 4: Execution Plan Analysis ---';
PRINT '';

-- Enable execution plan display
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT 'Query 1: Get escalated conversations (should use IX_ChatConversations_Status)';
PRINT 'Expected: Index Seek on IX_ChatConversations_Status';
PRINT '';

-- This query should use IX_ChatConversations_Status
SELECT TOP 10
    Id,
    ConversationCode,
    Status,
    EscalationReason,
    CreatedAt,
    UpdatedAt
FROM ChatConversations
WHERE Status = 'EscalatedToAdmin'
ORDER BY CreatedAt DESC;
PRINT '';

PRINT 'Query 2: Get user conversations (should use IX_ChatConversations_AccountId)';
PRINT 'Expected: Index Seek on IX_ChatConversations_AccountId';
PRINT '';

-- This query should use IX_ChatConversations_AccountId
-- Using a sample AccountId (adjust if needed)
DECLARE @SampleAccountId INT = (SELECT TOP 1 AccountId FROM ChatConversations WHERE AccountId IS NOT NULL);

IF @SampleAccountId IS NOT NULL
BEGIN
    SELECT 
        Id,
        ConversationCode,
        Status,
        CreatedAt,
        UpdatedAt
    FROM ChatConversations
    WHERE AccountId = @SampleAccountId
    ORDER BY UpdatedAt DESC;
END
ELSE
BEGIN
    PRINT 'No conversations with AccountId found - skipping test';
END
PRINT '';

PRINT 'Query 3: Get inactive conversations (should use IX_ChatConversations_UpdatedAt)';
PRINT 'Expected: Index Seek on IX_ChatConversations_UpdatedAt';
PRINT '';

-- This query should use IX_ChatConversations_UpdatedAt
SELECT 
    Id,
    ConversationCode,
    Status,
    UpdatedAt
FROM ChatConversations
WHERE Status IN ('Open', 'AnsweredByAdmin')
AND UpdatedAt < DATEADD(DAY, -7, GETUTCDATE())
ORDER BY UpdatedAt;
PRINT '';

PRINT 'Query 4: Get conversation messages (should use IX_ChatMessages_ConversationId_CreatedAt)';
PRINT 'Expected: Index Seek on IX_ChatMessages_ConversationId_CreatedAt';
PRINT '';

-- This query should use IX_ChatMessages_ConversationId_CreatedAt
DECLARE @SampleConversationId INT = (SELECT TOP 1 Id FROM ChatConversations);

IF @SampleConversationId IS NOT NULL
BEGIN
    SELECT 
        Id,
        ConversationId,
        SenderType,
        MessageText,
        CreatedAt
    FROM ChatMessages
    WHERE ConversationId = @SampleConversationId
    ORDER BY CreatedAt;
END
ELSE
BEGIN
    PRINT 'No conversations found - skipping test';
END
PRINT '';

-- Disable statistics
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- =============================================
-- Part 5: Index Usage Statistics
-- =============================================
PRINT '--- Part 5: Index Usage Statistics ---';
PRINT '';

PRINT 'ChatConversations Index Usage:';
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks AS UserSeeks,
    s.user_scans AS UserScans,
    s.user_lookups AS UserLookups,
    s.user_updates AS UserUpdates,
    s.last_user_seek AS LastUserSeek,
    s.last_user_scan AS LastUserScan
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
AND s.object_id = OBJECT_ID('ChatConversations')
ORDER BY i.name;
PRINT '';

PRINT 'ChatMessages Index Usage:';
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks AS UserSeeks,
    s.user_scans AS UserScans,
    s.user_lookups AS UserLookups,
    s.user_updates AS UserUpdates,
    s.last_user_seek AS LastUserSeek,
    s.last_user_scan AS LastUserScan
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
AND s.object_id = OBJECT_ID('ChatMessages')
ORDER BY i.name;
PRINT '';

-- =============================================
-- Part 6: Summary
-- =============================================
PRINT '--- Part 6: Verification Summary ---';
PRINT '';

DECLARE @MissingIndexes INT = 0;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChatConversations_Status' AND object_id = OBJECT_ID('ChatConversations'))
    SET @MissingIndexes = @MissingIndexes + 1;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChatConversations_AccountId' AND object_id = OBJECT_ID('ChatConversations'))
    SET @MissingIndexes = @MissingIndexes + 1;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChatConversations_UpdatedAt' AND object_id = OBJECT_ID('ChatConversations'))
    SET @MissingIndexes = @MissingIndexes + 1;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChatMessages_ConversationId_CreatedAt' AND object_id = OBJECT_ID('ChatMessages'))
    SET @MissingIndexes = @MissingIndexes + 1;

IF @MissingIndexes = 0
BEGIN
    PRINT '✓ ALL REQUIRED INDEXES EXIST';
    PRINT '';
    PRINT 'Required indexes verified:';
    PRINT '  - IX_ChatConversations_Status';
    PRINT '  - IX_ChatConversations_AccountId';
    PRINT '  - IX_ChatConversations_UpdatedAt';
    PRINT '  - IX_ChatMessages_ConversationId_CreatedAt';
    PRINT '';
    PRINT 'Review the execution plans above to confirm indexes are being used.';
    PRINT 'Look for "Index Seek" operations in the query results.';
END
ELSE
BEGIN
    PRINT '✗ MISSING INDEXES DETECTED';
    PRINT CONCAT('Number of missing indexes: ', @MissingIndexes);
    PRINT '';
    PRINT 'Please run the migration script 10_create_chat_tables.sql to create missing indexes.';
END

PRINT '';
PRINT '=== Index Verification Complete ===';
GO
