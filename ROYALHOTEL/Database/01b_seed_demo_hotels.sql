-- Demo hotels for analytics/reporting and MongoDB HotelCatalog mapping

IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 2)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, City)
    VALUES (2, N'Nha Trang');
    SET IDENTITY_INSERT Hotels OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 3)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, City)
    VALUES (3, N'Phu Quoc');
    SET IDENTITY_INSERT Hotels OFF;
END
GO
