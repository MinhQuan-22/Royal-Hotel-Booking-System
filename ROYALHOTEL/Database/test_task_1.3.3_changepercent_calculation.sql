-- test_task_1.3.3_changepercent_calculation.sql
-- Test script specifically for Task 1.3.3: Calculate ChangePercent as ((NewRate - OldRate) / OldRate) * 100
-- Purpose: Validate the accuracy of ChangePercent calculation within 0.01 tolerance

PRINT '========================================';
PRINT 'Task 1.3.3: ChangePercent Calculation Test';
PRINT '========================================';
PRINT '';
PRINT 'Testing: ChangePercent = ((NewRate - OldRate) / OldRate) * 100';
PRINT 'Requirement: Calculation must be accurate within 0.01 tolerance';
PRINT '';

-- ============================================================================
-- SETUP: Prepare test environment
-- ============================================================================

-- Store original room rates for restoration
IF OBJECT_ID('tempdb..#OriginalRates', 'U') IS NOT NULL
    DROP TABLE #OriginalRates;

SELECT Id, Rate INTO #OriginalRates FROM Rooms;

-- Clear existing audit log entries
DELETE FROM RoomRateChangeLog;

PRINT 'Test environment prepared.';
PRINT '';

-- ============================================================================
-- TEST 1: Positive rate increase (60% increase)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 1: Positive Rate Increase (+60%)';
PRINT '========================================';

DECLARE @TestRoom1 INT;
DECLARE @OldRate1 DECIMAL(18,2) = 100.00;
DECLARE @NewRate1 DECIMAL(18,2) = 160.00;
DECLARE @ExpectedChange1 DECIMAL(5,2) = 60.00;

-- Select a test room and set known rate
SELECT TOP 1 @TestRoom1 = Id FROM Rooms WHERE Rate > 0 ORDER BY Id;
UPDATE Rooms SET Rate = @OldRate1 WHERE Id = @TestRoom1;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom1;

-- Update to new rate
UPDATE Rooms SET Rate = @NewRate1 WHERE Id = @TestRoom1;

-- Verify calculation
DECLARE @ActualChange1 DECIMAL(5,2);
SELECT @ActualChange1 = ChangePercent FROM RoomRateChangeLog WHERE RoomId = @TestRoom1;

PRINT 'Old Rate: $' + CAST(@OldRate1 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate1 AS NVARCHAR(20));
PRINT 'Expected ChangePercent: ' + CAST(@ExpectedChange1 AS NVARCHAR(10)) + '%';
PRINT 'Actual ChangePercent: ' + CAST(@ActualChange1 AS NVARCHAR(10)) + '%';
PRINT 'Difference: ' + CAST(ABS(@ActualChange1 - @ExpectedChange1) AS NVARCHAR(10));

IF ABS(@ActualChange1 - @ExpectedChange1) <= 0.01
    PRINT 'PASS: Calculation accurate within 0.01 tolerance';
ELSE
    PRINT 'FAIL: Calculation exceeds 0.01 tolerance';

PRINT '';

-- ============================================================================
-- TEST 2: Negative rate decrease (-60% decrease)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 2: Negative Rate Decrease (-60%)';
PRINT '========================================';

DECLARE @TestRoom2 INT;
DECLARE @OldRate2 DECIMAL(18,2) = 250.00;
DECLARE @NewRate2 DECIMAL(18,2) = 100.00;
DECLARE @ExpectedChange2 DECIMAL(5,2) = -60.00;

-- Select a different test room and set known rate
SELECT TOP 1 @TestRoom2 = Id FROM Rooms WHERE Rate > 0 AND Id != @TestRoom1 ORDER BY Id;
UPDATE Rooms SET Rate = @OldRate2 WHERE Id = @TestRoom2;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom2;

-- Update to new rate
UPDATE Rooms SET Rate = @NewRate2 WHERE Id = @TestRoom2;

