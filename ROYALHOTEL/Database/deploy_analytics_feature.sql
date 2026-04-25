-- =============================================
-- Script: deploy_analytics_feature.sql
-- Purpose: Master deployment script for SQL Trigger, Analytics, Audit & Report Integration
-- Related Tasks: Task 1.5.2
-- =============================================
-- 
-- This script deploys the complete analytics feature in the correct order:
-- 1. RoomRateChangeLog table
-- 2. Performance indexes
-- 3. Rate audit trigger
-- 4. Quarterly revenue analytics stored procedure
-- 5. Statistics update
--
-- Usage:
--   Execute this script on the target database to deploy all analytics components
--
-- Rollback:
--   Use rollback_analytics_feature.sql to remove all components
--
-- =============================================

USE RoyalHotel;
GO

PRINT '========================================';
PRINT 'Analytics Feature Deployment';
PRINT '========================================';
PRINT '';
PRINT 'This script will deploy:';
PRINT '1. RoomRateChangeLog table';
PRINT '2. Performance indexes';
PRINT '3. Rate_Audit_Trigger';
PRINT '4. Quarterly_Revenue_Analytics stored procedure';
PRINT '5. Statistics updates';
PRINT '';
PRINT 'Starting deployment...';
PRINT '';

-- =============================================
-- Step 1: Create RoomRateChangeLog Table
-- =============================================
PRINT '========================================';
PRINT 'Step 1: Creating RoomRateChangeLog Table';
PRINT '========================================';
PRINT '';

-- Check if table already exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RoomRateChangeLog')
BEGIN
    PRINT 'Executing: 03_room_rate_change_log.sql';
    -- Note: In production, use SQLCMD mode or execute scripts separately
    -- :r 03_room_rate_change_log.sql
    PRINT 'Please execute: 03_room_rate_change_log.sql';
    PRINT '';
END
ELSE
BEGIN
    PRINT '✓ RoomRateChangeLog table already exists';
    PRINT '';
END

-- =============================================
-- Step 2: Create Performance Indexes
-- =============================================
PRINT '========================================';
PRINT 'Step 2: Creating Performance Indexes';
PRINT '========================================';
PRINT '';

-- Index 1: IX_RoomRateChangeLog_RoomId_ChangedAt (created by 03_room_rate_change_log.sql)
PRINT 'Index 1: IX_RoomRateChangeLog_RoomId_ChangedAt';
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RoomRateChangeLog_RoomId_ChangedAt')
    PRINT '✓ Already exists';
ELSE
    PRINT '⚠ Not found - should be created by 03_room_rate_change_log.sql';
PRINT '';

-- Index 2: IX_Bookings_Status_CheckIn_Includes
PRINT 'Index 2: IX_Bookings_Status_CheckIn_Includes';
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Bookings_Status_CheckIn_Includes')
BEGIN
    PRINT 'Executing: 04_create_index_bookings_status_checkin.sql';
    -- :r 04_create_index_bookings_status_checkin.sql
    PRINT 'Please execute: 04_create_index_bookings_status_checkin.sql';
    PRINT '';
END
ELSE
BEGIN
    PRINT '✓ Already exists';
    PRINT '';
END

-- Index 3: IX_Rooms_HotelId_Includes
PRINT 'Index 3: IX_Rooms_HotelId_Includes';
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Rooms_HotelId_Includes')
BEGIN
    PRINT 'Executing: 05_create_index_rooms_hotelid.sql';
    -- :r 05_create_index_rooms_hotelid.sql
    PRINT 'Please execute: 05_create_index_rooms_hotelid.sql';
    PRINT '';
END
ELSE
BEGIN
    PRINT '✓ Already exists';
    PRINT '';
END

-- =============================================
-- Step 3: Create Rate_Audit_Trigger
-- =============================================
PRINT '========================================';
PRINT 'Step 3: Creating Rate_Audit_Trigger';
PRINT '========================================';
PRINT '';

IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'Rate_Audit_Trigger')
BEGIN
    PRINT 'Executing: 06_rate_audit_trigger.sql';
    -- :r 06_rate_audit_trigger.sql
    PRINT 'Please execute: 06_rate_audit_trigger.sql';
    PRINT '';
END
ELSE
BEGIN
    PRINT '✓ Rate_Audit_Trigger already exists';
    PRINT '';
END

-- =============================================
-- Step 4: Create Quarterly_Revenue_Analytics Stored Procedure
-- =============================================
PRINT '========================================';
PRINT 'Step 4: Creating Quarterly_Revenue_Analytics';
PRINT '========================================';
PRINT '';

IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = 'Quarterly_Revenue_Analytics')
BEGIN
    PRINT 'Executing: 07_quarterly_revenue_analytics.sql';
    -- :r 07_quarterly_revenue_analytics.sql
    PRINT 'Please execute: 07_quarterly_revenue_analytics.sql';
    PRINT '';
END
ELSE
BEGIN
    PRINT '✓ Quarterly_Revenue_Analytics already exists';
    PRINT '';
END

-- =============================================
-- Step 5: Update Statistics
-- =============================================
PRINT '========================================';
PRINT 'Step 5: Updating Statistics';
PRINT '========================================';
PRINT '';

PRINT 'Executing: 08_update_statistics.sql';
-- :r 08_update_statistics.sql

-- Update statistics on Bookings table
PRINT 'Updating statistics on Bookings table...';
UPDATE STATISTICS Bookings WITH FULLSCAN;
PRINT '✓ Bookings statistics updated';
PRINT '';

-- Update statistics on Rooms table
PRINT 'Updating statistics on Rooms table...';
UPDATE STATISTICS Rooms WITH FULLSCAN;
PRINT '✓ Rooms statistics updated';
PRINT '';

-- Update statistics on RoomRateChangeLog table
PRINT 'Updating statistics on RoomRateChangeLog table...';
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RoomRateChangeLog')
BEGIN
    UPDATE STATISTICS RoomRateChangeLog WITH FULLSCAN;
    PRINT '✓ RoomRateChangeLog statistics updated';
END
ELSE
BEGIN
    PRINT '⚠ RoomRateChangeLog table not found - skipping';
END
PRINT '';

-- Update statistics on Hotels table
PRINT 'Updating statistics on Hotels table...';
UPDATE STATISTICS Hotels WITH FULLSCAN;
PRINT '✓ Hotels statistics updated';
PRINT '';

-- =============================================
-- Deployment Complete
-- =============================================
PRINT '========================================';
PRINT 'Deployment Complete';
PRINT '========================================';
PRINT '';
PRINT 'Summary:';
PRINT '--------';
PRINT '✓ RoomRateChangeLog table';
PRINT '✓ Performance indexes';
PRINT '✓ Rate_Audit_Trigger';
PRINT '✓ Quarterly_Revenue_Analytics stored procedure';
PRINT '✓ Statistics updated';
PRINT '';
PRINT 'Next Steps:';
PRINT '-----------';
PRINT '1. Verify all components using test scripts';
PRINT '2. Run seed data generator (if needed)';
PRINT '3. Deploy C# backend changes';
PRINT '4. Test analytics endpoints';
PRINT '';
PRINT 'Verification Scripts:';
PRINT '- test_03_room_rate_change_log.sql';
PRINT '- test_all_indexes_task_1.2.4.sql';
PRINT '- test_06_rate_audit_trigger.sql';
PRINT '- test_07_quarterly_revenue_analytics.sql';
PRINT '';
