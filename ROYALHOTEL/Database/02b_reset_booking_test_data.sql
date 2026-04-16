-- 02_reset_booking_test_data.sql
-- Reset test data for booking procedure tests

-- Delete payment transactions linked to test bookings
DELETE PT
FROM PaymentTransactions PT
JOIN Bookings B ON PT.BookingId = B.Id
WHERE B.BookingCode IN ('TEST-BK-A', 'TEST-BK-B', 'TEST-BK-C', 'TEST-BK-D');
GO

-- Delete test bookings
DELETE FROM Bookings
WHERE BookingCode IN ('TEST-BK-A', 'TEST-BK-B', 'TEST-BK-C', 'TEST-BK-D');
GO

-- Restore demo room status if previously changed
UPDATE Rooms
SET Status = 'ACTIVE',
    IsActive = 1
WHERE Code IN ('NT-DLX-201', 'NT-STE-301', 'PQ-DLX-201', 'PQ-STE-401');
GO
