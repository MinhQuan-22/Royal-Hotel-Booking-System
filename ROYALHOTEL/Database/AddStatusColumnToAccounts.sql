USE RoyalHotelDb;
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

SELECT 'Status column added successfully!' AS Result;
GO
