-- ============================================================
-- ROYALHOTEL — SQL Server Seed Data
-- File: SEED_data.sql
-- Run on: RoyalHotelDb
-- Prerequisite: INIT_schema.sql must be run first
-- ============================================================

USE RoyalHotelDb;
GO

-- ============================================================
-- HOTELS (3 demo hotels matching MongoDB HotelCatalog)
-- ============================================================

-- Hotel 1 — Da Nang (seeded via INIT_schema.sql backfill, but ensure full data)
IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 1)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, Name, Address, City, Country)
    VALUES (1, N'Royal Luxury Da Nang', N'Đường Mỹ Khê, Đà Nẵng', N'Da Nang', N'Vietnam');
    SET IDENTITY_INSERT Hotels OFF;
END
ELSE
BEGIN
    UPDATE Hotels
    SET Name = N'Royal Luxury Da Nang', Address = N'Đường Mỹ Khê, Đà Nẵng', Country = N'Vietnam'
    WHERE Id = 1 AND Name = 'ROYALHOTEL';
END
GO

IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 2)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, Name, Address, City, Country)
    VALUES (2, N'Royal Luxury Nha Trang', N'Đường Trần Phú, Nha Trang', N'Nha Trang', N'Vietnam');
    SET IDENTITY_INSERT Hotels OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 3)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, Name, Address, City, Country)
    VALUES (3, N'Royal Luxury Phu Quoc', N'Bãi Dài, Phú Quốc', N'Phu Quoc', N'Vietnam');
    SET IDENTITY_INSERT Hotels OFF;
END
GO

-- ============================================================
-- ROOMS
-- Hotel 1 — Da Nang
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'DN-STD-101')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('DN-STD-101', N'Da Nang Standard Ocean View', N'Standard', 1200000, 2, 1, N'Phòng Standard với tầm nhìn hướng biển, 35m², giường king size, ban công riêng.', NULL, SYSDATETIME(), SYSDATETIME(), 1, 1200000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'DN-DLX-201')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('DN-DLX-201', N'Da Nang Deluxe Sea Breeze', N'Deluxe', 1800000, 2, 1, N'Phòng Deluxe 55m² với bồn tắm đứng, tầm nhìn panorama ra biển.', NULL, SYSDATETIME(), SYSDATETIME(), 1, 1800000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'DN-STE-301')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('DN-STE-301', N'Da Nang Presidential Suite', N'Suite', 3500000, 4, 1, N'Suite Tổng thống 120m², phòng khách riêng, bếp nhỏ, butler riêng 24/7.', NULL, SYSDATETIME(), SYSDATETIME(), 1, 3500000, 'ACTIVE');
GO

-- ============================================================
-- Hotel 2 — Nha Trang
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-DLX-201')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NT-DLX-201', N'Nha Trang Deluxe Ocean View', N'Deluxe', 1800000, 2, 1, N'Phòng Deluxe 50m² hướng biển, ban công rộng nhìn ra vịnh Nha Trang.', NULL, SYSDATETIME(), SYSDATETIME(), 2, 1800000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-STE-301')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NT-STE-301', N'Nha Trang Premium Suite', N'Suite', 2600000, 4, 1, N'Suite cao cấp 90m² với bể tắm nước nóng ngoài trời trên ban công.', NULL, SYSDATETIME(), SYSDATETIME(), 2, 2600000, 'ACTIVE');
GO

-- ============================================================
-- Hotel 3 — Phu Quoc
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'PQ-DLX-201')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('PQ-DLX-201', N'Phu Quoc Garden Deluxe', N'Deluxe', 2100000, 2, 1, N'Villa Deluxe 60m² giữa vườn nhiệt đới, vòi sen ngoài trời, lối đi riêng xuống biển.', NULL, SYSDATETIME(), SYSDATETIME(), 3, 2100000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'PQ-STE-401')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('PQ-STE-401', N'Phu Quoc Family Suite', N'Suite', 3200000, 4, 1, N'Suite Gia Đình 150m² với hồ bơi riêng, bếp nhỏ, tầm nhìn hoàng hôn ra biển Tây.', NULL, SYSDATETIME(), SYSDATETIME(), 3, 3200000, 'ACTIVE');
GO

