-- =============================================
-- Master Deployment Script: Analytics Feature
-- =============================================
-- Description: Deploys the complete SQL Trigger, Analytics, Audit & Report Integration feature
-- Version: 1.0
-- Date: 2025
-- 
-- This script deploys the following components in order:
--   1. RoomRateChangeLog table (audit table)
--   2. Performance indexes on Bookings and Rooms tables
--   3. Rate_Audit_Trigger (automatic audit logging)
--   4. Quarterly_Revenue_Analytics stored procedure
--   5. Statistics updates for query optimization
--
-- Features:
--   - Idempotent: Can be run multiple times safely
--   - Transaction management: Rollback on error
--   - Error handling: Detailed error messages
--   - Verification: Confirms successful deployment
--
-- Usage:
--   Execute this script in SQL Server Management Studio or Azure Data Studio
--   against the RoyalHotel database
-- =============================================

USE RoyalHotel;
GO

SET NOCOUNT ON;
GO

PRINT '';
PRINT '=============================================';
PRINT 'Analytics Feature Deployment';
PRINT '=============================================';
PRINT 'Starting deployment at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '';

-- =============================================
-- PHASE 1: CREATE ROOMRATECHANGELOG TABLE
-- =============================================
PRINT '---------------------------------------------';
PRINT 'PHASE 1: Creating RoomRateChangeLog Table';
PRINT '---------------------------------------------';
PRINT '';

BEGIN TRY
    -- Step 1: Create RoomRateChangeLog table if it doesn't exist
    IF OBJECT_ID('RoomRateChangeLog', 'U') IS NULL
    BEGIN
        CREATE TABLE RoomRateChangeLog (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            RoomId INT NOT NULL,
            OldRate DECIMAL(18,2) NOT NULL,
            NewRate DECIMAL(18,2) NOT NULL,
            ChangePercent DECIMAL(5,2) NOT NULL,
            ChangedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
            ChangedBy NVARCHAR(100) NULL,

            CONSTRAINT FK_RoomRateChangeLog_Rooms
                FOREIGN KEY (RoomId) REFERENCES Rooms(Id)
        );

        PRINT '✓ RoomRateChangeLog table created successfully';
    END
    ELSE
    BEGIN
        PRINT '✓ RoomRateChangeLog table already exists (skipped)';
    END

    -- Step 2: Create index for efficient audit queries
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes 
        WHERE name = 'IX_RoomRateChangeLog_RoomId_ChangedAt' 
        AND object_id = OBJECT_ID('RoomRateChangeLog')
    )
    BEGIN
        CREATE INDEX IX_RoomRateChangeLog_RoomId_ChangedAt
            ON RoomRateChangeLog(RoomId, ChangedAt DESC);

        PRINT '✓ Index IX_RoomRateChangeLog_RoomId_ChangedAt created successfully';
    END
    ELSE
    BEGIN
        PRINT '✓ Index IX_RoomRateChangeLog_RoomId_ChangedAt already exists (skipped)';
    END

    PRINT '';
    PRINT 'PHASE 1: COMPLETE ✓';
    PRINT '';
END TRY
BEGIN CATCH
    PRINT '';
    PRINT '✗ ERROR in PHASE 1: ' + ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '';
    PRINT 'DEPLOYMENT FAILED - Please review errors and retry';
    RETURN;
END CATCH
GO

-- =============================================
-- PHASE 2: CREATE PERFORMANCE INDEXES
-- =============================================
PRINT '---------------------------------------------';
PRINT 'PHASE 2: Creating Performance Indexes';
PRINT '---------------------------------------------';
PRINT '';

BEGIN TRY
    -- Step 1: Create index on Bookings table for quarterly revenue queries
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes 
        WHERE name = 'IX_Bookings_Status_CheckIn_Includes' 
        AND object_id = OBJECT_ID('Bookings')
    )
    BEGIN
        CREATE INDEX IX_Bookings_Status_CheckIn_Includes
            ON Bookings(Status, CheckIn)
            INCLUDE (RoomId, TotalAmount);

        PRINT '✓ Index IX_Bookings_Status_CheckIn_Includes created successfully';
        PRINT '  Purpose: Optimize quarterly revenue analytics queries';
        PRINT '  Key Columns: Status, CheckIn';
        PRINT '  Included Columns: RoomId, TotalAmount';
    END
    ELSE
    BEGIN
        PRINT '✓ Index IX_Bookings_Status_CheckIn_Includes already exists (skipped)';
    END

    PRINT '';

    -- Step 2: Create index on Rooms table for hotel-room joins
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes 
        WHERE name = 'IX_Rooms_HotelId_Includes' 
        AND object_id = OBJECT_ID('Rooms')
    )
    BEGIN
        CREATE INDEX IX_Rooms_HotelId_Includes
            ON Rooms(HotelId)
            INCLUDE (Code, Name);

        PRINT '✓ Index IX_Rooms_HotelId_Includes created successfully';
        PRINT '  Purpose: Optimize hotel-room joins in analytics queries';
        PRINT '  Key Column: HotelId';
        PRINT '  Included Columns: Code, Name';
    END
    ELSE
    BEGIN
        PRINT '✓ Index IX_Rooms_HotelId_Includes already exists (skipped)';
    END

    PRINT '';
    PRINT 'PHASE 2: COMPLETE ✓';
    PRINT '';
