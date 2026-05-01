-- ============================================================
-- ROYALHOTEL — SQL Server Schema Initialization
-- File: INIT_schema.sql
-- Run on: RoyalHotelDb
-- Order: Run this FIRST before SEED_data.sql
-- ============================================================

USE RoyalHotelDb;
GO

-- ============================================================
-- TABLE: Hotels
-- ============================================================
IF OBJECT_ID('Hotels', 'U') IS NULL
BEGIN
    CREATE TABLE Hotels (
        Id      INT IDENTITY(1,1) PRIMARY KEY,
        Name    NVARCHAR(200) NOT NULL DEFAULT 'ROYALHOTEL',
        Address NVARCHAR(500) NOT NULL DEFAULT '',
        City    NVARCHAR(100) NOT NULL,
        Country NVARCHAR(100) NOT NULL DEFAULT 'Vietnam'
    );
    PRINT 'Hotels table created.';
END

IF COL_LENGTH('Hotels', 'Name')    IS NULL ALTER TABLE Hotels ADD Name    NVARCHAR(200) NOT NULL CONSTRAINT DF_Hotels_Name    DEFAULT 'ROYALHOTEL';
IF COL_LENGTH('Hotels', 'Address') IS NULL ALTER TABLE Hotels ADD Address NVARCHAR(500) NOT NULL CONSTRAINT DF_Hotels_Address DEFAULT '';
IF COL_LENGTH('Hotels', 'Country') IS NULL ALTER TABLE Hotels ADD Country NVARCHAR(100) NOT NULL CONSTRAINT DF_Hotels_Country DEFAULT 'Vietnam';
GO

-- ============================================================
-- TABLE: Accounts
-- ============================================================
IF OBJECT_ID('Accounts', 'U') IS NULL
BEGIN
    CREATE TABLE Accounts (
        Id           INT IDENTITY(1,1) PRIMARY KEY,
        FullName     NVARCHAR(200) NOT NULL,
        Email        NVARCHAR(200) NOT NULL UNIQUE,
        PasswordHash NVARCHAR(500) NOT NULL,
        Role         NVARCHAR(20)  NOT NULL DEFAULT 'user',
        Status       NVARCHAR(20)  NOT NULL DEFAULT 'Active',
        CreatedAt    DATETIME2     NOT NULL DEFAULT GETUTCDATE()
    );
    PRINT 'Accounts table created.';
END

IF COL_LENGTH('Accounts', 'Status') IS NULL
    ALTER TABLE Accounts ADD Status NVARCHAR(20) NOT NULL CONSTRAINT DF_Accounts_Status DEFAULT 'Active';
GO

-- ============================================================
-- TABLE: Rooms
-- ============================================================
IF OBJECT_ID('Rooms', 'U') IS NULL
BEGIN
    CREATE TABLE Rooms (
        Id                INT IDENTITY(1,1) PRIMARY KEY,
        Code              NVARCHAR(50)    NOT NULL UNIQUE,
        Name              NVARCHAR(200)   NOT NULL,
        RoomType          NVARCHAR(50)    NOT NULL,
        BasePricePerNight DECIMAL(18,2)   NOT NULL,
        MaxGuests         INT             NOT NULL DEFAULT 2,
        IsActive          BIT             NOT NULL DEFAULT 1,
        Description       NVARCHAR(MAX)   NULL,
        CoverImageUrl     NVARCHAR(500)   NULL,
        CreatedAt         DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt         DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
        HotelId           INT             NOT NULL,
        Rate              DECIMAL(18,2)   NOT NULL,
        Status            NVARCHAR(20)    NOT NULL DEFAULT 'ACTIVE',

        CONSTRAINT FK_Rooms_Hotels FOREIGN KEY (HotelId) REFERENCES Hotels(Id),
        CONSTRAINT CK_Rooms_Rate_Positive CHECK (Rate > 0),
        CONSTRAINT CK_Rooms_Status CHECK (Status IN ('ACTIVE', 'MAINTENANCE', 'INACTIVE'))
    );
    PRINT 'Rooms table created.';
