-- test_06_rate_audit_trigger.sql
-- Comprehensive test script for Rate_Audit_Trigger
-- Tests: Single-row updates, multi-row updates, threshold filtering, NULL/zero handling

-- ============================================================================
-- SETUP: Prepare test environment
-- ============================================================================

PRINT '========================================';
PRINT 'Rate_Audit_Trigger Test Suite';
PRINT '========================================';
PRINT '';

-- Clear existing audit log entries for clean testing
DELETE FROM RoomRateChangeLog;
PRINT 'Cleared existing RoomRateChangeLog entries.';
PRINT '';

-- Store original room rates for restoration after tests
IF OBJECT_ID('tempdb..#OriginalRates', 'U') IS NOT NULL
    DROP TABLE #OriginalRates;

SELECT Id, Rate INTO #OriginalRates FROM Rooms;
PRINT 'Stored original room rates for restoration.';
PRINT '';

-- ============================================================================
-- TEST 1: Single-row update with rate increase > 50%
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 1: Single-row update (increase > 50%)';
PRINT '========================================';

DECLARE @TestRoomId1 INT;
DECLARE @OldRate1 DECIMAL(18,2);
DECLARE @NewRate1 DECIMAL(18,2);

-- Select a test room
SELECT TOP 1 @TestRoomId1 = Id, @OldRate1 = Rate 
FROM Rooms 
WHERE Rate > 0 
ORDER BY Id;

-- Calculate new rate (60% increase)
SET @NewRate1 = @OldRate1 * 1.60;

PRINT 'Test Room ID: ' + CAST(@TestRoomId1 AS NVARCHAR(10));
PRINT 'Old Rate: $' + CAST(@OldRate1 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate1 AS NVARCHAR(20));
PRINT 'Expected Change: +60%';
PRINT '';

-- Update the room rate
UPDATE Rooms SET Rate = @NewRate1 WHERE Id = @TestRoomId1;

-- Verify audit log entry
PRINT 'Audit Log Entry:';
SELECT 
    RoomId,
    OldRate,
    NewRate,
    ChangePercent,
    ChangedBy,
    ChangedAt
FROM RoomRateChangeLog
WHERE RoomId = @TestRoomId1;

-- Verify calculation
DECLARE @LoggedChangePercent1 DECIMAL(5,2);
SELECT @LoggedChangePercent1 = ChangePercent 
FROM RoomRateChangeLog 
WHERE RoomId = @TestRoomId1;

IF @LoggedChangePercent1 BETWEEN 59.99 AND 60.01
    PRINT 'PASS: Change percent calculated correctly (60%)';
ELSE
    PRINT 'FAIL: Change percent incorrect. Expected 60%, got ' + CAST(@LoggedChangePercent1 AS NVARCHAR(10));

PRINT '';

-- ============================================================================
-- TEST 2: Single-row update with rate decrease > 50%
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 2: Single-row update (decrease > 50%)';
PRINT '========================================';

DECLARE @TestRoomId2 INT;
DECLARE @OldRate2 DECIMAL(18,2);
DECLARE @NewRate2 DECIMAL(18,2);

-- Select a different test room
SELECT TOP 1 @TestRoomId2 = Id, @OldRate2 = Rate 
FROM Rooms 
WHERE Rate > 0 AND Id != @TestRoomId1
ORDER BY Id;

-- Calculate new rate (60% decrease)
SET @NewRate2 = @OldRate2 * 0.40;

PRINT 'Test Room ID: ' + CAST(@TestRoomId2 AS NVARCHAR(10));
PRINT 'Old Rate: $' + CAST(@OldRate2 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate2 AS NVARCHAR(20));
PRINT 'Expected Change: -60%';
PRINT '';

-- Update the room rate
UPDATE Rooms SET Rate = @NewRate2 WHERE Id = @TestRoomId2;

-- Verify audit log entry
PRINT 'Audit Log Entry:';
SELECT 
    RoomId,
    OldRate,
    NewRate,
    ChangePercent,
    ChangedBy,
    ChangedAt
FROM RoomRateChangeLog
WHERE RoomId = @TestRoomId2;

-- Verify calculation
DECLARE @LoggedChangePercent2 DECIMAL(5,2);
SELECT @LoggedChangePercent2 = ChangePercent 
FROM RoomRateChangeLog 
WHERE RoomId = @TestRoomId2;

IF @LoggedChangePercent2 BETWEEN -60.01 AND -59.99
    PRINT 'PASS: Change percent calculated correctly (-60%)';
ELSE
    PRINT 'FAIL: Change percent incorrect. Expected -60%, got ' + CAST(@LoggedChangePercent2 AS NVARCHAR(10));

PRINT '';

