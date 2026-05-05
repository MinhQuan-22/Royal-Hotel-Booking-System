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
        Guests      INT             NOT NULL DEFAULT 1,
        Status      NVARCHAR(20)    NOT NULL DEFAULT 'Pending',
        
        GuestName   NVARCHAR(200)   NULL,
        GuestEmail  NVARCHAR(200)   NULL,
        GuestPhone  NVARCHAR(20)    NULL,
        
        PricePerNight DECIMAL(18,2)  NULL,
        TotalAmount   DECIMAL(18,2)  NULL,
        PaymentMethod NVARCHAR(50)   NULL,
        CreatedAt     DATETIME2      NOT NULL DEFAULT GETUTCDATE(),

        -- --- REFUND & CANCELLATION ---
        CancelledAt   DATETIME2      NULL,
        CancelReason  NVARCHAR(500)  NULL,
        CancelNote    NVARCHAR(MAX)  NULL,
        RefundAmount  DECIMAL(18,2)  NULL DEFAULT 0,
        RefundStatus  NVARCHAR(50)   NULL,
        RefundPolicyApplied NVARCHAR(500) NULL,
        RefundProcessedAt   DATETIME2 NULL,

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
    -- Ensure columns exist for migration/cleanup scenarios
    IF COL_LENGTH('Bookings', 'BookingCode') IS NULL ALTER TABLE Bookings ADD BookingCode NVARCHAR(50) NULL;
    IF COL_LENGTH('Bookings', 'Guests')      IS NULL ALTER TABLE Bookings ADD Guests INT NOT NULL DEFAULT 1;
    IF COL_LENGTH('Bookings', 'RefundAmount') IS NULL ALTER TABLE Bookings ADD RefundAmount DECIMAL(18,2) NULL DEFAULT 0;
    IF COL_LENGTH('Bookings', 'GuestName')   IS NULL ALTER TABLE Bookings ADD GuestName NVARCHAR(200) NULL;
    IF COL_LENGTH('Bookings', 'GuestEmail')  IS NULL ALTER TABLE Bookings ADD GuestEmail NVARCHAR(200) NULL;
    IF COL_LENGTH('Bookings', 'GuestPhone')  IS NULL ALTER TABLE Bookings ADD GuestPhone NVARCHAR(20) NULL;
    IF COL_LENGTH('Bookings', 'PricePerNight') IS NULL ALTER TABLE Bookings ADD PricePerNight DECIMAL(18,2) NULL;
    IF COL_LENGTH('Bookings', 'PaymentMethod') IS NULL ALTER TABLE Bookings ADD PaymentMethod NVARCHAR(50) NULL;
    IF COL_LENGTH('Bookings', 'CancelledAt')  IS NULL ALTER TABLE Bookings ADD CancelledAt DATETIME2 NULL;
    IF COL_LENGTH('Bookings', 'CancelReason') IS NULL ALTER TABLE Bookings ADD CancelReason NVARCHAR(500) NULL;
    IF COL_LENGTH('Bookings', 'CancelNote')   IS NULL ALTER TABLE Bookings ADD CancelNote NVARCHAR(MAX) NULL;
    IF COL_LENGTH('Bookings', 'RefundStatus') IS NULL ALTER TABLE Bookings ADD RefundStatus NVARCHAR(50) NULL;
    IF COL_LENGTH('Bookings', 'RefundProcessedAt') IS NULL ALTER TABLE Bookings ADD RefundProcessedAt DATETIME2 NULL;
    IF COL_LENGTH('Bookings', 'RefundPolicyApplied') IS NULL ALTER TABLE Bookings ADD RefundPolicyApplied NVARCHAR(500) NULL;

    -- Update NULL Guests to default 1 to prevent C# SqlNullValueException
    EXEC('UPDATE Bookings SET Guests = 1 WHERE Guests IS NULL');

    -- Backfill BookingCode
    EXEC('UPDATE Bookings SET BookingCode = CONCAT(''BK-'', Id) WHERE BookingCode IS NULL');

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys       WHERE name = 'FK_Bookings_Rooms')
        ALTER TABLE Bookings ADD CONSTRAINT FK_Bookings_Rooms FOREIGN KEY (RoomId) REFERENCES Rooms(Id);
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints  WHERE name = 'CK_Bookings_DateRange')
        ALTER TABLE Bookings ADD CONSTRAINT CK_Bookings_DateRange CHECK (CheckOut > CheckIn);
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints  WHERE name = 'CK_Bookings_Status')
        ALTER TABLE Bookings ADD CONSTRAINT CK_Bookings_Status CHECK (Status IN ('Pending','Confirmed','CheckedIn','CheckedOut','Completed','Cancelled'));
END
GO

-- Booking locking column (for race condition prevention)
IF COL_LENGTH('Bookings', 'LockExpiry') IS NULL
    ALTER TABLE Bookings ADD LockExpiry DATETIME2 NULL;
IF COL_LENGTH('Bookings', 'LockedBy')   IS NULL
    ALTER TABLE Bookings ADD LockedBy   NVARCHAR(100) NULL;
GO


