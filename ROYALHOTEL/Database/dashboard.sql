INSERT INTO [dbo].[Accounts] (FullName, Email, Phone, PasswordHash, PasswordSalt, CreatedAt, UpdatedAt, Role, Status) 
VALUES (N'Huy Hoàng Trần', 'hoangt1245@gmail.com', '0123456789', '3v9ShlK5d9Ufm6YMud2jD+XmgC/hsljG0A0ORTeI6/U=', '12t7D5MvPXDtJehXkYpRjw==', '2026-04-04 06:59:38', '2026-04-04 06:59:38', 'admin', 'active');

INSERT INTO [dbo].[Accounts] (FullName, Email, Phone, PasswordHash, PasswordSalt, CreatedAt, UpdatedAt, Role, Status) 
VALUES (N'Nguyễn Văn A', 'anguyen@gmail.com', '0123456789', 'nF3Mw9t0l1KP2Qr25fv1NQH1IIQHasY/ExWpOlJ3Whg=', 'e0ujvjFD8D1s3dlsVfW7eA==', '2026-04-20 14:58:27', '2026-04-20 14:58:27', 'user', 'active');

INSERT INTO [dbo].[Accounts] (FullName, Email, Phone, PasswordHash, PasswordSalt, CreatedAt, UpdatedAt, Role, Status) 
VALUES (N'Trương Tuấn T', 'tuantu@gmail.com', '0123456789', 'FmKu+s+Mmo6QF8i/o9l5altXcyII/RNk3KJih0meCT0=', 'bVXlH/N27X5QYvGB9hBLXw==', '2026-04-20 14:59:43', '2026-04-20 14:59:43', 'user', 'active');

INSERT INTO [dbo].[Accounts] (FullName, Email, Phone, PasswordHash, PasswordSalt, CreatedAt, UpdatedAt, Role, Status) 
VALUES (N'Nguyen Thi Thuy', 'thuynguyen@gmail.com', '0123456789', 'q2W/MVigpfoN1cQQ4FwJWSiSu/hWoCUCuzyA+Rt6RII=', 'rjUCNq58hf1pIloGBqrdfg==', '2026-04-20 15:00:26', '2026-04-20 15:00:26', 'user', 'active');

INSERT INTO [dbo].[Accounts] (FullName, Email, Phone, PasswordHash, PasswordSalt, CreatedAt, UpdatedAt, Role, Status) 
VALUES (N'Trần Thái Tuấn', 'tuantran@gmail.com', '0123456789', 'Ux4DZ7Jjuqcn2th31/gKqxyrmymp/d1Agqk35ZFkeQQ=', 'Rkw+N5Xu0i1PgIcBb0x5XA==', '2026-04-20 15:01:41', '2026-04-20 15:01:41', 'user', 'active');

INSERT INTO [dbo].[Accounts] (FullName, Email, Phone, PasswordHash, PasswordSalt, CreatedAt, UpdatedAt, Role, Status) 
VALUES (N'Ngô Thanh Tùng', 'thanhtung@gmail.com', '0123456789', 'bvr+jowC92GGuwKgCNJiYbrmBRaIqOg+7K71VEuX9NA=', 'ie+cxyVKI7BaBSrMKY68Hw==', '2026-04-20 15:03:23', '2026-04-20 15:03:23', 'user', 'active');

INSERT INTO [dbo].[Accounts] (FullName, Email, Phone, PasswordHash, PasswordSalt, CreatedAt, UpdatedAt, Role, Status) 
VALUES (N'Hồ Xuân Hương', 'xuanhuong@gmail.com', '0123456789', 'Dcnvs4Q7++vBs41b7JyxCU2+NafAF7Go4vpHE8dmudk=', 'qvcR0SAIgquqF1n1J/iH5w==', '2026-04-20 15:03:58', '2026-04-20 15:03:58', 'user', 'active');

INSERT INTO [dbo].[Accounts] (FullName, Email, Phone, PasswordHash, PasswordSalt, CreatedAt, UpdatedAt, Role, Status) 
VALUES (N'Trần Xuân Diệp', 'xuandiep@gmail.com', '0123456789', 'Dcnvs4Q7++vBs41b7JyxCU2+NafAF7Go4vpHE8dmudk=', 'qvcR0SAIgquqF1n1J/iH5w==', '2026-04-20 15:03:58', '2026-04-20 15:03:58', 'user', 'active');


INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-001', 1, '2026-04-01', '2026-04-05', 2, N'Completed', N'Huy Hoàng Trần', 'hoangt1245@gmail.com', '123456789', 400000000, 100000000, 1);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-002', 2, '2026-04-02', '2026-04-06', 1, N'Completed', N'Nguyễn Văn A', 'anguyen@gmail.com', '123456789', 120000000, 30000000, 2);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-003', 3, '2026-04-10', '2026-04-14', 2, N'CheckedOut', N'Trương Tuấn T', 'tuantu@gmail.com', '123456789', 400000000, 100000000, 3);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-004', 4, '2026-04-15', '2026-04-19', 1, N'Completed', N'Nguyen Thi Thuy', 'thuynguyen@gmail.com', '123456789', 200000000, 50000000, 4);
INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-005', 5, '2026-04-18', '2026-04-22', 2, N'CheckedIn', N'Trần Thái Tuấn', 'tuantran@gmail.com', '123456789', 400000000, 100000000, 5);
INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-006', 6, '2026-04-19', '2026-04-21', 1, N'CheckedIn', N'Ngô Thanh Tùng', 'thanhtung@gmail.com', '123456789', 6000000, 3000000, 6);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-007', 7, '2026-04-20', '2026-04-24', 1, N'CheckedIn', N'Hồ Xuân Hương', 'xuanhuong@gmail.com', '123456789', 20000000, 5000000, 7);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-008', 8, '2026-04-10', '2026-04-12', 2, N'Completed', N'Huy Hoàng Trần', 'hoangt1245@gmail.com', '123456789', 20000000, 10000000, 1);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId)
VALUES ('BK-009', 1, '2026-04-20', '2026-04-25', 2, N'CheckedIn', N'Nguyễn Văn A', 'anguyen@gmail.com', '123456789', 500000000, 100000000, 2);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-010', 2, '2026-04-20', '2026-04-23', 1, N'CheckedIn', N'Trương Tuấn T', 'tuantu@gmail.com', '123456789', 90000000, 30000000, 3);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-011', 3, '2026-04-21', '2026-04-25', 2, N'Confirmed', N'Nguyen Thi Thuy', 'thuynguyen@gmail.com', '123456789', 400000000, 100000000, 4);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-012', 4, '2026-04-25', '2026-04-30', 1, N'Confirmed', N'Trần Thái Tuấn', 'tuantran@gmail.com', '123456789', 250000000, 50000000, 5);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-013', 5, '2026-05-01', '2026-05-05', 2, N'Pending', N'Ngô Thanh Tùng', 'thanhtung@gmail.com', '123456789', 400000000, 100000000, 6);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-014', 6, '2026-05-05', '2026-05-08', 1, N'Pending', N'Hồ Xuân Hương', 'xuanhuong@gmail.com', '123456789', 9000000, 3000000, 7);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-015', 7, '2026-05-01', '2026-05-05', 2, N'Confirmed', N'Huy Hoàng Trần', 'hoangt1245@gmail.com', '123456789', 20000000, 5000000, 1);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-016', 8, '2026-05-05', '2026-05-10', 1, N'Pending', N'Nguyễn Văn A', 'anguyen@gmail.com', '123456789', 50000000, 10000000, 2);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-017', 1, '2026-05-10', '2026-05-15', 2, N'Pending', N'Trương Tuấn T', 'tuantu@gmail.com', '123456789', 500000000, 100000000, 3);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-018', 2, '2026-05-15', '2026-05-20', 1, N'Pending', N'Nguyen Thi Thuy', 'thuynguyen@gmail.com', '123456789', 150000000, 30000000, 4);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-019', 3, '2026-06-01', '2026-06-05', 2, N'Confirmed', N'Trần Thái Tuấn', 'tuantran@gmail.com', '123456789', 400000000, 100000000, 5);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-020', 4, '2026-06-05', '2026-06-10', 1, N'Confirmed', N'Ngô Thanh Tùng', 'thanhtung@gmail.com', '123456789', 250000000, 50000000, 6);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-021', 5, '2026-06-15', '2026-06-20', 2, N'Pending', N'Hồ Xuân Hương', 'xuanhuong@gmail.com', '123456789', 500000000, 100000000, 7);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-022', 6, '2026-06-15', '2026-06-18', 1, N'Cancelled', N'Huy Hoàng Trần', 'hoangt1245@gmail.com', '123456789', 9000000, 3000000, 1);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-023', 7, '2026-06-20', '2026-06-25', 2, N'Pending', N'Nguyễn Văn A', 'anguyen@gmail.com', '123456789', 25000000, 5000000, 2);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-024', 8, '2026-07-01', '2026-07-05', 2, N'Pending', N'Trương Tuấn T', 'tuantu@gmail.com', '123456789', 40000000, 10000000, 3);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-025', 1, '2026-07-10', '2026-07-15', 2, N'Cancelled', N'Nguyen Thi Thuy', 'thuynguyen@gmail.com', '123456789', 500000000, 100000000, 4);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-026', 2, '2026-07-20', '2026-07-25', 1, N'Pending', N'Trần Thái Tuấn', 'tuantran@gmail.com', '123456789', 150000000, 30000000, 5);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-027', 3, '2026-08-01', '2026-08-05', 2, N'Cancelled', N'Ngô Thanh Tùng', 'thanhtung@gmail.com', '123456789', 400000000, 100000000, 6);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-028', 4, '2026-08-10', '2026-08-15', 1, N'Pending', N'Hồ Xuân Hương', 'xuanhuong@gmail.com', '123456789', 250000000, 50000000, 7);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-029', 5, '2026-08-20', '2026-08-25', 2, N'Pending', N'Huy Hoàng Trần', 'hoangt1245@gmail.com', '123456789', 500000000, 100000000, 1);