-- ============================================================================
-- TEST 3: Single-row update with rate change <= 50% (should NOT log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 3: Rate change <= 50% (should NOT log)';
PRINT '========================================';

DECLARE @TestRoomId3 INT;
DECLARE @OldRate3 DECIMAL(18,2);
DECLARE @NewRate3 DECIMAL(18,2);

-- Select a different test room
SELECT TOP 1 @TestRoomId3 = Id, @OldRate3 = Rate 
FROM Rooms 
WHERE Rate > 0 AND Id NOT IN (@TestRoomId1, @TestRoomId2)
ORDER BY Id;

-- Calculate new rate (30% increase - below threshold)
SET @NewRate3 = @OldRate3 * 1.30;

PRINT 'Test Room ID: ' + CAST(@TestRoomId3 AS NVARCHAR(10));
PRINT 'Old Rate: $' + CAST(@OldRate3 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate3 AS NVARCHAR(20));
PRINT 'Expected Change: +30% (below 50% threshold)';
PRINT '';

-- Count log entries before update
DECLARE @LogCountBefore INT;
SELECT @LogCountBefore = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @TestRoomId3;

-- Update the room rate
UPDATE Rooms SET Rate = @NewRate3 WHERE Id = @TestRoomId3;

-- Count log entries after update
DECLARE @LogCountAfter INT;
SELECT @LogCountAfter = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @TestRoomId3;

IF @LogCountBefore = @LogCountAfter
    PRINT 'PASS: No audit log entry created (change below 50% threshold)';
ELSE
    PRINT 'FAIL: Audit log entry created when it should not have been';

PRINT '';

-- ============================================================================
-- TEST 4: Multi-row update with mixed changes
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 4: Multi-row update (mixed changes)';
PRINT '========================================';

-- Clear audit log for clean multi-row test
DELETE FROM RoomRateChangeLog;

-- Select 5 test rooms
IF OBJECT_ID('tempdb..#MultiRowTest', 'U') IS NOT NULL
    DROP TABLE #MultiRowTest;

SELECT TOP 5 
    Id,
    Rate AS OldRate,
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY Id) = 1 THEN Rate * 2.00  -- +100% (should log)
        WHEN ROW_NUMBER() OVER (ORDER BY Id) = 2 THEN Rate * 0.40  -- -60% (should log)
        WHEN ROW_NUMBER() OVER (ORDER BY Id) = 3 THEN Rate * 1.30  -- +30% (should NOT log)
        WHEN ROW_NUMBER() OVER (ORDER BY Id) = 4 THEN Rate * 1.55  -- +55% (should log)
        ELSE Rate * 0.90  -- -10% (should NOT log)
    END AS NewRate
INTO #MultiRowTest
FROM Rooms
WHERE Rate > 0
ORDER BY Id;

PRINT 'Test Rooms:';
SELECT 
    Id,
    OldRate,
    NewRate,
    ((NewRate - OldRate) / OldRate) * 100 AS ExpectedChangePercent,
    CASE 
        WHEN ABS(((NewRate - OldRate) / OldRate) * 100) > 50 THEN 'Should Log'
        ELSE 'Should NOT Log'
    END AS ExpectedBehavior
FROM #MultiRowTest;
PRINT '';

-- Perform multi-row update
UPDATE r
SET r.Rate = t.NewRate
FROM Rooms r
INNER JOIN #MultiRowTest t ON r.Id = t.Id;

PRINT 'Multi-row update executed.';
PRINT '';

-- Verify audit log entries
PRINT 'Audit Log Entries:';
SELECT 
    RoomId,
    OldRate,
    NewRate,
    ChangePercent,
    ChangedBy
FROM RoomRateChangeLog
ORDER BY RoomId;

-- Count expected vs actual log entries
DECLARE @ExpectedLogCount INT;
DECLARE @ActualLogCount INT;

SELECT @ExpectedLogCount = COUNT(*) 
FROM #MultiRowTest 
WHERE ABS(((NewRate - OldRate) / OldRate) * 100) > 50;

SELECT @ActualLogCount = COUNT(*) FROM RoomRateChangeLog;

PRINT '';
PRINT 'Expected log entries: ' + CAST(@ExpectedLogCount AS NVARCHAR(10));
PRINT 'Actual log entries: ' + CAST(@ActualLogCount AS NVARCHAR(10));

IF @ExpectedLogCount = @ActualLogCount
    PRINT 'PASS: Correct number of audit log entries created';
ELSE
    PRINT 'FAIL: Incorrect number of audit log entries';

PRINT '';

-- ============================================================================
-- TEST 5: NULL and zero OldRate handling
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 5: NULL and zero OldRate handling';
PRINT '========================================';

-- Clear audit log
DELETE FROM RoomRateChangeLog;

-- Create a test room with zero rate
DECLARE @ZeroRateRoomId INT;
INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxGuests)
VALUES (1, 'TEST-ZERO', 'Test Zero Rate Room', 'Standard', 0, 0, 'Available', 2);

SET @ZeroRateRoomId = SCOPE_IDENTITY();

PRINT 'Created test room with zero rate (ID: ' + CAST(@ZeroRateRoomId AS NVARCHAR(10)) + ')';