-- ============================================================
-- TABLE: RoomRateChangeLog
-- (Yêu cầu đề bài: log thay đổi giá phòng >50%)
-- NOTE: Tên bảng dùng số ít để khớp với EF DbContext ToTable("RoomRateChangeLog")
-- và AnalyticsService đọc qua _context.RoomRateChangeLogs
-- ============================================================
IF OBJECT_ID('RoomRateChangeLog', 'U') IS NULL
BEGIN
    CREATE TABLE RoomRateChangeLog (
        Id            INT IDENTITY(1,1) PRIMARY KEY,
        RoomId        INT             NOT NULL,
        OldRate       DECIMAL(18,2)   NOT NULL,
        NewRate       DECIMAL(18,2)   NOT NULL,
        ChangePercent DECIMAL(10,2)   NOT NULL DEFAULT 0,
        IsLargeChange BIT             NOT NULL DEFAULT 0,  -- 1 khi thay đổi > 50%
        ChangedAt     DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
        ChangedBy     NVARCHAR(200)   NULL,
        Reason        NVARCHAR(500)   NULL,

        CONSTRAINT FK_RoomRateChangeLog_Rooms FOREIGN KEY (RoomId) REFERENCES Rooms(Id)
    );
    PRINT 'RoomRateChangeLog table created.';
END
ELSE
BEGIN
    IF COL_LENGTH('RoomRateChangeLog', 'ChangePercent') IS NULL
        ALTER TABLE RoomRateChangeLog ADD ChangePercent DECIMAL(10,2) NOT NULL DEFAULT 0;
    IF COL_LENGTH('RoomRateChangeLog', 'IsLargeChange') IS NULL
        ALTER TABLE RoomRateChangeLog ADD IsLargeChange BIT NOT NULL DEFAULT 0;
END
GO

-- ============================================================
-- TRIGGER: trg_Rooms_RateAudit
-- Yêu cầu đề bài: "Create a SQL Trigger that notifies a log
-- table whenever a room rate is changed by >50%."
-- Trigger ghi log TẤT CẢ thay đổi, đánh dấu IsLargeChange=1
-- khi thay đổi vượt quá 50%
-- ============================================================
IF OBJECT_ID('trg_Rooms_RateAudit', 'TR') IS NOT NULL
    DROP TRIGGER trg_Rooms_RateAudit;
GO

CREATE TRIGGER trg_Rooms_RateAudit
ON Rooms AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(Rate)
    BEGIN
        -- Ghi vào RoomRateChangeLog (số ít) — khớp với EF DbContext ToTable("RoomRateChangeLog")
        INSERT INTO RoomRateChangeLog
            (RoomId, OldRate, NewRate, ChangePercent, IsLargeChange, ChangedAt, ChangedBy, Reason)
        SELECT
            d.Id,
            d.Rate,
            i.Rate,
            ROUND((ABS(i.Rate - d.Rate) / NULLIF(d.Rate, 0)) * 100, 2),
            CASE
                WHEN (ABS(i.Rate - d.Rate) / NULLIF(d.Rate, 0)) * 100 > 50 THEN 1
                ELSE 0
            END,
            GETUTCDATE(),
            SYSTEM_USER,
            CASE
                WHEN (ABS(i.Rate - d.Rate) / NULLIF(d.Rate, 0)) * 100 > 50
                    THEN N'LARGE RATE CHANGE (>50%) - Requires review'
                ELSE N'Rate updated'
            END
        FROM inserted i
        JOIN deleted d ON i.Id = d.Id
        WHERE i.Rate <> d.Rate;
    END
END;
GO
PRINT 'Trigger trg_Rooms_RateAudit created (logs all changes, flags >50% as IsLargeChange=1).';
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
-- TABLE: PaymentTransactions
-- (Referenced by sp_ConfirmBooking — must exist before the SP)
-- ============================================================
IF OBJECT_ID('PaymentTransactions', 'U') IS NULL
BEGIN
    CREATE TABLE PaymentTransactions (
        Id                  INT IDENTITY(1,1) PRIMARY KEY,
        BookingId           INT             NOT NULL,
        PaymentMethod       NVARCHAR(50)    NOT NULL,
        Amount              DECIMAL(18,2)   NOT NULL,
        Status              NVARCHAR(20)    NOT NULL DEFAULT 'Paid',
        TransactionType     NVARCHAR(20)    NOT NULL DEFAULT 'Payment',
        TransactionCode     NVARCHAR(100)   NULL,
        ParentTransactionId INT             NULL,
        Note                NVARCHAR(500)   NULL,
        ProcessedAt         DATETIME2       NULL,
        CreatedAt           DATETIME2       NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT FK_PaymentTransactions_Bookings
            FOREIGN KEY (BookingId) REFERENCES Bookings(Id) ON DELETE CASCADE,
        CONSTRAINT FK_PaymentTransactions_Parent
            FOREIGN KEY (ParentTransactionId) REFERENCES PaymentTransactions(Id),
        CONSTRAINT CK_PaymentTransactions_Type
            CHECK (TransactionType IN ('Payment', 'Refund')),
        CONSTRAINT CK_PaymentTransactions_Status
            CHECK (Status IN ('Paid', 'Failed', 'Pending'))
    );
    PRINT 'PaymentTransactions table created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PaymentTransactions_BookingId')
    CREATE INDEX IX_PaymentTransactions_BookingId ON PaymentTransactions(BookingId);
GO

