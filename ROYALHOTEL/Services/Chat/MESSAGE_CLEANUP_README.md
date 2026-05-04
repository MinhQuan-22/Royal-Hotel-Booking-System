# Message Cleanup Service - Tự Động Xóa Tin Nhắn Hàng Ngày

## Tổng Quan

Service `MessageCleanupService` tự động xóa tất cả tin nhắn chat cũ hàng ngày để đảm bảo dữ liệu luôn sạch sẽ và tuân thủ yêu cầu bảo mật.

## Chức Năng

### Tự Động Xóa Tin Nhắn

- **Thời gian chạy:** Mỗi ngày lúc 3:00 AM UTC
- **Logic xóa:** Xóa tất cả tin nhắn có `CreatedAt < ngày hôm nay`
- **Bảo toàn:** Conversations (cuộc hội thoại) được giữ lại, chỉ xóa messages

### Ví Dụ

```
Hôm nay: 2026-04-27
Service chạy lúc: 2026-04-27 03:00:00 UTC
Xóa: Tất cả messages có CreatedAt < 2026-04-27 00:00:00 UTC
Giữ lại: Messages được tạo từ 2026-04-27 00:00:00 trở đi
```

## Cấu Trúc Code

### File Chính

- **Location:** `ROYALHOTEL/Services/Chat/MessageCleanupService.cs`
- **Type:** Background Service (IHostedService)
- **Dependencies:**
  - `RoyalHotelDbContext` (Database access)
  - `ILogger<MessageCleanupService>` (Logging)

### Đăng Ký Service

File: `ROYALHOTEL/Program.cs`

```csharp
builder.Services.AddHostedService<ROYALHOTEL.Services.Chat.MessageCleanupService>();
```

## Cách Hoạt Động

### 1. Khởi Động

```
Application starts
  ↓
MessageCleanupService.ExecuteAsync() called
  ↓
Calculate next 3 AM UTC
  ↓
Wait until 3 AM
```

### 2. Thực Thi Hàng Ngày

```
3:00 AM UTC
  ↓
Query: SELECT * FROM ChatMessages WHERE CreatedAt < TODAY
  ↓
Delete all old messages
  ↓
Log results
  ↓
Wait 24 hours
  ↓
Repeat
```

### 3. Xử Lý Lỗi

- Nếu có lỗi → Log error và tiếp tục chạy
- Service không bị dừng khi có lỗi
- Retry tự động sau 24 giờ

## Testing

### Test Thủ Công (Manual Testing)

#### Option 1: Sử dụng API Endpoint

```bash
# Gọi API để xóa messages ngay lập tức (chỉ dành cho Admin)
curl -X DELETE https://localhost:5001/AdminChat/CleanupMessages \
  -H "Cookie: .AspNetCore.Session=YOUR_SESSION_COOKIE"
```

**Response:**

```json
{
  "success": true,
  "message": "Successfully deleted 150 messages",
  "messagesDeleted": 150,
  "cutoffDate": "2026-04-27T00:00:00Z"
}
```

#### Option 2: Kiểm Tra Database Trực Tiếp

```sql
-- Xem số lượng messages cũ
SELECT COUNT(*) as OldMessagesCount
FROM ChatMessages
WHERE CreatedAt < CAST(GETUTCDATE() AS DATE);

-- Xem chi tiết messages cũ
SELECT
    Id,
    ConversationId,
    SenderType,
    CreatedAt,
    DATEDIFF(day, CreatedAt, GETUTCDATE()) as DaysOld
FROM ChatMessages
WHERE CreatedAt < CAST(GETUTCDATE() AS DATE)
ORDER BY CreatedAt DESC;
```

#### Option 3: Kiểm Tra Logs

```bash
# Xem logs của MessageCleanupService
# Location: Application logs hoặc console output

# Tìm kiếm trong logs:
grep "MessageCleanupService" application.log
```

**Expected Log Output:**

```
[2026-04-27 03:00:00] MessageCleanupService started
[2026-04-27 03:00:00] MessageCleanupService scheduled to run at 2026-04-27 03:00:00 UTC
[2026-04-27 03:00:00] Starting daily message cleanup
[2026-04-27 03:00:00] Found 150 messages to delete (created before 2026-04-27 00:00:00)
[2026-04-27 03:00:01] Message cleanup completed: 150 messages deleted
[2026-04-27 03:00:01] Message cleanup execution completed in 1234ms
```

### Test Tự Động (Automated Testing)

#### Unit Test Example

```csharp
[Fact]
public async Task DeleteOldMessagesAsync_ShouldDeleteMessagesBeforeToday()
{
    // Arrange
    var options = new DbContextOptionsBuilder<RoyalHotelDbContext>()
        .UseInMemoryDatabase(databaseName: "TestDb")
        .Options;

    using var context = new RoyalHotelDbContext(options);

    // Add old messages (yesterday)
    context.ChatMessages.Add(new ChatMessage
    {
        ConversationId = 1,
        SenderType = "User",
        MessageText = "Old message",
        CreatedAt = DateTime.UtcNow.AddDays(-1)
    });

    // Add new messages (today)
    context.ChatMessages.Add(new ChatMessage
    {
        ConversationId = 1,
        SenderType = "User",
        MessageText = "New message",
        CreatedAt = DateTime.UtcNow
    });

    await context.SaveChangesAsync();

    var serviceProvider = new ServiceCollection()
        .AddScoped<RoyalHotelDbContext>(_ => context)
        .BuildServiceProvider();

    var logger = new Mock<ILogger<MessageCleanupService>>();
    var service = new MessageCleanupService(serviceProvider, logger.Object);

    // Act
    var result = await service.DeleteOldMessagesAsync();

    // Assert
    Assert.True(result.Success);
    Assert.Equal(1, result.MessagesDeleted);
    Assert.Equal(1, context.ChatMessages.Count()); // Only new message remains
}
```

