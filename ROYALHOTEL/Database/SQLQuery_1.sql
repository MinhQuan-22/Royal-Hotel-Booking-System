CREATE DATABASE RoyalHotelDb
GO
USE RoyalHotelDb
GO


-- ROOMS
CREATE TABLE Rooms (
  Id INT IDENTITY(1,1) PRIMARY KEY,
  Code NVARCHAR(50) NOT NULL UNIQUE,
  Name NVARCHAR(200) NOT NULL,
  RoomType NVARCHAR(50) NOT NULL,      -- Standard/Deluxe/Suite...
  BasePricePerNight DECIMAL(18,2) NOT NULL,
  MaxGuests INT NOT NULL,
  IsActive BIT NOT NULL DEFAULT 1,
  Description NVARCHAR(MAX) NULL,
  CoverImageUrl NVARCHAR(500) NULL,
  CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

-- AMENITIES
CREATE TABLE Amenities (
  Id INT IDENTITY(1,1) PRIMARY KEY,
  AmenityKey NVARCHAR(80) NOT NULL UNIQUE,   -- wifi, pool, breakfast...
  Name NVARCHAR(200) NOT NULL,
  IconClass NVARCHAR(120) NULL,              -- Bootstrap icon class (giữ UI icons)
  Category NVARCHAR(80) NULL
);

-- ROOM-AMENITIES (M:N)
CREATE TABLE RoomAmenities (
  RoomId INT NOT NULL,
  AmenityId INT NOT NULL,
  PRIMARY KEY(RoomId, AmenityId),
  CONSTRAINT FK_RoomAmenities_Rooms FOREIGN KEY(RoomId) REFERENCES Rooms(Id) ON DELETE CASCADE,
  CONSTRAINT FK_RoomAmenities_Amenities FOREIGN KEY(AmenityId) REFERENCES Amenities(Id) ON DELETE CASCADE
);

-- ROOM IMAGES
CREATE TABLE RoomImages (
  Id INT IDENTITY(1,1) PRIMARY KEY,
  RoomId INT NOT NULL,
  ImageUrl NVARCHAR(500) NOT NULL,
  SortOrder INT NOT NULL DEFAULT 0,
  AltText NVARCHAR(200) NULL,
  CONSTRAINT FK_RoomImages_Rooms FOREIGN KEY(RoomId) REFERENCES Rooms(Id) ON DELETE CASCADE
);

-- BOOKINGS (để lọc availability)
CREATE TABLE Bookings (
  Id INT IDENTITY(1,1) PRIMARY KEY,
  BookingCode NVARCHAR(50) NOT NULL UNIQUE,
  RoomId INT NOT NULL,
  CheckIn DATE NOT NULL,
  CheckOut DATE NOT NULL,
  Guests INT NOT NULL,
  Status NVARCHAR(30) NOT NULL, -- Confirmed/CheckedIn/CheckedOut/Completed/Cancelled
  GuestName NVARCHAR(200) NULL,
  GuestEmail NVARCHAR(200) NULL,
  GuestPhone NVARCHAR(50) NULL,
  TotalAmount DECIMAL(18,2) NULL,
  CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  CONSTRAINT FK_Bookings_Rooms FOREIGN KEY(RoomId) REFERENCES Rooms(Id)
);

CREATE INDEX IX_Bookings_RoomId_Dates ON Bookings(RoomId, CheckIn, CheckOut, Status);


-- 1) Amenities
INSERT INTO Amenities(AmenityKey, Name, IconClass, Category) VALUES
('Wifi',        N'Wifi miễn phí',        N'📶', N'basic'),
('HotShower',   N'Vòi tắm nóng lạnh',    N'🚿', N'bath'),
('Balcony',     N'Ban công',             N'🏙️', N'view'),
('Breakfast',   N'Buffet sáng',          N'🍳', N'food'),
('Spa',         N'Spa',                  N'🌸', N'service'),
('Pool',        N'Hồ bơi',               N'🏊', N'service'),
('Housekeeping',N'Dọn phòng hàng ngày',  N'🧼', N'service'),
('Aircon',      N'Điều hòa',             N'❄️', N'basic'),
('TV',          N'TV màn hình phẳng',    N'📺', N'basic'),
('Minibar',     N'Minibar',              N'☕', N'food'),
('AirportPickup',N'Đưa đón sân bay',     N'🚗', N'service');
GO

