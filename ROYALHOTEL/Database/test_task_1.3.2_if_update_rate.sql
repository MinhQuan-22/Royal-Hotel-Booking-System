-- test_task_1.3.2_if_update_rate.sql
-- Test script for Task 1.3.2: Verify IF UPDATE(Rate) logic in Rate_Audit_Trigger
-- Purpose: Ensure trigger only processes when Rate column is actually updated

PRINT '========================================';
PRINT 'Task 1.3.2: IF UPDATE(Rate) Logic Test';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- SETUP: Prepare test environment
-- ============================================================================

-- Clear existing audit log entries for clean testing
DELETE FROM RoomRateChangeLog;
PRINT 'Cleared existing RoomRateChangeLog entries.';
PRINT '';

-- Store original room data for restoration after tests
IF OBJECT_ID('tempdb..#OriginalRoomData', 'U') IS NOT NULL
    DROP TABLE #OriginalRoomData;

SELECT Id, Rate, Name, Status, MaxGuests 
INTO #OriginalRoomData 
FROM Rooms;
PRINT 'Stored original room data for restoration.';
PRINT '';

-- ============================================================================
-- TEST 1: Update Rate column (should trigger audit log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 1: Update Rate column (should trigger)';
PRINT '========================================';

DECLARE @TestRoomId1 INT;
DECLARE @OldRate1 DECIMAL(18,2);
DECLARE @NewRate1 DECIMAL(18,2);

-- Select a test room
SELECT TOP 1 @TestRoomId1 = Id, @OldRate1 = Rate 
FROM Rooms 
WHERE Rate > 0 
ORDER BY Id;

-- Calculate new rate (60% increase - exceeds 50% threshold)
SET @NewRate1 = @OldRate1 * 1.60;

PRINT 'Test Room ID: ' + CAST(@TestRoomId1 AS NVARCHAR(10));
PRINT 'Old Rate: $' + CAST(@OldRate1 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate1 AS NVARCHAR(20));
PRINT 'Expected: Audit log entry should be created';
PRINT '';

-- Update ONLY the Rate column
UPDATE Rooms 
SET Rate = @NewRate1 
WHERE Id = @TestRoomId1;

-- Verify audit log entry was created
DECLARE @LogCount1 INT;
SELECT @LogCount1 = COUNT(*) 
FROM RoomRateChangeLog 
WHERE RoomId = @TestRoomId1;

IF @LogCount1 = 1
BEGIN
    PRINT 'PASS: Audit log entry created when Rate column was updated';
    SELECT 
        RoomId,
        OldRate,
        NewRate,
        ChangePercent,
        ChangedBy,
        ChangedAt
    FROM RoomRateChangeLog
    WHERE RoomId = @TestRoomId1;
END
ELSE
    PRINT 'FAIL: Expected 1 audit log entry, found ' + CAST(@LogCount1 AS NVARCHAR(10));

PRINT '';

-- ============================================================================
-- TEST 2: Update non-Rate columns (should NOT trigger audit log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 2: Update non-Rate columns (should NOT trigger)';
PRINT '========================================';

-- Clear audit log for clean test
DELETE FROM RoomRateChangeLog;

DECLARE @TestRoomId2 INT;
DECLARE @OldName NVARCHAR(100);
DECLARE @NewName NVARCHAR(100);

-- Select a different test room
SELECT TOP 1 @TestRoomId2 = Id, @OldName = Name 
FROM Rooms 
WHERE Rate > 0 AND Id != @TestRoomId1
ORDER BY Id;

SET @NewName = @OldName + ' (Updated)';

PRINT 'Test Room ID: ' + CAST(@TestRoomId2 AS NVARCHAR(10));
PRINT 'Old Name: ' + @OldName;
PRINT 'New Name: ' + @NewName;
PRINT 'Expected: NO audit log entry (Rate column not updated)';
PRINT '';

-- Update ONLY the Name column (not Rate)
UPDATE Rooms 
SET Name = @NewName 
WHERE Id = @TestRoomId2;

-- Verify NO audit log entry was created
DECLARE @LogCount2 INT;
SELECT @LogCount2 = COUNT(*) 
FROM RoomRateChangeLog 
WHERE RoomId = @TestRoomId2;

IF @LogCount2 = 0
    PRINT 'PASS: No audit log entry created when Rate column was NOT updated';
ELSE
    PRINT 'FAIL: Audit log entry created when it should not have been (Rate not updated)';

PRINT '';

-- ============================================================================
-- TEST 3: Update Status column (should NOT trigger audit log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 3: Update Status column (should NOT trigger)';
PRINT '========================================';

DECLARE @TestRoomId3 INT;
DECLARE @OldStatus NVARCHAR(50);
DECLARE @NewStatus NVARCHAR(50);

-- Select a different test room
SELECT TOP 1 @TestRoomId3 = Id, @OldStatus = Status 
FROM Rooms 
WHERE Rate > 0 AND Id NOT IN (@TestRoomId1, @TestRoomId2)
ORDER BY Id;

-- Toggle status
SET @NewStatus = CASE 
    WHEN @OldStatus = 'Available' THEN 'Maintenance'
    ELSE 'Available'
END;

PRINT 'Test Room ID: ' + CAST(@TestRoomId3 AS NVARCHAR(10));
PRINT 'Old Status: ' + @OldStatus;
PRINT 'New Status: ' + @NewStatus;
PRINT 'Expected: NO audit log entry (Rate column not updated)';
PRINT '';

-- Update ONLY the Status column (not Rate)
UPDATE Rooms 
SET Status = @NewStatus 
WHERE Id = @TestRoomId3;

-- Verify NO audit log entry was created
DECLARE @LogCount3 INT;
SELECT @LogCount3 = COUNT(*) 
FROM RoomRateChangeLog 
WHERE RoomId = @TestRoomId3;

IF @LogCount3 = 0
    PRINT 'PASS: No audit log entry created when Status column was updated (Rate not changed)';
ELSE
    PRINT 'FAIL: Audit log entry created when it should not have been (Rate not updated)';

PRINT '';

-- ============================================================================
-- TEST 4: Update multiple columns including Rate (should trigger audit log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 4: Update multiple columns including Rate';
PRINT '========================================';

-- Clear audit log for clean test
DELETE FROM RoomRateChangeLog;

DECLARE @TestRoomId4 INT;
DECLARE @OldRate4 DECIMAL(18,2);
DECLARE @NewRate4 DECIMAL(18,2);
DECLARE @OldMaxGuests INT;
DECLARE @NewMaxGuests INT;

-- Select a different test room
SELECT TOP 1 @TestRoomId4 = Id, @OldRate4 = Rate, @OldMaxGuests = MaxGuests 
FROM Rooms 
WHERE Rate > 0 AND Id NOT IN (@TestRoomId1, @TestRoomId2, @TestRoomId3)
ORDER BY Id;

-- Calculate new rate (70% increase - exceeds 50% threshold)
SET @NewRate4 = @OldRate4 * 1.70;
SET @NewMaxGuests = @OldMaxGuests + 1;

PRINT 'Test Room ID: ' + CAST(@TestRoomId4 AS NVARCHAR(10));
PRINT 'Old Rate: $' + CAST(@OldRate4 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate4 AS NVARCHAR(20));
PRINT 'Old MaxGuests: ' + CAST(@OldMaxGuests AS NVARCHAR(10));
PRINT 'New MaxGuests: ' + CAST(@NewMaxGuests AS NVARCHAR(10));
PRINT 'Expected: Audit log entry should be created (Rate column updated)';
PRINT '';

-- Update BOTH Rate and MaxGuests columns
UPDATE Rooms 
SET Rate = @NewRate4,
    MaxGuests = @NewMaxGuests
WHERE Id = @TestRoomId4;

-- Verify audit log entry was created
DECLARE @LogCount4 INT;
SELECT @LogCount4 = COUNT(*) 
FROM RoomRateChangeLog 
WHERE RoomId = @TestRoomId4;

IF @LogCount4 = 1
BEGIN
    PRINT 'PASS: Audit log entry created when Rate column was updated (along with other columns)';
    SELECT 
        RoomId,
        OldRate,
        NewRate,
        ChangePercent,
        ChangedBy,
        ChangedAt
    FROM RoomRateChangeLog
    WHERE RoomId = @TestRoomId4;
END
ELSE
    PRINT 'FAIL: Expected 1 audit log entry, found ' + CAST(@LogCount4 AS NVARCHAR(10));

PRINT '';

-- ============================================================================
-- TEST 5: Update Rate to same value (should NOT trigger audit log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 5: Update Rate to same value (no actual change)';
PRINT '========================================';

-- Clear audit log for clean test
DELETE FROM RoomRateChangeLog;

DECLARE @TestRoomId5 INT;
DECLARE @CurrentRate5 DECIMAL(18,2);

-- Select a different test room
SELECT TOP 1 @TestRoomId5 = Id, @CurrentRate5 = Rate 
FROM Rooms 
WHERE Rate > 0 AND Id NOT IN (@TestRoomId1, @TestRoomId2, @TestRoomId3, @TestRoomId4)
ORDER BY Id;

PRINT 'Test Room ID: ' + CAST(@TestRoomId5 AS NVARCHAR(10));
PRINT 'Current Rate: $' + CAST(@CurrentRate5 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@CurrentRate5 AS NVARCHAR(20)) + ' (same value)';
PRINT 'Expected: NO audit log entry (change percent = 0%, below 50% threshold)';
PRINT '';

-- Update Rate to the same value
UPDATE Rooms 
SET Rate = @CurrentRate5 
WHERE Id = @TestRoomId5;

-- Verify NO audit log entry was created
DECLARE @LogCount5 INT;
SELECT @LogCount5 = COUNT(*) 
FROM RoomRateChangeLog 
WHERE RoomId = @TestRoomId5;

IF @LogCount5 = 0
    PRINT 'PASS: No audit log entry created when Rate updated to same value (0% change)';
ELSE
    PRINT 'FAIL: Audit log entry created for 0% change';

PRINT '';

-- ============================================================================
-- CLEANUP: Restore original room data
-- ============================================================================

PRINT '========================================';
PRINT 'CLEANUP: Restoring original room data';
PRINT '========================================';

UPDATE r
SET r.Rate = o.Rate,
    r.Name = o.Name,
    r.Status = o.Status,
    r.MaxGuests = o.MaxGuests
FROM Rooms r
INNER JOIN #OriginalRoomData o ON r.Id = o.Id;

PRINT 'Original room data restored.';
PRINT '';

-- Clear test audit log entries
DELETE FROM RoomRateChangeLog;
PRINT 'Test audit log entries cleared.';
PRINT '';

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

PRINT '========================================';
PRINT 'Task 1.3.2 TEST SUMMARY';
PRINT '========================================';
PRINT 'All tests executed. Review results above.';
PRINT '';
PRINT 'Test Coverage:';
PRINT '- TEST 1: Update Rate column only (should trigger)';
PRINT '- TEST 2: Update Name column only (should NOT trigger)';
PRINT '- TEST 3: Update Status column only (should NOT trigger)';
PRINT '- TEST 4: Update Rate + other columns (should trigger)';
PRINT '- TEST 5: Update Rate to same value (should NOT trigger due to 0% change)';
PRINT '';
PRINT 'Expected Behavior:';
PRINT 'The IF UPDATE(Rate) check ensures the trigger only processes';
PRINT 'when the Rate column is included in the UPDATE statement,';
PRINT 'preventing unnecessary processing for other column updates.';
PRINT '';

