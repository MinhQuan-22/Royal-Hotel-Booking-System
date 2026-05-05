-- ============================================================
-- ROYALHOTEL — SQL Server Seed Data
-- File: SEED_data.sql
-- Run on: RoyalHotelDb
-- Prerequisite: INIT_schema.sql must be run first
-- ============================================================

USE RoyalHotelDb;
GO

-- ============================================================
-- HOTELS (5 demo hotels matching MongoDB HotelCatalog)
-- ============================================================

-- Hotel 1 — New York
IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 1)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, Name, Address, City, Country)
    VALUES (1, N'Royal Hotel New York', N'123 Fifth Avenue, Midtown Manhattan', N'New York', N'United States');
    SET IDENTITY_INSERT Hotels OFF;
END
ELSE
BEGIN
    UPDATE Hotels
    SET Name = N'Royal Hotel New York', Address = N'123 Fifth Avenue, Midtown Manhattan', City = N'New York', Country = N'United States'
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

IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 4)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, Name, Address, City, Country)
    VALUES (4, N'Royal Hotel Los Angeles', N'123 Sunset Boulevard, LA', N'Los Angeles', N'United States');
    SET IDENTITY_INSERT Hotels OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Id = 5)
BEGIN
    SET IDENTITY_INSERT Hotels ON;
    INSERT INTO Hotels (Id, Name, Address, City, Country)
    VALUES (5, N'Royal Hotel Chicago', N'456 Michigan Avenue, Chicago Loop', N'Chicago', N'United States');
    SET IDENTITY_INSERT Hotels OFF;
END
GO

-- ============================================================
-- ROOMS
-- Hotel 1 — New York
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NY-DLX-201')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NY-DLX-201', N'New York City View Deluxe', N'Deluxe', 5500000, 2, 1, N'Phòng Deluxe 50m² tầm nhìn ra Manhattan skyline, đầy đủ tiện nghi 5 sao.', NULL, SYSDATETIME(), SYSDATETIME(), 1, 5500000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NY-STE-401')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NY-STE-401', N'New York Penthouse Suite', N'Suite', 12000000, 4, 1, N'Penthouse Suite 200m² với terrace riêng nhìn toàn cảnh New York, butler 24/7.', NULL, SYSDATETIME(), SYSDATETIME(), 1, 12000000, 'ACTIVE');
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

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-JS-101')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NT-JS-101', N'Nha Trang Junior Suite', N'Suite', 2500000, 2, 1, N'Phòng Suite tiêu chuẩn với không gian thư giãn sang trọng.', NULL, SYSDATETIME(), SYSDATETIME(), 2, 2500000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-DLX-202')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NT-DLX-202', N'Nha Trang Deluxe Room', N'Deluxe', 1800000, 2, 1, N'Phòng Deluxe sang trọng với thiết kế hiện đại.', NULL, SYSDATETIME(), SYSDATETIME(), 2, 1800000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-ES-101')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NT-ES-101', N'Nha Trang Executive Suite', N'Suite', 3500000, 4, 1, N'Phòng Executive Suite cao cấp dành cho gia đình.', NULL, SYSDATETIME(), SYSDATETIME(), 2, 3500000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-PRM-101')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NT-PRM-101', N'Nha Trang Premium Room', N'Family', 2200000, 3, 1, N'Phòng Premium gia đình rộng rãi và tiện nghi.', NULL, SYSDATETIME(), SYSDATETIME(), 2, 2200000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-RS-101')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NT-RS-101', N'Nha Trang Royal Suite', N'Suite', 5000000, 4, 1, N'Phòng Royal Suite đẳng cấp hoàng gia tuyệt đẹp.', NULL, SYSDATETIME(), SYSDATETIME(), 2, 5000000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-STD-101')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NT-STD-101', N'Nha Trang Standard Room', N'Standard', 1000000, 2, 1, N'Phòng Standard với tiện nghi cơ bản hiện đại.', NULL, SYSDATETIME(), SYSDATETIME(), 2, 1000000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-SGL-101')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NT-SGL-101', N'Nha Trang Single Room', N'Single', 800000, 1, 1, N'Phòng Single dành cho khách lẻ nghỉ dưỡng tĩnh lặng.', NULL, SYSDATETIME(), SYSDATETIME(), 2, 800000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'NT-DBL-101')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('NT-DBL-101', N'Nha Trang Double Room', N'Double', 1200000, 2, 1, N'Phòng Double thoải mái dành cho hai người.', NULL, SYSDATETIME(), SYSDATETIME(), 2, 1200000, 'ACTIVE');
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
-- Hotel 4 — Los Angeles
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'LA-STD-101')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('LA-STD-101', N'LA Standard Ocean View', N'Standard', 2500000, 2, 1, N'Phòng Standard với tầm nhìn hướng biển, 35m², giường king size, ban công riêng.', NULL, SYSDATETIME(), SYSDATETIME(), 4, 2500000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'LA-DLX-201')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('LA-DLX-201', N'LA Deluxe Sea Breeze', N'Deluxe', 4500000, 2, 1, N'Phòng Deluxe 55m² với bồn tắm đứng, tầm nhìn panorama ra biển.', NULL, SYSDATETIME(), SYSDATETIME(), 4, 4500000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'LA-STE-301')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('LA-STE-301', N'LA Presidential Suite', N'Suite', 9500000, 4, 1, N'Suite Tổng thống 120m², phòng khách riêng, bếp nhỏ, butler riêng 24/7.', NULL, SYSDATETIME(), SYSDATETIME(), 4, 9500000, 'ACTIVE');
GO

