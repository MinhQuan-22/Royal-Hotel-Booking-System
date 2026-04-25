-- test_task_1.3.5_null_zero_handling.sql
-- Comprehensive test script for Task 1.3.5: Handle NULL and zero OldRate values
-- Purpose: Verify Rate_Audit_Trigger correctly prevents division by zero and handles NULL values
-- Requirements: Requirement 2, AC 6

-- ============================================================================
-- SETUP: Prepare test environment
-- ============================================================================

PRINT '========================================';
PRINT 'Task 1.3.5: NULL and Zero OldRate Handling Tests';
PRINT '========================================';
PRINT '';
PRINT 'Requirement 2, AC 6: WHEN OLD.Rate is zero or NULL,';
PRINT 'THE Rate_Audit_Trigger SHALL NOT attempt to calculate ChangePercent';
PRINT 'and SHALL NOT insert a log record';
PRINT '';

-- Clear existing audit log entries for clean testing
DELETE FROM RoomRateChangeLog;
PRINT 'Cleared existing RoomRateChangeLog entries.';
PRINT '';

-- ============================================================================
-- TEST 1: Zero OldRate - Update from 0 to positive value
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 1: Zero OldRate (0 -> 100)';
PRINT '========================================';
PRINT 'Expected: NO audit log entry (prevents division by zero)';
PRINT '';

-- Create a test room with zero rate
DECLARE @ZeroRateRoomId1 INT;
INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxOccupancy)
VALUES (1, 'TEST-ZERO-1', 'Test Zero Rate Room 1', 'Standard', 0.00, 0.00, 'Available', 2);

SET @ZeroRateRoomId1 = SCOPE_IDENTITY();
PRINT 'Created test room with zero rate (ID: ' + CAST(@ZeroRateRoomId1 AS NVARCHAR(10)) + ')';
PRINT 'Old Rate: $0.00';
PRINT 'New Rate: $100.00';
PRINT '';

-- Count log entries before update
DECLARE @LogCountBefore1 INT;
SELECT @LogCountBefore1 = COUNT(*) FROM RoomRateChangeLog;

-- Update zero rate to non-zero
UPDATE Rooms SET Rate = 100.00 WHERE Id = @ZeroRateRoomId1;

-- Count log entries after update
DECLARE @LogCountAfter1 INT;
SELECT @LogCountAfter1 = COUNT(*) FROM RoomRateChangeLog;

-- Verify no log entry was created
IF @LogCountBefore1 = @LogCountAfter1
BEGIN
    PRINT 'PASS: No audit log entry created for zero OldRate';
    PRINT 'Division by zero prevented successfully.';
END
ELSE
BEGIN
    PRINT 'FAIL: Audit log entry created for zero OldRate';
    PRINT 'Expected 0 new entries, got ' + CAST(@LogCountAfter1 - @LogCountBefore1 AS NVARCHAR(10));
    
    -- Show the incorrect entry
    SELECT * FROM RoomRateChangeLog WHERE RoomId = @ZeroRateRoomId1;
END

PRINT '';

-- ============================================================================
-- TEST 2: Zero OldRate - Update from 0 to another zero value
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 2: Zero OldRate (0 -> 0)';
PRINT '========================================';
PRINT 'Expected: NO audit log entry (no change and zero rate)';
PRINT '';

-- Create another test room with zero rate
DECLARE @ZeroRateRoomId2 INT;
INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxOccupancy)
VALUES (1, 'TEST-ZERO-2', 'Test Zero Rate Room 2', 'Standard', 0.00, 0.00, 'Available', 2);

SET @ZeroRateRoomId2 = SCOPE_IDENTITY();
PRINT 'Created test room with zero rate (ID: ' + CAST(@ZeroRateRoomId2 AS NVARCHAR(10)) + ')';
PRINT 'Old Rate: $0.00';
PRINT 'New Rate: $0.00';
PRINT '';