INSERT INTO Bookings (BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName, GuestEmail, GuestPhone, TotalAmount, PricePerNight, AccountId) 
VALUES ('BK-030', 6, '2026-09-01', '2026-09-05', 1, N'Pending', N'Nguyễn Văn A', 'anguyen@gmail.com', '123456789', 12000000, 3000000, 2);


-- 1. Snapshot Metrics (Single row)
SELECT 
    -- Occupancy Rate (%)
    (SELECT CAST(COUNT(DISTINCT RoomId) * 100.0 / NULLIF((SELECT COUNT(*) FROM [dbo].[Rooms] WHERE Status = 'Active'), 0) AS DECIMAL(5,2))
     FROM [dbo].[Bookings] 
     WHERE CAST(GETDATE() AS DATE) >= CheckIn 
       AND CAST(GETDATE() AS DATE) < CheckOut 
       AND Status IN ('Confirmed', 'CheckedIn')) AS OccupancyRate,
       
    -- Pending Bookings
    (SELECT COUNT(*) 
     FROM [dbo].[Bookings] 
     WHERE Status = 'Pending') AS PendingBookings,
    
    -- Available Rooms
    (SELECT COUNT(*) FROM [dbo].[Rooms] WHERE Status = 'Active') - 
    ISNULL((SELECT COUNT(DISTINCT RoomId) 
     FROM [dbo].[Bookings] 
     WHERE CAST(GETDATE() AS DATE) >= CheckIn 
       AND CAST(GETDATE() AS DATE) < CheckOut 
       AND Status IN ('Confirmed', 'CheckedIn')), 0) AS AvailableRooms,

    -- Cancellation Rate (%)
    -- Calculates the percentage of bookings that have a 'Cancelled' status
    (SELECT CAST(SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))
     FROM [dbo].[Bookings]) AS CancellationRate;

-- 2. Total Revenue by Month
-- Groups the total amount of 'Completed' bookings by Year and Month
SELECT 
    YEAR(CheckIn) AS BookingYear,
    MONTH(CheckIn) AS BookingMonth,
    ISNULL(SUM(TotalAmount), 0) AS MonthlyRevenue
FROM [dbo].[Bookings]
WHERE Status = 'Completed'
GROUP BY YEAR(CheckIn), MONTH(CheckIn)
ORDER BY BookingYear DESC, BookingMonth DESC;


-- 4. Top 3 Most Booked Rooms
-- Includes Code, Name, Type, TotalNights, TotalBookings, and TotalRevenue
SELECT TOP 3
    r.Code,
    r.Name,
    r.RoomType AS [Type],
    -- Thay thế PricePerNight bằng TotalNights (tổng số đêm)
    ISNULL(SUM(DATEDIFF(day, b.CheckIn, b.CheckOut)), 0) AS TotalNights,
    COUNT(b.Id) AS TotalBookings,
    ISNULL(SUM(CASE WHEN b.Status = 'Completed' THEN b.TotalAmount ELSE 0 END), 0) AS TotalRevenue
FROM [dbo].[Rooms] r
LEFT JOIN [dbo].[Bookings] b ON r.Id = b.RoomId
GROUP BY r.Code, r.Name, r.RoomType
ORDER BY TotalBookings DESC;



-- 3. Top 3 Highest Revenue Rooms
-- Includes Code, Name, Type, PricePerNight, TotalBookings, TotalRevenue, and OccupancyRate (Monthly)
SELECT TOP 3
    r.Code,
    r.Name,
    r.RoomType AS [Type],
    r.BasePricePerNight AS PricePerNight,
    COUNT(b.Id) AS TotalBookings,
    -- Tính Occupancy Rate dựa trên tổng số đêm thực tế đã book / 30 ngày chuẩn
    CAST((ISNULL(SUM(DATEDIFF(day, b.CheckIn, b.CheckOut)), 0) * 100.0) / 30.0 AS DECIMAL(5,2)) AS OccupancyRate,
    ISNULL(SUM(b.TotalAmount), 0) AS TotalRevenue
FROM [dbo].[Rooms] r
LEFT JOIN [dbo].[Bookings] b ON r.Id = b.RoomId AND b.Status = 'Completed'
AND MONTH(b.CheckIn) = MONTH(GETDATE()) AND YEAR(b.CheckIn) = YEAR(GETDATE())
GROUP BY r.Code, r.Name, r.RoomType, r.BasePricePerNight
ORDER BY TotalRevenue DESC;