-- ============================================================
-- Hotel 5 — Chicago
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'CHI-DLX-201')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('CHI-DLX-201', N'Chicago Lakefront Deluxe', N'Deluxe', 4800000, 2, 1, N'Phòng Deluxe 48m² nhìn ra hồ Michigan, thiết kế hiện đại sang trọng.', NULL, SYSDATETIME(), SYSDATETIME(), 5, 4800000, 'ACTIVE');
GO

IF NOT EXISTS (SELECT 1 FROM Rooms WHERE Code = 'CHI-STE-401')
    INSERT INTO Rooms (Code, Name, RoomType, BasePricePerNight, MaxGuests, IsActive, Description, CoverImageUrl, CreatedAt, UpdatedAt, HotelId, Rate, Status)
    VALUES ('CHI-STE-401', N'Chicago Executive Suite', N'Suite', 9000000, 4, 1, N'Suite Executive 180m² với phòng họp riêng, tầm nhìn panorama ra Chicago Loop.', NULL, SYSDATETIME(), SYSDATETIME(), 5, 9000000, 'ACTIVE');
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
-- ACCOUNTS DATA
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM Accounts WHERE Email = 'chudinhminhquan1002@gmail.com')
    INSERT INTO Accounts (FullName, Email, Phone, PasswordHash, PasswordSalt, Role, Status, CreatedAt, UpdatedAt)
    VALUES (N'System Admin', 'chudinhminhquan1002@gmail.com', '0901234567', 'Jbhupnn2yjfDZ73HsoztNzC6uyCwowtBeaHuX1rqLSg=', 'oLxo3KAJfvea10bdVKmBeg==', 'admin', 'active', GETUTCDATE(), GETUTCDATE());
GO

IF NOT EXISTS (SELECT 1 FROM Accounts WHERE Email = 'tthuuttrangg08022005@gmail.com')
    INSERT INTO Accounts (FullName, Email, Phone, PasswordHash, PasswordSalt, Role, Status, CreatedAt, UpdatedAt)
    VALUES (N'Test User', 'tthuuttrangg08022005@gmail.com', '0907654321', '3BI9hPu7cm2FDqQ98EQMRxUM+VXHDu+A8G2uBNmx1Us=', 'iC2sp7EyJHmnFmTL/R5r4Q==', 'user', 'active', GETUTCDATE(), GETUTCDATE());