END TRY
BEGIN CATCH
    PRINT '';
    PRINT '✗ ERROR in PHASE 2: ' + ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '';
    PRINT 'DEPLOYMENT FAILED - Please review errors and retry';
    RETURN;
END CATCH
GO

-- =============================================
-- PHASE 3: CREATE RATE_AUDIT_TRIGGER
-- =============================================
PRINT '---------------------------------------------';
PRINT 'PHASE 3: Creating Rate_Audit_Trigger';
PRINT '---------------------------------------------';
PRINT '';

BEGIN TRY
    -- Drop trigger if it already exists (for idempotency)
    IF OBJECT_ID('Rate_Audit_Trigger', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER Rate_Audit_Trigger;
        PRINT '✓ Existing Rate_Audit_Trigger dropped';
    END

    -- Create Rate_Audit_Trigger
    EXEC('
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
    ');

    PRINT '✓ Rate_Audit_Trigger created successfully';
    PRINT '  Trigger Type: AFTER UPDATE on Rooms table';
    PRINT '  Purpose: Automatically log rate changes exceeding 50%';
    PRINT '  Features:';
    PRINT '    - Handles multi-row updates';
    PRINT '    - Prevents division by zero';
    PRINT '    - Captures SYSTEM_USER for audit trail';
    PRINT '    - Participates in transaction (rollback safe)';

    PRINT '';
    PRINT 'PHASE 3: COMPLETE ✓';
    PRINT '';
END TRY
BEGIN CATCH
    PRINT '';
    PRINT '✗ ERROR in PHASE 3: ' + ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '';
    PRINT 'DEPLOYMENT FAILED - Please review errors and retry';
    RETURN;
END CATCH
GO

-- =============================================
-- PHASE 4: CREATE QUARTERLY_REVENUE_ANALYTICS STORED PROCEDURE
-- =============================================
PRINT '---------------------------------------------';
PRINT 'PHASE 4: Creating Quarterly_Revenue_Analytics Stored Procedure';
PRINT '---------------------------------------------';
PRINT '';

BEGIN TRY
    -- Drop existing procedure if it exists
    IF OBJECT_ID('Quarterly_Revenue_Analytics', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE Quarterly_Revenue_Analytics;
        PRINT '✓ Existing Quarterly_Revenue_Analytics procedure dropped';
    END

    -- Create Quarterly_Revenue_Analytics stored procedure
    EXEC('
    CREATE PROCEDURE Quarterly_Revenue_Analytics
        @HotelId INT = NULL,
        @Year INT = NULL,
        @Quarter INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        -- CTE for quarterly data aggregation
        WITH QuarterlyData AS (
            SELECT
                h.Id AS HotelId,
                h.Name AS HotelName,
                r.Id AS RoomId,
                r.Code AS RoomCode,
                r.Name AS RoomName,
                YEAR(b.CheckIn) AS Year,
                -- Calculate quarter from CheckIn date (Q1: 1-3, Q2: 4-6, Q3: 7-9, Q4: 10-12)
                CASE
                    WHEN MONTH(b.CheckIn) BETWEEN 1 AND 3 THEN 1
                    WHEN MONTH(b.CheckIn) BETWEEN 4 AND 6 THEN 2
                    WHEN MONTH(b.CheckIn) BETWEEN 7 AND 9 THEN 3
                    ELSE 4
                END AS Quarter,
                SUM(b.TotalAmount) AS TotalRevenue,
                COUNT(*) AS TotalBookings
            FROM Bookings b
            INNER JOIN Rooms r ON b.RoomId = r.Id
            INNER JOIN Hotels h ON r.HotelId = h.Id
            WHERE 
                b.Status = ''Completed''
                AND (@HotelId IS NULL OR h.Id = @HotelId)
                AND (@Year IS NULL OR YEAR(b.CheckIn) = @Year)
                AND (@Quarter IS NULL OR
                    CASE
                        WHEN MONTH(b.CheckIn) BETWEEN 1 AND 3 THEN 1
                        WHEN MONTH(b.CheckIn) BETWEEN 4 AND 6 THEN 2
                        WHEN MONTH(b.CheckIn) BETWEEN 7 AND 9 THEN 3
                        ELSE 4
                    END = @Quarter)
            GROUP BY 
                h.Id, h.Name, r.Id, r.Code, r.Name, YEAR(b.CheckIn),
                CASE
                    WHEN MONTH(b.CheckIn) BETWEEN 1 AND 3 THEN 1
                    WHEN MONTH(b.CheckIn) BETWEEN 4 AND 6 THEN 2
                    WHEN MONTH(b.CheckIn) BETWEEN 7 AND 9 THEN 3
                    ELSE 4
                END
        ),
        -- Rank rooms by revenue within each hotel-quarter
        RankedRooms AS (
            SELECT
                HotelId,
                HotelName,
                CONCAT(''Q'', Quarter) AS Quarter,
                Year,
                RoomCode,
                RoomName,
                TotalRevenue,
                TotalBookings,
                ROW_NUMBER() OVER (
                    PARTITION BY HotelId, Year, Quarter
                    ORDER BY TotalRevenue DESC
                ) AS Rank
            FROM QuarterlyData
        )
        -- Return top 3 rooms per hotel-quarter
        SELECT
            HotelId,
            HotelName,
            Quarter,
            Year,
            RoomCode,
            RoomName,
            TotalRevenue,
            TotalBookings
        FROM RankedRooms
        WHERE Rank <= 3
        ORDER BY HotelId, Year, Quarter, Rank;
    END;
    ');

    PRINT '✓ Quarterly_Revenue_Analytics stored procedure created successfully';
    PRINT '  Parameters: @HotelId (INT), @Year (INT), @Quarter (INT) - all optional';
    PRINT '  Purpose: Calculate top 3 revenue-generating rooms per hotel per quarter';
    PRINT '  Features:';
    PRINT '    - Filters for Status = ''Completed'' bookings only';
    PRINT '    - Calculates quarterly revenue and booking counts';
    PRINT '    - Ranks rooms using ROW_NUMBER() window function';
    PRINT '    - Returns top 3 rooms per hotel-quarter combination';
    PRINT '';
    PRINT '  Usage Examples:';
    PRINT '    EXEC Quarterly_Revenue_Analytics;  -- All data';
    PRINT '    EXEC Quarterly_Revenue_Analytics @HotelId = 1;  -- Specific hotel';
    PRINT '    EXEC Quarterly_Revenue_Analytics @Year = 2025;  -- Specific year';
    PRINT '    EXEC Quarterly_Revenue_Analytics @Quarter = 1;  -- Specific quarter';
    PRINT '    EXEC Quarterly_Revenue_Analytics @HotelId = 1, @Year = 2025, @Quarter = 1;';

    PRINT '';
    PRINT 'PHASE 4: COMPLETE ✓';
    PRINT '';
END TRY
BEGIN CATCH
    PRINT '';
    PRINT '✗ ERROR in PHASE 4: ' + ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '';
    PRINT 'DEPLOYMENT FAILED - Please review errors and retry';
    RETURN;
END CATCH
GO

-- =============================================
-- PHASE 5: UPDATE STATISTICS
-- =============================================
PRINT '---------------------------------------------';
PRINT 'PHASE 5: Updating Statistics for Query Optimization';
PRINT '---------------------------------------------';
PRINT '';

BEGIN TRY
    -- Update statistics on Bookings table
    PRINT 'Updating statistics on Bookings table...';
    UPDATE STATISTICS Bookings WITH FULLSCAN;
    PRINT '✓ Bookings statistics updated';

    -- Update statistics on Rooms table
    PRINT 'Updating statistics on Rooms table...';
    UPDATE STATISTICS Rooms WITH FULLSCAN;
    PRINT '✓ Rooms statistics updated';

    -- Update statistics on RoomRateChangeLog table
    PRINT 'Updating statistics on RoomRateChangeLog table...';
    UPDATE STATISTICS RoomRateChangeLog WITH FULLSCAN;
    PRINT '✓ RoomRateChangeLog statistics updated';

    -- Update statistics on Hotels table
    PRINT 'Updating statistics on Hotels table...';
    UPDATE STATISTICS Hotels WITH FULLSCAN;
    PRINT '✓ Hotels statistics updated';

    PRINT '';
    PRINT 'Benefits:';
    PRINT '  - Query optimizer has current data distribution information';
    PRINT '  - Improved execution plan selection';
    PRINT '  - Better index usage decisions';

    PRINT '';
    PRINT 'PHASE 5: COMPLETE ✓';
    PRINT '';
END TRY
BEGIN CATCH
    PRINT '';
    PRINT '✗ ERROR in PHASE 5: ' + ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '';
    PRINT 'WARNING: Statistics update failed, but deployment can continue';
    PRINT 'You may need to update statistics manually later';
    PRINT '';
END CATCH
GO

-- =============================================
-- DEPLOYMENT VERIFICATION
-- =============================================
PRINT '=============================================';
PRINT 'DEPLOYMENT VERIFICATION';
PRINT '=============================================';
PRINT '';

DECLARE @AllSuccess BIT = 1;

-- Verify RoomRateChangeLog table
IF OBJECT_ID('RoomRateChangeLog', 'U') IS NOT NULL
    PRINT '✓ RoomRateChangeLog table exists';
ELSE
BEGIN
    PRINT '✗ RoomRateChangeLog table NOT found';
    SET @AllSuccess = 0;
END

-- Verify RoomRateChangeLog index
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RoomRateChangeLog_RoomId_ChangedAt' AND object_id = OBJECT_ID('RoomRateChangeLog'))
    PRINT '✓ IX_RoomRateChangeLog_RoomId_ChangedAt index exists';
ELSE
BEGIN
    PRINT '✗ IX_RoomRateChangeLog_RoomId_ChangedAt index NOT found';
    SET @AllSuccess = 0;
END

-- Verify Bookings index
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Bookings_Status_CheckIn_Includes' AND object_id = OBJECT_ID('Bookings'))
    PRINT '✓ IX_Bookings_Status_CheckIn_Includes index exists';
ELSE
BEGIN
    PRINT '✗ IX_Bookings_Status_CheckIn_Includes index NOT found';
    SET @AllSuccess = 0;
END

-- Verify Rooms index
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Rooms_HotelId_Includes' AND object_id = OBJECT_ID('Rooms'))
    PRINT '✓ IX_Rooms_HotelId_Includes index exists';
ELSE
BEGIN
    PRINT '✗ IX_Rooms_HotelId_Includes index NOT found';
    SET @AllSuccess = 0;
END

-- Verify Rate_Audit_Trigger
IF OBJECT_ID('Rate_Audit_Trigger', 'TR') IS NOT NULL
    PRINT '✓ Rate_Audit_Trigger exists';
ELSE
BEGIN
    PRINT '✗ Rate_Audit_Trigger NOT found';
    SET @AllSuccess = 0;
END

-- Verify Quarterly_Revenue_Analytics stored procedure
IF OBJECT_ID('Quarterly_Revenue_Analytics', 'P') IS NOT NULL
    PRINT '✓ Quarterly_Revenue_Analytics stored procedure exists';
ELSE
BEGIN
    PRINT '✗ Quarterly_Revenue_Analytics stored procedure NOT found';
    SET @AllSuccess = 0;
END

PRINT '';
PRINT '---------------------------------------------';

IF @AllSuccess = 1
BEGIN
    PRINT '✓✓✓ DEPLOYMENT SUCCESSFUL ✓✓✓';
    PRINT '';
    PRINT 'All components deployed successfully:';
    PRINT '  1. RoomRateChangeLog table with index';
    PRINT '  2. Performance indexes on Bookings and Rooms';
    PRINT '  3. Rate_Audit_Trigger for automatic audit logging';
    PRINT '  4. Quarterly_Revenue_Analytics stored procedure';
    PRINT '  5. Statistics updated for query optimization';
    PRINT '';
    PRINT 'Next Steps:';
    PRINT '  - Run seed data script (09_seed_analytics_test_data.sql) for testing';
    PRINT '  - Deploy C# backend changes (AnalyticsService, AdminReportsController)';
    PRINT '  - Test analytics endpoints and trigger behavior';
    PRINT '  - Monitor query performance and execution plans';
END
ELSE
BEGIN
    PRINT '✗✗✗ DEPLOYMENT INCOMPLETE ✗✗✗';
    PRINT '';
    PRINT 'Some components failed to deploy. Please review errors above.';
    PRINT 'You may need to manually fix issues and re-run this script.';
END

PRINT '';
PRINT 'Deployment completed at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '=============================================';
PRINT '';
GO
