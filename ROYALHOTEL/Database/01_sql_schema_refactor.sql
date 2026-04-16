-- 01_sql_schema_refactor.sql

-- Step 1: Create Hotels
-- Step 1: Create or align Hotels table
IF OBJECT_ID('Hotels', 'U') IS NULL
BEGIN
    CREATE TABLE Hotels (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL DEFAULT 'ROYALHOTEL',
        Address NVARCHAR(500) NOT NULL DEFAULT '',
        City NVARCHAR(100) NOT NULL,
        Country NVARCHAR(100) NOT NULL DEFAULT 'Vietnam'
    );
END
GO

IF COL_LENGTH('Hotels', 'Name') IS NULL
    ALTER TABLE Hotels ADD Name NVARCHAR(200) NOT NULL CONSTRAINT DF_Hotels_Name DEFAULT 'ROYALHOTEL';
GO

IF COL_LENGTH('Hotels', 'Address') IS NULL
    ALTER TABLE Hotels ADD Address NVARCHAR(500) NOT NULL CONSTRAINT DF_Hotels_Address DEFAULT '';
GO

IF COL_LENGTH('Hotels', 'Country') IS NULL
    ALTER TABLE Hotels ADD Country NVARCHAR(100) NOT NULL CONSTRAINT DF_Hotels_Country DEFAULT 'Vietnam';
GO

-- Step 2: Add new columns to Rooms
IF COL_LENGTH('Rooms', 'HotelId') IS NULL
    ALTER TABLE Rooms ADD HotelId INT NULL;
GO

IF COL_LENGTH('Rooms', 'Rate') IS NULL
    ALTER TABLE Rooms ADD Rate DECIMAL(18,2) NULL;
GO

IF COL_LENGTH('Rooms', 'Status') IS NULL
    ALTER TABLE Rooms ADD Status NVARCHAR(20) NOT NULL CONSTRAINT DF_Rooms_Status DEFAULT 'ACTIVE';
GO

-- Step 3: Backfill Rate from old column
IF COL_LENGTH('Rooms', 'BasePricePerNight') IS NOT NULL
BEGIN
    UPDATE Rooms
    SET Rate = BasePricePerNight
    WHERE Rate IS NULL;
END
GO

-- Step 4: Backfill HotelId (example default mapping, adjust as needed)
IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 1)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, City)
    VALUES (1, N'Da Nang');
    SET IDENTITY_INSERT Hotels OFF;
END
GO

UPDATE Rooms
SET HotelId = 1
WHERE HotelId IS NULL;
GO

-- Step 5: Add required columns to Bookings
IF COL_LENGTH('Bookings', 'Status') IS NULL
    ALTER TABLE Bookings ADD Status NVARCHAR(20) NOT NULL CONSTRAINT DF_Bookings_Status DEFAULT 'Pending';
GO

IF COL_LENGTH('Bookings', 'TotalAmount') IS NULL
    ALTER TABLE Bookings ADD TotalAmount DECIMAL(18,2) NULL;
GO

IF COL_LENGTH('Bookings', 'BookingCode') IS NULL
    ALTER TABLE Bookings ADD BookingCode NVARCHAR(50) NULL;
GO

-- Step 6: Add constraints
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Rooms_Hotels'
)
BEGIN
    ALTER TABLE Rooms
    ADD CONSTRAINT FK_Rooms_Hotels FOREIGN KEY (HotelId) REFERENCES Hotels(Id);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Rooms_Rate_Positive'
)
BEGIN
    ALTER TABLE Rooms
    ADD CONSTRAINT CK_Rooms_Rate_Positive CHECK (Rate > 0);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Rooms_Status'
)
BEGIN
    ALTER TABLE Rooms
    ADD CONSTRAINT CK_Rooms_Status CHECK (Status IN ('ACTIVE', 'MAINTENANCE', 'INACTIVE'));
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Bookings_DateRange'
)
BEGIN
    ALTER TABLE Bookings
    ADD CONSTRAINT CK_Bookings_DateRange CHECK (CheckOut > CheckIn);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Bookings_Status'
)
BEGIN
    ALTER TABLE Bookings
    ADD CONSTRAINT CK_Bookings_Status CHECK (
        Status IN ('Pending', 'Confirmed', 'CheckedIn', 'CheckedOut', 'Completed', 'Cancelled')
    );
END
GO

-- Step 7: Populate BookingCode if missing
UPDATE Bookings
SET BookingCode = CONCAT('BK-', Id)
WHERE BookingCode IS NULL;
GO

-- Step 8: Ensure Bookings.RoomId FK exists
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Bookings_Rooms'
)
BEGIN
    ALTER TABLE Bookings
    ADD CONSTRAINT FK_Bookings_Rooms FOREIGN KEY (RoomId) REFERENCES Rooms(Id);
END
GO

-- Step 9: Add TotalAmount rule
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Bookings_TotalAmount_NonNegative'
)
BEGIN
    ALTER TABLE Bookings
    ADD CONSTRAINT CK_Bookings_TotalAmount_NonNegative
    CHECK (TotalAmount IS NULL OR TotalAmount >= 0);
END
GO

-- Step 10: Validate data before making columns NOT NULL
IF EXISTS (SELECT 1 FROM Rooms WHERE HotelId IS NULL)
    THROW 50100, 'Rooms.HotelId still contains NULL values. Fix data mapping before proceeding.', 1;
GO

IF EXISTS (SELECT 1 FROM Rooms WHERE Rate IS NULL)
    THROW 50101, 'Rooms.Rate still contains NULL values. Fix data before proceeding.', 1;
GO

IF EXISTS (SELECT 1 FROM Bookings WHERE BookingCode IS NULL)
    THROW 50102, 'Bookings.BookingCode still contains NULL values. Fix data before proceeding.', 1;
GO

-- Step 11: Harden nullability
ALTER TABLE Rooms ALTER COLUMN HotelId INT NOT NULL;
GO

ALTER TABLE Rooms ALTER COLUMN Rate DECIMAL(18,2) NOT NULL;
GO

ALTER TABLE Bookings ALTER COLUMN BookingCode NVARCHAR(50) NOT NULL;
GO

-- Step 12: Add indexes AFTER ALTER COLUMN
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes WHERE name = 'UQ_Bookings_BookingCode'
)
BEGIN
    CREATE UNIQUE INDEX UQ_Bookings_BookingCode
    ON Bookings(BookingCode);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes WHERE name = 'IX_Rooms_HotelId_Status'
)
BEGIN
    CREATE INDEX IX_Rooms_HotelId_Status
    ON Rooms(HotelId, Status);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes WHERE name = 'IX_Bookings_RoomId_CheckIn_CheckOut_Status'
)
BEGIN
    CREATE INDEX IX_Bookings_RoomId_CheckIn_CheckOut_Status
    ON Bookings(RoomId, CheckIn, CheckOut, Status);
END
GO