-- ============================================================
-- STORED PROCEDURE: sp_GetTopBookedRooms
-- Mục đích: Lấy top 3 phòng được đặt nhiều nhất (specific room level)
-- Yêu cầu: Trả về đúng columns cho TopBookedRoomDto:
--   RoomId, RoomCode, RoomName, RoomType, BookingCount
-- Dùng trong: RoomQueryService.GetTopBookedRoomsAsync()
--   → highlight phòng hot trên trang Rooms/Index
-- ============================================================
IF OBJECT_ID('sp_GetTopBookedRooms', 'P') IS NOT NULL DROP PROCEDURE sp_GetTopBookedRooms;
GO
CREATE PROCEDURE sp_GetTopBookedRooms
    @TopN INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@TopN)
        r.Id          AS RoomId,
        r.Code        AS RoomCode,
        r.Name        AS RoomName,
        r.RoomType    AS RoomType,
        COUNT(b.Id)   AS BookingCount
    FROM Bookings b
    JOIN Rooms r ON b.RoomId = r.Id
    WHERE b.Status NOT IN ('Cancelled')
    GROUP BY r.Id, r.Code, r.Name, r.RoomType
    ORDER BY BookingCount DESC;
END
GO
PRINT 'Stored procedure sp_GetTopBookedRooms created.';

-- ============================================================
-- STORED PROCEDURE: sp_ConfirmBooking (PESSIMISTIC LOCKING)
-- Yêu cầu đề bài: "Implement a Pessimistic Locking strategy
-- in SQL during booking to prevent double-booking."
-- Kỹ thuật: WITH (UPDLOCK, ROWLOCK) — khóa hàng trước khi
-- đọc, ngăn transaction khác giành phòng cùng lúc.
-- ============================================================
IF OBJECT_ID('sp_ConfirmBooking', 'P') IS NOT NULL DROP PROCEDURE sp_ConfirmBooking;
GO

CREATE PROCEDURE sp_ConfirmBooking
    @BookingId     INT,
    @PaymentMethod NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;
    BEGIN TRY

        -- ── PESSIMISTIC LOCKING ──────────────────────────────────────
        -- WITH (UPDLOCK) : báo SQL Server đây sẽ là ghi, không cho
        --                  transaction khác lấy shared lock trên hàng này
        -- WITH (ROWLOCK) : khóa cấp hàng, tránh leo thang table lock
        -- Cơ chế: nếu 2 user cùng xác nhận booking cho 1 phòng,
        --         chỉ 1 transaction được tiếp tục, transaction kia
        --         phải chờ đến khi COMMIT/ROLLBACK xong.
        -- ─────────────────────────────────────────────────────────────
        DECLARE
            @RoomId     INT,
            @CheckIn    DATE,
            @CheckOut   DATE,
            @Status     NVARCHAR(20),
            @IsActive   BIT,
            @RoomStatus NVARCHAR(20),
            @TotalAmt   DECIMAL(18,2);

        SELECT
            @RoomId     = b.RoomId,
            @CheckIn    = b.CheckIn,
            @CheckOut   = b.CheckOut,
            @Status     = b.Status,
            @TotalAmt   = b.TotalAmount,
            @IsActive   = r.IsActive,
            @RoomStatus = r.Status
        FROM Bookings b WITH (UPDLOCK, ROWLOCK)
        JOIN Rooms r    WITH (UPDLOCK, ROWLOCK) ON b.RoomId = r.Id
        WHERE b.Id = @BookingId;

        -- Validation
        IF @RoomId IS NULL
            THROW 50010, 'Booking not found.', 1;

        IF @Status <> 'Pending'
            THROW 50011, 'Only Pending bookings can be confirmed.', 1;

        IF @IsActive = 0 OR @RoomStatus <> 'ACTIVE'
            THROW 50012, 'Room is not active or currently unavailable.', 1;

        -- Kiểm tra double-booking: phòng đã được xác nhận trong cùng khoảng thời gian?
        IF EXISTS (
            SELECT 1 FROM Bookings WITH (UPDLOCK, ROWLOCK)
            WHERE  RoomId   = @RoomId
              AND  Id       <> @BookingId
              AND  Status   IN ('Confirmed', 'CheckedIn')
              AND  CheckIn  < @CheckOut
              AND  CheckOut > @CheckIn
        )
            THROW 50013, 'Room already booked for the selected dates (double-booking prevented).', 1;

        -- Cập nhật trạng thái booking (optimistic concurrency check)
        UPDATE Bookings WITH (ROWLOCK)
        SET    Status = 'Confirmed'
        WHERE  Id = @BookingId AND Status = 'Pending';

        IF @@ROWCOUNT = 0
            THROW 50014, 'Booking status changed concurrently. Please retry.', 1;

        -- Ghi nhận transaction thanh toán
        INSERT INTO PaymentTransactions
            (BookingId, PaymentMethod, Amount, Status, TransactionType,
             TransactionCode, ProcessedAt, CreatedAt)
        VALUES (
            @BookingId,
            @PaymentMethod,
            ISNULL(@TotalAmt, 0),
            'Paid',
            'Payment',
            CONCAT('PAY-', @BookingId, '-', CONVERT(NVARCHAR(8), GETDATE(), 112)),
            GETUTCDATE(),
            GETUTCDATE()
        );

        COMMIT TRANSACTION;
        PRINT 'sp_ConfirmBooking: Booking confirmed successfully.';

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
PRINT 'Stored procedure sp_ConfirmBooking (Pessimistic Locking) created.';
GO