-- 2) Rooms (5 phòng để khớp UI)
INSERT INTO Rooms(Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl)
VALUES
('JR-01', N'Junior Suite',     'Suite', 1500000, 2, 1, N'Junior Suite rộng rãi, sang trọng, phù hợp cặp đôi.', '/assets/home/Room1.jpg'),
('DL-01', N'Deluxe Room',      'Deluxe',1200000, 2, 1, N'Deluxe Room thiết kế hiện đại, đầy đủ tiện nghi.',     '/assets/home/Room2.jpg'),
('EX-01', N'Executive Suite',  'Suite', 2000000, 4, 1, N'Executive Suite dành cho gia đình/nhóm nhỏ.',          '/assets/home/Room3.jpg'),
('PR-01', N'Premium Room',     'Family',1800000, 3, 1, N'Premium Room phù hợp gia đình nhỏ, thoải mái.',        '/assets/home/Room4.jpg'),
('RY-01', N'Royal Suite',      'Suite', 2500000, 6, 1, N'Royal Suite cao cấp nhất, trải nghiệm thượng hạng.',   '/assets/home/hero.jpg');
GO

-- 3) RoomImages (mỗi phòng 4 ảnh giống layout detail)
DECLARE @roomId INT;

DECLARE room_cursor CURSOR FOR
SELECT Id FROM Rooms ORDER BY Id;
OPEN room_cursor;
FETCH NEXT FROM room_cursor INTO @roomId;

WHILE @@FETCH_STATUS = 0
BEGIN
  INSERT INTO RoomImages(RoomId, ImageUrl, SortOrder, AltText) VALUES
  (@roomId, '/assets/rooms/room1.png', 0, 'img1'),
  (@roomId, '/assets/rooms/room2.jpg', 1, 'img2'),
  (@roomId, '/assets/rooms/room3jpg.jpg', 2, 'img3'),
  (@roomId, '/assets/rooms/room4.png', 3, 'img4');

  FETCH NEXT FROM room_cursor INTO @roomId;
END

CLOSE room_cursor;
DEALLOCATE room_cursor;
GO

-- 4) RoomAmenities (tiện ích khác nhau theo loại phòng)
-- Helper: lấy AmenityId theo key
DECLARE @Wifi INT = (SELECT Id FROM Amenities WHERE AmenityKey='Wifi');
DECLARE @HotShower INT = (SELECT Id FROM Amenities WHERE AmenityKey='HotShower');
DECLARE @Balcony INT = (SELECT Id FROM Amenities WHERE AmenityKey='Balcony');
DECLARE @Breakfast INT = (SELECT Id FROM Amenities WHERE AmenityKey='Breakfast');
DECLARE @Spa INT = (SELECT Id FROM Amenities WHERE AmenityKey='Spa');
DECLARE @Pool INT = (SELECT Id FROM Amenities WHERE AmenityKey='Pool');
DECLARE @Housekeeping INT = (SELECT Id FROM Amenities WHERE AmenityKey='Housekeeping');
DECLARE @Aircon INT = (SELECT Id FROM Amenities WHERE AmenityKey='Aircon');
DECLARE @TV INT = (SELECT Id FROM Amenities WHERE AmenityKey='TV');
DECLARE @Minibar INT = (SELECT Id FROM Amenities WHERE AmenityKey='Minibar');
DECLARE @AirportPickup INT = (SELECT Id FROM Amenities WHERE AmenityKey='AirportPickup');