GO

-- ============================================================
-- AMENITIES
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM Amenities WHERE AmenityKey = 'WIFI')
BEGIN
    INSERT INTO Amenities (AmenityKey, Name, IconClass, Category) VALUES
    ('WIFI', N'Wi-Fi miễn phí', 'fa-wifi', 'General'),
    ('POOL', N'Hồ bơi vô cực', 'fa-swimming-pool', 'Leisure'),
    ('JACUZZI', N'Bồn tắm sục Jacuzzi', 'fa-hot-tub', 'Room'),
    ('GYM', N'Phòng Gym 24/7', 'fa-dumbbell', 'Leisure'),
    ('SPA', N'Dịch vụ Spa', 'fa-spa', 'Leisure'),
    ('SHUTTLE', N'Đưa đón sân bay', 'fa-shuttle-van', 'General'),
    ('BUFFET', N'Bữa sáng Buffet', 'fa-utensils', 'Food'),
    ('BALCONY', N'Ban công hướng biển', 'fa-water', 'Room'),
    ('MINIBAR', N'Quầy bar mini', 'fa-glass-martini-alt', 'Room'),
    ('TV', N'Tivi màn hình phẳng', 'fa-tv', 'Room');
END
GO

-- ============================================================
-- ROOM AMENITIES
-- ============================================================
DELETE FROM RoomAmenities;

INSERT INTO RoomAmenities (RoomId, AmenityId)
SELECT r.Id, a.Id FROM Rooms r CROSS JOIN Amenities a
WHERE a.AmenityKey IN ('WIFI', 'TV', 'MINIBAR', 'BUFFET');

INSERT INTO RoomAmenities (RoomId, AmenityId)
SELECT r.Id, a.Id FROM Rooms r CROSS JOIN Amenities a
WHERE r.RoomType IN ('Deluxe', 'Suite', 'Family')
  AND a.AmenityKey IN ('POOL', 'SPA', 'SHUTTLE');

INSERT INTO RoomAmenities (RoomId, AmenityId)
SELECT r.Id, a.Id FROM Rooms r CROSS JOIN Amenities a
WHERE (r.Name LIKE '%Suite%' OR r.Name LIKE '%Ocean%' OR r.Name LIKE '%Sea%')
  AND a.AmenityKey IN ('JACUZZI', 'BALCONY');
GO

-- ============================================================
-- ROOM IMAGES
-- ============================================================
DELETE FROM RoomImages;

INSERT INTO RoomImages (RoomId, ImageUrl, SortOrder, AltText)
SELECT Id, '/assets/rooms/room1.png', 1, N'Hình ảnh phòng chính' FROM Rooms;

INSERT INTO RoomImages (RoomId, ImageUrl, SortOrder, AltText)
SELECT Id, '/assets/rooms/room2.jpg', 2, N'Hình ảnh phòng góc nhìn 2' FROM Rooms;

INSERT INTO RoomImages (RoomId, ImageUrl, SortOrder, AltText)
SELECT Id, '/assets/rooms/room3jpg.jpg', 3, N'Hình ảnh phòng tắm' FROM Rooms;

INSERT INTO RoomImages (RoomId, ImageUrl, SortOrder, AltText)
SELECT Id, '/assets/rooms/room4.png', 4, N'Hình ảnh ban công' FROM Rooms;
GO

-- ============================================================
-- PRICING RULES & HISTORIES
-- ============================================================
DELETE FROM PricingRuleHistories;
DELETE FROM PricingRules;