-- Count log entries before update
DECLARE @LogCountBefore2 INT;
SELECT @LogCountBefore2 = COUNT(*) FROM RoomRateChangeLog;

-- Update zero rate to zero (no actual change)
UPDATE Rooms SET Rate = 0.00 WHERE Id = @ZeroRateRoomId2;

-- Count log entries after update
DECLARE @LogCountAfter2 INT;
SELECT @LogCountAfter2 = COUNT(*) FROM RoomRateChangeLog;

-- Verify no log entry was created
IF @LogCountBefore2 = @LogCountAfter2
BEGIN
    PRINT 'PASS: No audit log entry created for zero to zero update';
END
ELSE
BEGIN
    PRINT 'FAIL: Audit log entry created for zero to zero update';
    PRINT 'Expected 0 new entries, got ' + CAST(@LogCountAfter2 - @LogCountBefore2 AS NVARCHAR(10));
END

PRINT '';

-- ============================================================================
-- TEST 3: NULL OldRate - Update from NULL to positive value
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 3: NULL OldRate (NULL -> 150)';
PRINT '========================================';
PRINT 'Expected: NO audit log entry (prevents NULL division)';
PRINT '';

-- Create a test room with NULL rate
DECLARE @NullRateRoomId1 INT;
INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxOccupancy)
VALUES (1, 'TEST-NULL-1', 'Test NULL Rate Room 1', 'Standard', NULL, 0.00, 'Available', 2);

SET @NullRateRoomId1 = SCOPE_IDENTITY();
PRINT 'Created test room with NULL rate (ID: ' + CAST(@NullRateRoomId1 AS NVARCHAR(10)) + ')';
PRINT 'Old Rate: NULL';
PRINT 'New Rate: $150.00';
PRINT '';

-- Count log entries before update
DECLARE @LogCountBefore3 INT;
SELECT @LogCountBefore3 = COUNT(*) FROM RoomRateChangeLog;

-- Update NULL rate to non-NULL
UPDATE Rooms SET Rate = 150.00 WHERE Id = @NullRateRoomId1;

-- Count log entries after update
DECLARE @LogCountAfter3 INT;
SELECT @LogCountAfter3 = COUNT(*) FROM RoomRateChangeLog;

-- Verify no log entry was created
IF @LogCountBefore3 = @LogCountAfter3
BEGIN
    PRINT 'PASS: No audit log entry created for NULL OldRate';
    PRINT 'NULL division prevented successfully.';
END
ELSE
BEGIN
    PRINT 'FAIL: Audit log entry created for NULL OldRate';
    PRINT 'Expected 0 new entries, got ' + CAST(@LogCountAfter3 - @LogCountBefore3 AS NVARCHAR(10));
    
    -- Show the incorrect entry
    SELECT * FROM RoomRateChangeLog WHERE RoomId = @NullRateRoomId1;
END

PRINT '';

-- ============================================================================
-- TEST 4: NULL OldRate - Update from NULL to NULL
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 4: NULL OldRate (NULL -> NULL)';
PRINT '========================================';
PRINT 'Expected: NO audit log entry (no change and NULL rate)';
PRINT '';

-- Create another test room with NULL rate
DECLARE @NullRateRoomId2 INT;
INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxOccupancy)
VALUES (1, 'TEST-NULL-2', 'Test NULL Rate Room 2', 'Standard', NULL, 0.00, 'Available', 2);

SET @NullRateRoomId2 = SCOPE_IDENTITY();
PRINT 'Created test room with NULL rate (ID: ' + CAST(@NullRateRoomId2 AS NVARCHAR(10)) + ')';
PRINT 'Old Rate: NULL';
PRINT 'New Rate: NULL';
PRINT '';

-- Count log entries before update
DECLARE @LogCountBefore4 INT;
SELECT @LogCountBefore4 = COUNT(*) FROM RoomRateChangeLog;

-- Update NULL rate to NULL (no actual change)
UPDATE Rooms SET Rate = NULL WHERE Id = @NullRateRoomId2;