-- Verify calculation
DECLARE @ActualChange2 DECIMAL(5,2);
SELECT @ActualChange2 = ChangePercent FROM RoomRateChangeLog WHERE RoomId = @TestRoom2;

PRINT 'Old Rate: $' + CAST(@OldRate2 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate2 AS NVARCHAR(20));
PRINT 'Expected ChangePercent: ' + CAST(@ExpectedChange2 AS NVARCHAR(10)) + '%';
PRINT 'Actual ChangePercent: ' + CAST(@ActualChange2 AS NVARCHAR(10)) + '%';
PRINT 'Difference: ' + CAST(ABS(@ActualChange2 - @ExpectedChange2) AS NVARCHAR(10));

IF ABS(@ActualChange2 - @ExpectedChange2) <= 0.01
    PRINT 'PASS: Calculation accurate within 0.01 tolerance';
ELSE
    PRINT 'FAIL: Calculation exceeds 0.01 tolerance';

PRINT '';

-- ============================================================================
-- TEST 3: Large positive increase (+100% increase)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 3: Large Positive Increase (+100%)';
PRINT '========================================';

DECLARE @TestRoom3 INT;
DECLARE @OldRate3 DECIMAL(18,2) = 150.00;
DECLARE @NewRate3 DECIMAL(18,2) = 300.00;
DECLARE @ExpectedChange3 DECIMAL(5,2) = 100.00;

-- Select a different test room and set known rate
SELECT TOP 1 @TestRoom3 = Id FROM Rooms WHERE Rate > 0 AND Id NOT IN (@TestRoom1, @TestRoom2) ORDER BY Id;
UPDATE Rooms SET Rate = @OldRate3 WHERE Id = @TestRoom3;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom3;

-- Update to new rate
UPDATE Rooms SET Rate = @NewRate3 WHERE Id = @TestRoom3;

-- Verify calculation
DECLARE @ActualChange3 DECIMAL(5,2);
SELECT @ActualChange3 = ChangePercent FROM RoomRateChangeLog WHERE RoomId = @TestRoom3;

PRINT 'Old Rate: $' + CAST(@OldRate3 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate3 AS NVARCHAR(20));
PRINT 'Expected ChangePercent: ' + CAST(@ExpectedChange3 AS NVARCHAR(10)) + '%';
PRINT 'Actual ChangePercent: ' + CAST(@ActualChange3 AS NVARCHAR(10)) + '%';
PRINT 'Difference: ' + CAST(ABS(@ActualChange3 - @ExpectedChange3) AS NVARCHAR(10));

IF ABS(@ActualChange3 - @ExpectedChange3) <= 0.01
    PRINT 'PASS: Calculation accurate within 0.01 tolerance';
ELSE
    PRINT 'FAIL: Calculation exceeds 0.01 tolerance';

PRINT '';

-- ============================================================================
-- TEST 4: Large negative decrease (-75% decrease)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 4: Large Negative Decrease (-75%)';
PRINT '========================================';

DECLARE @TestRoom4 INT;
DECLARE @OldRate4 DECIMAL(18,2) = 400.00;
DECLARE @NewRate4 DECIMAL(18,2) = 100.00;
DECLARE @ExpectedChange4 DECIMAL(5,2) = -75.00;

-- Select a different test room and set known rate
SELECT TOP 1 @TestRoom4 = Id FROM Rooms WHERE Rate > 0 AND Id NOT IN (@TestRoom1, @TestRoom2, @TestRoom3) ORDER BY Id;
UPDATE Rooms SET Rate = @OldRate4 WHERE Id = @TestRoom4;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom4;

-- Update to new rate
UPDATE Rooms SET Rate = @NewRate4 WHERE Id = @TestRoom4;

-- Verify calculation
DECLARE @ActualChange4 DECIMAL(5,2);
SELECT @ActualChange4 = ChangePercent FROM RoomRateChangeLog WHERE RoomId = @TestRoom4;

