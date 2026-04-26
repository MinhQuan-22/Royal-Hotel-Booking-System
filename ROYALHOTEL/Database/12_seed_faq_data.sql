-- =============================================
-- Script: 12_seed_faq_data.sql
-- Description: Seed common FAQ questions and answers for AI Live Chat Support
-- Categories: Policies, Amenities, Booking, Payment
-- Validates: Requirements 19.2
-- =============================================

USE RoyalHotelDb;
GO

-- Check if FAQ table exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FAQ')
BEGIN
    PRINT 'ERROR: FAQ table does not exist. Please run 11_create_faq_table.sql first.';
    RETURN;
END
GO

-- Clear existing FAQ data (optional - comment out if you want to preserve existing data)
-- DELETE FROM FAQ;
-- GO

-- =============================================
-- Category: Policies
-- =============================================

-- Check-in/Check-out Policy
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Giờ check-in và check-out là mấy giờ?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Giờ check-in và check-out là mấy giờ?',
        N'Giờ check-in tiêu chuẩn là 14:00 (2:00 PM) và giờ check-out là 12:00 (12:00 PM). Nếu quý khách muốn check-in sớm hoặc check-out muộn, vui lòng liên hệ với lễ tân để được hỗ trợ tùy theo tình trạng phòng trống.',
        'Policies',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Check-in/Check-out time';
END
GO

-- Cancellation Policy
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Chính sách hủy phòng như thế nào?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Chính sách hủy phòng như thế nào?',
        N'Quý khách có thể hủy đặt phòng miễn phí trước 48 giờ so với ngày check-in. Nếu hủy trong vòng 48 giờ trước ngày check-in, phí hủy sẽ tương đương với giá phòng của 1 đêm. Đối với các gói đặc biệt hoặc khuyến mãi, chính sách hủy có thể khác, vui lòng kiểm tra điều khoản khi đặt phòng.',
        'Policies',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Cancellation policy';
END
GO

-- Pet Policy
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có cho phép mang thú cưng không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Khách sạn có cho phép mang thú cưng không?',
        N'Rất tiếc, hiện tại khách sạn chưa cho phép mang thú cưng vào phòng để đảm bảo sự thoải mái cho tất cả khách hàng. Tuy nhiên, chúng tôi có thể giới thiệu các dịch vụ chăm sóc thú cưng gần khách sạn nếu quý khách cần.',
        'Policies',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Pet policy';
END
GO

-- Smoking Policy
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có phòng hút thuốc không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Khách sạn có phòng hút thuốc không?',
        N'Tất cả các phòng tại Royal Hotel đều là phòng không hút thuốc để đảm bảo không khí trong lành cho mọi khách hàng. Chúng tôi có khu vực hút thuốc được chỉ định ở sảnh tầng trệt và khu vực ngoài trời.',
        'Policies',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Smoking policy';
END
GO

-- =============================================
-- Category: Amenities
-- =============================================

-- WiFi
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có WiFi miễn phí không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Khách sạn có WiFi miễn phí không?',
        N'Có, chúng tôi cung cấp WiFi tốc độ cao miễn phí trong tất cả các phòng và khu vực công cộng của khách sạn. Thông tin đăng nhập WiFi sẽ được cung cấp khi quý khách check-in.',
        'Amenities',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: WiFi';
END
GO

-- Parking
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có chỗ đậu xe không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Khách sạn có chỗ đậu xe không?',
        N'Có, chúng tôi có bãi đậu xe riêng với dịch vụ valet parking. Phí đậu xe là 100,000 VND/ngày. Bãi đậu xe có camera an ninh 24/7 và nhân viên bảo vệ.',
        'Amenities',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Parking';
END
GO

-- Pool and Gym
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có hồ bơi và phòng gym không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Khách sạn có hồ bơi và phòng gym không?',
        N'Có, chúng tôi có hồ bơi ngoài trời mở cửa từ 6:00 AM đến 10:00 PM và phòng gym hiện đại hoạt động 24/7. Cả hai tiện ích đều miễn phí cho khách lưu trú. Khăn tắm và nước uống được cung cấp tại khu vực hồ bơi.',
        'Amenities',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Pool and Gym';
END
GO

-- Restaurant
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có nhà hàng không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Khách sạn có nhà hàng không?',
        N'Có, chúng tôi có nhà hàng phục vụ ẩm thực Việt Nam và quốc tế. Bữa sáng buffet được phục vụ từ 6:30 AM đến 10:00 AM, bữa trưa từ 11:30 AM đến 2:00 PM, và bữa tối từ 6:00 PM đến 10:00 PM. Chúng tôi cũng có dịch vụ room service 24/7.',
        'Amenities',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Restaurant';
END
GO

-- Spa
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn có dịch vụ spa không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Khách sạn có dịch vụ spa không?',
        N'Có, Royal Spa của chúng tôi cung cấp đầy đủ các dịch vụ massage, chăm sóc da mặt, và các liệu trình thư giãn. Spa mở cửa từ 9:00 AM đến 9:00 PM hàng ngày. Vui lòng đặt lịch trước để được phục vụ tốt nhất.',
        'Amenities',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Spa';
END
GO

-- =============================================
-- Category: Booking
-- =============================================

