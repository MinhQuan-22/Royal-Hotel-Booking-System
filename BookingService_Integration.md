# Booking Service Integration

## 1. Goal
Integrate SQL Server pessimistic locking into the ROYALHOTEL booking confirmation flow to prevent double-booking.

## 2. Files Updated
- 01_sql_schema_refactor.sql
- 02_booking_locking.sql
- CoreBookingService.cs (or equivalent booking service)
- BookingController.cs (or equivalent endpoint/controller)

## 3. Endpoint Flow
1. Frontend sends confirm-payment request
2. Backend validates request
3. Backend calls sp_ConfirmBooking
4. SQL Server performs pessimistic locking
5. If overlap exists, SQL throws a business error
6. Backend catches the error and returns a clear response
7. If no overlap exists, booking status changes from Pending to Confirmed

## 4. Business Errors
- Booking not found
- Only pending bookings can be confirmed
- Room is not active or not available
- Room is no longer available for the selected dates
- Booking status changed during processing

## 5. Failure Path if No Locking is Used
- Request A and Request B read the same room as available
- Both pass the availability check
- Both update booking as Confirmed
- Result: double-booking occurs

## 6. Dependency with Member 2
- Member 2 returns hotel_id / room_id candidates from MongoDB HotelCatalog
- Final room availability is always validated in SQL Server
- MongoDB never decides final booking confirmation

## 7. Dependency with Member 3
- Final booking statuses must be shared with Member 3
- TotalAmount is the source field for revenue analytics
- Revenue report must follow the agreed status rule from DataContract_Booking.md

## 8. Hotel Mapping Clarification
- HotelId = 1 is the primary operational property for all existing legacy ROYALHOTEL rooms
- Additional hotels (HotelId = 2, 3, ...) are seeded for demo, MongoDB catalog mapping, and per-hotel analytics
- Final booking consistency is still enforced entirely in SQL Server regardless of hotel count
