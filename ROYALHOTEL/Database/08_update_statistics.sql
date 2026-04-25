-- =============================================
-- Script: 08_update_statistics.sql
-- Purpose: Update statistics on key tables for optimal query performance
-- Related Requirements: Requirement 6 - Query Performance Optimization
-- Related Tasks: Task 1.5.1
-- =============================================

USE RoyalHotel;
GO

PRINT '========================================';
PRINT 'Updating Statistics for Analytics Tables';
PRINT '========================================';
PRINT '';

-- Update statistics on Bookings table
-- This table is critical for quarterly revenue analytics
PRINT 'Updating statistics on Bookings table...';
UPDATE STATISTICS Bookings WITH FULLSCAN;
PRINT '✓ Bookings statistics updated';
PRINT '';

-- Update statistics on Rooms table
-- This table is used for hotel-room joins in analytics
PRINT 'Updating statistics on Rooms table...';
UPDATE STATISTICS Rooms WITH FULLSCAN;
PRINT '✓ Rooms statistics updated';
PRINT '';

-- Update statistics on RoomRateChangeLog table
-- This table is used for audit log queries
PRINT 'Updating statistics on RoomRateChangeLog table...';
UPDATE STATISTICS RoomRateChangeLog WITH FULLSCAN;
PRINT '✓ RoomRateChangeLog statistics updated';
PRINT '';

-- Update statistics on Hotels table (optional but recommended)
-- This table is used in analytics joins
PRINT 'Updating statistics on Hotels table...';
UPDATE STATISTICS Hotels WITH FULLSCAN;
PRINT '✓ Hotels statistics updated';
PRINT '';

PRINT '========================================';
PRINT 'Statistics Update Complete';
PRINT '========================================';
PRINT '';
PRINT 'Benefits:';
PRINT '- Query optimizer has current data distribution information';
PRINT '- Improved execution plan selection';
PRINT '- Better index usage decisions';
PRINT '';
PRINT 'Recommendations:';
PRINT '- Run this script after bulk data loads';
PRINT '- Schedule periodic statistics updates (weekly or monthly)';
PRINT '- Monitor query performance and update as needed';
PRINT '';