-- ============================================================
-- STORED PROCEDURE: Quarterly_Revenue_Analytics (WINDOW FUNCTIONS)
-- Yêu cầu đề bài: "Use SQL Window Functions to rank room
-- performance within each hotel based on revenue."
-- Kỹ thuật: RANK() OVER (PARTITION BY HotelId ORDER BY Revenue)
-- ============================================================
IF OBJECT_ID('Quarterly_Revenue_Analytics', 'P') IS NOT NULL
    DROP PROCEDURE Quarterly_Revenue_Analytics;
GO

CREATE PROCEDURE Quarterly_Revenue_Analytics
    @HotelId  INT = NULL,
    @Year     INT = NULL,
    @Quarter  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ── WINDOW FUNCTIONS ─────────────────────────────────────────────
    -- RANK()       OVER (PARTITION BY): xếp hạng phòng theo doanh thu
    --              trong từng khách sạn theo từng quý
    -- DENSE_RANK() OVER (PARTITION BY): tương tự RANK nhưng không bỏ số
    -- ROW_NUMBER() OVER (PARTITION BY): số thứ tự tuyệt đối
    -- SUM()        OVER (PARTITION BY): tổng doanh thu cả khách sạn
    --              trong quý (running aggregate without GROUP BY)
    -- ─────────────────────────────────────────────────────────────────
    WITH QuarterlyData AS (
        SELECT
            h.Id                                AS HotelId,
            h.Name                              AS HotelName,
            h.City,
            r.Id                                AS RoomId,
            r.Code                              AS RoomCode,
            r.Name                              AS RoomName,
            r.RoomType,
            YEAR(b.CreatedAt)                   AS BookingYear,
            DATEPART(QUARTER, b.CreatedAt)      AS BookingQuarter,
            COUNT(b.Id)                         AS BookingCount,
            SUM(ISNULL(b.TotalAmount, 0))       AS TotalRevenue,
            AVG(ISNULL(b.TotalAmount, 0))       AS AvgRevenue
        FROM Bookings b
        JOIN Rooms   r ON b.RoomId  = r.Id
        JOIN Hotels  h ON r.HotelId = h.Id
        WHERE b.Status IN ('Confirmed', 'CheckedIn', 'CheckedOut', 'Completed')
          AND (@HotelId IS NULL OR h.Id               = @HotelId)
          AND (@Year    IS NULL OR YEAR(b.CreatedAt)  = @Year)
          AND (@Quarter IS NULL OR DATEPART(QUARTER, b.CreatedAt) = @Quarter)
        GROUP BY
            h.Id, h.Name, h.City,
            r.Id, r.Code, r.Name, r.RoomType,
            YEAR(b.CreatedAt), DATEPART(QUARTER, b.CreatedAt)
    )
    SELECT
        HotelId,
        HotelName,
        City,
        RoomId,
        RoomCode,
        RoomName,
        RoomType,
        BookingYear,
        BookingQuarter,
        BookingCount,
        TotalRevenue,
        AvgRevenue,

        -- ── WINDOW FUNCTIONS (Project 14 Core Requirement) ──────────
        RANK() OVER (
            PARTITION BY HotelId, BookingYear, BookingQuarter
            ORDER BY TotalRevenue DESC
        )                                                       AS RevenueRank,

        DENSE_RANK() OVER (
            PARTITION BY HotelId, BookingYear, BookingQuarter
            ORDER BY TotalRevenue DESC
        )                                                       AS DenseRevenueRank,

        ROW_NUMBER() OVER (
            PARTITION BY HotelId, BookingYear, BookingQuarter
            ORDER BY TotalRevenue DESC
        )                                                       AS RowNum,

        -- Tổng doanh thu toàn khách sạn trong quý (aggregate window)
        SUM(TotalRevenue) OVER (
            PARTITION BY HotelId, BookingYear, BookingQuarter
        )                                                       AS HotelQuarterTotalRevenue,

        -- Tỉ lệ đóng góp doanh thu của phòng trong quý (%)
        ROUND(
            TotalRevenue * 100.0 / NULLIF(
                SUM(TotalRevenue) OVER (
                    PARTITION BY HotelId, BookingYear, BookingQuarter
                ), 0
            ), 2
        )                                                       AS RevenueShare_Pct
        -- ────────────────────────────────────────────────────────────

    FROM QuarterlyData
    ORDER BY HotelId, BookingYear, BookingQuarter, RevenueRank;
END;
GO
PRINT 'Stored procedure Quarterly_Revenue_Analytics (Window Functions) created.';
GO

-- ============================================================
-- STORED PROCEDURE: sp_GetHotelList
-- Mục đích: Lấy danh sách chi nhánh kèm số phòng ACTIVE
-- Dùng cho: Dropdown/card chọn chi nhánh phía giao diện
-- ============================================================
IF OBJECT_ID('sp_GetHotelList', 'P') IS NOT NULL DROP PROCEDURE sp_GetHotelList;
GO

CREATE PROCEDURE sp_GetHotelList
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        h.Id,
        h.Name,
        h.Address,
        h.City,
        h.Country,
        COUNT(r.Id) AS ActiveRoomCount
    FROM Hotels h
    LEFT JOIN Rooms r ON r.HotelId = h.Id AND r.Status = 'ACTIVE' AND r.IsActive = 1
    GROUP BY h.Id, h.Name, h.Address, h.City, h.Country
    ORDER BY h.Id;