-- Junior Suite
INSERT INTO RoomAmenities(RoomId, AmenityId)
SELECT r.Id, a.AmenityId FROM Rooms r
CROSS APPLY (VALUES(@Wifi),(@Balcony),(@Aircon),(@TV),(@Minibar)) a(AmenityId)
WHERE r.Code='JR-01';

-- Deluxe
INSERT INTO RoomAmenities(RoomId, AmenityId)
SELECT r.Id, a.AmenityId FROM Rooms r
CROSS APPLY (VALUES(@Wifi),(@HotShower),(@Balcony),(@Breakfast),(@Housekeeping)) a(AmenityId)
WHERE r.Code='DL-01';

-- Executive Suite
INSERT INTO RoomAmenities(RoomId, AmenityId)
SELECT r.Id, a.AmenityId FROM Rooms r
CROSS APPLY (VALUES(@Wifi),(@Breakfast),(@Spa),(@Pool),(@Aircon),(@TV)) a(AmenityId)
WHERE r.Code='EX-01';

-- Premium
INSERT INTO RoomAmenities(RoomId, AmenityId)
SELECT r.Id, a.AmenityId FROM Rooms r
CROSS APPLY (VALUES(@Wifi),(@Pool),(@Balcony),(@Housekeeping),(@Aircon)) a(AmenityId)
WHERE r.Code='PR-01';

-- Royal Suite
INSERT INTO RoomAmenities(RoomId, AmenityId)
SELECT r.Id, a.AmenityId FROM Rooms r
CROSS APPLY (VALUES(@Wifi),(@Breakfast),(@Spa),(@AirportPickup),(@Pool),(@Aircon),(@TV),(@Minibar)) a(AmenityId)
WHERE r.Code='RY-01';
GO

-- 5) Booking mẫu để test availability (lọc theo ngày)
INSERT INTO Bookings(BookingCode, RoomId, CheckIn, CheckOut, Guests, Status, GuestName)
SELECT 'RH-SEED-001', Id, '2026-02-27', '2026-03-01', 2, 'Confirmed', N'Test Guest'
FROM Rooms WHERE Code='DL-01';
GO


-- 1) Đảm bảo đủ 6 RoomType (nếu thiếu thì insert 1 phòng mẫu mỗi loại)
IF NOT EXISTS (SELECT 1 FROM Rooms WHERE RoomType='Standard')
INSERT INTO Rooms(Code,Name,RoomType,BasePricePerNight,MaxGuests,IsActive,Description,CoverImageUrl)
VALUES ('STD-01',N'Standard Room','Standard',3000000,2,1,N'Phòng Standard','/assets/home/Room1.jpg');

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE RoomType='Single')
INSERT INTO Rooms(Code,Name,RoomType,BasePricePerNight,MaxGuests,IsActive,Description,CoverImageUrl)
VALUES ('SGL-01',N'Single Room','Single',5000000,1,1,N'Phòng Single','/assets/home/Room2.jpg');

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE RoomType='Double')
INSERT INTO Rooms(Code,Name,RoomType,BasePricePerNight,MaxGuests,IsActive,Description,CoverImageUrl)
VALUES ('DBL-01',N'Double Room','Double',10000000,2,1,N'Phòng Double','/assets/home/Room3.jpg');

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE RoomType='Deluxe')
INSERT INTO Rooms(Code,Name,RoomType,BasePricePerNight,MaxGuests,IsActive,Description,CoverImageUrl)
VALUES ('DLX-01',N'Deluxe Room','Deluxe',30000000,2,1,N'Phòng Deluxe','/assets/home/Room4.jpg');

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE RoomType='Family')
INSERT INTO Rooms(Code,Name,RoomType,BasePricePerNight,MaxGuests,IsActive,Description,CoverImageUrl)
VALUES ('FML-01',N'Family Room','Family',50000000,4,1,N'Phòng Family','/assets/home/hero.jpg');

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE RoomType='Suite')
INSERT INTO Rooms(Code,Name,RoomType,BasePricePerNight,MaxGuests,IsActive,Description,CoverImageUrl)
VALUES ('STE-01',N'Suite','Suite',100000000,6,1,N'Phòng Suite','/assets/home/Room1.jpg');

