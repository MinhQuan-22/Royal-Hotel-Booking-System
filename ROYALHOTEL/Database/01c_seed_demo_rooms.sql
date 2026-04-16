-- 01c_seed_demo_rooms.sql
-- Demo rooms for Hotel 2 (Nha Trang) and Hotel 3 (Phu Quoc)
-- Compatible with current ROYALHOTEL structure and Project 14

-- =========================
-- HOTEL 2 - NHA TRANG
-- =========================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-DLX-201')
BEGIN
    INSERT INTO Rooms (
        Code,
        Name,
        RoomType,
        BasePricePerNight,
        MaxGuests,
        IsActive,
        Description,
        CoverImageUrl,
        CreatedAt,
        UpdatedAt,
        HotelId,
        Rate,
        Status
    )
    VALUES (
        'NT-DLX-201',
        N'Nha Trang Deluxe Ocean View',
        N'Deluxe',
        1800000,
        2,
        1,
        NULL,
        NULL,
        SYSDATETIME(),
        SYSDATETIME(),
        2,
        1800000,
        'ACTIVE'
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-STE-301')
BEGIN
    INSERT INTO Rooms (
        Code,
        Name,
        RoomType,
        BasePricePerNight,
        MaxGuests,
        IsActive,
        Description,
        CoverImageUrl,
        CreatedAt,
        UpdatedAt,
        HotelId,
        Rate,
        Status
    )
    VALUES (
        'NT-STE-301',
        N'Nha Trang Premium Suite',
        N'Suite',
        2600000,
        4,
        1,
        NULL,
        NULL,
        SYSDATETIME(),
        SYSDATETIME(),
        2,
        2600000,
        'ACTIVE'
    );
END
GO

-- =========================
-- HOTEL 3 - PHU QUOC
-- =========================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'PQ-DLX-201')
BEGIN
    INSERT INTO Rooms (
        Code,
        Name,
        RoomType,
        BasePricePerNight,
        MaxGuests,
        IsActive,
        Description,
        CoverImageUrl,
        CreatedAt,
        UpdatedAt,
        HotelId,
        Rate,
        Status
    )
    VALUES (
        'PQ-DLX-201',
        N'Phu Quoc Garden Deluxe',
        N'Deluxe',
        2100000,
        2,
        1,
        NULL,
        NULL,
        SYSDATETIME(),
        SYSDATETIME(),
        3,
        2100000,
        'ACTIVE'
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'PQ-STE-401')
BEGIN
    INSERT INTO Rooms (
        Code,
        Name,
        RoomType,
        BasePricePerNight,
        MaxGuests,
        IsActive,
        Description,
        CoverImageUrl,
        CreatedAt,
        UpdatedAt,
        HotelId,
        Rate,
        Status
    )
    VALUES (
        'PQ-STE-401',
        N'Phu Quoc Family Suite',
        N'Suite',
        3200000,
        4,
        1,
        NULL,
        NULL,
        SYSDATETIME(),
        SYSDATETIME(),
        3,
        3200000,
        'ACTIVE'
    );
END
GO