END;
GO
PRINT 'Stored procedure sp_GetHotelList created.';
GO

PRINT '';
PRINT '=================================================';
PRINT 'ROYALHOTEL Schema Initialization Complete.';
PRINT 'Next step: run SEED_data.sql';
PRINT '=================================================';
GO

-- ============================================================
-- STORED PROCEDURE: sp_GetDashboardKpi
-- Mục đích: Tính toán các chỉ số KPI chính (Doanh thu, Tỷ lệ lấp đầy, Tỷ lệ hủy)
-- Kỹ thuật: Conditional Aggregation, Complex Date Logic
-- ============================================================
IF OBJECT_ID('sp_GetDashboardKpi', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetDashboardKpi;
GO

CREATE PROCEDURE sp_GetDashboardKpi
    @HotelId INT  = NULL,
    @Year    INT,
    @Month   INT  = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME2 = DATEFROMPARTS(@Year, ISNULL(NULLIF(@Month, 0), 1), 1);
    DECLARE @EndDate DATETIME2;
    IF @Month = 0 SET @EndDate = DATEADD(YEAR, 1, @StartDate);
    ELSE SET @EndDate = DATEADD(MONTH, 1, @StartDate);

    SELECT
        -- Total Bookings: Sales performance based on CreatedAt
        ISNULL(SUM(CASE WHEN b.CreatedAt >= @StartDate AND b.CreatedAt < @EndDate THEN 1 ELSE 0 END), 0) AS TotalBookings,

        -- Gross Revenue: Based on CheckIn (Earned Revenue)
        ISNULL(SUM(CASE WHEN b.CheckIn >= @StartDate AND b.CheckIn < @EndDate AND b.Status <> 'Pending' THEN b.TotalAmount ELSE 0 END), 0) AS GrossRevenue,

        -- Refund Amount: Based on CheckIn
        ISNULL(SUM(CASE WHEN b.CheckIn >= @StartDate AND b.CheckIn < @EndDate AND b.Status <> 'Pending' THEN b.RefundAmount ELSE 0 END), 0) AS RefundAmount,

        -- Net Revenue: Gross - Refund (Calculated at SQL)
        ISNULL(SUM(CASE WHEN b.CheckIn >= @StartDate AND b.CheckIn < @EndDate AND b.Status <> 'Pending' THEN ISNULL(b.TotalAmount, 0) - ISNULL(b.RefundAmount, 0) ELSE 0 END), 0) AS NetRevenue,

        -- Cancellation Rate: Based on CheckIn bookings
        ROUND(
            ISNULL(SUM(
                CASE WHEN b.Status = 'Cancelled' AND b.CheckIn >= @StartDate AND b.CheckIn < @EndDate THEN 1.0 ELSE 0 END
            ), 0)
            * 100.0 
            / NULLIF(SUM(CASE WHEN b.CheckIn >= @StartDate AND b.CheckIn < @EndDate AND b.Status <> 'Pending' THEN 1 ELSE 0 END), 0)
        , 2) AS CancellationRate,

        -- Occupancy Rate: Based on CheckIn bookings
        ROUND(
            ISNULL(SUM(
                CASE WHEN b.Status IN ('Confirmed','CheckedIn','CheckedOut','Completed') AND b.CheckIn >= @StartDate AND b.CheckIn < @EndDate
                     THEN CAST(DATEDIFF(DAY, b.CheckIn, b.CheckOut) AS DECIMAL(10,2)) ELSE 0 END
            ), 0)
            * 100.0
            / NULLIF(
                (SELECT COUNT(r2.Id) FROM Rooms r2 WHERE r2.IsActive = 1 AND r2.Status = 'ACTIVE' AND (@HotelId IS NULL OR r2.HotelId = @HotelId))
                * DATEDIFF(DAY, @StartDate, @EndDate)
            , 0)
        , 2) AS OccupancyRate
    FROM Bookings b
    JOIN Rooms   r ON b.RoomId  = r.Id
    JOIN Hotels  h ON r.HotelId = h.Id
    WHERE (b.CheckIn >= @StartDate AND b.CheckIn < @EndDate OR b.CreatedAt >= @StartDate AND b.CreatedAt < @EndDate)
      AND (@HotelId IS NULL OR h.Id = @HotelId)
      AND b.Status <> 'Pending';
END;
GO

-- ============================================================
-- STORED PROCEDURE: sp_GetDashboardMonthlyRevenue
-- ============================================================
IF OBJECT_ID('sp_GetDashboardMonthlyRevenue', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetDashboardMonthlyRevenue;
GO

CREATE PROCEDURE sp_GetDashboardMonthlyRevenue
    @HotelId INT  = NULL,
    @Year    INT,
    @Month   INT  = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @Month = 0
    BEGIN
        WITH Months AS (
            SELECT 1 AS MonthNum UNION ALL SELECT 2 UNION ALL SELECT 3
            UNION ALL SELECT 4  UNION ALL SELECT 5 UNION ALL SELECT 6
            UNION ALL SELECT 7  UNION ALL SELECT 8 UNION ALL SELECT 9
            UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
        )
        SELECT
            m.MonthNum,
            CONCAT(N'T', m.MonthNum)                            AS Label,
            ISNULL(SUM(CASE WHEN b.Status IN ('Confirmed','CheckedIn','CheckedOut','Completed', 'Cancelled') 
                            THEN ISNULL(b.TotalAmount, 0) - ISNULL(b.RefundAmount, 0) ELSE 0 END), 0) AS NetRevenue
        FROM Months m
        LEFT JOIN Bookings b 
            ON YEAR(b.CheckIn) = @Year AND MONTH(b.CheckIn) = m.MonthNum
            AND (@HotelId IS NULL OR b.RoomId IN (SELECT Id FROM Rooms WHERE HotelId = @HotelId))
            AND b.Status <> 'Pending'
        GROUP BY m.MonthNum
        ORDER BY m.MonthNum;
    END
    ELSE
    BEGIN
        SELECT
            wk.WeekNum,
            CONCAT(N'Tuần ', wk.WeekNum)                        AS Label,
            ISNULL(SUM(CASE WHEN b.Status IN ('Confirmed','CheckedIn','CheckedOut','Completed', 'Cancelled') 
                            THEN ISNULL(b.TotalAmount, 0) - ISNULL(b.RefundAmount, 0) ELSE 0 END), 0) AS NetRevenue
        FROM (VALUES(1),(2),(3),(4)) AS wk(WeekNum)
        LEFT JOIN Bookings b 
            ON YEAR(b.CheckIn) = @Year AND MONTH(b.CheckIn) = @Month 
            AND CEILING(CAST(DAY(b.CheckIn) AS FLOAT) / 7.0) = wk.WeekNum
            AND (@HotelId IS NULL OR b.RoomId IN (SELECT Id FROM Rooms WHERE HotelId = @HotelId))
            AND b.Status <> 'Pending'
        GROUP BY wk.WeekNum
        ORDER BY wk.WeekNum;
    END
END;
GO

-- ============================================================
-- STORED PROCEDURE: sp_GetDashboardTopRooms
-- ============================================================
IF OBJECT_ID('sp_GetDashboardTopRooms', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetDashboardTopRooms;
GO

CREATE PROCEDURE sp_GetDashboardTopRooms
    @HotelId INT  = NULL,
    @Year    INT,
    @Month   INT  = 0,
    @TopN    INT  = 5
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME2 = DATEFROMPARTS(@Year, ISNULL(NULLIF(@Month, 0), 1), 1);
    DECLARE @EndDate DATETIME2;
    IF @Month = 0 SET @EndDate = DATEADD(YEAR, 1, @StartDate);
    ELSE SET @EndDate = DATEADD(MONTH, 1, @StartDate);

    SELECT TOP (@TopN)
        r.Code                                                  AS RoomCode,
        r.Name                                                  AS RoomName,
        r.RoomType                                              AS RoomType,
        h.City                                                  AS Branch,
        ISNULL(SUM(CASE WHEN b.CheckIn >= @StartDate AND b.CheckIn < @EndDate THEN ISNULL(b.TotalAmount,0) - ISNULL(b.RefundAmount,0) ELSE 0 END), 0) AS NetRevenue,
        COUNT(CASE WHEN b.CheckIn >= @StartDate AND b.CheckIn < @EndDate THEN b.Id END) AS TotalBookings,
        RANK() OVER (ORDER BY SUM(ISNULL(b.TotalAmount,0) - ISNULL(b.RefundAmount,0)) DESC) AS Rank
    FROM Rooms r
    JOIN Hotels h ON r.HotelId = h.Id
    LEFT JOIN Bookings b ON b.RoomId = r.Id AND b.Status <> 'Pending'
    WHERE (@HotelId IS NULL OR h.Id = @HotelId)
    GROUP BY r.Id, r.Code, r.Name, r.RoomType, h.City
    ORDER BY NetRevenue DESC;
END;
GO

-- ============================================================
-- STORED PROCEDURE: sp_GetDashboardRoomOccupancy
-- ============================================================
IF OBJECT_ID('sp_GetDashboardRoomOccupancy', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetDashboardRoomOccupancy;
GO

CREATE PROCEDURE sp_GetDashboardRoomOccupancy
    @HotelId INT  = NULL,
    @Year    INT,
    @Month   INT  = 0,
    @TopN    INT  = 5
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME2 = DATEFROMPARTS(@Year, ISNULL(NULLIF(@Month, 0), 1), 1);
    DECLARE @EndDate DATETIME2;
    IF @Month = 0 SET @EndDate = DATEADD(YEAR, 1, @StartDate);
    ELSE SET @EndDate = DATEADD(MONTH, 1, @StartDate);

    DECLARE @DaysInPeriod INT = DATEDIFF(DAY, @StartDate, @EndDate);

    SELECT TOP (@TopN)
        r.Code                                                  AS RoomCode,
        r.Name                                                  AS RoomName,
        h.City                                                  AS Branch,
        ROUND(
            ISNULL(SUM(
                CASE
                    WHEN b.Status IN ('Confirmed','CheckedIn','CheckedOut','Completed') AND b.CheckIn >= @StartDate AND b.CheckIn < @EndDate
                        THEN CAST(DATEDIFF(DAY, b.CheckIn, b.CheckOut) AS DECIMAL(10,2))
                    ELSE 0
                END
            ), 0) * 100.0 / NULLIF(@DaysInPeriod, 0)
        , 2)                                                    AS OccupancyPct
    FROM Rooms r
    JOIN Hotels h ON r.HotelId = h.Id
    LEFT JOIN Bookings b ON b.RoomId = r.Id AND b.Status <> 'Pending'
    WHERE (@HotelId IS NULL OR h.Id = @HotelId)
      AND r.IsActive = 1
      AND r.Status = 'ACTIVE'
    GROUP BY r.Id, r.Code, r.Name, h.City
    ORDER BY OccupancyPct DESC;
END;
GO

-- ============================================================
-- STORED PROCEDURE: sp_GetDashboardCancellationTrend
-- ============================================================
IF OBJECT_ID('sp_GetDashboardCancellationTrend', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetDashboardCancellationTrend;
GO

CREATE PROCEDURE sp_GetDashboardCancellationTrend
    @HotelId INT  = NULL,
    @Year    INT,
    @Month   INT  = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @Month = 0
    BEGIN
        WITH Months AS (
            SELECT 1 AS MonthNum UNION ALL SELECT 2 UNION ALL SELECT 3
            UNION ALL SELECT 4  UNION ALL SELECT 5 UNION ALL SELECT 6
            UNION ALL SELECT 7  UNION ALL SELECT 8 UNION ALL SELECT 9
            UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
        )
        SELECT
            m.MonthNum,
            CONCAT(N'T', m.MonthNum)                            AS Label,
            ISNULL(COUNT(CASE WHEN b.Status = 'Cancelled' AND b.CheckIn >= DATEFROMPARTS(@Year, m.MonthNum, 1) AND b.CheckIn < DATEADD(MONTH, 1, DATEFROMPARTS(@Year, m.MonthNum, 1)) THEN 1 END), 0) AS Cancelled,
            ISNULL(COUNT(CASE WHEN b.CheckIn >= DATEFROMPARTS(@Year, m.MonthNum, 1) AND b.CheckIn < DATEADD(MONTH, 1, DATEFROMPARTS(@Year, m.MonthNum, 1)) THEN b.Id END), 0) AS TotalBookings,
            ISNULL(SUM(CASE WHEN b.CheckIn >= DATEFROMPARTS(@Year, m.MonthNum, 1) AND b.CheckIn < DATEADD(MONTH, 1, DATEFROMPARTS(@Year, m.MonthNum, 1)) THEN ISNULL(b.RefundAmount, 0) ELSE 0 END), 0) AS RefundAmount
        FROM Months m
        LEFT JOIN Bookings b ON b.Status <> 'Pending'
            AND (@HotelId IS NULL OR b.RoomId IN (SELECT Id FROM Rooms WHERE HotelId = @HotelId))
        GROUP BY m.MonthNum
        ORDER BY m.MonthNum;
    END
    ELSE
    BEGIN
        DECLARE @StartDate DATETIME2 = DATEFROMPARTS(@Year, @Month, 1);
        SELECT
            wk.WeekNum,
            CONCAT(N'Tuần ', wk.WeekNum)                        AS Label,
            ISNULL(COUNT(CASE WHEN b.Status = 'Cancelled' AND b.CheckIn >= @StartDate AND MONTH(b.CheckIn) = @Month AND CEILING(CAST(DAY(b.CheckIn) AS FLOAT) / 7.0) = wk.WeekNum THEN 1 END), 0) AS Cancelled,
            ISNULL(COUNT(CASE WHEN b.CheckIn >= @StartDate AND MONTH(b.CheckIn) = @Month AND CEILING(CAST(DAY(b.CheckIn) AS FLOAT) / 7.0) = wk.WeekNum THEN b.Id END), 0) AS TotalBookings,
            ISNULL(SUM(CASE WHEN b.CheckIn >= @StartDate AND MONTH(b.CheckIn) = @Month AND CEILING(CAST(DAY(b.CheckIn) AS FLOAT) / 7.0) = wk.WeekNum THEN ISNULL(b.RefundAmount, 0) ELSE 0 END), 0) AS RefundAmount
        FROM (VALUES(1),(2),(3),(4)) AS wk(WeekNum)
        LEFT JOIN Bookings b ON b.Status <> 'Pending'
            AND (@HotelId IS NULL OR b.RoomId IN (SELECT Id FROM Rooms WHERE HotelId = @HotelId))
        GROUP BY wk.WeekNum
        ORDER BY wk.WeekNum;
    END
END;
GO

-- ============================================================
-- STORED PROCEDURE: sp_GetAdminReportRoomPerformance
-- ============================================================
IF OBJECT_ID('sp_GetAdminReportRoomPerformance', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetAdminReportRoomPerformance;
GO

CREATE PROCEDURE sp_GetAdminReportRoomPerformance
    @HotelId INT  = NULL,
    @Year    INT,
    @Month   INT  = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME2 = DATEFROMPARTS(@Year, ISNULL(NULLIF(@Month, 0), 1), 1);
    DECLARE @EndDate DATETIME2 = DATEADD(MONTH, CASE WHEN @Month=0 THEN 12 ELSE 1 END, @StartDate);

    DECLARE @TotalDays INT = DATEDIFF(DAY, @StartDate, @EndDate);

    SELECT 
        h.Name AS Branch,
        r.Code AS RoomCode,
        r.Name AS RoomName,
        r.RoomType,
        SUM(ISNULL(b.TotalAmount, 0)) AS GrossRevenue,
        SUM(CASE WHEN b.Status = 'Cancelled' THEN 1 ELSE 0 END) AS CancelledCount,
        SUM(ISNULL(b.RefundAmount, 0)) AS RefundAmount,
        COUNT(b.Id) AS TotalBookings,
        ROUND(ISNULL(SUM(CASE WHEN b.Status IN ('Confirmed','CheckedIn','CheckedOut','Completed') THEN CAST(DATEDIFF(DAY, b.CheckIn, b.CheckOut) AS DECIMAL(10,2)) ELSE 0 END), 0) * 100.0 / NULLIF(@TotalDays, 0), 2) AS OccupancyPct,
        ROUND(SUM(CASE WHEN b.Status = 'Cancelled' THEN 1.0 ELSE 0 END) * 100.0 / NULLIF(COUNT(b.Id), 0), 2) AS CancellationPct
    FROM Rooms r
    JOIN Hotels  h ON r.HotelId = h.Id
    LEFT JOIN Bookings b ON b.RoomId = r.Id
        AND b.Status <> 'Pending'
        AND b.CheckIn >= @StartDate
        AND b.CheckIn <  @EndDate
    WHERE (@HotelId IS NULL OR h.Id = @HotelId)
    GROUP BY h.Id, h.Name, h.City, r.Id, r.Code, r.Name, r.RoomType
    ORDER BY Branch, GrossRevenue DESC;
END;
GO

-- ============================================================
-- STORED PROCEDURE: sp_GetAdminReportTimeAnalysis
-- ============================================================
IF OBJECT_ID('sp_GetAdminReportTimeAnalysis', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetAdminReportTimeAnalysis;
GO

CREATE PROCEDURE sp_GetAdminReportTimeAnalysis
    @HotelId INT  = NULL,
    @Year    INT,
    @Month   INT  = 0
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #TimePeriods (
        Label           NVARCHAR(50),
        NetRevenue      DECIMAL(18,2),
        TotalBookings   INT
    );

    IF @Month = 0
    BEGIN
        INSERT INTO #TimePeriods (Label, NetRevenue, TotalBookings)
        SELECT 
            CONCAT(N'Tháng ', m.MonthNum),
            ISNULL(SUM(CASE WHEN b.Status IN ('Confirmed','CheckedIn','CheckedOut','Completed', 'Cancelled') 
                            THEN ISNULL(b.TotalAmount, 0) - ISNULL(b.RefundAmount, 0) ELSE 0 END), 0),
            COUNT(CASE WHEN b.Status <> 'Pending' THEN b.Id END)
        FROM (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) AS m(MonthNum)
        LEFT JOIN Bookings b 
            ON YEAR(b.CheckIn) = @Year AND MONTH(b.CheckIn) = m.MonthNum
            AND (@HotelId IS NULL OR b.RoomId IN (SELECT Id FROM Rooms WHERE HotelId = @HotelId))
            AND b.Status <> 'Pending'
        GROUP BY m.MonthNum;
    END
    ELSE
    BEGIN
        INSERT INTO #TimePeriods (Label, NetRevenue, TotalBookings)
        SELECT 
            CONCAT(N'Tuần ', wk.WeekNum),
            ISNULL(SUM(CASE WHEN b.Status IN ('Confirmed','CheckedIn','CheckedOut','Completed', 'Cancelled') 
                            THEN ISNULL(b.TotalAmount, 0) - ISNULL(b.RefundAmount, 0) ELSE 0 END), 0),
            COUNT(CASE WHEN b.Status <> 'Pending' THEN b.Id END)
        FROM (VALUES(1),(2),(3),(4)) AS wk(WeekNum)
        LEFT JOIN Bookings b 
            ON YEAR(b.CheckIn) = @Year AND MONTH(b.CheckIn) = @Month 
            AND CEILING(CAST(DAY(b.CheckIn) AS FLOAT) / 7.0) = wk.WeekNum
            AND (@HotelId IS NULL OR b.RoomId IN (SELECT Id FROM Rooms WHERE HotelId = @HotelId))
            AND b.Status <> 'Pending'
        GROUP BY wk.WeekNum;
    END

    SELECT TOP 1
        (SELECT TOP 1 Label FROM #TimePeriods ORDER BY NetRevenue DESC) AS HighestRevenueLabel,
        (SELECT TOP 1 NetRevenue FROM #TimePeriods ORDER BY NetRevenue DESC) AS HighestRevenueValue,

        (SELECT TOP 1 Label FROM #TimePeriods ORDER BY NetRevenue ASC) AS LowestRevenueLabel,
        (SELECT TOP 1 NetRevenue FROM #TimePeriods ORDER BY NetRevenue ASC) AS LowestRevenueValue,

        (SELECT TOP 1 Label FROM #TimePeriods ORDER BY TotalBookings DESC) AS MostBookingLabel,
        (SELECT TOP 1 TotalBookings FROM #TimePeriods ORDER BY TotalBookings DESC) AS MostBookingCount
    FROM #TimePeriods;

    DROP TABLE #TimePeriods;
END;
GO

PRINT 'ROYALHOTEL Schema Initialization Complete with Advanced Analytics.';
GO