-- Count log entries after update
DECLARE @LogCountAfter4 INT;
SELECT @LogCountAfter4 = COUNT(*) FROM RoomRateChangeLog;

-- Verify no log entry was created
IF @LogCountBefore4 = @LogCountAfter4
BEGIN
    PRINT 'PASS: No audit log entry created for NULL to NULL update';
END
ELSE
BEGIN
    PRINT 'FAIL: Audit log entry created for NULL to NULL update';
    PRINT 'Expected 0 new entries, got ' + CAST(@LogCountAfter4 - @LogCountBefore4 AS NVARCHAR(10));
END

PRINT '';

-- ============================================================================
-- TEST 5: Very small positive OldRate (edge case near zero)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 5: Very small positive OldRate (0.01 -> 100)';
PRINT '========================================';
PRINT 'Expected: AUDIT LOG ENTRY (valid calculation, change > 50%)';
PRINT '';

-- Create a test room with very small rate
DECLARE @SmallRateRoomId INT;
INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxOccupancy)
VALUES (1, 'TEST-SMALL-1', 'Test Small Rate Room', 'Standard', 0.01, 0.01, 'Available', 2);

SET @SmallRateRoomId = SCOPE_IDENTITY();
PRINT 'Created test room with very small rate (ID: ' + CAST(@SmallRateRoomId AS NVARCHAR(10)) + ')';
PRINT 'Old Rate: $0.01';
PRINT 'New Rate: $100.00';
PRINT 'Expected Change: +999,900% (well above 50% threshold)';
PRINT '';

-- Count log entries before update
DECLARE @LogCountBefore5 INT;
SELECT @LogCountBefore5 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @SmallRateRoomId;

-- Update small rate to large rate
UPDATE Rooms SET Rate = 100.00 WHERE Id = @SmallRateRoomId;

-- Count log entries after update
DECLARE @LogCountAfter5 INT;
SELECT @LogCountAfter5 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @SmallRateRoomId;

-- Verify log entry was created
IF @LogCountAfter5 = @LogCountBefore5 + 1
BEGIN
    PRINT 'PASS: Audit log entry created for very small positive OldRate';
    PRINT 'Trigger correctly handles edge case near zero.';
    
    -- Show the entry
    SELECT 
        RoomId,
        OldRate,
        NewRate,
        ChangePercent,
        ChangedBy,
        ChangedAt
    FROM RoomRateChangeLog 
    WHERE RoomId = @SmallRateRoomId;
END
ELSE
BEGIN
    PRINT 'FAIL: No audit log entry created for very small positive OldRate';
    PRINT 'Expected 1 new entry, got ' + CAST(@LogCountAfter5 - @LogCountBefore5 AS NVARCHAR(10));
END

PRINT '';

-- ============================================================================
-- TEST 6: Negative OldRate (invalid scenario but should be handled)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 6: Negative OldRate (-50 -> 100)';
PRINT '========================================';
PRINT 'Expected: AUDIT LOG ENTRY (negative rate is > 0 check fails, so no entry)';
PRINT 'Note: Negative rates should not exist in production, but trigger should handle gracefully';
PRINT '';

-- Create a test room with negative rate (edge case)
DECLARE @NegativeRateRoomId INT;
INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxOccupancy)
VALUES (1, 'TEST-NEG-1', 'Test Negative Rate Room', 'Standard', -50.00, 0.00, 'Available', 2);

SET @NegativeRateRoomId = SCOPE_IDENTITY();
PRINT 'Created test room with negative rate (ID: ' + CAST(@NegativeRateRoomId AS NVARCHAR(10)) + ')';
PRINT 'Old Rate: -$50.00';
PRINT 'New Rate: $100.00';
PRINT '';

-- Count log entries before update
DECLARE @LogCountBefore6 INT;
SELECT @LogCountBefore6 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @NegativeRateRoomId;

