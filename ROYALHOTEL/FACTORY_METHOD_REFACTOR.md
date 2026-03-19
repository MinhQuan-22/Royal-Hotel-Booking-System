# Factory Method Pattern - Payment Refactor

## 1. Files đã tạo mới (4 files)

### Services/Payments/IPaymentProcessor.cs
- Interface chung cho các payment processor
- Method: `Task<PaymentTransaction> ProcessAsync(Models.Booking booking)`

### Services/Payments/BankTransferProcessor.cs
- Concrete Product 1
- Xử lý thanh toán qua chuyển khoản ngân hàng
- TransactionCode prefix: "BANK-"

### Services/Payments/VisaProcessor.cs
- Concrete Product 2
- Xử lý thanh toán qua thẻ Visa
- TransactionCode prefix: "VISA-"

### Services/Payments/PaymentProcessorFactory.cs
- Factory class (Creator)
- Method: `Create(string paymentMethod)` trả về IPaymentProcessor
- Map: "bank_transfer" → BankTransferProcessor, "visa" → VisaProcessor

## 2. Files đã sửa (1 file)

### Services/Booking/BookingService.cs
- Thêm using: `using ROYALHOTEL.Services.Payments;`
- Refactor method `ConfirmPaymentAsync`:
  - Thay thế việc tạo PaymentTransaction trực tiếp
  - Sử dụng Factory để lấy processor phù hợp
  - Gọi processor.ProcessAsync() để tạo transaction
- Xóa method `GenerateTransactionCode()` (đã chuyển vào từng processor)

## 3. Design Pattern áp dụng

**Pattern**: Factory Method

**Vai trò các class**:
- **Creator (Factory)**: `PaymentProcessorFactory`
- **Product Interface**: `IPaymentProcessor`
- **Concrete Product 1**: `BankTransferProcessor`
- **Concrete Product 2**: `VisaProcessor`
- **Client**: `BookingService`

## 4. Lợi ích

✅ **Open/Closed Principle**: Thêm payment method mới không cần sửa BookingService
✅ **Single Responsibility**: Mỗi processor chịu trách nhiệm tạo transaction cho 1 method
✅ **Loose Coupling**: BookingService không phụ thuộc vào concrete processor
✅ **Extensibility**: Dễ dàng thêm MomoProcessor, ZaloPayProcessor, etc.

## 5. Flow sau refactor

1. User chọn payment method (bank_transfer hoặc visa)
2. BookingController gọi `BookingService.ConfirmPaymentAsync(bookingId, paymentMethod)`
3. BookingService validate booking
4. BookingService gọi `PaymentProcessorFactory.Create(paymentMethod)`
5. Factory trả về processor phù hợp (BankTransferProcessor hoặc VisaProcessor)
6. BookingService gọi `processor.ProcessAsync(booking)`
7. Processor tạo PaymentTransaction với prefix phù hợp
8. BookingService lưu transaction vào DB
9. Booking chuyển status sang "Confirmed"
10. Redirect sang Success page

## 6. Cách thêm payment method mới

Ví dụ thêm Momo:

1. Tạo `Services/Payments/MomoProcessor.cs`:
```csharp
public class MomoProcessor : IPaymentProcessor
{
    public Task<PaymentTransaction> ProcessAsync(Models.Booking booking)
    {
        var transaction = new PaymentTransaction
        {
            BookingId = booking.Id,
            PaymentMethod = "momo",
            Amount = booking.TotalAmount ?? 0,
            Status = "Paid",
            TransactionCode = $"MOMO-{DateTime.Now:yyyyMMddHHmmss}",
            CreatedAt = DateTime.UtcNow
        };
        return Task.FromResult(transaction);
    }
}
```

2. Sửa `PaymentProcessorFactory.cs`:
```csharp
return paymentMethod switch
{
    "bank_transfer" => new BankTransferProcessor(),
    "visa" => new VisaProcessor(),
    "momo" => new MomoProcessor(), // Thêm dòng này
    _ => throw new ArgumentException($"Unsupported payment method: {paymentMethod}")
};
```

3. Không cần sửa BookingService!

## 7. Testing

### Test 1: Bank Transfer
1. Đặt phòng
2. Chọn "Chuyển khoản ngân hàng"
3. Thanh toán
4. Kiểm tra DB: PaymentTransactions có TransactionCode bắt đầu bằng "BANK-"

### Test 2: Visa
1. Đặt phòng
2. Chọn "Thẻ tín dụng/ghi nợ"
3. Thanh toán
4. Kiểm tra DB: PaymentTransactions có TransactionCode bắt đầu bằng "VISA-"

### Test 3: Flow không thay đổi
1. Đặt phòng → Payment → Success vẫn hoạt động bình thường
2. Booking status vẫn chuyển từ Pending → Confirmed
3. Availability logic vẫn hoạt động đúng
4. MyBookings vẫn hiển thị đúng

## 8. Code comparison

### Trước refactor (BookingService.cs):
```csharp
var transaction = new PaymentTransaction
{
    BookingId = booking.Id,
    PaymentMethod = paymentMethod,
    Amount = booking.TotalAmount ?? 0,
    Status = "Paid",
    TransactionCode = GenerateTransactionCode(),
    CreatedAt = DateTime.UtcNow
};
_context.PaymentTransactions.Add(transaction);
```

### Sau refactor (BookingService.cs):
```csharp
var processor = PaymentProcessorFactory.Create(paymentMethod);
var transaction = await processor.ProcessAsync(booking);
_context.PaymentTransactions.Add(transaction);
```

## 9. Lưu ý

- ✅ Flow nghiệp vụ không thay đổi
- ✅ Database schema không thay đổi
- ✅ Controller/View không thay đổi
- ✅ Không cần migration
- ✅ Backward compatible 100%
- ✅ Code compile và chạy thành công

## 10. Kết luận

Refactor thành công áp dụng Factory Method pattern cho Payment module mà không phá vỡ bất kỳ functionality nào. Code giờ dễ maintain và extend hơn.