GO

-- 2) Update giá đúng theo loại phòng (đúng yêu cầu anh)
UPDATE Rooms SET BasePricePerNight =  3000000 WHERE RoomType='Standard';
UPDATE Rooms SET BasePricePerNight =  5000000 WHERE RoomType='Single';
UPDATE Rooms SET BasePricePerNight = 10000000 WHERE RoomType='Double';
UPDATE Rooms SET BasePricePerNight = 30000000 WHERE RoomType='Deluxe';
UPDATE Rooms SET BasePricePerNight = 50000000 WHERE RoomType='Family';
UPDATE Rooms SET BasePricePerNight =100000000 WHERE RoomType='Suite';
GO


BEGIN TRAN;

-- Standard Room (RoomId = 6): Wifi(1), HotShower(2), Aircon(8), TV(9)
INSERT INTO RoomAmenities(RoomId, AmenityId)
SELECT 6, v.AmenityId
FROM (VALUES (1),(2),(8),(9)) v(AmenityId)
WHERE NOT EXISTS (
  SELECT 1 FROM RoomAmenities ra
  WHERE ra.RoomId = 6 AND ra.AmenityId = v.AmenityId
);

-- Single Room (RoomId = 7): Wifi(1), HotShower(2), Aircon(8), TV(9)
INSERT INTO RoomAmenities(RoomId, AmenityId)
SELECT 7, v.AmenityId
FROM (VALUES (1),(2),(8),(9)) v(AmenityId)
WHERE NOT EXISTS (
  SELECT 1 FROM RoomAmenities ra
  WHERE ra.RoomId = 7 AND ra.AmenityId = v.AmenityId
);

-- Double Room (RoomId = 8): Wifi(1), HotShower(2), Balcony(3), TV(9)
INSERT INTO RoomAmenities(RoomId, AmenityId)
SELECT 8, v.AmenityId
FROM (VALUES (1),(2),(3),(9)) v(AmenityId)
WHERE NOT EXISTS (
  SELECT 1 FROM RoomAmenities ra
  WHERE ra.RoomId = 8 AND ra.AmenityId = v.AmenityId
);

COMMIT TRAN;
GO

-- ACCOUNTS
IF OBJECT_ID('dbo.Accounts', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Accounts (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    Phone NVARCHAR(50) NULL,
    PasswordHash NVARCHAR(500) NOT NULL,
    PasswordSalt NVARCHAR(200) NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
  );
END
GO

-- PASSWORD RESET OTPs
IF OBJECT_ID('dbo.PasswordResetOtps', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.PasswordResetOtps (
    Id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    AccountId INT NOT NULL,
    OtpHash NVARCHAR(200) NOT NULL,
    OtpSalt NVARCHAR(200) NOT NULL,
    ExpiresAt DATETIME2 NOT NULL,
    UsedAt DATETIME2 NULL,
    AttemptCount INT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_PasswordResetOtps_Accounts FOREIGN KEY(AccountId)
      REFERENCES dbo.Accounts(Id) ON DELETE CASCADE
  );

  CREATE INDEX IX_PasswordResetOtps_AccountId_ExpiresAt
    ON dbo.PasswordResetOtps(AccountId, ExpiresAt, UsedAt);
END
GO

-- Thêm Role để phân quyền Admin/User
IF COL_LENGTH('dbo.Accounts', 'Role') IS NULL
BEGIN
  ALTER TABLE dbo.Accounts
  ADD Role NVARCHAR(20) NOT NULL
      CONSTRAINT DF_Accounts_Role DEFAULT('User');
END
GO

-- 1) Chuẩn hóa dữ liệu role về lowercase
IF COL_LENGTH('dbo.Accounts', 'Role') IS NOT NULL
BEGIN
  UPDATE dbo.Accounts SET Role = LOWER(Role);
END
GO

-- 2) Fix default Role = 'user'
IF OBJECT_ID('DF_Accounts_Role', 'D') IS NOT NULL
BEGIN
  ALTER TABLE dbo.Accounts DROP CONSTRAINT DF_Accounts_Role;