END
ELSE
BEGIN
    IF COL_LENGTH('Rooms', 'HotelId') IS NULL ALTER TABLE Rooms ADD HotelId INT NULL;
    IF COL_LENGTH('Rooms', 'Rate')    IS NULL ALTER TABLE Rooms ADD Rate    DECIMAL(18,2) NULL;
    IF COL_LENGTH('Rooms', 'Status')  IS NULL ALTER TABLE Rooms ADD Status  NVARCHAR(20) NOT NULL CONSTRAINT DF_Rooms_Status DEFAULT 'ACTIVE';

    -- Backfill Rate from BasePricePerNight
    IF COL_LENGTH('Rooms', 'BasePricePerNight') IS NOT NULL
        UPDATE Rooms SET Rate = BasePricePerNight WHERE Rate IS NULL;

    -- Backfill HotelId to default hotel 1
    UPDATE Rooms SET HotelId = 1 WHERE HotelId IS NULL;

    -- Add FK and constraints if missing
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Rooms_Hotels')
        ALTER TABLE Rooms ADD CONSTRAINT FK_Rooms_Hotels FOREIGN KEY (HotelId) REFERENCES Hotels(Id);
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Rooms_Rate_Positive')
        ALTER TABLE Rooms ADD CONSTRAINT CK_Rooms_Rate_Positive CHECK (Rate > 0);
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Rooms_Status')
        ALTER TABLE Rooms ADD CONSTRAINT CK_Rooms_Status CHECK (Status IN ('ACTIVE', 'MAINTENANCE', 'INACTIVE'));
END
GO

-- ============================================================
-- TABLE: Bookings
-- ============================================================
IF OBJECT_ID('Bookings', 'U') IS NULL
BEGIN
    CREATE TABLE Bookings (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        RoomId      INT             NOT NULL,
        AccountId   INT             NULL,
        BookingCode NVARCHAR(50)    NOT NULL UNIQUE,
        CheckIn     DATE            NOT NULL,
        CheckOut    DATE            NOT NULL,
        Status      NVARCHAR(20)    NOT NULL DEFAULT 'Pending',
        TotalAmount DECIMAL(18,2)   NULL,
        CreatedAt   DATETIME2       NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Bookings_Rooms    FOREIGN KEY (RoomId)    REFERENCES Rooms(Id),
        CONSTRAINT FK_Bookings_Accounts FOREIGN KEY (AccountId) REFERENCES Accounts(Id) ON DELETE SET NULL,
        CONSTRAINT CK_Bookings_DateRange  CHECK (CheckOut > CheckIn),
        CONSTRAINT CK_Bookings_Status     CHECK (Status IN ('Pending','Confirmed','CheckedIn','CheckedOut','Completed','Cancelled')),
        CONSTRAINT CK_Bookings_TotalAmount_NonNegative CHECK (TotalAmount IS NULL OR TotalAmount >= 0)
    );
    PRINT 'Bookings table created.';
END
ELSE
BEGIN
    IF COL_LENGTH('Bookings', 'Status')      IS NULL ALTER TABLE Bookings ADD Status      NVARCHAR(20)  NOT NULL CONSTRAINT DF_Bookings_Status  DEFAULT 'Pending';
    IF COL_LENGTH('Bookings', 'TotalAmount') IS NULL ALTER TABLE Bookings ADD TotalAmount DECIMAL(18,2) NULL;
    IF COL_LENGTH('Bookings', 'BookingCode') IS NULL ALTER TABLE Bookings ADD BookingCode NVARCHAR(50)  NULL;
    IF COL_LENGTH('Bookings', 'AccountId')   IS NULL ALTER TABLE Bookings ADD AccountId   INT           NULL;

    -- Backfill BookingCode
    UPDATE Bookings SET BookingCode = CONCAT('BK-', Id) WHERE BookingCode IS NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys       WHERE name = 'FK_Bookings_Rooms')
        ALTER TABLE Bookings ADD CONSTRAINT FK_Bookings_Rooms FOREIGN KEY (RoomId) REFERENCES Rooms(Id);
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints  WHERE name = 'CK_Bookings_DateRange')
        ALTER TABLE Bookings ADD CONSTRAINT CK_Bookings_DateRange CHECK (CheckOut > CheckIn);
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints  WHERE name = 'CK_Bookings_Status')
        ALTER TABLE Bookings ADD CONSTRAINT CK_Bookings_Status CHECK (Status IN ('Pending','Confirmed','CheckedIn','CheckedOut','Completed','Cancelled'));
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints  WHERE name = 'CK_Bookings_TotalAmount_NonNegative')
        ALTER TABLE Bookings ADD CONSTRAINT CK_Bookings_TotalAmount_NonNegative CHECK (TotalAmount IS NULL OR TotalAmount >= 0);