PRINT 'Old Rate: $' + CAST(@OldRate4 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate4 AS NVARCHAR(20));
PRINT 'Expected ChangePercent: ' + CAST(@ExpectedChange4 AS NVARCHAR(10)) + '%';
PRINT 'Actual ChangePercent: ' + CAST(@ActualChange4 AS NVARCHAR(10)) + '%';
PRINT 'Difference: ' + CAST(ABS(@ActualChange4 - @ExpectedChange4) AS NVARCHAR(10));

IF ABS(@ActualChange4 - @ExpectedChange4) <= 0.01
    PRINT 'PASS: Calculation accurate within 0.01 tolerance';
ELSE
    PRINT 'FAIL: Calculation exceeds 0.01 tolerance';

PRINT '';

-- ============================================================================
-- TEST 5: Fractional rate change (+55.5% increase)
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 5: Fractional Rate Change (+55.5%)';
PRINT '========================================';

DECLARE @TestRoom5 INT;
DECLARE @OldRate5 DECIMAL(18,2) = 200.00;
DECLARE @NewRate5 DECIMAL(18,2) = 311.00;
DECLARE @ExpectedChange5 DECIMAL(5,2) = 55.50;

-- Select a different test room and set known rate
SELECT TOP 1 @TestRoom5 = Id FROM Rooms WHERE Rate > 0 AND Id NOT IN (@TestRoom1, @TestRoom2, @TestRoom3, @TestRoom4) ORDER BY Id;
UPDATE Rooms SET Rate = @OldRate5 WHERE Id = @TestRoom5;
DELETE FROM RoomRateChangeLog WHERE RoomId = @TestRoom5;

-- Update to new rate
UPDATE Rooms SET Rate = @NewRate5 WHERE Id = @TestRoom5;

-- Verify calculation
DECLARE @ActualChange5 DECIMAL(5,2);
SELECT @ActualChange5 = ChangePercent FROM RoomRateChangeLog WHERE RoomId = @TestRoom5;

PRINT 'Old Rate: $' + CAST(@OldRate5 AS NVARCHAR(20));
PRINT 'New Rate: $' + CAST(@NewRate5 AS NVARCHAR(20));
PRINT 'Expected ChangePercent: ' + CAST(@ExpectedChange5 AS NVARCHAR(10)) + '%';
PRINT 'Actual ChangePercent: ' + CAST(@ActualChange5 AS NVARCHAR(10)) + '%';
PRINT 'Difference: ' + CAST(ABS(@ActualChange5 - @ExpectedChange5) AS NVARCHAR(10));

IF ABS(@ActualChange5 - @ExpectedChange5) <= 0.01
    PRINT 'PASS: Calculation accurate within 0.01 tolerance';
ELSE
    PRINT 'FAIL: Calculation exceeds 0.01 tolerance';

PRINT '';

-- ============================================================================
-- TEST 6: Round-trip calculation property validation
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 6: Round-trip Calculation Property';
PRINT '========================================';
PRINT 'Requirement 1, AC 5: ((NewRate - OldRate) / OldRate) * 100 = ChangePercent';
PRINT '';

-- Query all audit log entries and verify round-trip calculation
SELECT 
    RoomId,
    OldRate,
    NewRate,
    ChangePercent AS StoredChangePercent,
    ((NewRate - OldRate) / OldRate) * 100 AS CalculatedChangePercent,
    ABS(ChangePercent - ((NewRate - OldRate) / OldRate) * 100) AS Difference,
    CASE 
        WHEN ABS(ChangePercent - ((NewRate - OldRate) / OldRate) * 100) <= 0.01 THEN 'PASS'
        ELSE 'FAIL'
    END AS ValidationResult
FROM RoomRateChangeLog
ORDER BY RoomId;

-- Count validation results
DECLARE @TotalEntries INT;
DECLARE @PassedEntries INT;

SELECT @TotalEntries = COUNT(*) FROM RoomRateChangeLog;