-- How to Book
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Làm thế nào để đặt phòng?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Làm thế nào để đặt phòng?',
        N'Quý khách có thể đặt phòng trực tiếp trên website của chúng tôi, gọi điện đến hotline, hoặc gửi email. Để đặt phòng trên website, vui lòng chọn ngày check-in, check-out, số lượng khách, sau đó chọn loại phòng và hoàn tất thanh toán. Quý khách sẽ nhận được email xác nhận ngay sau khi đặt phòng thành công.',
        'Booking',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: How to book';
END
GO

-- Booking Modification
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Tôi có thể thay đổi ngày đặt phòng không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Tôi có thể thay đổi ngày đặt phòng không?',
        N'Có, quý khách có thể thay đổi ngày đặt phòng miễn phí trước 48 giờ so với ngày check-in ban đầu, tùy thuộc vào tình trạng phòng trống. Để thay đổi đặt phòng, vui lòng liên hệ với bộ phận đặt phòng qua email hoặc hotline với mã đặt phòng của quý khách.',
        'Booking',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Booking modification';
END
GO

-- Group Booking
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Làm thế nào để đặt phòng cho nhóm lớn?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Làm thế nào để đặt phòng cho nhóm lớn?',
        N'Đối với đặt phòng nhóm (từ 5 phòng trở lên), vui lòng liên hệ trực tiếp với bộ phận bán hàng của chúng tôi để được tư vấn và nhận ưu đãi đặc biệt. Chúng tôi có thể sắp xếp các phòng gần nhau và cung cấp các dịch vụ bổ sung cho nhóm.',
        'Booking',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Group booking';
END
GO

-- Special Requests
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Tôi có thể yêu cầu phòng tầng cao hoặc view đẹp không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Tôi có thể yêu cầu phòng tầng cao hoặc view đẹp không?',
        N'Có, quý khách có thể ghi chú yêu cầu đặc biệt khi đặt phòng hoặc liên hệ trực tiếp với khách sạn. Chúng tôi sẽ cố gắng đáp ứng yêu cầu của quý khách tùy theo tình trạng phòng trống, tuy nhiên không thể đảm bảo 100%. Một số loại phòng có view đặc biệt có thể có phụ phí.',
        'Booking',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Special requests';
END
GO

-- =============================================
-- Category: Payment
-- =============================================

-- Payment Methods
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Khách sạn chấp nhận những hình thức thanh toán nào?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Khách sạn chấp nhận những hình thức thanh toán nào?',
        N'Chúng tôi chấp nhận thanh toán bằng tiền mặt (VND), thẻ tín dụng (Visa, Mastercard, JCB, American Express), thẻ ghi nợ nội địa, và chuyển khoản ngân hàng. Thanh toán trực tuyến khi đặt phòng được xử lý an toàn qua cổng thanh toán.',
        'Payment',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Payment methods';
END
GO

-- Deposit Policy
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Tôi có cần đặt cọc khi đặt phòng không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Tôi có cần đặt cọc khi đặt phòng không?',
        N'Khi đặt phòng trực tuyến, quý khách có thể chọn thanh toán toàn bộ hoặc đặt cọc 30% giá trị đặt phòng. Số tiền còn lại sẽ được thanh toán khi check-in hoặc check-out. Đối với đặt phòng qua điện thoại, chúng tôi yêu cầu thông tin thẻ tín dụng để đảm bảo đặt phòng.',
        'Payment',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Deposit policy';
END
GO

-- Invoice
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Tôi có thể nhận hóa đơn VAT không?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Tôi có thể nhận hóa đơn VAT không?',
        N'Có, chúng tôi cung cấp hóa đơn VAT cho tất cả các giao dịch. Vui lòng cung cấp thông tin công ty (tên công ty, mã số thuế, địa chỉ) cho lễ tân khi check-out. Hóa đơn điện tử sẽ được gửi qua email trong vòng 24 giờ.',
        'Payment',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Invoice';
END
GO

-- Refund Policy
IF NOT EXISTS (SELECT 1 FROM FAQ WHERE Question = N'Chính sách hoàn tiền như thế nào?')
BEGIN
    INSERT INTO FAQ (Question, Answer, Category, IsActive, CreatedAt, UpdatedAt)
    VALUES (
        N'Chính sách hoàn tiền như thế nào?',
        N'Đối với đặt phòng được hủy theo đúng chính sách hủy (trước 48 giờ), số tiền đã thanh toán sẽ được hoàn lại trong vòng 7-10 ngày làm việc về tài khoản hoặc thẻ thanh toán ban đầu. Phí hủy phòng (nếu có) sẽ được trừ vào số tiền hoàn lại. Vui lòng liên hệ bộ phận đặt phòng để được hỗ trợ về hoàn tiền.',
        'Payment',
        1,
        GETDATE(),
        GETDATE()
    );
    PRINT 'Inserted FAQ: Refund policy';
END
GO

-- =============================================
-- Verification
-- =============================================

PRINT '';
PRINT '==============================================';
PRINT 'FAQ Seed Data Summary';
PRINT '==============================================';

SELECT 
    Category,
    COUNT(*) AS TotalQuestions,
    SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END) AS ActiveQuestions
FROM FAQ
GROUP BY Category
ORDER BY Category;

PRINT '';
PRINT 'Total FAQ entries: ' + CAST((SELECT COUNT(*) FROM FAQ) AS VARCHAR(10));
PRINT 'FAQ seed data script completed successfully.';
GO