END
GO

-- Booking locking column (for race condition prevention)
IF COL_LENGTH('Bookings', 'LockExpiry') IS NULL
    ALTER TABLE Bookings ADD LockExpiry DATETIME2 NULL;
IF COL_LENGTH('Bookings', 'LockedBy')   IS NULL
    ALTER TABLE Bookings ADD LockedBy   NVARCHAR(100) NULL;
GO

-- ============================================================
-- TABLE: RoomRateChangeLogs
-- ============================================================
IF OBJECT_ID('RoomRateChangeLogs', 'U') IS NULL
BEGIN
    CREATE TABLE RoomRateChangeLogs (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        RoomId      INT             NOT NULL,
        OldRate     DECIMAL(18,2)   NOT NULL,
        NewRate     DECIMAL(18,2)   NOT NULL,
        ChangedAt   DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
        ChangedBy   NVARCHAR(200)   NULL,
        Reason      NVARCHAR(500)   NULL,

        CONSTRAINT FK_RoomRateChangeLogs_Rooms FOREIGN KEY (RoomId) REFERENCES Rooms(Id)
    );
    PRINT 'RoomRateChangeLogs table created.';
END
GO

-- Rate audit trigger
IF OBJECT_ID('trg_Rooms_RateAudit', 'TR') IS NULL
BEGIN
    EXEC sp_executesql N'
    CREATE TRIGGER trg_Rooms_RateAudit
    ON Rooms AFTER UPDATE AS
    BEGIN
        SET NOCOUNT ON;
        IF UPDATE(Rate)
        BEGIN
            INSERT INTO RoomRateChangeLogs (RoomId, OldRate, NewRate, ChangedAt, ChangedBy, Reason)
            SELECT d.Id, d.Rate, i.Rate, GETUTCDATE(), SYSTEM_USER, N''Rate updated via trigger''
            FROM inserted i JOIN deleted d ON i.Id = d.Id
            WHERE i.Rate <> d.Rate;
        END
    END';
    PRINT 'Rate audit trigger created.';
END
GO

-- ============================================================
-- TABLE: ChatConversations
-- ============================================================
IF OBJECT_ID('ChatConversations', 'U') IS NULL
BEGIN
    CREATE TABLE ChatConversations (
        Id               INT IDENTITY(1,1) PRIMARY KEY,
        ConversationCode NVARCHAR(50)   NOT NULL UNIQUE,
        AccountId        INT            NULL,
        GuestName        NVARCHAR(200)  NULL,
        GuestEmail       NVARCHAR(200)  NULL,
        GuestPhone       NVARCHAR(20)   NULL,
        Status           NVARCHAR(30)   NOT NULL DEFAULT 'Open',
        EscalationReason NVARCHAR(500)  NULL,
        CreatedAt        DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt        DATETIME2      NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT FK_ChatConversations_Accounts FOREIGN KEY (AccountId) REFERENCES Accounts(Id) ON DELETE SET NULL,
        CONSTRAINT CK_ChatConversations_Status   CHECK (Status IN ('Open','EscalatedToAdmin','AnsweredByAdmin','Closed'))
    );
    PRINT 'ChatConversations table created.';
END
ELSE
BEGIN
    -- Add GuestPhone if missing (added in migration 14)
    IF COL_LENGTH('ChatConversations', 'GuestPhone') IS NULL
        ALTER TABLE ChatConversations ADD GuestPhone NVARCHAR(20) NULL;