SELECT @PassedEntries = COUNT(*) 
FROM RoomRateChangeLog
WHERE ABS(ChangePercent - ((NewRate - OldRate) / OldRate) * 100) <= 0.01;

PRINT '';
PRINT 'Total audit log entries: ' + CAST(@TotalEntries AS NVARCHAR(10));
PRINT 'Entries passing validation: ' + CAST(@PassedEntries AS NVARCHAR(10));

IF @TotalEntries = @PassedEntries
    PRINT 'PASS: All entries satisfy round-trip calculation property';
ELSE
    PRINT 'FAIL: Some entries do not satisfy round-trip calculation property';

PRINT '';

-- ============================================================================
-- TEST 7: Signed value storage validation
-- ============================================================================

PRINT '========================================';
PRINT 'TEST 7: Signed Value Storage';
PRINT '========================================';
PRINT 'Requirement 2, AC 5: Store signed ChangePercent value';
PRINT '';

-- Verify positive and negative values are stored correctly
DECLARE @PositiveCount INT;
DECLARE @NegativeCount INT;

SELECT @PositiveCount = COUNT(*) FROM RoomRateChangeLog WHERE ChangePercent > 0;
SELECT @NegativeCount = COUNT(*) FROM RoomRateChangeLog WHERE ChangePercent < 0;

PRINT 'Positive ChangePercent entries: ' + CAST(@PositiveCount AS NVARCHAR(10));
PRINT 'Negative ChangePercent entries: ' + CAST(@NegativeCount AS NVARCHAR(10));

IF @PositiveCount > 0 AND @NegativeCount > 0
    PRINT 'PASS: Both positive and negative values stored correctly';
ELSE
    PRINT 'FAIL: Missing positive or negative values';

PRINT '';

-- Display sample positive and negative entries
PRINT 'Sample Positive Entry:';
SELECT TOP 1 RoomId, OldRate, NewRate, ChangePercent 
FROM RoomRateChangeLog 
WHERE ChangePercent > 0 
ORDER BY ChangePercent DESC;

PRINT '';
PRINT 'Sample Negative Entry:';
SELECT TOP 1 RoomId, OldRate, NewRate, ChangePercent 
FROM RoomRateChangeLog 
WHERE ChangePercent < 0 
ORDER BY ChangePercent ASC;

PRINT '';

-- ============================================================================
-- CLEANUP: Restore original room rates
-- ============================================================================

PRINT '========================================';
PRINT 'CLEANUP';
PRINT '========================================';

-- Restore original rates
UPDATE r
SET r.Rate = o.Rate
FROM Rooms r
INNER JOIN #OriginalRates o ON r.Id = o.Id;

-- Clear test audit log entries
DELETE FROM RoomRateChangeLog;

PRINT 'Original room rates restored.';
PRINT 'Test audit log entries cleared.';
PRINT '';

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

PRINT '========================================';
PRINT 'TEST SUMMARY';
PRINT '========================================';
PRINT '';
PRINT 'Task 1.3.3: Calculate ChangePercent as ((NewRate - OldRate) / OldRate) * 100';
PRINT '';
PRINT 'Tests Executed:';
PRINT '1. Positive rate increase (+60%) - Accuracy validation';
PRINT '2. Negative rate decrease (-60%) - Accuracy validation';
PRINT '3. Large positive increase (+100%) - Accuracy validation';
PRINT '4. Large negative decrease (-75%) - Accuracy validation';
PRINT '5. Fractional rate change (+55.5%) - Accuracy validation';
PRINT '6. Round-trip calculation property - All entries validated';
PRINT '7. Signed value storage - Positive and negative values';
PRINT '';
PRINT 'Requirements Validated:';
PRINT '- Requirement 1, AC 5: Round-trip calculation property (within 0.01 tolerance)';
PRINT '- Requirement 2, AC 5: Signed ChangePercent value storage';
PRINT '';
PRINT 'All tests completed. Review results above.';
PRINT '';
