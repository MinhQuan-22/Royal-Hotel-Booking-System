# Data Contract – Booking Module

## 1. SQL Core Tables
- Hotels(Id, City)
- Rooms(Id, HotelId, Rate, Status, ...)
- Bookings(Id, RoomId, CheckIn, CheckOut, Status, TotalAmount, BookingCode, ...)

## 2. Room Status
- ACTIVE: phòng đang kinh doanh
- MAINTENANCE: phòng đang bảo trì
- INACTIVE: phòng ngừng sử dụng

Lưu ý: Rooms.Status không dùng để biểu diễn booked/unbooked theo ngày.

## 3. Booking Status
- Pending
- Confirmed
- CheckedIn
- CheckedOut
- Completed
- Cancelled

## 4. Confirm-Time Overlap Rule
At payment confirmation time, overlapping bookings are blocked against:
- Confirmed
- CheckedIn

Pending bookings are treated as non-finalized drafts and do not block final confirmation until one booking is confirmed atomically.

## 5. Revenue Analytics Rule
Các booking status được tính doanh thu cho analytics:
- CheckedOut
- Completed

Lưu ý:
- Pending không được tính doanh thu
- Confirmed không được tính doanh thu để tránh ghi nhận doanh thu khi khách chưa hoàn tất kỳ lưu trú
- TV3 phải bám đúng rule này khi viết query Top 3 Revenue Generating Rooms

## 6. Date Overlap Formula
Hai booking bị giao nhau khi:
@CheckIn < CheckOut AND @CheckOut > CheckIn

## 7. SQL ↔ Mongo Mapping
- hotel_id trong MongoDB phải map đúng Hotels.Id
- room_id trong MongoDB (nếu có) phải map đúng Rooms.Id
- Rate, Status, availability luôn lấy từ SQL Server
- description, amenities, images nằm ở MongoDB HotelCatalog

## 8. Legacy Hotel Mapping Rule
- All existing ROYALHOTEL rooms are mapped to Hotels.Id = 1
- Hotels.Id = 1 represents the current real operational property
- Hotels.Id = 2 and Hotels.Id = 3 are seeded as demo properties for MongoDB catalog and analytics demonstration
- Existing legacy rooms must not be randomly reassigned to Hotel 2 or Hotel 3
- If multi-hotel reporting is required, demo rooms and demo bookings must be created separately for Hotel 2 and Hotel 3

## 9. Demo Room Seed Rule
- Demo rooms are created only for HotelId = 2 and HotelId = 3
- Legacy rooms of HotelId = 1 must remain unchanged
- BasePricePerNight must stay aligned with Rate
- IsActive must stay aligned with Status = ACTIVE
- Description and CoverImageUrl are intentionally left NULL for Member 2 to manage through MongoDB HotelCatalog
