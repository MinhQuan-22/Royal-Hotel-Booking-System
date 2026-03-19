# Observer Pattern Refactor - Booking Event System

## Pattern áp dụng
**OBSERVER PATTERN**

## Các thành phần

### Subject/Publisher Interface
- **IBookingEventPublisher** - Interface để publish events

### Concrete Subject/Publisher
- **BookingEventPublisher** - Nhận danh sách observers và notify tất cả khi có event

### Observer Interface
- **IBookingEventObserver** - Interface chung cho tất cả observers

### Concrete Observers
- **EmailBookingConfirmedObserver** - Gửi email xác nhận (tái sử dụng Adapter)
- **AuditLogBookingObserver** - Ghi audit log hệ thống

### Event Data
- **BookingConfirmedEvent** - Chứa thông tin booking đã confirmed

## Mục đích

Tách biệt việc phát sự kiện khỏi xử lý hành động sau sự kiện:
- CoreBookingService chỉ publish event, không biết ai sẽ xử lý
- Observers tự đăng ký và xử lý event theo cách riêng
- Dễ dàng thêm/bớt observers mà không sửa CoreBookingService
- Một observer fail không ảnh hưởng observers khác

## Files tạo mới

1. **Services/Events/IBookingEventPublisher.cs**
   - Subject/Publisher interface
   - Method: `PublishBookingConfirmedAsync(BookingConfirmedEvent evt)`

2. **Services/Events/BookingEventPublisher.cs**
   - Concrete Subject/Publisher
   - Nhận `IEnumerable<IBookingEventObserver>` qua DI
   - Loop qua tất cả observers và notify
   - Try/catch riêng cho từng observer

3. **Services/Events/IBookingEventObserver.cs**
   - Observer interface
   - Method: `HandleBookingConfirmedAsync(BookingConfirmedEvent evt)`

4. **Services/Events/BookingConfirmedEvent.cs**
   - Event data class
   - Chứa `Booking` object

5. **Services/Events/EmailBookingConfirmedObserver.cs**
   - Concrete Observer cho email
   - Inject `IBookingNotificationService` (Adapter)
   - Delegate việc gửi email cho Adapter

6. **Services/Events/AuditLogBookingObserver.cs**
   - Concrete Observer cho audit log
   - Ghi log ra Console với thông tin booking

## Files đã sửa

1. **Services/Booking/CoreBookingService.cs**
   - Bỏ dependency: `IBookingNotificationService`
   - Thêm dependency: `IBookingEventPublisher`
   - Trong `ConfirmPaymentAsync()` sau SaveChanges():
     - Tạo `BookingConfirmedEvent`
     - Gọi `_bookingEventPublisher.PublishBookingConfirmedAsync(evt)`
   - Wrap trong try/catch để event fail không làm fail payment

2. **Program.cs**
   - Thêm using: `ROYALHOTEL.Services.Events`
   - Đăng ký DI:
     - `IBookingEventPublisher` → `BookingEventPublisher`
     - `IBookingEventObserver` → `EmailBookingConfirmedObserver`
     - `IBookingEventObserver` → `AuditLogBookingObserver`

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
Tạo BookingConfirmedEvent
    ↓
_bookingEventPublisher.PublishBookingConfirmedAsync(event)
    ↓
BookingEventPublisher.PublishBookingConfirmedAsync()
    ↓
Loop qua tất cả IBookingEventObserver:
    ├─ EmailBookingConfirmedObserver.HandleBookingConfirmedAsync()
    │   ↓
    │   Gọi IBookingNotificationService (Adapter)
    │   ↓
    │   EmailNotificationAdapter.SendBookingConfirmationAsync()
    │   ↓
    │   IEmailSender.SendAsync() (SMTP)
    │   ↓
    │   ✉️ Email gửi đến khách
    │
    └─ AuditLogBookingObserver.HandleBookingConfirmedAsync()
        ↓
        Console.WriteLine() - Ghi audit log
        ↓
        📝 Log được ghi
```

## Xử lý lỗi

- Mỗi observer được try/catch riêng trong Publisher
- Nếu EmailObserver fail → AuditLogObserver vẫn chạy
- Nếu tất cả observers fail → Payment vẫn thành công
- Log warning cho từng observer fail

## Tích hợp với các Pattern khác

### Observer + Adapter
- **EmailBookingConfirmedObserver** (Observer) sử dụng **IBookingNotificationService** (Adapter)
- Observer xử lý "khi nào gửi email"
- Adapter xử lý "gửi email như thế nào"

### Observer + Factory Method
- CoreBookingService vẫn dùng Factory Method để tạo PaymentProcessor
- Sau khi payment xong, publish event cho Observers

### Observer + Decorator
- BookingValidationDecorator vẫn wrap CoreBookingService
- Validation chạy trước, event publish sau

## Lợi ích

1. **Loose Coupling**: CoreBookingService không biết ai xử lý event
2. **Open/Closed Principle**: Thêm observer mới không sửa CoreBookingService
3. **Single Responsibility**: Mỗi observer có 1 trách nhiệm rõ ràng
4. **Fault Tolerance**: 1 observer fail không ảnh hưởng observers khác
5. **Extensibility**: Dễ dàng thêm observers mới (SMS, Push notification, Analytics, etc.)

## Tương thích

✅ Giữ nguyên Factory Method Pattern (payment processors)
✅ Giữ nguyên Decorator Pattern (booking validation)
✅ Giữ nguyên Adapter Pattern (email notification)
✅ Giữ nguyên booking flow
✅ Giữ nguyên payment flow
✅ Giữ nguyên booking history
✅ Không thay đổi database
✅ Không cần migration

## Design Patterns trong project

Project hiện sử dụng 4 patterns:

1. **Factory Method** - Payment processing
   - `PaymentProcessorFactory`
   - `BankTransferProcessor`, `VisaProcessor`

2. **Decorator** - Booking validation
   - `BookingValidationDecorator` wraps `CoreBookingService`

3. **Adapter** - Email notification
   - `EmailNotificationAdapter` adapts `IEmailSender` to `IBookingNotificationService`

4. **Observer** - Event system ⭐ MỚI
   - `BookingEventPublisher` notifies `IBookingEventObserver[]`
   - `EmailBookingConfirmedObserver`, `AuditLogBookingObserver`

Tất cả patterns hoạt động độc lập và bổ trợ cho nhau.

## Mở rộng trong tương lai

Dễ dàng thêm observers mới:
- **SmsBookingConfirmedObserver** - Gửi SMS xác nhận
- **PushNotificationObserver** - Gửi push notification
- **AnalyticsObserver** - Ghi dữ liệu analytics
- **AdminNotificationObserver** - Thông báo admin có booking mới
- **InventoryObserver** - Cập nhật inventory system

Chỉ cần:
1. Tạo class implement `IBookingEventObserver`
2. Đăng ký trong Program.cs
3. Không cần sửa CoreBookingService