END
GO

ALTER TABLE dbo.Accounts
ADD CONSTRAINT DF_Accounts_Role DEFAULT('user') FOR Role;
GO

-- 3) Thêm check constraint (nếu chưa có) để role chỉ admin/user
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Accounts_Role')
BEGIN
  ALTER TABLE dbo.Accounts
  ADD CONSTRAINT CK_Accounts_Role CHECK (Role IN ('admin','user'));
END
GO

UPDATE Accounts
SET Role = 'admin'
WHERE Email = 'tthuuttrangg08022005@gmail.com' OR Email = 'joumitthavong@gmail.com';
GO

BEGIN TRAN;

DELETE ra
FROM RoomAmenities ra
INNER JOIN Amenities a ON a.Id = ra.AmenityId
WHERE a.AmenityKey NOT IN ('Spa', 'Breakfast', 'Pool', 'Balcony', 'Wifi', 'AirportPickup');

DECLARE @Wifi INT = (SELECT Id FROM Amenities WHERE AmenityKey = 'Wifi');
DECLARE @Balcony INT = (SELECT Id FROM Amenities WHERE AmenityKey = 'Balcony');
DECLARE @Breakfast INT = (SELECT Id FROM Amenities WHERE AmenityKey = 'Breakfast');
DECLARE @Spa INT = (SELECT Id FROM Amenities WHERE AmenityKey = 'Spa');
DECLARE @Pool INT = (SELECT Id FROM Amenities WHERE AmenityKey = 'Pool');
DECLARE @AirportPickup INT = (SELECT Id FROM Amenities WHERE AmenityKey = 'AirportPickup');

INSERT INTO RoomAmenities(RoomId, AmenityId)
SELECT r.Id, v.AmenityId
FROM Rooms r
CROSS APPLY
(
    VALUES
        (CASE WHEN r.RoomType = 'Standard' THEN @Wifi END),
        (CASE WHEN r.RoomType = 'Standard' THEN @Breakfast END),

        (CASE WHEN r.RoomType = 'Single' THEN @Wifi END),
        (CASE WHEN r.RoomType = 'Single' THEN @Balcony END),

        (CASE WHEN r.RoomType = 'Double' THEN @Wifi END),
        (CASE WHEN r.RoomType = 'Double' THEN @Balcony END),
        (CASE WHEN r.RoomType = 'Double' THEN @Breakfast END),

        (CASE WHEN r.RoomType = 'Deluxe' THEN @Wifi END),
        (CASE WHEN r.RoomType = 'Deluxe' THEN @Balcony END),
        (CASE WHEN r.RoomType = 'Deluxe' THEN @Breakfast END),
        (CASE WHEN r.RoomType = 'Deluxe' THEN @Spa END),

        (CASE WHEN r.RoomType = 'Family' THEN @Wifi END),
        (CASE WHEN r.RoomType = 'Family' THEN @Pool END),
        (CASE WHEN r.RoomType = 'Family' THEN @Balcony END),

        (CASE WHEN r.RoomType = 'Suite' THEN @Wifi END),
        (CASE WHEN r.RoomType = 'Suite' THEN @Breakfast END),
        (CASE WHEN r.RoomType = 'Suite' THEN @Spa END),
        (CASE WHEN r.RoomType = 'Suite' THEN @Pool END),
        (CASE WHEN r.RoomType = 'Suite' THEN @AirportPickup END)
) v(AmenityId)
WHERE v.AmenityId IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM RoomAmenities ra
      WHERE ra.RoomId = r.Id
        AND ra.AmenityId = v.AmenityId
  );

COMMIT TRAN;
GO


USE RoyalHotelDb;
GO

-- 1) Thêm PricePerNight nếu chưa có
IF COL_LENGTH('dbo.Bookings', 'PricePerNight') IS NULL
BEGIN
    ALTER TABLE dbo.Bookings
    ADD PricePerNight DECIMAL(18,2) NULL;
