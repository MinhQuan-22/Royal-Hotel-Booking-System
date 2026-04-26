-- =====================================================
-- Test Script for Message Cleanup Service
-- Purpose: Verify that old messages are deleted correctly
-- =====================================================

-- Step 1: Check current messages count
SELECT 
    'Current Messages' as Status,
    COUNT(*) as TotalMessages,
    COUNT(CASE WHEN CreatedAt < CAST(GETUTCDATE() AS DATE) THEN 1 END) as OldMessages,
    COUNT(CASE WHEN CreatedAt >= CAST(GETUTCDATE() AS DATE) THEN 1 END) as TodayMessages
FROM ChatMessages;

-- Step 2: View old messages details
SELECT 
    Id,
    ConversationId,
    SenderType,
    LEFT(MessageText, 50) as MessagePreview,
    CreatedAt,
    DATEDIFF(day, CreatedAt, GETUTCDATE()) as DaysOld
FROM ChatMessages
WHERE CreatedAt < CAST(GETUTCDATE() AS DATE)
ORDER BY CreatedAt DESC;

-- Step 3: View today's messages (should be kept)
SELECT 
    Id,
    ConversationId,
    SenderType,
    LEFT(MessageText, 50) as MessagePreview,
    CreatedAt,
    DATEDIFF(hour, CreatedAt, GETUTCDATE()) as HoursOld
FROM ChatMessages
WHERE CreatedAt >= CAST(GETUTCDATE() AS DATE)
ORDER BY CreatedAt DESC;

-- =====================================================
-- MANUAL CLEANUP (for testing only)
-- WARNING: This will delete old messages immediately!
-- =====================================================

-- Uncomment the following lines to manually delete old messages:

/*
BEGIN TRANSACTION;

-- Show what will be deleted
SELECT 
    'Messages to be deleted' as Action,
    COUNT(*) as Count
FROM ChatMessages
WHERE CreatedAt < CAST(GETUTCDATE() AS DATE);

-- Delete old messages
DELETE FROM ChatMessages
WHERE CreatedAt < CAST(GETUTCDATE() AS DATE);

-- Show result
SELECT 
    'After deletion' as Status,
    COUNT(*) as RemainingMessages
FROM ChatMessages;

COMMIT TRANSACTION;
-- ROLLBACK TRANSACTION; -- Use this if you want to undo
*/

-- =====================================================
-- CREATE TEST DATA (for testing the cleanup service)
-- =====================================================

-- Uncomment to create test messages from different days:

/*
-- Insert messages from 3 days ago
INSERT INTO ChatMessages (ConversationId, SenderType, MessageText, IsEscalationMessage, CreatedAt)
SELECT TOP 1 
    Id as ConversationId,
    'User' as SenderType,
    'Test message from 3 days ago' as MessageText,
    0 as IsEscalationMessage,
    DATEADD(day, -3, GETUTCDATE()) as CreatedAt
FROM ChatConversations
WHERE Id IS NOT NULL;

-- Insert messages from yesterday
INSERT INTO ChatMessages (ConversationId, SenderType, MessageText, IsEscalationMessage, CreatedAt)
SELECT TOP 1 
    Id as ConversationId,
    'User' as SenderType,
    'Test message from yesterday' as MessageText,
    0 as IsEscalationMessage,
    DATEADD(day, -1, GETUTCDATE()) as CreatedAt
FROM ChatConversations
WHERE Id IS NOT NULL;

-- Insert messages from today (should NOT be deleted)
INSERT INTO ChatMessages (ConversationId, SenderType, MessageText, IsEscalationMessage, CreatedAt)
SELECT TOP 1 
    Id as ConversationId,
    'User' as SenderType,
    'Test message from today' as MessageText,
    0 as IsEscalationMessage,
    GETUTCDATE() as CreatedAt
FROM ChatConversations
WHERE Id IS NOT NULL;

SELECT 'Test data created' as Status;
*/

-- =====================================================
-- VERIFY CLEANUP SERVICE EXECUTION
-- =====================================================

-- Check if service ran successfully by looking at message counts over time
SELECT 
    CAST(CreatedAt AS DATE) as MessageDate,
    COUNT(*) as MessageCount,
    MIN(CreatedAt) as FirstMessage,
    MAX(CreatedAt) as LastMessage
FROM ChatMessages
GROUP BY CAST(CreatedAt AS DATE)
ORDER BY MessageDate DESC;

-- =====================================================
-- PERFORMANCE CHECK
-- =====================================================

-- Check if index exists on CreatedAt (recommended for performance)
SELECT 
    i.name as IndexName,
    i.type_desc as IndexType,
    COL_NAME(ic.object_id, ic.column_id) as ColumnName
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('ChatMessages')
    AND COL_NAME(ic.object_id, ic.column_id) = 'CreatedAt';

-- If no index exists, create one for better performance:
/*
CREATE INDEX IX_ChatMessages_CreatedAt 
ON ChatMessages(CreatedAt)
INCLUDE (Id, ConversationId, SenderType);
*/

-- =====================================================
-- MONITORING QUERIES
-- =====================================================

-- Daily message statistics (useful for monitoring)
SELECT 
    CAST(CreatedAt AS DATE) as Date,
    COUNT(*) as TotalMessages,
    COUNT(CASE WHEN SenderType = 'User' THEN 1 END) as UserMessages,
    COUNT(CASE WHEN SenderType = 'AI' THEN 1 END) as AIMessages,
    COUNT(CASE WHEN SenderType = 'Admin' THEN 1 END) as AdminMessages
FROM ChatMessages
WHERE CreatedAt >= DATEADD(day, -7, GETUTCDATE())
GROUP BY CAST(CreatedAt AS DATE)
ORDER BY Date DESC;

-- Conversation activity (to understand cleanup impact)
SELECT 
    c.Id,
    c.ConversationCode,
    c.Status,
    c.GuestName,
    COUNT(m.Id) as MessageCount,
    MAX(m.CreatedAt) as LastMessageAt,
    DATEDIFF(day, MAX(m.CreatedAt), GETUTCDATE()) as DaysSinceLastMessage
FROM ChatConversations c
LEFT JOIN ChatMessages m ON c.Id = m.ConversationId
GROUP BY c.Id, c.ConversationCode, c.Status, c.GuestName
ORDER BY LastMessageAt DESC;
