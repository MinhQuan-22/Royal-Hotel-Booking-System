-- 06_rate_audit_trigger.sql
-- Migration script for Rate_Audit_Trigger
-- Purpose: Automatically log room rate changes exceeding 50% to RoomRateChangeLog table
-- Task: 1.3.1 - Write SQL trigger on Rooms table AFTER UPDATE

-- Step 1: Drop trigger if it already exists (for idempotency)
IF OBJECT_ID('Rate_Audit_Trigger', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER Rate_Audit_Trigger;
    PRINT 'Existing Rate_Audit_Trigger dropped.';
END
GO

-- Step 2: Create Rate_Audit_Trigger
CREATE TRIGGER Rate_Audit_Trigger
ON Rooms
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Only process if Rate column was actually updated
    IF UPDATE(Rate)
    BEGIN
        -- Insert audit log entries for rate changes exceeding 50% threshold
        INSERT INTO RoomRateChangeLog (RoomId, OldRate, NewRate, ChangePercent, ChangedBy)
        SELECT
            i.Id AS RoomId,
            d.Rate AS OldRate,
            i.Rate AS NewRate,
            ((i.Rate - d.Rate) / d.Rate) * 100 AS ChangePercent,
            SYSTEM_USER AS ChangedBy
        FROM inserted i
        INNER JOIN deleted d ON i.Id = d.Id
        WHERE
            -- Filter out NULL or zero OldRate to prevent division by zero
            d.Rate IS NOT NULL
            AND d.Rate > 0
            -- Only log changes where absolute change percent exceeds 50%
            AND ABS(((i.Rate - d.Rate) / d.Rate) * 100) > 50;
    END
END;
GO

-- Step 3: Verify trigger creation
IF OBJECT_ID('Rate_Audit_Trigger', 'TR') IS NOT NULL
BEGIN
    PRINT 'Rate_Audit_Trigger created successfully.';
    PRINT '';
    PRINT 'Trigger Details:';
    PRINT '----------------';
    
    SELECT 
        t.name AS TriggerName,
        OBJECT_NAME(t.parent_id) AS TableName,
        te.type_desc AS EventType,
        t.is_disabled AS IsDisabled,
        t.create_date AS CreatedDate,
        t.modify_date AS ModifiedDate
    FROM sys.triggers t
    INNER JOIN sys.trigger_events te ON t.object_id = te.object_id
    WHERE t.name = 'Rate_Audit_Trigger';
END
ELSE
BEGIN
    PRINT 'ERROR: Rate_Audit_Trigger creation failed.';
END
GO

-- Step 4: Display trigger definition
PRINT '';
PRINT 'Trigger Definition:';
PRINT '-------------------';
SELECT OBJECT_DEFINITION(OBJECT_ID('Rate_Audit_Trigger')) AS TriggerDefinition;
GO
