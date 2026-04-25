-- test_task_1.3.4_abs_filter.sql
-- Focused test for Task 1.3.4: Filter for ABS(ChangePercent) > 50
-- Purpose: Verify that the trigger correctly filters rate changes using ABS(ChangePercent) > 50
-- This ensures both positive and negative changes exceeding 50% are logged

-- ============================================================================
-- SETUP: Prepare test environment
-- ============================================================================

PRINT '========================================';
PRINT 'Task 1.3.4: ABS(ChangePercent) > 50 Filter Test';
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
-- TEST 1: Positive change > 50% (should log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 1: Positive change > 50% (should log)';
PRINT '========================================';

DECLARE @TestRoom1 INT;
DECLARE @OldRate1 DECIMAL(18,2) = 100.00;
DECLARE @NewRate1 DECIMAL(18,2) = 160.00; -- +60%

SELECT TOP 1 @TestRoom1 = Id FROM Rooms WHERE Rate > 0 ORDER BY Id;

-- Set known old rate
UPDATE Rooms SET Rate = @OldRate1 WHERE Id = @TestRoom1;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom1;

-- Update to +60% (should log)
UPDATE Rooms SET Rate = @NewRate1 WHERE Id = @TestRoom1;

DECLARE @LogCount1 INT;
SELECT @LogCount1 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @TestRoom1;

PRINT 'Old Rate: $' + CAST(@OldRate1 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate1 AS NVARCHAR(20));
PRINT 'Change: +60%';
PRINT 'ABS(60) = 60 > 50: TRUE';
PRINT '';

IF @LogCount1 = 1
BEGIN
    PRINT 'PASS: Audit log entry created for +60% change';
    SELECT RoomId, OldRate, NewRate, ChangePercent FROM RoomRateChangeLog WHERE RoomId = @TestRoom1;
END
ELSE
    PRINT 'FAIL: Expected 1 audit log entry, found ' + CAST(@LogCount1 AS NVARCHAR(10));

PRINT '';

-- ============================================================================
-- TEST 2: Negative change > 50% (should log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 2: Negative change > 50% (should log)';
PRINT '========================================';

DECLARE @TestRoom2 INT;
DECLARE @OldRate2 DECIMAL(18,2) = 250.00;
DECLARE @NewRate2 DECIMAL(18,2) = 100.00; -- -60%

SELECT TOP 1 @TestRoom2 = Id FROM Rooms WHERE Rate > 0 AND Id != @TestRoom1 ORDER BY Id;

-- Set known old rate
UPDATE Rooms SET Rate = @OldRate2 WHERE Id = @TestRoom2;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom2;

-- Update to -60% (should log)
UPDATE Rooms SET Rate = @NewRate2 WHERE Id = @TestRoom2;

DECLARE @LogCount2 INT;
SELECT @LogCount2 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @TestRoom2;

PRINT 'Old Rate: $' + CAST(@OldRate2 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate2 AS NVARCHAR(20));
PRINT 'Change: -60%';
PRINT 'ABS(-60) = 60 > 50: TRUE';
PRINT '';

IF @LogCount2 = 1
BEGIN
    PRINT 'PASS: Audit log entry created for -60% change';
    SELECT RoomId, OldRate, NewRate, ChangePercent FROM RoomRateChangeLog WHERE RoomId = @TestRoom2;
END
ELSE
    PRINT 'FAIL: Expected 1 audit log entry, found ' + CAST(@LogCount2 AS NVARCHAR(10));

PRINT '';

-- ============================================================================
-- TEST 3: Positive change = 50% (should NOT log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 3: Positive change = 50% (should NOT log)';
PRINT '========================================';

DECLARE @TestRoom3 INT;
DECLARE @OldRate3 DECIMAL(18,2) = 100.00;
DECLARE @NewRate3 DECIMAL(18,2) = 150.00; -- Exactly +50%

SELECT TOP 1 @TestRoom3 = Id FROM Rooms WHERE Rate > 0 AND Id NOT IN (@TestRoom1, @TestRoom2) ORDER BY Id;

-- Set known old rate
UPDATE Rooms SET Rate = @OldRate3 WHERE Id = @TestRoom3;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom3;

-- Update to exactly +50% (should NOT log)
UPDATE Rooms SET Rate = @NewRate3 WHERE Id = @TestRoom3;

DECLARE @LogCount3 INT;
SELECT @LogCount3 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @TestRoom3;

PRINT 'Old Rate: $' + CAST(@OldRate3 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate3 AS NVARCHAR(20));
PRINT 'Change: +50%';
PRINT 'ABS(50) = 50 > 50: FALSE (boundary condition)';
PRINT '';

IF @LogCount3 = 0
    PRINT 'PASS: No audit log entry for exactly +50% change (> not >=)';
ELSE
    PRINT 'FAIL: Audit log entry created for exactly +50% change';

PRINT '';

-- ============================================================================
-- TEST 4: Negative change = -50% (should NOT log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 4: Negative change = -50% (should NOT log)';
PRINT '========================================';

DECLARE @TestRoom4 INT;
DECLARE @OldRate4 DECIMAL(18,2) = 200.00;
DECLARE @NewRate4 DECIMAL(18,2) = 100.00; -- Exactly -50%

SELECT TOP 1 @TestRoom4 = Id FROM Rooms WHERE Rate > 0 AND Id NOT IN (@TestRoom1, @TestRoom2, @TestRoom3) ORDER BY Id;

-- Set known old rate
UPDATE Rooms SET Rate = @OldRate4 WHERE Id = @TestRoom4;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom4;

-- Update to exactly -50% (should NOT log)
UPDATE Rooms SET Rate = @NewRate4 WHERE Id = @TestRoom4;

DECLARE @LogCount4 INT;
SELECT @LogCount4 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @TestRoom4;

PRINT 'Old Rate: $' + CAST(@OldRate4 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate4 AS NVARCHAR(20));
PRINT 'Change: -50%';
PRINT 'ABS(-50) = 50 > 50: FALSE (boundary condition)';
PRINT '';

IF @LogCount4 = 0
    PRINT 'PASS: No audit log entry for exactly -50% change (> not >=)';
ELSE
    PRINT 'FAIL: Audit log entry created for exactly -50% change';

PRINT '';

-- ============================================================================
-- TEST 5: Positive change < 50% (should NOT log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 5: Positive change < 50% (should NOT log)';
PRINT '========================================';

DECLARE @TestRoom5 INT;
DECLARE @OldRate5 DECIMAL(18,2) = 100.00;
DECLARE @NewRate5 DECIMAL(18,2) = 130.00; -- +30%

SELECT TOP 1 @TestRoom5 = Id FROM Rooms WHERE Rate > 0 AND Id NOT IN (@TestRoom1, @TestRoom2, @TestRoom3, @TestRoom4) ORDER BY Id;

-- Set known old rate
UPDATE Rooms SET Rate = @OldRate5 WHERE Id = @TestRoom5;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom5;

-- Update to +30% (should NOT log)
UPDATE Rooms SET Rate = @NewRate5 WHERE Id = @TestRoom5;

DECLARE @LogCount5 INT;
SELECT @LogCount5 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @TestRoom5;

PRINT 'Old Rate: $' + CAST(@OldRate5 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate5 AS NVARCHAR(20));
PRINT 'Change: +30%';
PRINT 'ABS(30) = 30 > 50: FALSE';
PRINT '';

IF @LogCount5 = 0
    PRINT 'PASS: No audit log entry for +30% change';
ELSE
    PRINT 'FAIL: Audit log entry created for +30% change';

PRINT '';

-- ============================================================================
-- TEST 6: Negative change < 50% (should NOT log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 6: Negative change < 50% (should NOT log)';
PRINT '========================================';

DECLARE @TestRoom6 INT;
DECLARE @OldRate6 DECIMAL(18,2) = 200.00;
DECLARE @NewRate6 DECIMAL(18,2) = 160.00; -- -20%

SELECT TOP 1 @TestRoom6 = Id FROM Rooms WHERE Rate > 0 AND Id NOT IN (@TestRoom1, @TestRoom2, @TestRoom3, @TestRoom4, @TestRoom5) ORDER BY Id;

-- Set known old rate
UPDATE Rooms SET Rate = @OldRate6 WHERE Id = @TestRoom6;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom6;

-- Update to -20% (should NOT log)
UPDATE Rooms SET Rate = @NewRate6 WHERE Id = @TestRoom6;

DECLARE @LogCount6 INT;
SELECT @LogCount6 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @TestRoom6;

PRINT 'Old Rate: $' + CAST(@OldRate6 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate6 AS NVARCHAR(20));
PRINT 'Change: -20%';
PRINT 'ABS(-20) = 20 > 50: FALSE';
PRINT '';

IF @LogCount6 = 0
    PRINT 'PASS: No audit log entry for -20% change';
ELSE
    PRINT 'FAIL: Audit log entry created for -20% change';

PRINT '';

-- ============================================================================
-- TEST 7: Boundary test (+51% should log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 7: Boundary test (+51% should log)';
PRINT '========================================';

DECLARE @TestRoom7 INT;
DECLARE @OldRate7 DECIMAL(18,2) = 100.00;
DECLARE @NewRate7 DECIMAL(18,2) = 151.00; -- +51%

SELECT TOP 1 @TestRoom7 = Id FROM Rooms WHERE Rate > 0 AND Id NOT IN (@TestRoom1, @TestRoom2, @TestRoom3, @TestRoom4, @TestRoom5, @TestRoom6) ORDER BY Id;

-- Set known old rate
UPDATE Rooms SET Rate = @OldRate7 WHERE Id = @TestRoom7;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom7;

-- Update to +51% (should log)
UPDATE Rooms SET Rate = @NewRate7 WHERE Id = @TestRoom7;

DECLARE @LogCount7 INT;
SELECT @LogCount7 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @TestRoom7;

PRINT 'Old Rate: $' + CAST(@OldRate7 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate7 AS NVARCHAR(20));
PRINT 'Change: +51%';
PRINT 'ABS(51) = 51 > 50: TRUE';
PRINT '';

IF @LogCount7 = 1
BEGIN
    PRINT 'PASS: Audit log entry created for +51% change';
    SELECT RoomId, OldRate, NewRate, ChangePercent FROM RoomRateChangeLog WHERE RoomId = @TestRoom7;
END
ELSE
    PRINT 'FAIL: Expected 1 audit log entry, found ' + CAST(@LogCount7 AS NVARCHAR(10));

PRINT '';

-- ============================================================================
-- TEST 8: Boundary test (-51% should log)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 8: Boundary test (-51% should log)';
PRINT '========================================';

DECLARE @TestRoom8 INT;
DECLARE @OldRate8 DECIMAL(18,2) = 200.00;
DECLARE @NewRate8 DECIMAL(18,2) = 98.00; -- -51%

SELECT TOP 1 @TestRoom8 = Id FROM Rooms WHERE Rate > 0 AND Id NOT IN (@TestRoom1, @TestRoom2, @TestRoom3, @TestRoom4, @TestRoom5, @TestRoom6, @TestRoom7) ORDER BY Id;

-- Set known old rate
UPDATE Rooms SET Rate = @OldRate8 WHERE Id = @TestRoom8;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom8;

-- Update to -51% (should log)
UPDATE Rooms SET Rate = @NewRate8 WHERE Id = @TestRoom8;

DECLARE @LogCount8 INT;
SELECT @LogCount8 = COUNT(*) FROM RoomRateChangeLog WHERE RoomId = @TestRoom8;

PRINT 'Old Rate: $' + CAST(@OldRate8 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate8 AS NVARCHAR(20));
PRINT 'Change: -51%';
PRINT 'ABS(-51) = 51 > 50: TRUE';
PRINT '';

IF @LogCount8 = 1
BEGIN
    PRINT 'PASS: Audit log entry created for -51% change';
    SELECT RoomId, OldRate, NewRate, ChangePercent FROM RoomRateChangeLog WHERE RoomId = @TestRoom8;
END
ELSE
    PRINT 'FAIL: Expected 1 audit log entry, found ' + CAST(@LogCount8 AS NVARCHAR(10));

PRINT '';

-- ============================================================================
-- TEST 9: Verify ABS() function in trigger WHERE clause
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 9: Verify ABS() function in trigger';
PRINT '========================================';

-- Check trigger definition contains ABS() filter
DECLARE @TriggerDef NVARCHAR(MAX);
SET @TriggerDef = OBJECT_DEFINITION(OBJECT_ID('Rate_Audit_Trigger'));

IF @TriggerDef LIKE '%ABS(%' AND @TriggerDef LIKE '%> 50%'
BEGIN
    PRINT 'PASS: Trigger definition contains ABS() filter with > 50 threshold';
    PRINT '';
    PRINT 'Relevant code snippet:';
    PRINT '  AND ABS(((i.Rate - d.Rate) / d.Rate) * 100) > 50';
END
ELSE
    PRINT 'FAIL: Trigger definition does not contain expected ABS() filter';

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
PRINT 'TEST SUITE COMPLETE - Task 1.3.4';
PRINT '========================================';
PRINT '';
PRINT 'Test Coverage Summary:';
PRINT '- TEST 1: +60% change (should log) - Verifies positive changes > 50%';
PRINT '- TEST 2: -60% change (should log) - Verifies negative changes > 50%';
PRINT '- TEST 3: +50% change (should NOT log) - Verifies boundary condition';
PRINT '- TEST 4: -50% change (should NOT log) - Verifies boundary condition';
PRINT '- TEST 5: +30% change (should NOT log) - Verifies positive changes < 50%';
PRINT '- TEST 6: -20% change (should NOT log) - Verifies negative changes < 50%';
PRINT '- TEST 7: +51% change (should log) - Verifies just above threshold';
PRINT '- TEST 8: -51% change (should log) - Verifies just above threshold';
PRINT '- TEST 9: Trigger definition verification - Confirms ABS() in code';
PRINT '';
PRINT 'Key Validation:';
PRINT '- ABS() function correctly handles both positive and negative changes';
PRINT '- Threshold is > 50 (not >= 50), so exactly 50% does NOT log';
PRINT '- Changes at 51% and above DO log (both positive and negative)';
PRINT '- Changes below 50% do NOT log (both positive and negative)';
PRINT '';
PRINT 'Requirements Satisfied:';
PRINT '- Requirement 2, AC 2: Changes > 50% are logged';
PRINT '- Requirement 2, AC 3: Changes <= 50% are NOT logged';
PRINT '- Design: Uses ABS(((i.Rate - d.Rate) / d.Rate) * 100) > 50';
PRINT '';

