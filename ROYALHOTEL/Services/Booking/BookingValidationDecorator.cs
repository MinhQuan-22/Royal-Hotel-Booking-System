using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.ViewModels.Booking;

namespace ROYALHOTEL.Services.Booking;

/// <summary>
/// Concrete Decorator:
/// bổ sung bước validate trước khi gọi vào core booking service.
/// </summary>
public class BookingValidationDecorator : BookingServiceDecorator
{
    private readonly RoyalHotelDbContext _context;

    public BookingValidationDecorator(IBookingService inner, RoyalHotelDbContext context)
        : base(inner)
    {
        _context = context;
    }

    public override async Task<Models.Booking> CreateBookingAsync(CreateBookingRequest request, int? accountId = null)
    {
        // Validation 1: Room exists and is active
        var room = await _context.Rooms
            .FirstOrDefaultAsync(r => r.Id == request.RoomId && r.IsActive);

        if (room == null)
            throw new InvalidOperationException("Phòng không tồn tại hoặc đang không hoạt động.");

        // Validation 2: CheckOutDate > CheckInDate
        if (request.CheckOutDate <= request.CheckInDate)
            throw new InvalidOperationException("Ngày trả phòng phải sau ngày nhận phòng.");

        // Validation 3: Guests validation (> 0 and <= MaxGuests)
        if (request.Guests <= 0 || request.Guests > room.MaxGuests)
            throw new InvalidOperationException($"Số khách không hợp lệ. Phòng này tối đa {room.MaxGuests} khách.");

        // Validation 4: Overlap check with Confirmed/CheckedIn bookings
        // Dùng Pessimistic Locking qua Stored Procedure giống ConfirmPaymentAsync
        using var transaction = await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.ReadCommitted);
        try
        {
            var hasOverlapParam = new Microsoft.Data.SqlClient.SqlParameter
            {
                ParameterName = "HasOverlap",
                SqlDbType = System.Data.SqlDbType.Bit,
                Direction = System.Data.ParameterDirection.Output
            };

            await _context.Database.ExecuteSqlRawAsync(
                "EXEC sp_RequireBookingLock @RoomId, @CheckIn, @CheckOut, @ExcludeBookingId, @HasOverlap OUTPUT",
                new Microsoft.Data.SqlClient.SqlParameter("RoomId", request.RoomId),
                new Microsoft.Data.SqlClient.SqlParameter("CheckIn", request.CheckInDate),
                new Microsoft.Data.SqlClient.SqlParameter("CheckOut", request.CheckOutDate),
                new Microsoft.Data.SqlClient.SqlParameter("ExcludeBookingId", 0), // Không exclude booking nào vì đang tạo mới
                hasOverlapParam);

            var hasConfirmedOverlap = (bool)hasOverlapParam.Value;

            if (hasConfirmedOverlap)
                throw new InvalidOperationException("Phòng này đã được đặt trong khoảng thời gian anh chọn.");

            // All validations passed, delegate to wrapped service
            var booking = await base.CreateBookingAsync(request, accountId);
            
            await transaction.CommitAsync();
            return booking;
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }
}