-- ============================================================
-- FAQ DATA
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Giờ check-in và check-out là mấy giờ?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Giờ check-in và check-out là mấy giờ?',
        N'Giờ check-in tiêu chuẩn là 14:00 và check-out là 12:00. Quý khách muốn check-in sớm hoặc check-out muộn vui lòng liên hệ lễ tân để hỗ trợ tùy tình trạng phòng.',
        'Policies', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Chính sách hủy phòng như thế nào?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Chính sách hủy phòng như thế nào?',
        N'Hủy miễn phí trước 48 giờ so với ngày check-in. Hủy trong vòng 48 giờ sẽ bị tính phí tương đương 1 đêm. Gói đặc biệt có thể có chính sách riêng.',
        'Policies', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có cho phép mang thú cưng không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Khách sạn có cho phép mang thú cưng không?',
        N'Hiện tại khách sạn chưa cho phép thú cưng để đảm bảo sự thoải mái chung. Chúng tôi có thể giới thiệu dịch vụ chăm sóc thú cưng gần khách sạn nếu cần.',
        'Policies', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có phòng hút thuốc không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Khách sạn có phòng hút thuốc không?',
        N'Tất cả phòng đều không hút thuốc. Khu vực hút thuốc được chỉ định ở sảnh tầng trệt và ngoài trời.',
        'Policies', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có WiFi miễn phí không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Khách sạn có WiFi miễn phí không?',
        N'Có, WiFi tốc độ cao miễn phí trong tất cả phòng và khu vực công cộng. Thông tin đăng nhập được cung cấp khi check-in.',
        'Amenities', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có chỗ đậu xe không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Khách sạn có chỗ đậu xe không?',
        N'Có bãi đậu xe với dịch vụ valet parking, phí 100.000 VND/ngày. Camera an ninh 24/7 và nhân viên bảo vệ.',
        'Amenities', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có hồ bơi và phòng gym không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Khách sạn có hồ bơi và phòng gym không?',
        N'Có hồ bơi ngoài trời (6:00–22:00) và phòng gym 24/7, miễn phí cho khách lưu trú. Khăn tắm và nước uống có sẵn tại hồ bơi.',
        'Amenities', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có nhà hàng không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Khách sạn có nhà hàng không?',
        N'Có nhà hàng ẩm thực Việt Nam và quốc tế. Buffet sáng 6:30–10:00, trưa 11:30–14:00, tối 18:00–22:00. Room service 24/7.',
        'Amenities', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có dịch vụ spa không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Khách sạn có dịch vụ spa không?',
        N'Royal Spa cung cấp massage, chăm sóc da mặt và các liệu trình thư giãn, mở cửa 9:00–21:00 hàng ngày. Vui lòng đặt lịch trước.',
        'Amenities', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Làm thế nào để đặt phòng?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Làm thế nào để đặt phòng?',
        N'Đặt phòng trực tiếp trên website, gọi hotline hoặc gửi email. Chọn ngày, loại phòng, hoàn tất thanh toán và nhận email xác nhận ngay.',
        'Booking', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Tôi có thể thay đổi ngày đặt phòng không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Tôi có thể thay đổi ngày đặt phòng không?',
        N'Có thể thay đổi miễn phí trước 48 giờ so với ngày check-in ban đầu, tùy tình trạng phòng trống. Liên hệ bộ phận đặt phòng với mã đặt phòng để được hỗ trợ.',
        'Booking', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Làm thế nào để đặt phòng cho nhóm lớn?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Làm thế nào để đặt phòng cho nhóm lớn?',
        N'Đặt phòng nhóm (từ 5 phòng trở lên) vui lòng liên hệ bộ phận bán hàng để được tư vấn và nhận ưu đãi đặc biệt.',
        'Booking', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Tôi có thể yêu cầu phòng tầng cao hoặc view đẹp không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Tôi có thể yêu cầu phòng tầng cao hoặc view đẹp không?',
        N'Có thể ghi chú khi đặt phòng hoặc liên hệ trực tiếp. Chúng tôi sẽ cố gắng đáp ứng tùy phòng trống, một số view đặc biệt có thể có phụ phí.',
        'Booking', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn chấp nhận những hình thức thanh toán nào?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Khách sạn chấp nhận những hình thức thanh toán nào?',
        N'Chấp nhận tiền mặt (VND), thẻ tín dụng (Visa, Mastercard, JCB, Amex), thẻ ghi nợ nội địa và chuyển khoản ngân hàng. Thanh toán trực tuyến qua cổng thanh toán an toàn.',
        'Payment', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Tôi có cần đặt cọc khi đặt phòng không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Tôi có cần đặt cọc khi đặt phòng không?',
        N'Khi đặt trực tuyến có thể chọn thanh toán toàn bộ hoặc đặt cọc 30%. Số tiền còn lại thanh toán khi check-in hoặc check-out.',
        'Payment', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Tôi có thể nhận hóa đơn VAT không?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Tôi có thể nhận hóa đơn VAT không?',
        N'Có, cung cấp thông tin công ty (tên, MST, địa chỉ) cho lễ tân khi check-out. Hóa đơn điện tử gửi qua email trong vòng 24 giờ.',
        'Payment', 1, GETDATE(), GETDATE());
GO

IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Chính sách hoàn tiền như thế nào?')
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt) VALUES (
        N'Chính sách hoàn tiền như thế nào?',
        N'Hủy đúng chính sách (trước 48 giờ) được hoàn tiền trong 7–10 ngày làm việc. Phí hủy (nếu có) sẽ trừ vào số tiền hoàn lại. Liên hệ bộ phận đặt phòng để hỗ trợ.',
        'Payment', 1, GETDATE(), GETDATE());
GO

-- ============================================================
-- VERIFY
-- ============================================================
PRINT '';
PRINT '=================================================';
SELECT 'Hotels'            AS [Table], COUNT(*) AS [Rows] FROM Hotels         UNION ALL
SELECT 'Rooms'             AS [Table], COUNT(*) AS [Rows] FROM Rooms           UNION ALL
SELECT 'FAQ'               AS [Table], COUNT(*) AS [Rows] FROM FAQ;
PRINT 'ROYALHOTEL Seed Data Complete.';
PRINT '=================================================';
GO