END
GO

-- 2) Thêm PaymentMethod nếu chưa có
IF COL_LENGTH('dbo.Bookings', 'PaymentMethod') IS NULL
BEGIN
    ALTER TABLE dbo.Bookings
    ADD PaymentMethod NVARCHAR(50) NULL;
END
GO

-- 3) Tạo bảng PaymentTransactions nếu chưa có
IF OBJECT_ID('dbo.PaymentTransactions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PaymentTransactions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        BookingId INT NOT NULL,
        PaymentMethod NVARCHAR(50) NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        Status NVARCHAR(50) NOT NULL DEFAULT 'Paid',
        TransactionCode NVARCHAR(100) NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

        CONSTRAINT FK_PaymentTransactions_Bookings
            FOREIGN KEY (BookingId) REFERENCES dbo.Bookings(Id)
            ON DELETE CASCADE
    );
END
GO

SELECT TOP 20 *
FROM Bookings
ORDER BY Id DESC;

SELECT Id, BookingCode, RoomId, CheckIn, CheckOut, Status, GuestName, CreatedAt
FROM Bookings
WHERE RoomId = (
    SELECT TOP 1 Id
    FROM Rooms
    WHERE Name = N'Royal Suite'
)
ORDER BY CheckIn;

ALTER TABLE [dbo].[Bookings] ADD [AccountId] INT NULL;

ALTER TABLE [dbo].[Bookings]
ADD CONSTRAINT [FK_Bookings_Accounts_AccountId] 
FOREIGN KEY ([AccountId]) REFERENCES [dbo].[Accounts]([Id])
ON DELETE SET NULL;

CREATE INDEX [IX_Bookings_AccountId] ON [dbo].[Bookings]([AccountId]);
GO

--add Status column để phân biệt active/locked (phục vụ chức năng khóa tài khoản)
IF COL_LENGTH('dbo.Accounts', 'Status') IS NULL
BEGIN
    ALTER TABLE dbo.Accounts
    ADD Status NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Accounts_Status DEFAULT('active');
END
GO

UPDATE dbo.Accounts
SET Status = 'active'
WHERE Status IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Accounts_Status')
BEGIN
    ALTER TABLE dbo.Accounts
    ADD CONSTRAINT CK_Accounts_Status CHECK (Status IN ('active','locked'));
END
GO

-- Step 1: Add AccountId column (nullable)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Bookings]') AND name = 'AccountId')
BEGIN
    ALTER TABLE [dbo].[Bookings]
    ADD [AccountId] INT NULL;
END
GO

-- Step 2: Add Foreign Key constraint
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Bookings_Accounts_AccountId')
BEGIN
    ALTER TABLE [dbo].[Bookings]
    ADD CONSTRAINT [FK_Bookings_Accounts_AccountId] 
    FOREIGN KEY ([AccountId]) 
    REFERENCES [dbo].[Accounts]([Id])
    ON DELETE SET NULL;
END
GO

-- Step 3: Create index for better query performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Bookings_AccountId' AND object_id = OBJECT_ID(N'[dbo].[Bookings]'))
BEGIN
    CREATE INDEX [IX_Bookings_AccountId] ON [dbo].[Bookings]([AccountId]);
END
GO

PRINT 'Migration completed: AccountId added to Bookings table';


--add Status column để phân biệt active/locked (phục vụ chức năng khóa tài khoản)
IF COL_LENGTH('dbo.Accounts', 'Status') IS NULL
BEGIN
    ALTER TABLE dbo.Accounts
    ADD Status NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Accounts_Status DEFAULT('active');
END
GO

UPDATE dbo.Accounts
SET Status = 'active'
WHERE Status IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Accounts_Status')
BEGIN
    ALTER TABLE dbo.Accounts
    ADD CONSTRAINT CK_Accounts_Status CHECK (Status IN ('active','locked'));
END
GO

SELECT 'Status column added successfully!' AS Result;
GO