-- Update negative rate to positive rate
UPDATE Rooms SET Rate = 100.00 WHERE Id = @NegativeRateRoomId;

-- Count log entries after update
DECLARE @LogCountAfter6 INT;
SELECT @LogCountAfter6 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @NegativeRateRoomId;

-- Verify no log entry was created (negative rate filtered by d.Rate > 0)
IF @LogCountBefore6 = @LogCountAfter6
BEGIN
    PRINT 'PASS: No audit log entry created for negative OldRate';
    PRINT 'Trigger correctly filters negative rates with d.Rate > 0 check.';
END
ELSE
BEGIN
    PRINT 'FAIL: Audit log entry created for negative OldRate';
    PRINT 'Expected 0 new entries, got ' + CAST(@LogCountAfter6 - @LogCountBefore6 AS NVARCHAR(10));
    
    -- Show the incorrect entry
    SELECT * FROM RoomRateChangeLog WHERE RoomId = @NegativeRateRoomId;
END

PRINT '';

-- ============================================================================
-- TEST 7: Multi-row update with mixed NULL, zero, and valid rates
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 7: Multi-row update (mixed NULL, zero, valid)';
PRINT '========================================';
PRINT 'Expected: Only valid positive OldRate with >50% change should log';
PRINT '';

-- Clear audit log for clean test
DELETE FROM RoomRateChangeLog;

-- Create test rooms with different rate scenarios
DECLARE @MultiTestRoom1 INT, @MultiTestRoom2 INT, @MultiTestRoom3 INT, @MultiTestRoom4 INT;

INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxOccupancy)
VALUES (1, 'MULTI-1', 'Multi Test Room 1', 'Standard', NULL, 0.00, 'Available', 2);
SET @MultiTestRoom1 = SCOPE_IDENTITY();

INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxOccupancy)
VALUES (1, 'MULTI-2', 'Multi Test Room 2', 'Standard', 0.00, 0.00, 'Available', 2);
SET @MultiTestRoom2 = SCOPE_IDENTITY();

INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxOccupancy)
VALUES (1, 'MULTI-3', 'Multi Test Room 3', 'Standard', 100.00, 100.00, 'Available', 2);
SET @MultiTestRoom3 = SCOPE_IDENTITY();

INSERT INTO Rooms (HotelId, Code, Name, RoomType, Rate, BasePricePerNight, Status, MaxOccupancy)
VALUES (1, 'MULTI-4', 'Multi Test Room 4', 'Standard', 50.00, 50.00, 'Available', 2);
SET @MultiTestRoom4 = SCOPE_IDENTITY();

PRINT 'Created 4 test rooms:';
PRINT '  Room 1: NULL rate -> will update to $200';
PRINT '  Room 2: $0 rate -> will update to $200';
PRINT '  Room 3: $100 rate -> will update to $200 (+100%, should log)';
PRINT '  Room 4: $50 rate -> will update to $60 (+20%, should NOT log)';
PRINT '';

-- Perform multi-row update
UPDATE Rooms 
SET Rate = CASE 
    WHEN Id = @MultiTestRoom1 THEN 200.00
    WHEN Id = @MultiTestRoom2 THEN 200.00
    WHEN Id = @MultiTestRoom3 THEN 200.00
    WHEN Id = @MultiTestRoom4 THEN 60.00
    ELSE Rate
END
WHERE Id IN (@MultiTestRoom1, @MultiTestRoom2, @MultiTestRoom3, @MultiTestRoom4);

-- Count log entries
DECLARE @MultiLogCount INT;
SELECT @MultiLogCount = COUNT(*) FROM RoomRateChangeLog;

PRINT 'Audit log entries created: ' + CAST(@MultiLogCount AS NVARCHAR(10));
PRINT '';

