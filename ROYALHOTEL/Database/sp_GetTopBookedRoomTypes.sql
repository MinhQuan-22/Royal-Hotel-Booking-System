-- =============================================
-- Stored Procedure: sp_GetTopBookedRooms
-- Purpose: Calculate top 3 most-booked specific rooms
-- For: Database Advanced Course Project
-- =============================================

CREATE OR ALTER PROCEDURE dbo.sp_GetTopBookedRooms
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate top 3 specific rooms by booking count
    -- Only count bookings with valid statuses (Confirmed, CheckedIn, CheckedOut, Completed)
    -- Exclude Pending and Cancelled bookings
    SELECT TOP 3
        r.Id AS RoomId,
        r.Code AS RoomCode,
        r.Name AS RoomName,
        r.RoomType,
        COUNT(b.Id) AS BookingCount
    FROM dbo.Bookings b
    INNER JOIN dbo.Rooms r ON r.Id = b.RoomId
    WHERE b.Status IN ('Confirmed', 'CheckedIn', 'CheckedOut', 'Completed')
    GROUP BY r.Id, r.Code, r.Name, r.RoomType
    HAVING COUNT(b.Id) > 0
    ORDER BY COUNT(b.Id) DESC, r.Code ASC;
END
GO