END
GO

-- ============================================================
-- TABLE: ChatMessages
-- ============================================================
IF OBJECT_ID('ChatMessages', 'U') IS NULL
BEGIN
    CREATE TABLE ChatMessages (
        Id                   INT IDENTITY(1,1) PRIMARY KEY,
        ConversationId       INT              NOT NULL,
        SenderType           NVARCHAR(20)     NOT NULL,
        MessageText          NVARCHAR(MAX)    NOT NULL,
        IsEscalationMessage  BIT              NOT NULL DEFAULT 0,
        CreatedAt            DATETIME2        NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT FK_ChatMessages_Conversations FOREIGN KEY (ConversationId) REFERENCES ChatConversations(Id) ON DELETE CASCADE,
        CONSTRAINT CK_ChatMessages_SenderType    CHECK (SenderType IN ('User','AI','Admin'))
    );
    PRINT 'ChatMessages table created.';
END
GO

-- ============================================================
-- TABLE: FAQ
-- ============================================================
IF OBJECT_ID('FAQ', 'U') IS NULL
BEGIN
    CREATE TABLE FAQ (
        Id        INT IDENTITY(1,1) PRIMARY KEY,
        Question  NVARCHAR(500) NOT NULL,
        Answer    NVARCHAR(MAX) NOT NULL,
        Category  NVARCHAR(100) NOT NULL,
        IsActive  BIT           NOT NULL DEFAULT 1,
        CreatedAt DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT CK_FAQ_Category CHECK (Category IN ('Policies','Amenities','Booking','Payment'))
    );
    PRINT 'FAQ table created.';
END
GO

-- ============================================================
-- INDEXES
-- ============================================================

-- Bookings
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Bookings_BookingCode')
    CREATE UNIQUE INDEX UQ_Bookings_BookingCode ON Bookings(BookingCode);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Bookings_RoomId_CheckIn_CheckOut_Status')
    CREATE INDEX IX_Bookings_RoomId_CheckIn_CheckOut_Status ON Bookings(RoomId, CheckIn, CheckOut, Status);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Bookings_Status_CheckIn')
    CREATE INDEX IX_Bookings_Status_CheckIn ON Bookings(Status, CheckIn);

-- Rooms
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Rooms_HotelId_Status')
    CREATE INDEX IX_Rooms_HotelId_Status ON Rooms(HotelId, Status);

-- Chat
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChatConversations_Status')
    CREATE INDEX IX_ChatConversations_Status ON ChatConversations(Status);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChatConversations_AccountId')
    CREATE INDEX IX_ChatConversations_AccountId ON ChatConversations(AccountId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChatConversations_UpdatedAt')
    CREATE INDEX IX_ChatConversations_UpdatedAt ON ChatConversations(UpdatedAt DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChatMessages_ConversationId_CreatedAt')
    CREATE INDEX IX_ChatMessages_ConversationId_CreatedAt ON ChatMessages(ConversationId, CreatedAt);

-- FAQ
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FAQ_Category_IsActive')
    CREATE INDEX IX_FAQ_Category_IsActive ON FAQ(Category, IsActive);
GO

-- ============================================================
-- STORED PROCEDURE: sp_GetTopBookedRoomTypes
-- ============================================================
IF OBJECT_ID('sp_GetTopBookedRoomTypes', 'P') IS NOT NULL DROP PROCEDURE sp_GetTopBookedRoomTypes;
GO
CREATE PROCEDURE sp_GetTopBookedRoomTypes
    @TopN INT = 5
AS
BEGIN
    SELECT TOP (@TopN)
        r.RoomType,
        COUNT(b.Id) AS BookingCount
    FROM Bookings b
    JOIN Rooms r ON b.RoomId = r.Id
    WHERE b.Status NOT IN ('Cancelled')
    GROUP BY r.RoomType
    ORDER BY BookingCount DESC;
END
GO

PRINT '';
PRINT '=================================================';
PRINT 'ROYALHOTEL Schema Initialization Complete.';
PRINT 'Next step: run SEED_data.sql';
PRINT '=================================================';
GO