INSERT INTO PricingRules (Name, RuleType, RoomType, StartDate, EndDate, DayOfWeekMask, Multiplier, Priority, IsActive, Notes, CreatedAt, UpdatedAt, CreatedBy, UpdatedBy)
VALUES
(N'Khuyến mãi Mùa Hè', 'Seasonal', NULL, DATEADD(month, -1, GETDATE()), DATEADD(month, 2, GETDATE()), '1111111', 0.85, 1, 1, N'Giảm 15% mùa hè', GETUTCDATE(), GETUTCDATE(), 'System Admin', 'System Admin'),
(N'Flash Sale Cuối Tuần', 'Promo', NULL, GETDATE(), DATEADD(day, 2, GETDATE()), '0000011', 0.80, 2, 1, N'Giảm 20% cuối tuần', GETUTCDATE(), GETUTCDATE(), 'System Admin', 'System Admin');

INSERT INTO PricingRuleHistories (PricingRuleId, ActionType, RuleName, RuleType, RoomType, StartDate, EndDate, DayOfWeekMask, Multiplier, Priority, IsActive, Notes, ChangedAt, ChangedBy)
SELECT Id, 'Created', Name, RuleType, RoomType, StartDate, EndDate, DayOfWeekMask, Multiplier, Priority, IsActive, Notes, GETUTCDATE(), 'System Admin'
FROM PricingRules;
GO

-- ============================================================
-- BOOKINGS & PAYMENT TRANSACTIONS
-- ============================================================
DELETE FROM PaymentTransactions;
DELETE FROM Bookings;

DECLARE @UserId INT = (SELECT TOP 1 Id FROM Accounts WHERE Role = 'user');
DECLARE @AdminId INT = (SELECT TOP 1 Id FROM Accounts WHERE Role = 'admin');

-- Booking 1 (Completed)
INSERT INTO Bookings (RoomId, AccountId, BookingCode, CheckIn, CheckOut, Guests, Status, PricePerNight, TotalAmount, PaymentMethod, CreatedAt)
SELECT TOP 1 Id, @UserId, 'BK-TEST-001', DATEADD(day, -10, CAST(GETDATE() AS DATE)), DATEADD(day, -7, CAST(GETDATE() AS DATE)), 2, 'Completed', Rate, Rate * 3, 'Credit Card', DATEADD(day, -15, GETUTCDATE())
FROM Rooms ORDER BY Id ASC;

-- Booking 2 (Confirmed)
INSERT INTO Bookings (RoomId, AccountId, BookingCode, CheckIn, CheckOut, Guests, Status, PricePerNight, TotalAmount, PaymentMethod, CreatedAt)
SELECT TOP 1 Id, @UserId, 'BK-TEST-002', DATEADD(day, 5, CAST(GETDATE() AS DATE)), DATEADD(day, 8, CAST(GETDATE() AS DATE)), 2, 'Confirmed', Rate, Rate * 3, 'Credit Card', DATEADD(day, -2, GETUTCDATE())
FROM Rooms ORDER BY Id DESC;

-- Booking 3 (Pending)
INSERT INTO Bookings (RoomId, AccountId, BookingCode, CheckIn, CheckOut, Guests, Status, PricePerNight, TotalAmount, PaymentMethod, CreatedAt)
SELECT TOP 1 Id, @AdminId, 'BK-TEST-003', DATEADD(day, 12, CAST(GETDATE() AS DATE)), DATEADD(day, 15, CAST(GETDATE() AS DATE)), 4, 'Pending', Rate, Rate * 3, 'Bank Transfer', GETUTCDATE()
FROM Rooms WHERE RoomType = 'Suite';

INSERT INTO PaymentTransactions (BookingId, PaymentMethod, Amount, Status, TransactionType, TransactionCode, ProcessedAt, CreatedAt)
SELECT Id, PaymentMethod, TotalAmount, 'Paid', 'Payment', CONCAT('PAY-', BookingCode), CreatedAt, CreatedAt
FROM Bookings
WHERE Status IN ('Completed', 'Confirmed');
GO

