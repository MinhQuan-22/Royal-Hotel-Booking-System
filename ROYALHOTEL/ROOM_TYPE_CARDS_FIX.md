# Room Type Cards Display Fix

## 📋 Vấn Đề

Trước đây, menu card "Phòng & Giá" hiển thị các loại phòng có thể bị ảnh hưởng bởi filter chi nhánh:

- Khi filter theo chi nhánh, số lượng loại phòng hiển thị giảm xuống
- Giới hạn `.Take(6)` có thể không hiển thị đủ tất cả loại phòng trong hệ thống
- Người dùng không thấy được toàn bộ các loại phòng có sẵn

## ✅ Giải Pháp

### 1. **Luôn Hiển Thị Đầy Đủ Các Loại Phòng**

- Menu card bây giờ hiển thị **TẤT CẢ** các loại phòng có trong toàn bộ hệ thống
- Không bị ảnh hưởng bởi filter chi nhánh
- Xóa giới hạn `.Take(6)` để hiển thị đủ tất cả loại phòng

### 2. **Hiển Thị Tên Loại Phòng Chung**

- Hiển thị: `Standard`, `Single`, `Double`, `Deluxe`, `Family`, `Suite`
- KHÔNG hiển thị tên chi nhánh kèm theo (ví dụ: "Standard - Hà Nội")
- Sử dụng `r.RoomType.Trim()` để lấy tên loại phòng

### 3. **Filter Chỉ Áp Dụng Cho Danh Sách Phòng**

- Menu card ở trên: Luôn hiển thị đầy đủ tất cả loại phòng
- Danh sách phòng ở dưới: Áp dụng filter theo chi nhánh, giá, tiện ích, v.v.

## 🔧 Thay Đổi Code

### File: `ROYALHOTEL/Services/Rooms/RoomQueryService.cs`

**Trước:**

```csharp
public async Task<List<Room>> GetFeaturedRoomTypesAsync(int? hotelId = null)
{
    var query = _repo.Query()
        .Where(r => !string.IsNullOrWhiteSpace(r.RoomType));

    if (hotelId.HasValue)
        query = query.Where(r => r.HotelId == hotelId.Value);  // ❌ Filter theo chi nhánh

    var rooms = await query.ToListAsync();

    return rooms
        .GroupBy(r => _catalog.NormalizeRoomType(r.RoomType), StringComparer.OrdinalIgnoreCase)
        .Select(g => g.OrderBy(x => x.BasePricePerNight)
                      .ThenBy(x => x.Id)
                      .First())
        .OrderBy(r => _catalog.GetRoomTypeOrder(r.RoomType))
        .ThenBy(r => _catalog.NormalizeRoomType(r.RoomType))
        .Take(6)  // ❌ Giới hạn 6 loại
        .ToList();
}
```

**Sau:**

```csharp
public async Task<List<Room>> GetFeaturedRoomTypesAsync(int? hotelId = null)
{
    // ALWAYS get ALL room types from entire system (ignore hotelId filter for featured cards)
    // This ensures the menu cards always show all available room types
    var query = _repo.Query()
        .Where(r => !string.IsNullOrWhiteSpace(r.RoomType));

    // DO NOT filter by hotelId here - we want to show all room types in the system
    // The filter will only apply to the room list below, not the featured cards

    var rooms = await query.ToListAsync();

    return rooms
        .GroupBy(r => _catalog.NormalizeRoomType(r.RoomType), StringComparer.OrdinalIgnoreCase)
        .Select(g => g.OrderBy(x => x.BasePricePerNight)
                      .ThenBy(x => x.Id)
                      .First())
        .OrderBy(r => _catalog.GetRoomTypeOrder(r.RoomType))
        .ThenBy(r => _catalog.NormalizeRoomType(r.RoomType))
        // Remove Take(6) limit to show ALL room types in the system
        .ToList();  // ✅ Hiển thị tất cả loại phòng
}
```

### File: `ROYALHOTEL/Services/Rooms/RoomPageService.cs`

**Trước:**

```csharp
// FeaturedRooms lọc theo chi nhánh nếu có chọn
var featuredRooms = await _roomQueryService.GetFeaturedRoomTypesAsync(request.HotelId);
```

**Sau:**

```csharp
// FeaturedRooms: Always show ALL room types from entire system (not filtered by branch)
// This ensures the menu cards remain consistent regardless of filter selection
var featuredRooms = await _roomQueryService.GetFeaturedRoomTypesAsync();
```

## 📊 Kết Quả

### Trước Khi Sửa:

- Filter chi nhánh Hà Nội → Chỉ hiển thị 3-4 loại phòng
- Filter chi nhánh Đà Nẵng → Chỉ hiển thị 4-5 loại phòng
- Không nhất quán, người dùng không thấy được toàn bộ loại phòng

### Sau Khi Sửa:

- ✅ Luôn hiển thị đầy đủ 6 loại phòng: Standard, Single, Double, Deluxe, Family, Suite
- ✅ Không bị ảnh hưởng bởi filter chi nhánh
- ✅ Menu card cố định, chỉ danh sách phòng bên dưới thay đổi theo filter
- ✅ Người dùng luôn thấy được tất cả các loại phòng có sẵn trong hệ thống

## 🎯 Các Loại Phòng Trong Hệ Thống

1. **Standard** - Phòng tiêu chuẩn
2. **Single** - Phòng đơn
3. **Double** - Phòng đôi
4. **Deluxe** - Phòng cao cấp
5. **Family** - Phòng gia đình
6. **Suite** - Phòng suite

## ✅ Kiểm Tra

### Build Status:

```
Build succeeded.
2 Warning(s)
0 Error(s)
```

### Database Verification:

```sql
SELECT DISTINCT RoomType FROM Rooms
WHERE RoomType IS NOT NULL AND RoomType != ''
ORDER BY RoomType;
```

Kết quả: 6 loại phòng (Deluxe, Double, Family, Single, Standard, Suite)

## 📝 Lưu Ý

- Menu card hiển thị giá của phòng rẻ nhất trong mỗi loại
- Badge "🔥 Được đặt nhiều" vẫn hoạt động bình thường
- Filter chi nhánh, giá, tiện ích chỉ áp dụng cho danh sách phòng bên dưới
- View đã sử dụng `r.RoomType.Trim()` để hiển thị tên loại phòng (không kèm chi nhánh)
