# Adapter Pattern Refactor - Booking Email Notification

## Pattern áp dụng
**ADAPTER PATTERN**

## Các thành phần

### Target Interface
- **IBookingNotificationService** - Interface nghiệp vụ cho booking notification
- Method: `SendBookingConfirmationAsync(Booking booking)`

### Adapter
- **EmailNotificationAdapter** - Chuyển đổi từ ngôn ngữ nghiệp vụ booking sang technical email call

### Adaptee
- **IEmailSender** - Interface email service hiện có trong hệ thống
- **SmtpEmailSender** - Implementation SMTP đã có sẵn

## Mục đích

Tách biệt booking module khỏi email implementation cụ thể:
- Booking chỉ biết về `IBookingNotificationService` (nghiệp vụ)
- Không phụ thuộc trực tiếp vào `IEmailSender` (kỹ thuật)
- Adapter đóng vai trò cầu nối giữa 2 interface

## Files tạo mới

1. **Services/Notifications/IBookingNotificationService.cs**
   - Target interface cho booking notification
   - Method: `SendBookingConfirmationAsync(Booking booking)`

2. **Services/Notifications/EmailNotificationAdapter.cs**
   - Implement IBookingNotificationService
   - Inject IEmailSender trong constructor
   - Chuyển đổi booking data thành email format
   - Build HTML email với thông tin booking đầy đủ

## Files đã sửa

1. **Services/Booking/CoreBookingService.cs**
   - Inject `IBookingNotificationService`
   - Sau khi payment thành công và SaveChanges()
   - Gọi `SendBookingConfirmationAsync(booking)`
   - Wrap trong try/catch để email lỗi không làm fail payment

2. **Program.cs**
   - Thêm using `ROYALHOTEL.Services.Notifications`
   - Đăng ký: `builder.Services.AddScoped<IBookingNotificationService, EmailNotificationAdapter>()`

## Luồng hoạt động

```
User thanh toán thành công
    ↓
CoreBookingService.ConfirmPaymentAsync()
    ↓
Factory Method: Tạo PaymentProcessor
    ↓
Tạo PaymentTransaction
    ↓
Update Booking.Status = "Confirmed"
    ↓
SaveChangesAsync()
    ↓
Gọi: _bookingNotificationService.SendBookingConfirmationAsync(booking)
    ↓
EmailNotificationAdapter nhận request
    ↓
Build email subject + HTML body
    ↓
Adapt: Gọi _emailSender.SendAsync(toEmail, subject, htmlBody)
    ↓
SmtpEmailSender gửi email qua SMTP
    ↓
Email xác nhận đến GuestEmail
```

## Nội dung email

Email HTML chuyên nghiệp bao gồm:
- Lời chào khách (GuestName)
- Mã booking (BookingCode)
- Thông tin phòng (Name, Code)
- Check-in / Check-out (14:00 / 12:00)
- Số đêm, số khách
- Giá mỗi đêm, tổng tiền (format VNĐ)
- Phương thức thanh toán
- Trạng thái booking
- Thời gian tạo booking
- Thông tin liên hệ Royal Hotel

## Xử lý lỗi

- Email gửi lỗi **KHÔNG** làm fail payment
- Payment thành công vẫn là thành công
- Email là side effect bổ sung
- Log warning nếu gửi email thất bại

## Tương thích

✅ Giữ nguyên Factory Method Pattern (payment processors)
✅ Giữ nguyên Decorator Pattern (booking validation)
✅ Giữ nguyên booking flow hiện tại
✅ Giữ nguyên payment flow hiện tại
✅ Giữ nguyên booking history
✅ Tái sử dụng IEmailSender + SmtpEmailSender có sẵn
✅ Không thay đổi database schema
✅ Không cần migration

## Lợi ích

1. **Separation of Concerns**: Booking module không biết chi tiết email implementation
2. **Flexibility**: Dễ dàng thay đổi cách gửi notification (SMS, Push, etc.)
3. **Testability**: Có thể mock IBookingNotificationService để test
4. **Reusability**: Tái sử dụng email infrastructure có sẵn
5. **Maintainability**: Thay đổi email format không ảnh hưởng booking logic

## Design Patterns trong project

Project hiện sử dụng 3 patterns:

1. **Factory Method** - Payment processing
   - `PaymentProcessorFactory`
   - `BankTransferProcessor`, `VisaProcessor`

2. **Decorator** - Booking validation
   - `BookingValidationDecorator` wraps `CoreBookingService`

3. **Adapter** - Email notification
   - `EmailNotificationAdapter` adapts `IEmailSender` to `IBookingNotificationService`

Mỗi pattern giải quyết một vấn đề cụ thể và hoạt động độc lập.
