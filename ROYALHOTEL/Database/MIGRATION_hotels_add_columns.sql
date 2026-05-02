-- ============================================================
-- MIGRATION: Thêm cột Address và Country vào bảng Hotels
-- Chạy lệnh này trên DB: RoyalHotelDb (localhost,1433)
-- ============================================================

USE RoyalHotelDb;
GO

-- Thêm cột Address nếu chưa có
IF COL_LENGTH('Hotels', 'Address') IS NULL
BEGIN
    ALTER TABLE Hotels ADD Address NVARCHAR(500) NOT NULL CONSTRAINT DF_Hotels_Address DEFAULT '';
    PRINT 'Column Address added to Hotels.';
END
ELSE
    PRINT 'Column Address already exists.';
GO

-- Thêm cột Country nếu chưa có
IF COL_LENGTH('Hotels', 'Country') IS NULL
BEGIN
    ALTER TABLE Hotels ADD Country NVARCHAR(100) NOT NULL CONSTRAINT DF_Hotels_Country DEFAULT 'Vietnam';
    PRINT 'Column Country added to Hotels.';
END
ELSE
    PRINT 'Column Country already exists.';
GO

-- Cập nhật dữ liệu Address và Country cho 3 chi nhánh hiện có
UPDATE Hotels SET Address = N'Đường Võ Nguyên Giáp, Mỹ Khê, Sơn Trà',  Country = 'Vietnam' WHERE Id = 1 AND (Address = '' OR Address IS NULL);
UPDATE Hotels SET Address = N'Trần Phú, Lộc Thọ, Nha Trang',           Country = 'Vietnam' WHERE Id = 2 AND (Address = '' OR Address IS NULL);
UPDATE Hotels SET Address = N'Trần Hưng Đạo, Dương Đông, Phú Quốc',    Country = 'Vietnam' WHERE Id = 3 AND (Address = '' OR Address IS NULL);
GO

PRINT 'Migration complete. Verify:';
SELECT Id, Name, Address, City, Country FROM Hotels;
GO