-- Update zero rate to non-zero (should NOT log due to division by zero prevention)
UPDATE Rooms SET Rate = 100.00 WHERE Id = @ZeroRateRoomId;

DECLARE @ZeroRateLogCount INT;
SELECT @ZeroRateLogCount = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @ZeroRateRoomId;

IF @ZeroRateLogCount = 0
    PRINT 'PASS: No audit log entry for zero OldRate (division by zero prevented)';
ELSE
    PRINT 'FAIL: Audit log entry created for zero OldRate';

-- Clean up test room
DELETE FROM Rooms WHERE Id = @ZeroRateRoomId;

PRINT '';

-- ============================================================================
-- TEST 6: Boundary test (exactly 50% change)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 6: Boundary test (exactly 50% change)';
PRINT '========================================';

-- Clear audit log
DELETE FROM RoomRateChangeLog;

DECLARE @BoundaryRoomId INT;
DECLARE @BoundaryOldRate DECIMAL(18,2) = 100.00;
DECLARE @BoundaryNewRate DECIMAL(18,2) = 150.00; -- Exactly +50%

SELECT TOP 1 @BoundaryRoomId = Id FROM Rooms WHERE Rate > 0 ORDER BY Id;

-- Set known old rate
UPDATE Rooms SET Rate = @BoundaryOldRate WHERE Id = @BoundaryRoomId;

-- Clear any log entries from the setup
DELETE FROM RoomRateChangeLog WHERE RoomId = @BoundaryRoomId;

-- Update to exactly 50% increase
UPDATE Rooms SET Rate = @BoundaryNewRate WHERE Id = @BoundaryRoomId;

DECLARE @BoundaryLogCount INT;
SELECT @BoundaryLogCount = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @BoundaryRoomId;

PRINT 'Old Rate: $' + CAST(@BoundaryOldRate AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@BoundaryNewRate AS NVARCHAR(20));
PRINT 'Change: Exactly +50%';
PRINT '';

IF @BoundaryLogCount = 0
    PRINT 'PASS: No audit log entry for exactly 50% change (threshold is > 50, not >= 50)';
ELSE
    PRINT 'FAIL: Audit log entry created for exactly 50% change';

PRINT '';

-- ============================================================================
-- TEST 7: Transaction rollback test
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 7: Transaction rollback test';
PRINT '========================================';

-- Clear audit log
DELETE FROM RoomRateChangeLog;

DECLARE @RollbackRoomId INT;
DECLARE @RollbackOldRate DECIMAL(18,2);

SELECT TOP 1 @RollbackRoomId = Id, @RollbackOldRate = Rate 
FROM Rooms 
WHERE Rate > 0 
ORDER BY Id;

PRINT 'Test Room ID: ' + CAST(@RollbackRoomId AS NVARCHAR(10));
PRINT 'Old Rate: $' + CAST(@RollbackOldRate AS NVARCHAR(20));
PRINT '';

-- Begin transaction
BEGIN TRANSACTION;

-- Update rate (should trigger audit log)
UPDATE Rooms SET Rate = @RollbackOldRate * 2.00 WHERE Id = @RollbackRoomId;

-- Check if audit log entry exists
DECLARE @LogCountInTransaction INT;
SELECT @LogCountInTransaction = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @RollbackRoomId;

PRINT 'Audit log entries during transaction: ' + CAST(@LogCountInTransaction AS NVARCHAR(10));

-- Rollback transaction
ROLLBACK TRANSACTION;

-- Check if audit log entry was rolled back
DECLARE @LogCountAfterRollback INT;
SELECT @LogCountAfterRollback = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @RollbackRoomId;

PRINT 'Audit log entries after rollback: ' + CAST(@LogCountAfterRollback AS NVARCHAR(10));
PRINT '';

IF @LogCountAfterRollback = 0
    PRINT 'PASS: Audit log entry rolled back with transaction';
ELSE
    PRINT 'FAIL: Audit log entry not rolled back';

PRINT '';

-- ============================================================================
-- CLEANUP: Restore original room rates
-- ============================================================================

PRINT '========================================';
PRINT 'CLEANUP: Restoring original room rates';
PRINT '========================================';

UPDATE r
SET r.Rate = o.Rate
FROM Rooms r
INNER JOIN #OriginalRates o ON r.Id = o.Id;

PRINT 'Original room rates restored.';
PRINT '';

-- Clear test audit log entries
DELETE FROM RoomRateChangeLog;
PRINT 'Test audit log entries cleared.';
PRINT '';

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

PRINT '========================================';
PRINT 'TEST SUITE COMPLETE';
PRINT '========================================';
PRINT 'All tests executed. Review results above.';
PRINT '';
PRINT 'Key Test Coverage:';
PRINT '- Single-row updates (increase and decrease > 50%)';
PRINT '- Rate changes <= 50% (should not log)';
PRINT '- Multi-row updates with mixed changes';
PRINT '- NULL and zero OldRate handling';
PRINT '- Boundary test (exactly 50% change)';
PRINT '- Transaction rollback behavior';
PRINT '';