-- Verify only Room 3 logged
IF @MultiLogCount = 1
BEGIN
    DECLARE @LoggedRoomId INT;
    SELECT @LoggedRoomId = RoomId FROM RoomRateChangeLog;
    
    IF @LoggedRoomId = @MultiTestRoom3
    BEGIN
        PRINT 'PASS: Only Room 3 (valid rate with >50% change) logged';
        PRINT 'Rooms 1 (NULL), 2 (zero), and 4 (<50% change) correctly excluded.';
        
        -- Show the entry
        SELECT 
            RoomId,
            OldRate,
            NewRate,
            ChangePercent,
            ChangedBy
        FROM RoomRateChangeLog;
    END
    ELSE
    BEGIN
        PRINT 'FAIL: Wrong room logged';
        PRINT 'Expected Room ' + CAST(@MultiTestRoom3 AS NVARCHAR(10)) + ', got Room ' + CAST(@LoggedRoomId AS NVARCHAR(10));
    END
END
ELSE
BEGIN
    PRINT 'FAIL: Incorrect number of log entries';
    PRINT 'Expected 1 entry, got ' + CAST(@MultiLogCount AS NVARCHAR(10));
    
    -- Show all entries
    SELECT * FROM RoomRateChangeLog;
END

PRINT '';

-- ============================================================================
-- TEST 8: Verify trigger definition includes correct filters
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 8: Verify trigger definition';
PRINT '========================================';
PRINT 'Checking that trigger includes required filters:';
PRINT '  - d.Rate IS NOT NULL';
PRINT '  - d.Rate > 0';
PRINT '';

DECLARE @TriggerDefinition NVARCHAR(MAX);
SELECT @TriggerDefinition = OBJECT_DEFINITION(OBJECT_ID('Rate_Audit_Trigger'));

-- Check for NULL filter
IF @TriggerDefinition LIKE '%d.Rate IS NOT NULL%'
    PRINT 'PASS: Trigger includes NULL filter (d.Rate IS NOT NULL)';
ELSE
    PRINT 'FAIL: Trigger missing NULL filter';

-- Check for zero filter
IF @TriggerDefinition LIKE '%d.Rate > 0%'
    PRINT 'PASS: Trigger includes zero filter (d.Rate > 0)';
ELSE
    PRINT 'FAIL: Trigger missing zero filter';

PRINT '';

-- ============================================================================
-- CLEANUP: Remove test rooms
-- ============================================================================

PRINT '========================================';
PRINT 'CLEANUP: Removing test rooms';
PRINT '========================================';

-- Delete all test rooms created during this test
DELETE FROM Rooms WHERE Code LIKE 'TEST-%' OR Code LIKE 'MULTI-%';

-- Clear test audit log entries
DELETE FROM RoomRateChangeLog;

PRINT 'Test rooms and audit log entries removed.';
PRINT '';

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

PRINT '========================================';
PRINT 'TEST SUITE COMPLETE - Task 1.3.5';
PRINT '========================================';
PRINT '';
PRINT 'Test Coverage Summary:';
PRINT '----------------------';
PRINT '1. Zero OldRate (0 -> 100): Verified no log entry';
PRINT '2. Zero OldRate (0 -> 0): Verified no log entry';
PRINT '3. NULL OldRate (NULL -> 150): Verified no log entry';
PRINT '4. NULL OldRate (NULL -> NULL): Verified no log entry';
PRINT '5. Very small positive rate (0.01 -> 100): Verified log entry created';
PRINT '6. Negative OldRate (-50 -> 100): Verified no log entry';
PRINT '7. Multi-row mixed scenarios: Verified selective logging';
PRINT '8. Trigger definition: Verified correct filters present';
PRINT '';
PRINT 'Requirement 2, AC 6 Validation:';
PRINT '--------------------------------';
PRINT 'WHEN OLD.Rate is zero or NULL,';
PRINT 'THE Rate_Audit_Trigger SHALL NOT attempt to calculate ChangePercent';
PRINT 'and SHALL NOT insert a log record';
PRINT '';
PRINT 'Status: All tests validate this acceptance criterion.';
PRINT '';

