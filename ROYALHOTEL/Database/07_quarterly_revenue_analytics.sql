-- =============================================
-- Task 1.4: Create Quarterly_Revenue_Analytics Stored Procedure
-- =============================================
-- Description: Calculates top 3 revenue-generating rooms per hotel per quarter
-- Parameters:
--   @HotelId INT NULL - Optional filter for specific hotel
--   @Year INT NULL - Optional filter for specific year
--   @Quarter INT NULL - Optional filter for specific quarter (1-4)
-- Returns: Top 3 rooms per hotel-quarter with revenue and booking counts
-- =============================================

-- Drop existing procedure if it exists
IF OBJECT_ID('Quarterly_Revenue_Analytics', 'P') IS NOT NULL
    DROP PROCEDURE Quarterly_Revenue_Analytics;
GO

CREATE PROCEDURE Quarterly_Revenue_Analytics
    @HotelId INT = NULL,
    @Year INT = NULL,
    @Quarter INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Task 1.4.2: Implement CTE for quarterly data aggregation
    WITH QuarterlyData AS (
        SELECT
            h.Id AS HotelId,
            h.Name AS HotelName,
            r.Id AS RoomId,
            r.Code AS RoomCode,
            r.Name AS RoomName,
            YEAR(b.CheckIn) AS Year,
            -- Task 1.4.3: Calculate quarter from CheckIn date
            -- Q1: 1-3, Q2: 4-6, Q3: 7-9, Q4: 10-12
            CASE
                WHEN MONTH(b.CheckIn) BETWEEN 1 AND 3 THEN 1
                WHEN MONTH(b.CheckIn) BETWEEN 4 AND 6 THEN 2
                WHEN MONTH(b.CheckIn) BETWEEN 7 AND 9 THEN 3
                ELSE 4
            END AS Quarter,
            -- Task 1.4.5: Calculate SUM(TotalAmount) as TotalRevenue
            SUM(b.TotalAmount) AS TotalRevenue,
            -- Task 1.4.6: Calculate COUNT(*) as TotalBookings
            COUNT(*) AS TotalBookings
        FROM Bookings b
        -- Task 1.4.9: Join with Hotels and Rooms tables for display names
        INNER JOIN Rooms r ON b.RoomId = r.Id
        INNER JOIN Hotels h ON r.HotelId = h.Id
        WHERE 
            -- Task 1.4.4: Filter for Status = 'Completed' bookings only
            b.Status = 'Completed'
            -- Optional parameter filters
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
            h.Id, 
            h.Name, 
            r.Id, 
            r.Code, 
            r.Name, 
            YEAR(b.CheckIn),
            CASE
                WHEN MONTH(b.CheckIn) BETWEEN 1 AND 3 THEN 1
                WHEN MONTH(b.CheckIn) BETWEEN 4 AND 6 THEN 2
                WHEN MONTH(b.CheckIn) BETWEEN 7 AND 9 THEN 3
                ELSE 4
            END
    ),
    -- Task 1.4.7: Implement ROW_NUMBER() OVER (PARTITION BY HotelId, Year, Quarter ORDER BY TotalRevenue DESC)
    RankedRooms AS (
        SELECT
            HotelId,
            HotelName,
            CONCAT('Q', Quarter) AS Quarter,
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
    -- Task 1.4.8: Filter for Rank <= 3 to get top 3 rooms per hotel-quarter
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
GO

-- Verification output
PRINT '';
PRINT '=============================================';
PRINT 'Task 1.4: Quarterly_Revenue_Analytics Stored Procedure';
PRINT '=============================================';
PRINT '';

IF OBJECT_ID('Quarterly_Revenue_Analytics', 'P') IS NOT NULL
BEGIN
    PRINT '✓ Stored procedure created successfully';
    PRINT '';
    PRINT 'Features implemented:';
    PRINT '  ✓ 1.4.1: Parameters @HotelId, @Year, @Quarter (all optional)';
    PRINT '  ✓ 1.4.2: CTE for quarterly data aggregation';
    PRINT '  ✓ 1.4.3: Quarter calculation (Q1: 1-3, Q2: 4-6, Q3: 7-9, Q4: 10-12)';
    PRINT '  ✓ 1.4.4: Filter for Status = ''Completed'' bookings only';
    PRINT '  ✓ 1.4.5: Calculate SUM(TotalAmount) as TotalRevenue';
    PRINT '  ✓ 1.4.6: Calculate COUNT(*) as TotalBookings';
    PRINT '  ✓ 1.4.7: ROW_NUMBER() with PARTITION BY for ranking';
    PRINT '  ✓ 1.4.8: Filter for Rank <= 3 (top 3 rooms per hotel-quarter)';
    PRINT '  ✓ 1.4.9: Join with Hotels and Rooms tables for display names';
    PRINT '';
    PRINT 'Usage examples:';
    PRINT '  -- All data:';
    PRINT '  EXEC Quarterly_Revenue_Analytics;';
    PRINT '';
    PRINT '  -- Specific hotel:';
    PRINT '  EXEC Quarterly_Revenue_Analytics @HotelId = 1;';
    PRINT '';
    PRINT '  -- Specific year:';
    PRINT '  EXEC Quarterly_Revenue_Analytics @Year = 2025;';
    PRINT '';
    PRINT '  -- Specific quarter:';
    PRINT '  EXEC Quarterly_Revenue_Analytics @Quarter = 1;';
    PRINT '';
    PRINT '  -- Combined filters:';
    PRINT '  EXEC Quarterly_Revenue_Analytics @HotelId = 1, @Year = 2025, @Quarter = 1;';
    PRINT '';
    PRINT 'Task 1.4.1 through 1.4.9: COMPLETE ✓';
END
ELSE
BEGIN
    PRINT '✗ ERROR: Stored procedure creation failed';
    PRINT 'Please check for errors above';
END
GO