-- ============================================================
-- ROOM RATE CHANGE LOG (Trigger via UPDATE)
-- ============================================================
UPDATE Rooms
SET Rate = Rate * 1.6
WHERE Code = 'NT-RS-101';
GO

-- ============================================================
-- VERIFY
-- ============================================================
PRINT '';
PRINT '=================================================';
SELECT 'Hotels'            AS [Table], COUNT(*) AS [Rows] FROM Hotels         UNION ALL
SELECT 'Rooms'             AS [Table], COUNT(*) AS [Rows] FROM Rooms           UNION ALL
SELECT 'FAQ'               AS [Table], COUNT(*) AS [Rows] FROM FAQ             UNION ALL
SELECT 'Accounts'          AS [Table], COUNT(*) AS [Rows] FROM Accounts;
PRINT 'ROYALHOTEL Seed Data Complete.';
PRINT '=================================================';
GO

-- ============================================================
-- MASSIVE BOOKING GENERATION (For Advanced Analytics)
-- Mục đích: Tạo ~400 bookings trong năm 2026 để biểu đồ đẹp
-- ============================================================
PRINT 'Generating ~400 sample bookings for 2026...';
DECLARE @i INT = 1;
DECLARE @TotalRooms INT = (SELECT COUNT(*) FROM Rooms);
DECLARE @StartDate DATE = '2026-01-01';
DECLARE @EndDate DATE = '2026-12-31';

WHILE @i <= 400
BEGIN
    DECLARE @RoomId INT = (SELECT TOP 1 Id FROM Rooms ORDER BY NEWID());
    DECLARE @DaysFromStart INT = ABS(CHECKSUM(NEWID())) % DATEDIFF(DAY, @StartDate, @EndDate);
    DECLARE @CheckIn DATE = DATEADD(DAY, @DaysFromStart, @StartDate);
    DECLARE @StayDays INT = (ABS(CHECKSUM(NEWID())) % 4) + 1;
    DECLARE @CheckOut DATE = DATEADD(DAY, @StayDays, @CheckIn);
    
    DECLARE @Rate DECIMAL(18,2) = (SELECT Rate FROM Rooms WHERE Id = @RoomId);
    DECLARE @TotalAmount DECIMAL(18,2) = @Rate * @StayDays;
    
    DECLARE @RandStatus INT = ABS(CHECKSUM(NEWID())) % 100;
    DECLARE @Status NVARCHAR(20) = 'Completed';
    DECLARE @RefundAmount DECIMAL(18,2) = 0;
    
    IF @RandStatus < 15 
    BEGIN
        SET @Status = 'Cancelled';
        SET @RefundAmount = CASE WHEN @RandStatus < 7 THEN @TotalAmount ELSE @TotalAmount * 0.5 END;
    END
    ELSE IF @RandStatus < 30 SET @Status = 'Confirmed';
    ELSE IF @RandStatus < 60 SET @Status = 'CheckedOut';
    
    INSERT INTO Bookings (RoomId, BookingCode, CheckIn, CheckOut, Status, TotalAmount, CreatedAt, RefundAmount, Guests, GuestName, GuestEmail)
    VALUES (
        @RoomId, 
        CONCAT('BK-2026-', @i, '-', ABS(CHECKSUM(NEWID())) % 1000),
        @CheckIn, 
        @CheckOut, 
        @Status, 
        @TotalAmount, 
        DATEADD(DAY, - (ABS(CHECKSUM(NEWID())) % 30), @CheckIn), -- Booked 1-30 days before
        @RefundAmount,
        (ABS(CHECKSUM(NEWID())) % 2) + 1, -- 1-2 guests
        N'Guest ' + CAST(@i AS NVARCHAR(10)),
        'guest' + CAST(@i AS NVARCHAR(10)) + '@example.com'
    );
    
    SET @i = @i + 1;
END
PRINT 'Sample bookings generated.';
GO