## Monitoring & Maintenance

### Kiểm Tra Service Đang Chạy

```bash
# Kiểm tra trong logs khi application khởi động
# Tìm dòng: "MessageCleanupService started"
```

### Metrics Cần Theo Dõi

1. **Số lượng messages bị xóa mỗi ngày**
   - Normal: 50-500 messages/day
   - Alert nếu: > 10,000 messages/day (có thể có vấn đề)

2. **Thời gian thực thi**
   - Normal: < 5 seconds
   - Alert nếu: > 30 seconds

3. **Tỷ lệ lỗi**
   - Normal: 0%
   - Alert nếu: > 1%

### Troubleshooting

#### Vấn Đề: Service Không Chạy

**Triệu chứng:** Không thấy log "MessageCleanupService started"

**Giải pháp:**

1. Kiểm tra `Program.cs` có đăng ký service không
2. Restart application
3. Kiểm tra logs có error khi khởi động không

#### Vấn Đề: Messages Không Bị Xóa

**Triệu chứng:** Messages cũ vẫn còn trong database

**Giải pháp:**

1. Kiểm tra timezone: Service dùng UTC, database có đúng timezone không?
2. Kiểm tra logs: Có error trong quá trình xóa không?
3. Test thủ công bằng API endpoint
4. Kiểm tra database permissions

#### Vấn Đề: Service Chạy Quá Chậm

**Triệu chứng:** Execution time > 30 seconds

**Giải pháp:**

1. Kiểm tra số lượng messages: Có quá nhiều không?
2. Thêm index cho `CreatedAt` column:

```sql
CREATE INDEX IX_ChatMessages_CreatedAt
ON ChatMessages(CreatedAt);
```

3. Xem xét batch delete nếu có hàng triệu messages

## Configuration

### Thay Đổi Thời Gian Chạy

Mặc định: 3:00 AM UTC

Để thay đổi, sửa trong `MessageCleanupService.cs`:

```csharp
// Thay đổi từ 3 AM sang 2 AM
var nextRun = now.Date.AddHours(2); // Thay 3 thành 2
```

### Thay Đổi Chu Kỳ Chạy

Mặc định: 24 giờ (hàng ngày)

Để thay đổi:

```csharp
// Thay đổi từ 24 giờ sang 12 giờ (2 lần/ngày)
private readonly TimeSpan _checkInterval = TimeSpan.FromHours(12);
```

### Thay Đổi Logic Xóa

Mặc định: Xóa messages < hôm nay

Để giữ lại messages trong N ngày:

```csharp
// Giữ lại messages trong 7 ngày
var cutoffDate = DateTime.UtcNow.AddDays(-7);

var oldMessages = await dbContext.ChatMessages
    .Where(m => m.CreatedAt < cutoffDate)
    .ToListAsync(stoppingToken);
```

## Security & Compliance

### Data Retention Policy

- **Current:** Messages xóa sau 1 ngày
- **Conversations:** Giữ lại vô thời hạn (hoặc đến khi auto-close sau 7 ngày)
- **Compliance:** Tuân thủ GDPR/privacy requirements

### Audit Trail

- Mọi lần xóa đều được log
- Log bao gồm:
  - Timestamp
  - Số lượng messages bị xóa
  - Cutoff date
  - Execution time

### Backup Recommendations

Nếu cần giữ lại messages để audit:

1. Tạo backup table trước khi xóa
2. Archive messages sang cold storage
3. Hoặc disable service và implement custom retention policy

## Performance Impact

### Database Load

- **Query:** Simple WHERE clause với date comparison
- **Delete:** Batch delete, không ảnh hưởng performance
- **Recommended:** Chạy lúc 3 AM khi traffic thấp

### Application Impact

- **Memory:** Minimal (background service)
- **CPU:** Low (chỉ chạy 1 lần/ngày)
- **Network:** None (local database operation)

## FAQ

**Q: Messages bị xóa có thể khôi phục không?**
A: Không. Sau khi xóa, messages không thể khôi phục. Cần backup trước nếu muốn giữ lại.

**Q: Conversations có bị xóa không?**
A: Không. Chỉ messages bị xóa, conversations được giữ lại.

**Q: Service có chạy khi application restart không?**
A: Có. Service tự động khởi động và tính toán lại thời gian chạy tiếp theo.

**Q: Có thể disable service không?**
A: Có. Comment out dòng đăng ký trong `Program.cs`:

```csharp
// builder.Services.AddHostedService<ROYALHOTEL.Services.Chat.MessageCleanupService>();
```

**Q: Làm sao để test ngay lập tức?**
A: Sử dụng API endpoint `/AdminChat/CleanupMessages` (DELETE method)

## Contact & Support

Nếu có vấn đề với MessageCleanupService:

1. Kiểm tra logs
2. Xem Troubleshooting section
3. Contact development team với logs và error details
